import Foundation

/// What the brain hands back to the chat.
struct BrainReply {
    var text: String
    var thoughts: [String] = []
    var cards: [AceCard] = []
    /// Which part of Ace answered, shown after "How I got this" (rules, answer bank, web, LFM3 Omni...).
    var source: String = "rules"
    var mood: OrbMood = .happy
}

/// The parts of the app the brain can use (calendar, checks, opening links...).
@MainActor
protocol BrainHost: AnyObject {
    var settings: SettingsStore { get }
    var memory: MemoryStore { get }
    var sleepCoach: SleepCoach { get }
    func runCheck(spoken: Bool) async -> CheckReport
    func openLink(_ url: URL, title: String)
    func setHandsFree(_ on: Bool) -> String
    var pcPaired: Bool { get }
    func pcCommand(_ action: String, target: String?) async -> (ok: Bool, detail: String)
    func syncNow() async -> String
    func findFiles(_ query: String, largest: Bool) async -> (text: String, hits: [FileHit])
    func findScreenshots(_ query: String) async -> (text: String, hits: [ScreenshotHit])
    func describeLastPhoto() -> BrainReply?
    /// Runs a home command in Apple Home. `confirm` is set when Ace should ask before doing it.
    func homeCommand(_ cmd: HomeCommand, confirmed: Bool) async -> (reply: BrainReply, confirm: HomeCommand?)
    /// Asks an on-device model (only the ones switched on in Settings). Returns the answer and the model's name.
    func freeAnswer(_ question: String) async -> (text: String, model: String)?
    /// LFM3 Omni is downloaded and can run.
    var modelReady: Bool { get }
}

/// Ace V4's brain: rules + a big answer bank + a neural matcher + web research,
/// run as a think loop that keeps trying new ways until it's sure (or out of ideas).
/// The on-device models only get a turn when they're switched on AND nothing else was sure.
@MainActor
final class Brain {
    let bank = QABank()
    let classifier = IntentClassifier()
    weak var host: BrainHost?

    private var lastQuestion = ""
    private var lastAnswer = ""
    private var lastTopic = ""
    private var awaitingAnswerFor: String?
    private var pendingChoices: [QABank.Match] = []
    private var toldModelMissing = false
    /// A home action waiting for a yes (Ace wasn't sure which device you meant).
    private var pendingHome: HomeCommand?

    /// How sure the answer bank has to be to answer straight away.
    static let sure = 0.74
    /// Same, after saying the question another way.
    static let rephraseSure = 0.72
    /// Below this it's a guess, and Ace says so.
    static let guessFloor = 0.58

    // MARK: Think loop

    func respond(to raw: String, onThought: @escaping (String) -> Void) async -> BrainReply {
        var thoughts: [String] = []
        let think: (String) async -> Void = { step in
            thoughts.append(step)
            onThought(step)
            try? await Task.sleep(nanoseconds: 140_000_000)
        }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return BrainReply(text: Say.line(.empty)) }

        // Waiting for the right answer after "that's wrong"?
        if let q = awaitingAnswerFor {
            awaitingAnswerFor = nil
            if IntentRouter.parse(text) == nil, !text.hasSuffix("?") {
                bank.learn(question: q, answer: text, source: "taught", tag: "taught")
                await think("Saving your answer for \"\(q)\"")
                return finish(BrainReply(text: Say.line(.taughtAnswer, ["question": q, "answer": text]), thoughts: thoughts, source: "learned"), question: text)
            }
        }

        // Answering "Should I turn on the desk lamp?"
        if let ask = pendingHome {
            pendingHome = nil
            let t = TextKit.normalize(text)
            if Rx.matches(#"^(yes|yeah|yep|yup|ya|sure|ok|okay|do it|go ahead|please do|please|yes please|sure thing|of course|definitely|y)( please| do it| go ahead)?$"#, t), let host {
                await think("You said yes, so I'm doing it")
                var r = await host.homeCommand(ask, confirmed: true).reply
                r.thoughts = thoughts
                return finish(r, question: text)
            }
            if Rx.matches(#"^(no|nope|nah|no thanks|do not|dont|cancel|never mind|nevermind|stop|n|leave it)( thanks| thank you)?$"#, t) {
                return finish(BrainReply(text: Say.line(.homeCancelled), thoughts: thoughts, source: "home", mood: .idle), question: text)
            }
        }

        // Answering "do you mean A or B?"
        if !pendingChoices.isEmpty {
            let choices = pendingChoices
            pendingChoices = []
            if let pick = choose(text, from: choices) {
                await think("You picked \"\(pick.wording)\"")
                var r = answer(from: pick)
                r.thoughts = thoughts
                return finish(r, question: pick.wording)
            }
        }

        await think("Reading: \"\(text)\"")

        // LFM3 Omni picked as the brain: it answers, except for things only Ace can do (timers, checks, calendar...).
        if let host, host.settings.modelBrain {
            if let r = await modelBrainAnswer(text, host: host, think: think) {
                var reply = r
                thoughts.append("Answered by: \(reply.source)")
                reply.thoughts = thoughts
                return finish(reply, question: text)
            }
        }

        let parts = splitParts(text)
        if parts.count > 1 {
            await think("That's \(parts.count) questions. I'll answer each one.")
            var replies: [BrainReply] = []
            for p in parts {
                replies.append(await solve(p, think: think))
            }
            var combined = BrainReply(text: replies.map(\.text).joined(separator: "\n\n"), thoughts: thoughts)
            combined.cards = replies.flatMap(\.cards)
            combined.source = Self.joinSources(replies.map(\.source))
            combined.mood = replies.contains { $0.mood == .alert } ? .alert : .happy
            thoughts.append("Answered by: \(combined.source)")
            combined.thoughts = thoughts
            return finish(combined, question: text)
        }
        var reply = await solve(text, think: think)
        thoughts.append("Answered by: \(reply.source)")
        reply.thoughts = thoughts
        return finish(reply, question: text)
    }

    private func finish(_ r: BrainReply, question: String) -> BrainReply {
        var r = r
        // Never show or say a model's hidden thinking or control tags.
        r.text = TextKit.stripModelTags(r.text)
        if r.text.isEmpty && r.cards.isEmpty { r.text = Say.line(.empty) }
        lastQuestion = question
        lastAnswer = r.text
        return r
    }

    static func joinSources(_ sources: [String]) -> String {
        var out: [String] = []
        for s in sources where !out.contains(s) { out.append(s) }
        return out.joined(separator: " + ")
    }

    private func solve(_ text: String, think: (String) async -> Void) async -> BrainReply {
        var notes: [String] = []
        let decision = decide(text, notes: &notes)
        for n in notes { await think(n) }

        switch decision {
        case .rule(let intent), .classified(let intent):
            if let r = await run(intent, text: text, think: think) { return r }
            await think("That skill couldn't do it, so I'll keep looking")
        case .bank(let m):
            return answer(from: m)
        case .clarify(let a, let b):
            pendingChoices = [a, b]
            return BrainReply(text: Say.line(.clarify, ["first": a.wording, "second": b.wording]), source: "answer bank", mood: .idle)
        case .weak, .none:
            break
        }

        // Research it on the web, then learn it (only when the brain wasn't sure).
        if let host, host.settings.webAnswers, SystemMonitor.shared.online {
            await think("Not sure yet, so I'm researching it on the web")
            if let r = await WebService.research(text), r.confidence >= 0.5 {
                await think("Read \(max(1, r.sources.count)) source\(r.sources.count == 1 ? "" : "s") and picked the best sentences")
                lastTopic = r.title
                let short = Self.brief(r.summary, query: text)
                bank.learn(question: text, answer: short, source: "learned", tag: "learned.web", url: r.sources.first?.url.absoluteString)
                await think("Saved it to my answer bank so I'll know it next time")
                let card = WebCard(title: r.title, summary: r.summary, bullets: r.bullets, imageURL: r.imageURL, sources: r.sources)
                return BrainReply(text: short, cards: [.web(card)], source: "web")
            }
        }

        // Fall back to LFM3 Omni (or Apple's model) only when that's switched on and nothing above was sure.
        if let host, (host.settings.useLocalModel && host.modelReady) || host.settings.useAppleModel {
            await think(host.settings.useLocalModel && host.modelReady ? "I'm not sure, so I'm asking LFM3 Omni" : "I'm not sure, so I'm asking Apple's model")
            if let a = await host.freeAnswer(text) {
                let clean = TextKit.stripModelTags(a.text)
                if !clean.isEmpty {
                    await think("\(a.model) answered, so I'm going with that")
                    return BrainReply(text: clean, source: a.model)
                }
            }
        }

        // A weaker match is better than nothing, but say so.
        if case .weak(let m) = decision {
            await think("Going with my best guess")
            var r = answer(from: m)
            r.text = Say.line(.guess, ["question": m.wording]) + " " + r.text
            return r
        }

        await think("Out of ideas for now")
        lastTopic = Summarizer.topic(of: text)
        var r = BrainReply(text: Say.line(.dontKnow, ["question": TextKit.normalize(text)]), source: "rules", mood: .idle)
        if let host, let link = Sites.searchLink(text, site: nil, engine: host.settings.searchEngine) {
            r.cards = [.links([LinkItem(title: link.title, url: link.url)])]
        }
        return r
    }

    /// LFM3 Omni as the brain. Returns nil to let Normal Ace answer instead
    /// (for things only Ace can do, or when the model isn't on this iPad).
    private func modelBrainAnswer(_ text: String, host: BrainHost, think: (String) async -> Void) async -> BrainReply? {
        if let intent = IntentRouter.parse(text), intent.isAction {
            await think("That's something I do myself (\(describe(intent))), not a question for LFM3 Omni")
            return nil
        }
        guard host.modelReady else {
            await think("LFM3 Omni isn't on this iPad yet, so Normal Ace is answering")
            guard !toldModelMissing else { return nil }
            toldModelMissing = true
            var r = await solve(text, think: think)
            r.text += "\n\n" + Say.line(.modelMissing)
            return r
        }
        await think("Asking LFM3 Omni")
        if let a = await host.freeAnswer(text) {
            let clean = TextKit.stripModelTags(a.text)
            if !clean.isEmpty { return BrainReply(text: clean, source: a.model) }
        }
        await think("LFM3 Omni didn't answer, so Normal Ace is taking it")
        return nil
    }

    /// Web answers stay short: one or two sentences (the card has the rest).
    static func brief(_ text: String, query: String) -> String {
        let clean = TextKit.stripModelTags(text)
        let sentences = Summarizer.sentences(clean)
        guard !sentences.isEmpty else { return clean }
        var out = sentences[0]
        if sentences.count > 1, out.count + sentences[1].count < 230 { out += " " + sentences[1] }
        if out.count > 280 {
            let cut = out.prefix(277)
            let end = cut.lastIndex(of: " ") ?? cut.endIndex
            out = String(cut[..<end]) + "..."
        }
        return out
    }

    // MARK: Deciding what something means

    enum Decision {
        case rule(Intent)
        case bank(QABank.Match)
        case classified(Intent)
        case weak(QABank.Match)
        case clarify(QABank.Match, QABank.Match)
        case none

        var isSure: Bool {
            switch self {
            case .rule, .bank, .classified: return true
            default: return false
            }
        }
    }

    /// Works out what a message means: rules, follow-ups, the answer bank, typo fixes,
    /// the neural classifier, and saying it another way. Only reads; it never does anything.
    func decide(_ text: String, notes: inout [String], followUps: Bool = true) -> Decision {
        let norm = TextKit.normalize(text)
        guard !norm.isEmpty else { return .none }

        // 1. Rules.
        if let intent = IntentRouter.parse(text) {
            notes.append("Rule match: \(describe(intent))")
            return .rule(intent)
        }

        // 2. The answer bank (words + neural meaning).
        var matches = bank.search(norm)

        // 3. Follow-ups like "what about saturn" or "how many moons does it have".
        if followUps, let f = followUp(norm) {
            let plain = matches.first?.score ?? 0
            var inner: [String] = []
            let d = decide(f.question, notes: &inner, followUps: false)
            // "and italy?" is always a follow-up. "what continent is it in" is one when it fits at least as well.
            let fits: Bool
            switch d {
            case .bank(let m): fits = f.isAbout || plain < Self.sure || m.score >= plain
            case .rule, .classified: fits = f.isAbout || plain < Self.sure
            default: fits = false
            }
            if fits {
                notes.append("Sounds like a follow-up to \"\(lastQuestion)\", so I read it as \"\(f.question)\"")
                notes += inner
                return d
            }
        }

        if let best = matches.first {
            notes.append(String(format: "Answer bank: closest is \"%@\" (%.0f%% sure)", best.wording, best.score * 100))
            if best.score >= Self.sure { return .bank(best) }
        } else {
            notes.append("Nothing close in my answer bank")
        }

        // 4. Fix typos and look again.
        let fixed = spellFix(norm)
        if fixed != norm {
            notes.append("Fixing typos: \"\(fixed)\"")
            if let intent = IntentRouter.parse(fixed) {
                notes.append("Rule match: \(describe(intent))")
                return .rule(intent)
            }
            let again = bank.search(fixed)
            if let best = again.first, best.score >= Self.sure {
                notes.append(String(format: "Now it's \"%@\" (%.0f%% sure)", best.wording, best.score * 100))
                return .bank(best)
            }
            matches = Self.merge(matches, again)
        }

        // 5. The neural classifier, for skills said in unusual ways.
        if let c = classifier.classify(fixed), c.score >= 0.8, let intent = intent(for: c.skill, text: text) {
            notes.append(String(format: "Sounds like the %@ skill (%.0f%%)", c.skill.rawValue, c.score * 100))
            return .classified(intent)
        }

        // 6. Say it another way and look again.
        let rephrased = rephrase(fixed)
        if rephrased != fixed, !rephrased.isEmpty {
            notes.append("Trying it another way: \"\(rephrased)\"")
            if let intent = IntentRouter.parse(rephrased) {
                notes.append("Rule match: \(describe(intent))")
                return .rule(intent)
            }
            let again = bank.search(rephrased)
            if let best = again.first, best.score >= Self.rephraseSure { return .bank(best) }
            matches = Self.merge(matches, again)
        }

        // 7. Two answers fit just as well: ask which one.
        if matches.count >= 2 {
            let a = matches[0], b = matches[1]
            if a.score >= 0.62, a.score < Self.sure, a.score - b.score < 0.015, a.entry.id != b.entry.id, a.wording != b.wording {
                notes.append("Two answers fit equally well, so I'll ask")
                return .clarify(a, b)
            }
        }
        if let best = matches.first, best.score >= Self.guessFloor { return .weak(best) }
        return .none
    }

    private static func merge(_ a: [QABank.Match], _ b: [QABank.Match]) -> [QABank.Match] {
        var best: [String: QABank.Match] = [:]
        for m in a + b where (best[m.entry.id]?.score ?? -1) < m.score { best[m.entry.id] = m }
        return best.values.sorted { $0.score > $1.score }
    }

    // MARK: Multi-part questions

    /// Splits "what's the capital of japan, and how many moons does mars have?" into parts,
    /// but only when every part makes sense on its own.
    func splitParts(_ text: String) -> [String] {
        let attempts = [Self.splitOnPunctuation(text).flatMap(Self.splitOnJoiners), Self.splitOnJoiners(text)]
        for pieces in attempts {
            let parts = pieces.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            guard parts.count >= 2, parts.count <= 4 else { continue }
            if let ok = standAlone(parts) { return ok }
        }
        return [text]
    }

    private func standAlone(_ parts: [String]) -> [String]? {
        let lead = TextKit.normalize(parts[0]).split(separator: " ").first.map(String.init)
        let leadVerbs: Set<String> = ["check", "set", "open", "show", "tell", "give", "search", "find", "start"]
        var out: [String] = []
        for p in parts {
            if TextKit.words(p).count >= 2, isSure(p) {
                out.append(p)
            } else if let lead, leadVerbs.contains(lead), isSure(lead + " " + p) {
                out.append(lead + " " + p)
            } else {
                return nil
            }
        }
        return out
    }

    private func isSure(_ text: String) -> Bool {
        var ignored: [String] = []
        return decide(text, notes: &ignored, followUps: false).isSure
    }

    private static func splitOnPunctuation(_ text: String) -> [String] {
        var t = text
        // Sentence ends (not decimal points), semicolons and commas become breaks.
        t = t.replacingOccurrences(of: #"(?<=[?!;])\s+"#, with: "\u{1F}", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<=[A-Za-z])\.\s+"#, with: "\u{1F}", options: .regularExpression)
        t = t.replacingOccurrences(of: #",\s*(?:and\s+(?:also\s+)?)?"#, with: "\u{1F}", options: .regularExpression)
        return t.components(separatedBy: "\u{1F}")
    }

    private static func splitOnJoiners(_ text: String) -> [String] {
        let t = text.replacingOccurrences(of: #"\s+(?:and also|and then|and)\s+"#, with: "\u{1F}", options: [.regularExpression, .caseInsensitive])
        return t.components(separatedBy: "\u{1F}")
    }

    // MARK: Follow-ups

    struct FollowUp {
        var question: String
        var isAbout: Bool
    }

    /// "what about saturn" after "how many moons does jupiter have" -> "how many moons does saturn have".
    /// "how many moons does it have" after "tell me about mars" -> "how many moons does mars have".
    private func followUp(_ norm: String) -> FollowUp? {
        guard !lastQuestion.isEmpty else { return nil }
        let last = TextKit.normalize(lastQuestion)
        guard last != norm else { return nil }
        let words = last.split(separator: " ").map(String.init)

        if let g = Rx.groups(#"^(?:and |ok |okay |so |now )?(?:what about|how about|what of|same for|same with|and for|and)\s+(.+)$"#, norm) {
            var x = g[0].trimmingCharacters(in: .whitespaces)
            for p in ["in ", "on ", "of ", "for ", "at ", "with "] where x.hasPrefix(p) { x = String(x.dropFirst(p.count)) }
            // Try the new thing in each place the subject could be, and keep the one that makes the best question.
            var best: (question: String, score: Double)?
            for span in subjectSpans(in: last) {
                var y = x
                let before = span.lowerBound > 0 ? words[span.lowerBound - 1] : ""
                if ["a", "an", "the"].contains(before) {
                    for art in ["a ", "an ", "the "] where y.hasPrefix(art) { y = String(y.dropFirst(art.count)) }
                }
                guard !y.isEmpty, y != words[span].joined(separator: " ") else { continue }
                var swapped = words
                swapped.replaceSubrange(span, with: [y])
                let q = swapped.joined(separator: " ")
                let score = bank.search(q).first?.score ?? (IntentRouter.parse(q) != nil ? 0.9 : 0)
                if best == nil || score > best!.score { best = (q, score) }
            }
            return best.map { FollowUp(question: $0.question, isAbout: true) }
        }

        guard let span = entitySpan(in: last) else { return nil }
        let entity = words[span].joined(separator: " ")
        let pronouns: [String: String] = ["it": entity, "its": entity, "they": entity, "them": entity,
                                          "there": "in " + entity, "that": entity, "this": entity]
        let mine = norm.split(separator: " ").map(String.init)
        guard mine.contains(where: { pronouns[$0] != nil }) else { return nil }
        let swapped = mine.map { pronouns[$0] ?? $0 }.joined(separator: " ")
        return FollowUp(question: swapped, isAbout: false)
    }

    private static let notSubject: Set<String> = ["what", "who", "how", "when", "where", "why", "which", "tell", "many", "much", "long",
                                                  "does", "do", "is", "are", "the", "a", "an", "of", "in", "on", "about", "called", "say",
                                                  "you", "have", "has", "me", "facts", "know", "there", "it", "its"]

    /// Every place the subject of a question could be, likeliest first.
    private func subjectSpans(in text: String) -> [Range<Int>] {
        let words = text.split(separator: " ").map(String.init)
        var out: [Range<Int>] = []
        if let e = entitySpan(in: text) { out.append(e) }
        let single = words.indices
            .filter { !Self.notSubject.contains(words[$0]) && !TextKit.stopwords.contains(words[$0]) && words[$0].count > 1 }
            .sorted { bank.wordFrequency(words[$0]) < bank.wordFrequency(words[$1]) }
        for i in single where !out.contains(i..<(i + 1)) { out.append(i..<(i + 1)) }
        return out
    }

    /// The subject of a question: its rarest words ("japan" in "what is the capital of japan").
    private func entitySpan(in text: String) -> Range<Int>? {
        let words = text.split(separator: " ").map(String.init)
        let skip = Self.notSubject
        var best: (index: Int, freq: Int)?
        for (i, w) in words.enumerated() where !skip.contains(w) && !TextKit.stopwords.contains(w) && w.count > 1 {
            let f = bank.wordFrequency(w)
            if best == nil || f <= best!.freq { best = (i, f) }
        }
        guard let b = best else { return nil }
        // Grow it to neighbors that are also rare ("new zealand", "united kingdom").
        let limit = max(40, b.freq * 3)
        var lo = b.index, hi = b.index
        while lo > 0, !skip.contains(words[lo - 1]), !TextKit.stopwords.contains(words[lo - 1]), bank.wordFrequency(words[lo - 1]) <= limit { lo -= 1 }
        while hi + 1 < words.count, !skip.contains(words[hi + 1]), !TextKit.stopwords.contains(words[hi + 1]), bank.wordFrequency(words[hi + 1]) <= limit { hi += 1 }
        return lo..<(hi + 1)
    }

    /// Picks from "do you mean A or B?" ("the first one", "B", "2").
    private func choose(_ text: String, from choices: [QABank.Match]) -> QABank.Match? {
        let t = TextKit.normalize(text)
        if Rx.matches(#"\b(first|1st|1|former)\b"#, t), choices.count > 0, !Rx.matches(#"\b(second|2nd|two|2|latter)\b"#, t) { return choices[0] }
        if Rx.matches(#"\b(second|2nd|two|2|latter)\b"#, t), choices.count > 1 { return choices[1] }
        for c in choices where t == c.wording || Summarizer.overlap(query: t, text: c.wording) >= 0.99 { return c }
        return nil
    }

    // MARK: Typos

    /// Words the rules know, so typos in commands get fixed too.
    private static let ruleWords: Set<String> = [
        "remind", "reminder", "timer", "minutes", "minute", "seconds", "second", "hours", "hour", "weather", "forecast",
        "battery", "storage", "calendar", "schedule", "alarm", "recipe", "youtube", "google", "open", "search", "tomorrow",
        "today", "tonight", "check", "spell", "convert", "roman", "numerals", "random", "number", "between", "christmas",
        "halloween", "birthday", "until", "days", "time", "date", "please", "thanks", "thank", "hello", "goodbye",
        "morning", "afternoon", "evening", "remember", "forget", "name", "sounds", "settings", "restart", "computer",
        "event", "meeting", "practice", "delete", "cancel", "everything", "bedtime", "sleep", "screenshots", "files",
        "weekend", "week", "raining", "temperature", "memory", "space", "status", "website", "minecraft", "roblox",
    ]

    /// Fixes words Ace doesn't know into the closest word it does ("capitol" -> "capital").
    func spellFix(_ norm: String) -> String {
        var words = norm.split(separator: " ").map(String.init)
        for i in words.indices {
            let w = words[i]
            guard w.count >= 4, w.allSatisfy({ $0.isLetter }), !Self.ruleWords.contains(w), bank.wordFrequency(w) == 0,
                  !TextKit.stopwords.contains(w) else { continue }
            let maxDistance = w.count >= 8 ? 2 : 1
            var found: [String: (d: Int, f: Int)] = [:]
            for candidate in bank.vocabulary(near: w) + Self.ruleWords.filter({ abs($0.count - w.count) <= maxDistance }) {
                let d = TextKit.editDistance(w, candidate, limit: maxDistance)
                guard d <= maxDistance else { continue }
                found[candidate] = (d, max(1, bank.wordFrequency(candidate)) + (Self.ruleWords.contains(candidate) ? 50 : 0))
            }
            guard let closest = found.values.map({ $0.d }).min() else { continue }
            let close = found.filter { $0.value.d == closest }.sorted { $0.value.f > $1.value.f }.prefix(6).map { $0.key }
            if close.count == 1 { words[i] = close[0]; continue }
            // "leep year": "leap" and "sleep" are both one letter off, so keep the one that makes a real question.
            func fit(_ c: String) -> Double {
                var trial = words
                trial[i] = c
                return bank.search(trial.joined(separator: " ")).first?.score ?? 0
            }
            var best = close[0], bestFit = fit(close[0])
            for c in close.dropFirst() {
                let f = fit(c)
                if f > bestFit { best = c; bestFit = f }
            }
            words[i] = best
        }
        return words.joined(separator: " ")
    }

    // MARK: Understanding (no side effects, used by the smartness test)

    /// What Ace decided something means, without doing anything.
    enum Understanding: Equatable {
        case skill(String)
        case bank(String)
        case weakBank(String)
        case clarify([String])
        case unknown
        indirect case multi([Understanding])
    }

    /// Works out what the text means the same way `respond` does, minus the web and anything with side effects.
    func understand(_ raw: String) -> Understanding {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .unknown }
        let parts = splitParts(text)
        if parts.count > 1 { return .multi(parts.map { understandOne($0) }) }
        return understandOne(text)
    }

    /// Records a turn as if Ace had answered it (for follow-up questions in tests).
    func noteTurn(_ question: String) {
        lastQuestion = question
    }

    /// Starts a fresh conversation.
    func resetConversation() {
        lastQuestion = ""
        lastAnswer = ""
        lastTopic = ""
        awaitingAnswerFor = nil
        pendingChoices = []
        pendingHome = nil
    }

    private func understandOne(_ text: String) -> Understanding {
        var notes: [String] = []
        switch decide(text, notes: &notes) {
        case .rule(let i), .classified(let i): return .skill(i.kind)
        case .bank(let m): return .bank(m.entry.id)
        case .weak(let m): return .weakBank(m.entry.id)
        case .clarify(let a, let b): return .clarify([a.entry.id, b.entry.id])
        case .none: return .unknown
        }
    }

    // MARK: Answers

    private func answer(from m: QABank.Match) -> BrainReply {
        let e = m.entry
        let i = VariantPicker.shared.pick("bank." + e.id, count: e.a.count)
        var text = e.a[i]
        let name = host?.settings.userName ?? ""
        text = text.replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: " ,", with: ",").replacingOccurrences(of: " !", with: "!")
            .replacingOccurrences(of: "  ", with: " ")
        lastTopic = Summarizer.topic(of: m.wording)
        let source = e.source == "builtin" || e.source == nil ? "answer bank" : "learned"
        return BrainReply(text: text, source: source)
    }

    /// Drops filler like "can you tell me" and swaps a few words for ones the bank knows.
    private func rephrase(_ text: String) -> String {
        var t = " " + TextKit.normalize(text) + " "
        let fillers = ["can you tell me", "could you tell me", "do you know", "i want to know", "i wonder", "tell me",
                       "please", "hey ace", "ace", "real quick", "quick question", "i was wondering", "explain",
                       "i need to know", "can you", "could you", "would you", "i would like to know", "any idea",
                       "do you happen to know", "i am curious", "just wondering", "help me", "for me", "exactly",
                       "actually", "again", "right now", "you think", "basically", "like"]
        for f in fillers { t = t.replacingOccurrences(of: " \(f) ", with: " ") }
        let swaps = ["made you": "created you", "built you": "created you", "kinda": "kind of", "planets": "planet",
                     "favourite": "favorite", "colour": "color", "whats": "what is", "how come": "why",
                     "what is the name of": "what is", "what do you call": "what is", "is called": "is",
                     "how much is": "what is", "which is": "what is", "name the": "what is the"]
        for (a, b) in swaps { t = t.replacingOccurrences(of: " \(a) ", with: " \(b) ") }
        return t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    private func intent(for skill: IntentClassifier.Skill, text: String) -> Intent? {
        switch skill {
        case .recipe: return .recipe(Summarizer.topic(of: text))
        case .weather: return .weather(place: nil)
        case .timer: return DateParser.duration(in: text).map { .timer(seconds: $0.seconds, label: "Timer") }
        case .reminder: return .reminder(text: text)
        case .calendarAdd: return .calendarAdd(text: text)
        case .calendarList: return .calendarList(text: TextKit.normalize(text))
        case .check: return .check
        case .battery: return .battery
        case .storage: return .storage
        case .bedtime: return .bedtime
        case .joke: return nil
        case .webSearch: return nil
        }
    }

    private func describe(_ i: Intent) -> String {
        switch i {
        case .greeting: return "a hello"
        case .summon: return "you calling my name"
        case .thanks: return "a thank you"
        case .goodbye: return "a goodbye"
        case .time: return "the time"
        case .date: return "today's date"
        case .daysUntil: return "a countdown"
        case .math: return "math"
        case .convert: return "a unit conversion"
        case .roman: return "Roman numerals"
        case .randomNumber: return "a random number"
        case .spell: return "spelling"
        case .timer: return "a timer"
        case .reminder: return "a reminder"
        case .alarm: return "an alarm"
        case .calendarAdd: return "adding to the calendar"
        case .calendarEdit: return "changing an event"
        case .calendarDelete: return "deleting an event"
        case .calendarList: return "your schedule"
        case .openSite: return "opening a website"
        case .searchTab: return "a web search tab"
        case .recipe: return "a recipe"
        case .weather: return "the weather"
        case .check: return "a full check"
        case .battery: return "the battery"
        case .storage: return "storage"
        case .memoryUsage: return "memory use"
        case .network: return "the network"
        case .largeFiles: return "big files"
        case .findFiles: return "file search"
        case .findScreenshots: return "screenshot search"
        case .describePhoto: return "your picture"
        case .bedtime: return "bedtime"
        case .remember: return "something to remember"
        case .setName: return "your name"
        case .recall: return "something you told me"
        case .recallAll: return "what I remember"
        case .forget: return "forgetting something"
        case .handsFree: return "hands-free mode"
        case .pcPower: return "your PC's power"
        case .pcApp: return "an app window"
        case .pcStatus: return "your PC"
        case .syncNow: return "syncing"
        case .sounds: return "my sounds"
        case .tellMore: return "more on the last topic"
        case .repeatLast: return "repeating myself"
        case .correction: return "a correction"
        case .teach: return "teaching me"
        case .ipadOnlyLimit: return "an iPad limit"
        case .home: return "your home"
        }
    }

    // MARK: Skills

    private func run(_ intent: Intent, text: String, think: (String) async -> Void) async -> BrainReply? {
        guard let host else { return nil }
        let name = host.settings.userName
        let who = name.isEmpty ? "" : ", \(name)"
        let now = Date()
        switch intent {
        case .greeting:
            let hour = Calendar.current.component(.hour, from: now)
            let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
            return BrainReply(text: Say.line(.greeting, ["hello": part, "who": who]))

        case .summon:
            return BrainReply(text: Say.line(.summon, ["who": who]), mood: .happy)

        case .thanks:
            return BrainReply(text: Say.line(.thanks, ["who": who]))

        case .goodbye:
            return BrainReply(text: Say.line(.goodbye, ["who": who]), mood: .idle)

        case .time:
            return BrainReply(text: Say.line(.time, ["time": now.formatted(date: .omitted, time: .shortened)]))

        case .date:
            return BrainReply(text: Say.line(.date, ["date": now.formatted(.dateTime.weekday(.wide).month(.wide).day().year())]))

        case .daysUntil(let thing):
            guard let target = Holidays.date(for: thing, after: now) ?? DateParser.find(in: thing, now: now)?.date else { return nil }
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: target)).day ?? 0
            if days == 0 { return BrainReply(text: Say.line(.daysUntilToday, ["thing": thing])) }
            return BrainReply(text: Say.line(.daysUntil, ["count": "\(days) day\(days == 1 ? "" : "s")", "thing": thing,
                                                          "when": target.formatted(.dateTime.weekday(.wide).month(.wide).day())]))

        case .math(let expr):
            guard let v = try? MathEval.evaluate(expr) else { return nil }
            await think("Working it out: \(expr)")
            return BrainReply(text: Say.line(.math, ["expr": expr.replacingOccurrences(of: "pctof", with: "% of"), "value": MathEval.format(v)]))

        case .convert(let q):
            guard let r = UnitConvert.convert(q) else { return nil }
            return BrainReply(text: r)

        case .roman(let s):
            if let n = Int(s), let r = Roman.toRoman(n) { return BrainReply(text: Say.line(.toRoman, ["n": "\(n)", "roman": r])) }
            if let n = Roman.fromRoman(s) { return BrainReply(text: Say.line(.fromRoman, ["roman": s.uppercased(), "n": "\(n)"])) }
            return BrainReply(text: Say.line(.romanRange))

        case .randomNumber(let a, let b):
            return BrainReply(text: Say.line(.randomNumber, ["n": "\(Int.random(in: a...b))", "low": "\(a)", "high": "\(b)"]))

        case .spell(let word):
            let letters = word.uppercased().map(String.init).joined(separator: "-")
            return BrainReply(text: Say.line(.spell, ["word": word, "letters": letters]))

        case .timer(let seconds, let label):
            let id = "timer-\(UUID().uuidString)"
            let fire = now.addingTimeInterval(seconds)
            let ok = await Notifier.schedule(id: id, title: label, body: "Your \(DateParser.sayDuration(seconds)) timer is done.", at: fire, category: "timer")
            let card = TimerCard(label: label, fireDate: fire, notificationID: id)
            let note = ok ? "" : " " + Say.line(.timerNoAlerts)
            return BrainReply(text: Say.line(.timerSet, ["label": label, "duration": DateParser.sayDuration(seconds)]) + note, cards: [.timer(card)])

        case .alarm:
            return BrainReply(text: Say.line(.alarm))

        case .reminder(let raw):
            return await reminder(raw, think: think)

        case .calendarAdd(let raw):
            return await calendarAdd(raw, think: think)

        case .calendarEdit(let raw):
            return await calendarEdit(raw, think: think)

        case .calendarDelete(let raw):
            return await calendarDelete(raw, think: think)

        case .calendarList(let t):
            return await calendarList(t, think: think)

        case .openSite(let target):
            guard let link = Sites.link(for: target, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: Say.line(.openSite, ["site": link.title]), cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .searchTab(let query, let site):
            guard let link = Sites.searchLink(query, site: site, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: Say.line(.searchTab, ["site": site.flatMap { Sites.lookup($0)?.name } ?? "the web", "query": query]), cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .recipe(let dish):
            await think("Looking up a recipe for \(dish)")
            guard let card = await WebService.recipe(dish) else {
                return BrainReply(text: Say.line(.recipeNotFound, ["dish": dish]), mood: .idle)
            }
            lastTopic = card.name
            return BrainReply(text: Say.line(.recipeFound, ["name": card.name, "ingredients": "\(card.ingredients.count)", "steps": "\(card.steps.count)"]), cards: [.recipe(card)], source: "web")

        case .weather(let place):
            let saved = UserDefaults.standard.string(forKey: "weatherCity")
            guard let city = place ?? saved, !city.isEmpty else {
                return BrainReply(text: Say.line(.weatherAskCity), mood: .idle)
            }
            await think("Checking the forecast for \(city)")
            guard let card = await WebService.weather(place: city, fahrenheit: host.settings.useFahrenheit) else {
                return BrainReply(text: Say.line(.weatherFail, ["city": city]), mood: .idle)
            }
            UserDefaults.standard.set(city, forKey: "weatherCity")
            let d = WebService.describe(code: card.code)
            var s = Say.line(.weatherNow, ["temp": "\(Int(card.temperature.rounded()))\(card.unit)", "sky": d.text, "place": card.place])
            if let today = card.days.first {
                let rain = today.rainChance.map { ", \($0)% chance of rain" } ?? ""
                s += " " + Say.line(.weatherToday, ["high": "\(Int(today.high.rounded()))\(card.unit)",
                                                    "low": "\(Int(today.low.rounded()))\(card.unit)", "rain": rain])
            }
            return BrainReply(text: s, cards: [.weather(card)], source: "web")

        case .check:
            await think("Waking up to look around")
            let report = await host.runCheck(spoken: false)
            return BrainReply(text: report.summary, cards: [.check(report)], mood: report.needsAttention ? .alert : .happy)

        case .battery:
            let s = SystemMonitor.shared.snapshot()
            guard let level = s.batteryLevel else { return BrainReply(text: Say.line(.batteryUnknown)) }
            let pct = Int((level * 100).rounded())
            let slot = ["pct": "\(pct)"]
            var t: String
            switch s.batteryState {
            case .charging: t = Say.line(.batteryCharging, slot)
            case .full: t = Say.line(.batteryFull, slot)
            default: t = Say.line(pct <= 20 ? .batteryLow : .batteryOK, slot)
            }
            if s.lowPower { t += " " + Say.line(.lowPowerOn) }
            return BrainReply(text: t, mood: pct <= 20 && s.batteryState == .unplugged ? .alert : .happy)

        case .storage:
            let s = SystemMonitor.shared.snapshot()
            guard let free = s.freeBytes, let total = s.totalBytes, total > 0 else { return BrainReply(text: Say.line(.storageUnknown)) }
            let pct = Int(Double(free) / Double(total) * 100)
            var t = Say.line(.storage, ["free": SystemMonitor.bytes(free), "total": SystemMonitor.bytes(total), "pct": "\(pct)"])
            if pct < 10 { t += " " + Say.line(.storageLow) }
            return BrainReply(text: t, mood: pct < 10 ? .alert : .happy)

        case .memoryUsage:
            let s = SystemMonitor.shared.snapshot()
            return BrainReply(text: Say.line(.memoryUsage, ["ram": SystemMonitor.bytes(s.deviceMemoryBytes), "app": SystemMonitor.bytes(s.appMemoryBytes),
                                                            "free": SystemMonitor.bytes(s.availableMemoryBytes)]))

        case .network:
            let s = SystemMonitor.shared.snapshot()
            if !s.online { return BrainReply(text: Say.line(.offline), mood: .alert) }
            return BrainReply(text: Say.line(s.onWiFi ? .onlineWiFi : .onlineCellular))

        case .largeFiles:
            await think("Looking through the folders you shared with me")
            let r = await host.findFiles("", largest: true)
            return BrainReply(text: r.text, cards: r.hits.isEmpty ? [] : [.files(r.hits)])

        case .findFiles(let q):
            await think("Searching your shared folders for \"\(q)\"")
            let r = await host.findFiles(q, largest: false)
            return BrainReply(text: r.text, cards: r.hits.isEmpty ? [] : [.files(r.hits)])

        case .findScreenshots(let q):
            await think("Reading the text in your screenshots")
            let r = await host.findScreenshots(q)
            return BrainReply(text: r.text, cards: r.hits.isEmpty ? [] : [.screenshots(r.hits)])

        case .describePhoto:
            return host.describeLastPhoto() ?? BrainReply(text: Say.line(.noPhoto))

        case .bedtime:
            let a = host.sleepCoach.advice(now: now)
            return BrainReply(text: a.text)

        case .remember(let fact):
            host.memory.add(fact)
            return BrainReply(text: Say.line(.remembered, ["fact": MemoryStore.youForm(fact)]), source: "memory")

        case .setName(let n):
            let clean = n.split(separator: " ").map { TextKit.capitalizeFirst(String($0)) }.joined(separator: " ")
            host.settings.userName = clean
            return BrainReply(text: Say.line(.setName, ["name": clean]), source: "memory")

        case .recall(let what):
            if ["name", "name again"].contains(what) {
                return BrainReply(text: name.isEmpty ? Say.line(.noNameYet) : Say.line(.yourName, ["name": name]), source: "memory")
            }
            if let f = host.memory.recall("my " + what).first {
                return BrainReply(text: TextKit.capitalizeFirst(MemoryStore.youForm(f.text)) + ".", source: "memory")
            }
            return BrainReply(text: Say.line(.recallMissing, ["what": what]), source: "memory", mood: .idle)

        case .recallAll:
            let facts = host.memory.facts
            if facts.isEmpty && name.isEmpty { return BrainReply(text: Say.line(.recallNothing), source: "memory") }
            var lines: [String] = []
            if !name.isEmpty { lines.append("Your name is \(name).") }
            lines += facts.prefix(12).map { "• " + TextKit.capitalizeFirst(MemoryStore.youForm($0.text)) }
            return BrainReply(text: Say.line(.recallHeader) + "\n" + lines.joined(separator: "\n"), source: "memory")

        case .forget(let what):
            let n = host.memory.forget(matching: what)
            return BrainReply(text: n == 0 ? Say.line(.forgotNothing) : Say.line(.forgotSome, ["count": "\(n) thing\(n == 1 ? "" : "s")"]), source: "memory")

        case .handsFree(let on):
            return BrainReply(text: host.setHandsFree(on))

        case .pcPower(let action):
            guard host.pcPaired else {
                return BrainReply(text: Say.line(.pcNotPaired), mood: .idle)
            }
            await think("Telling Nimbus to \(action)")
            let r = await host.pcCommand(action, target: nil)
            let card = PowerCard(action: action, status: r.ok ? .done : .failed, detail: r.detail)
            return BrainReply(text: r.ok ? Say.line(action == "restart" ? .pcRestarting : .pcShuttingDown) : r.detail,
                              cards: [.power(card)], mood: r.ok ? .happy : .alert)

        case .pcApp(let action, let app, let onPC):
            if onPC || host.pcPaired {
                guard host.pcPaired else {
                    return BrainReply(text: Say.line(.pcAppNotPaired, ["action": action]), mood: .idle)
                }
                let r = await host.pcCommand(action, target: app)
                return BrainReply(text: r.ok ? Say.line(.pcAppDone, ["action": action, "app": app]) : r.detail, mood: r.ok ? .happy : .alert)
            }
            return BrainReply(text: Say.line(.pcAppOnIPad, ["action": action, "app": app]), mood: .idle)

        case .pcStatus:
            guard host.pcPaired else { return BrainReply(text: Say.line(.pcStatusOff), mood: .idle) }
            let r = await host.pcCommand("status", target: nil)
            return BrainReply(text: r.detail, mood: r.ok ? .happy : .alert)

        case .syncNow:
            return BrainReply(text: await host.syncNow())

        case .sounds(let on):
            host.settings.soundsOn = on
            return BrainReply(text: Say.line(on ? .soundsOn : .soundsOff))

        case .tellMore:
            let topic = lastTopic.isEmpty ? lastQuestion : lastTopic
            guard !topic.isEmpty, host.settings.webAnswers else { return BrainReply(text: Say.line(.tellMoreWhat)) }
            await think("Researching more about \(topic)")
            guard let r = await WebService.research(topic) else { return BrainReply(text: Say.line(.tellMoreFail, ["topic": topic]), mood: .idle) }
            let extra = Self.brief(r.bullets.isEmpty ? r.summary : r.bullets.joined(separator: " "), query: topic)
            return BrainReply(text: extra, cards: [.web(WebCard(title: r.title, summary: r.summary, bullets: r.bullets, imageURL: r.imageURL, sources: r.sources))], source: "web")

        case .repeatLast:
            return BrainReply(text: lastAnswer.isEmpty ? Say.line(.repeatNothing) : lastAnswer)

        case .correction(let fix):
            guard !lastQuestion.isEmpty else { return nil }
            if let fix {
                bank.learn(question: lastQuestion, answer: TextKit.capitalizeFirst(fix), source: "taught", tag: "taught")
                return BrainReply(text: Say.line(.correctionSaved, ["fix": TextKit.capitalizeFirst(fix)]), source: "learned")
            }
            awaitingAnswerFor = lastQuestion
            return BrainReply(text: Say.line(.correctionAsk), mood: .idle)

        case .teach(let q, let a):
            bank.learn(question: q, answer: TextKit.capitalizeFirst(a), source: "taught", tag: "taught")
            return BrainReply(text: Say.line(.taught, ["question": q, "answer": TextKit.capitalizeFirst(a)]), source: "learned")

        case .ipadOnlyLimit(let msg):
            return BrainReply(text: msg, mood: .idle)

        case .home(let cmd):
            await think("Talking to Apple Home")
            let r = await host.homeCommand(cmd, confirmed: false)
            if let ask = r.confirm {
                pendingHome = ask
            }
            return r.reply
        }
    }

    // MARK: Calendar and reminders

    private func reminder(_ raw: String, think: (String) async -> Void) async -> BrainReply {
        let found = DateParser.find(in: raw)
        let fillers = ["remind me to", "remind me about", "remind me that", "remind me", "set a reminder to", "set a reminder for",
                       "set a reminder", "make a reminder to", "create a reminder to", "add a reminder to", "reminder to",
                       "do not let me forget to", "dont let me forget to", "do not let me forget", "dont let me forget",
                       "make sure i remember to", "make sure i do not forget to", "please", "ace"]
        var title = DateParser.title(from: raw, removing: found?.phrases ?? [], fillers: fillers)
        if title.isEmpty { title = "Reminder" }
        let cal = CalendarService.shared
        await think("Making a reminder: \(title)")
        var due = found?.date
        if let f = found, f.allDay { due = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: f.date) }
        let addedToReminders = await cal.requestReminderAccess() && cal.addReminder(title, due: due)
        if let due, !addedToReminders {
            _ = await Notifier.schedule(id: "reminder-\(UUID().uuidString)", title: "Reminder", body: title, at: due, category: "reminder")
        }
        let when = due.map { " " + DateParser.say($0) } ?? ""
        let task = title.lowercased()
        if addedToReminders {
            return BrainReply(text: Say.line(.reminderSaved, ["task": task, "when": when]))
        }
        if due != nil {
            return BrainReply(text: Say.line(.reminderSet, ["task": task, "when": when]))
        }
        return BrainReply(text: Say.line(.reminderWhen, ["task": task]), mood: .idle)
    }

    private func calendarAdd(_ raw: String, think: (String) async -> Void) async -> BrainReply {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else {
            return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert)
        }
        _ = cal.nimbusCalendar()
        guard let found = DateParser.find(in: raw) else {
            return BrainReply(text: Say.line(.calendarWhen), mood: .idle)
        }
        let fillers = ["add", "put", "schedule", "create", "make", "book", "plan", "set up", "an event", "event", "a meeting",
                       "to my calendar", "on my calendar", "to the calendar", "on the calendar", "in my calendar", "my calendar",
                       "calendar", "to nimbus", "new event", "please", "ace", "called", "named", "for"]
        var title = DateParser.title(from: raw, removing: found.phrases, fillers: fillers)
        if title.isEmpty { title = "Event" }
        let length = found.duration ?? DateParser.duration(in: raw.components(separatedBy: " for ").dropFirst().joined(separator: " for "))?.seconds ?? 3600
        await think("Event: \(title), \(DateParser.say(found.date, allDay: found.allDay))")
        let draft = EventDraft(action: .add, title: title, start: found.date,
                               end: found.allDay ? found.date : found.date.addingTimeInterval(length), allDay: found.allDay)
        return BrainReply(text: Say.line(.calendarAddAsk, ["title": title, "when": DateParser.say(found.date, allDay: found.allDay)]),
                          cards: [.eventDraft(draft)], mood: .idle)
    }

    private func calendarEdit(_ raw: String, think: (String) async -> Void) async -> BrainReply? {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else { return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert) }
        let t = TextKit.normalize(raw)
        guard let g = Rx.groups(#"^(move|reschedule|change|push|rename|edit|update)\s+(?:my |the )?(.+?)\s+(?:to|from .+? to)\s+(.+)$"#, t) else { return nil }
        let verb = g[0], what = g[1], to = g[2]
        guard let event = cal.find(what, near: nil).first else {
            return BrainReply(text: Say.line(.eventNotFound, ["what": what]), mood: .idle)
        }
        var draft = EventDraft(action: .edit, title: event.title, start: event.start, end: event.end, allDay: event.allDay, eventID: event.id)
        if verb == "rename" {
            draft.title = TextKit.capitalizeFirst(to)
        } else if let f = DateParser.find(in: to) {
            let length = event.end.timeIntervalSince(event.start)
            if f.allDay, !event.allDay {
                // Keep the old time of day on the new day.
                let comps = Calendar.current.dateComponents([.hour, .minute], from: event.start)
                draft.start = Calendar.current.date(bySettingHour: comps.hour ?? 9, minute: comps.minute ?? 0, second: 0, of: f.date) ?? f.date
            } else {
                draft.start = f.date
            }
            draft.end = draft.start.addingTimeInterval(length)
        } else {
            return BrainReply(text: Say.line(.eventMoveWhen, ["title": event.title]), mood: .idle)
        }
        await think("Found \"\(event.title)\" \(DateParser.say(event.start, allDay: event.allDay))")
        let what2 = verb == "rename" ? "rename it to \"\(draft.title)\"" : "move it to \(DateParser.say(draft.start, allDay: draft.allDay))"
        return BrainReply(text: Say.line(.eventFound, ["title": event.title, "change": what2]), cards: [.eventDraft(draft)], mood: .idle)
    }

    private func calendarDelete(_ raw: String, think: (String) async -> Void) async -> BrainReply? {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else { return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert) }
        let found = DateParser.find(in: raw)
        let fillers = ["delete", "remove", "cancel", "clear", "my", "the", "event", "from my calendar", "from the calendar",
                       "off my calendar", "calendar", "please", "ace"]
        let what = DateParser.title(from: raw, removing: found?.phrases ?? [], fillers: fillers)
        guard let event = cal.find(what, near: found?.date).first else {
            return BrainReply(text: Say.line(.deleteNotFound, ["what": what]), mood: .idle)
        }
        await think("Found \"\(event.title)\" \(DateParser.say(event.start, allDay: event.allDay))")
        let draft = EventDraft(action: .delete, title: event.title, start: event.start, end: event.end, allDay: event.allDay, eventID: event.id)
        return BrainReply(text: Say.line(.deleteAsk, ["title": event.title, "when": DateParser.say(event.start, allDay: event.allDay)]), cards: [.eventDraft(draft)], mood: .alert)
    }

    private func calendarList(_ t: String, think: (String) async -> Void) async -> BrainReply {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else { return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert) }
        _ = cal.nimbusCalendar()
        let c = Calendar.current
        let today = c.startOfDay(for: Date())
        var start = Date()
        var end = c.date(byAdding: .day, value: 1, to: today)!
        var label = "today"
        if t.contains("tomorrow") {
            start = c.date(byAdding: .day, value: 1, to: today)!
            end = c.date(byAdding: .day, value: 2, to: today)!
            label = "tomorrow"
        } else if t.contains("week") {
            end = c.date(byAdding: .day, value: 7, to: today)!
            label = "in the next 7 days"
        } else if t.contains("weekend") {
            let weekday = c.component(.weekday, from: today)
            let toSat = (7 - weekday + 7) % 7
            start = c.date(byAdding: .day, value: toSat, to: today)!
            end = c.date(byAdding: .day, value: 2, to: start)!
            label = "this weekend"
        } else if t.contains("next") || t.contains("coming up") {
            end = c.date(byAdding: .day, value: 30, to: today)!
            let events = cal.events(from: start, to: end, nimbusOnly: false)
            guard let next = events.first else { return BrainReply(text: Say.line(.nothingComingUp)) }
            return BrainReply(text: Say.line(.nextUp, ["title": next.title, "when": DateParser.say(next.start, allDay: next.allDay)]), cards: [.events([next])])
        }
        await think("Reading your calendars \(label)")
        let events = cal.events(from: start, to: end, nimbusOnly: false)
        if events.isEmpty { return BrainReply(text: Say.line(.calendarFree, ["label": label])) }
        let first = events.prefix(3).map { "\($0.title) \($0.allDay ? "(all day)" : "at " + $0.start.formatted(date: .omitted, time: .shortened))" }
        let more = events.count > 3 ? ", plus \(events.count - 3) more" : ""
        return BrainReply(text: Say.line(.calendarList, ["count": "\(events.count) thing\(events.count == 1 ? "" : "s")", "label": label,
                                                        "list": first.joined(separator: ", ") + more]), cards: [.events(events)])
    }
}

/// Dates for "how many days until christmas" and friends.
enum Holidays {
    static func date(for name: String, after now: Date) -> Date? {
        let n = TextKit.normalize(name)
        let c = Calendar.current
        let year = c.component(.year, from: now)
        func next(_ month: Int, _ day: Int) -> Date? {
            for y in [year, year + 1] {
                if let d = c.date(from: DateComponents(year: y, month: month, day: day)), d >= c.startOfDay(for: now) { return d }
            }
            return nil
        }
        func nthWeekday(_ month: Int, _ weekday: Int, _ nth: Int) -> Date? {
            for y in [year, year + 1] {
                var comps = DateComponents(year: y, month: month, weekday: weekday, weekdayOrdinal: nth)
                comps.calendar = c
                if let d = c.date(from: comps), d >= c.startOfDay(for: now) { return d }
            }
            return nil
        }
        if n.contains("christmas eve") { return next(12, 24) }
        if n.contains("christmas") || n.contains("xmas") { return next(12, 25) }
        if n.contains("new year") { return next(1, 1) }
        if n.contains("halloween") { return next(10, 31) }
        if n.contains("valentine") { return next(2, 14) }
        if n.contains("4th of july") || n.contains("fourth of july") || n.contains("independence day") { return next(7, 4) }
        if n.contains("thanksgiving") { return nthWeekday(11, 5, 4) }
        if n.contains("summer") { return next(6, 21) }
        if n.contains("winter") { return next(12, 21) }
        if n.contains("spring") { return next(3, 20) }
        if n.contains("fall") || n.contains("autumn") { return next(9, 22) }
        if n.contains("mother") { return nthWeekday(5, 1, 2) }
        if n.contains("father") { return nthWeekday(6, 1, 3) }
        if n.contains("weekend") || n.contains("saturday") {
            let wd = c.component(.weekday, from: now)
            return c.date(byAdding: .day, value: (7 - wd + 7) % 7, to: c.startOfDay(for: now))
        }
        return nil
    }
}
