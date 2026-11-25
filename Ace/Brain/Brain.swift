import Foundation

/// What the brain hands back to the chat.
struct BrainReply {
    var text: String
    var thoughts: [String] = []
    var cards: [AceCard] = []
    /// Which part of Ace answered, shown after "How I got this" (rules, answer bank, web, LFM3 Omni...).
    var source: String = "rules"
    var mood: OrbMood = .happy
    /// What kind of answer this is ("timer", "weather", "dontKnow", "sassy"...), so Sassy mode picks the right line.
    var kind: String = ""
    /// Chat, banter or a goodbye (not a question, so "search it" won't search it).
    var chat: Bool = false
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
    /// Starts (true) or ends (false) a voice call, and returns what Ace says about it.
    func setCall(_ on: Bool) -> String
    /// Switches Sassy mode on or off from a spoken ask, and returns what Ace says about it.
    func setPersonality(_ sassy: Bool) -> String
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
    /// Opens Ace Piano, maybe on a song ("learn:twinkle" or "listen:twinkle"). False during a voice call.
    func showPiano(_ start: PianoStart) -> Bool
}

/// Ace V4's brain: rules + a big answer bank + a neural matcher + web research,
/// run as a think loop that keeps trying new ways until it's sure (or out of ideas).
/// The on-device models only get a turn when they're switched on AND nothing else was sure.
@MainActor
final class Brain {
    let bank = QABank()
    let classifier = IntentClassifier()
    weak var host: BrainHost?
    /// Tests turn Sassy mode on or off here. Otherwise it follows Settings.
    var sassyOverride: Bool?
    var sassy: Bool { sassyOverride ?? Sass.isOn(host?.settings.personality ?? "normal") }
    /// The sass slider (tests set it directly).
    var sassLevelOverride: SassLevel?
    var sassLevel: SassLevel { sassLevelOverride ?? SassLevel(setting: host?.settings.sassLevel ?? "extra") }

    private var lastQuestion = ""
    /// The last real question (not chat, a hello or a command), for "search it" and "look that up".
    private(set) var lastInfoQuestion = ""
    private var lastAnswer = ""
    private var lastTopic = ""
    private var awaitingAnswerFor: String?
    private var pendingChoices: [QABank.Match] = []
    private var toldModelMissing = false
    /// A home action waiting for a yes (Ace wasn't sure which device you meant).
    private var pendingHome: HomeCommand?
    /// A quick version of the recipe Ace just showed, offered with "Want a quick 5-minute mug version instead?"
    private var pendingQuickRecipe: String?
    /// The last recipe Ace showed, so "make it spicier" or "for 8 people" can change it.
    private(set) var lastRecipe: RecipeCard?
    /// What a follow-up like "what about tomorrow" turned into, so the next follow-up builds on it.
    private var resolvedQuestion: String?
    /// The game being played (trivia or 20 questions), if any.
    private(set) var game: ActiveGame?
    /// Changes with every new game question. Cards whose token doesn't match it are old and stop taking taps.
    private(set) var gameToken = ""
    private var gameSerial = 0
    /// Trivia questions asked lately, so a new round brings new ones.
    private var recentTrivia: [String] = []
    /// Best scores and streaks per trivia category.
    var triviaRecords = TriviaRecords.shared

    /// How sure the answer bank has to be to answer straight away.
    static let sure = 0.74
    /// Same, after saying the question another way.
    static let rephraseSure = 0.72
    /// Below this it's a guess, and Ace says so.
    static let guessFloor = 0.58
    /// How sure a knowledge-pack guess about "my ..." has to be.
    static let packPersonalGuessFloor = 0.66

    // MARK: Think loop

    func respond(to raw: String, onThought: @escaping (String) -> Void) async -> BrainReply {
        var thoughts: [String] = []
        let think: (String) async -> Void = { step in
            thoughts.append(step)
            onThought(step)
            try? await Task.sleep(nanoseconds: 140_000_000)
        }
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return BrainReply(text: Say.line(.empty)) }
        resolvedQuestion = nil

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

        // Answering "Want a quick 5-minute mug version instead?"
        if let id = pendingQuickRecipe {
            pendingQuickRecipe = nil
            if Self.acceptsQuickOffer(text), let e = RecipeBook.all.first(where: { $0.id == id }) {
                await think("You want the quick one, so here's \(e.name.lowercased())")
                lastTopic = e.name
                return finish(BrainReply(text: Say.line(.recipeFound, ["name": e.name, "ingredients": "\(e.ingredients.count)", "steps": "\(e.steps.count)"]),
                                         thoughts: thoughts, cards: [.recipe(e.card)], source: "Ace's recipe book", mood: .happy), question: text)
            }
        }

        // Playing trivia or 20 questions: answers go to the game.
        if game != nil, let r = playGame(text) {
            return finish(r, question: text)
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

        // "Hello Ace, what's the capital of the UK": the hello and the name aren't part of the question.
        let asked = IntentRouter.withoutGreeting(text)
        if asked != text {
            text = asked
            await think("You said hi first, so the question is \"\(asked)\"")
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
        lastQuestion = resolvedQuestion ?? question
        if !r.chat, !Self.notQuestions.contains(r.kind) { lastInfoQuestion = lastQuestion }
        resolvedQuestion = nil
        lastAnswer = r.text
        for card in r.cards {
            if case .recipe(let c) = card { lastRecipe = c }
        }
        return r
    }

    /// In Sassy mode the sassy set answers first, except for jobs (timers, weather, calendar...)
    /// that Ace does itself. Small talk like "hi" and "thanks" counts as a question here.
    static func sassyFirst(_ decision: Decision) -> Bool {
        switch decision {
        // A goodbye always gets Ace's goodbye (and the orb goes to sleep), sassy or not.
        case .rule(.goodbye), .classified(.goodbye): return false
        case .rule(let intent), .classified(let intent): return !intent.isAction
        default: return true
        }
    }

    /// "What continent is it in" is about the last thing you asked, so the sassy set (which doesn't
    /// know what "it" is) leaves it to the normal answers.
    static func soundsLikeFollowUp(_ text: String) -> Bool {
        let pointers: Set<String> = ["it", "its", "they", "them", "their", "there", "that", "this", "those", "these",
                                     "he", "she", "him", "her", "his"]
        return TextKit.words(text).contains { pointers.contains($0) }
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

        // Sassy mode: its own small set first, for anything that isn't a job like a timer or the weather.
        // Small talk said word for word always counts. A fact question with "it" or "that" in it is
        // probably about the last answer, so the normal answers take it.
        if sassy, Self.sassyFirst(decision), let entry = SassPack.shared.match(text),
           entry.exact || !Self.soundsLikeFollowUp(text), let hit = SassPack.shared.answer(text, level: sassLevel) {
            await think("Sassy mode: found it in the sassy set")
            let chatty = ["talk", "about", "joke"].contains(hit.entry.topic)
            return BrainReply(text: hit.text, source: "Ace's sassy set", kind: "sassy", chat: chatty)
        }

        switch decision {
        case .rule(let intent), .classified(let intent):
            // Chat and goodbyes are conversation: answered here, never searched.
            if let r = conversation(intent) {
                await think(intent == .goodbye ? "That's a goodbye" : "That's just chatting, not a question to look up")
                return r
            }
            if var r = await run(intent, text: text, think: think) {
                if r.kind.isEmpty { r.kind = intent.kind }
                return r
            }
            await think("That skill couldn't do it, so I'll keep looking")
        case .bank(let m):
            return withFavorite(answer(from: m), question: text)
        case .clarify(let a, let b):
            pendingChoices = [a, b]
            return BrainReply(text: Say.line(.clarify, ["first": a.wording, "second": b.wording]), source: "answer bank", mood: .idle, kind: "clarify")
        case .weak, .none:
            break
        }

        // Research it on the web, then learn it (only when the brain wasn't sure, and only for a clear
        // question: never chat, a goodbye, one word or only little words like "it").
        if let host, host.settings.webAnswers, SystemMonitor.shared.online, Chat.isInfoQuestion(text) {
            await think("Not sure yet, so I'm researching it on the web")
            if let r = await WebService.research(text), r.confidence >= 0.5 {
                await think("Read \(max(1, r.sources.count)) source\(r.sources.count == 1 ? "" : "s") and picked the best sentences")
                lastTopic = r.title
                let short = Self.brief(r.summary, query: text)
                // "Current", "now" and "latest" questions change, so they're looked up fresh each time.
                if Leaders.isTimeSensitive(text) {
                    await think("That can change, so I won't save it as a lasting answer")
                } else {
                    bank.learn(question: text, answer: short, source: "learned", tag: "learned.web", url: r.sources.first?.url.absoluteString)
                    await think("Saved it to my answer bank so I'll know it next time")
                }
                let card = WebCard(title: r.title, summary: r.summary, bullets: r.bullets, imageURL: r.imageURL, sources: r.sources)
                return withFavorite(BrainReply(text: short, cards: [.web(card)], source: "web"), question: text)
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

        // Not a question at all ("I'm going to the store"): chat back instead of "I don't know".
        if !Chat.isInfoQuestion(text), !Sass.isSerious(text) {
            await think("That sounds like chatting, not a question to look up")
            return chatReply(.smalltalk)
        }

        await think("Out of ideas for now")
        lastTopic = Summarizer.topic(of: text)
        var r = BrainReply(text: Say.line(.dontKnow, ["question": TextKit.normalize(text)]), source: "rules", mood: .idle, kind: "dontKnow")
        if let host, Chat.isInfoQuestion(text), let link = Sites.searchLink(text, site: nil, engine: host.settings.searchEngine) {
            r.cards = [.links([LinkItem(title: link.title, url: link.url)])]
        }
        return r
    }

    /// Kinds of reply that aren't answers to a question, so "search it" skips them.
    static let notQuestions: Set<String> = ["greeting", "summon", "thanks", "goodbye", "chat", "searchTab", "openSite",
                                            "clarify", "voiceSpeed", "sounds", "handsFree", "call", "settings", "personality", "sassy"]

    /// Chat and goodbyes, answered without the web. nil for anything else.
    func conversation(_ intent: Intent) -> BrainReply? {
        switch intent {
        case .chat(let kind): return chatReply(kind)
        case .goodbye: return goodbyeReply()
        default: return nil
        }
    }

    /// A reply to banter: friendly in Normal mode, sassy (about the situation, never the person) in Sassy mode.
    func chatReply(_ kind: Chat.Kind) -> BrainReply {
        if sassy {
            let line = SassPack.shared.line("banter." + kind.rawValue, level: sassLevel)
            if !line.isEmpty {
                return BrainReply(text: line, source: "Ace's sassy set", mood: .happy, kind: "sassy", chat: true)
            }
        }
        let options = Chat.lines(kind)
        let text = options[VariantPicker.shared.pick("chat." + kind.rawValue, count: options.count)]
        return BrainReply(text: text, source: "rules", mood: .happy, kind: "chat", chat: true)
    }

    /// Bye, and the orb goes to sleep.
    func goodbyeReply() -> BrainReply {
        let name = host?.settings.userName ?? ""
        let who = name.isEmpty ? "" : ", \(name)"
        return BrainReply(text: Say.line(.goodbye, ["who": who]), source: "rules", mood: .sleeping, kind: "goodbye", chat: true)
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

        // 0. Names you gave things ("my lamp is called Sunny"): "who is sunny", "turn on sunny".
        if let host {
            let aliases = host.memory.aliases
            if let g = Rx.groups(#"^(?:what|who) (?:is|are) ([a-z0-9][a-z0-9 '\-]*)$"#, norm), aliases[g[0]] != nil {
                notes.append("You gave something the name \"\(g[0])\"")
                return .rule(.recall(g[0]))
            }
            if let swapped = Self.withAliases(text, aliases), let intent = IntentRouter.parse(swapped) {
                // Only when the name is what the words were about: "turn on sunny" yes, "set the volume to max" no.
                let plain = IntentRouter.parse(text)
                var aboutTheName = plain == nil
                if case .home(let h)? = plain {
                    aboutTheName = aliases.keys.contains { h.target.contains($0) }
                }
                if aboutTheName {
                    notes.append("You call it by a name, so I read it as \"\(swapped)\"")
                    return .rule(intent)
                }
            }
        }

        // 1. Rules.
        if let intent = IntentRouter.parse(text) {
            // In Normal mode, small talk like "you're awesome" keeps its hand-made answer from the bank. Only the "feelings"
            // answers count, so "how are you" never gets "how old are you" and "yo what up" never gets a yo-yo.
            if !sassy, case .chat(let kind) = intent, kind.isSmallTalk, let best = bank.search(norm).first,
               best.entry.id.hasPrefix("feelings."), best.score >= Self.sure {
                notes.append("Small talk with a hand-made answer: \"\(best.wording)\"")
                return .bank(best)
            }
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
                resolvedQuestion = f.question
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
        if let best = matches.first, best.score >= Self.guessFloor {
            // A loose guess from the big knowledge pack about something of yours ("how much does my backpack weigh")
            // is usually about something else, so only take it when it fits well.
            if best.entry.source == "pack", best.score < Self.packPersonalGuessFloor, Rx.matches(#"\bmy\b"#, norm) {
                notes.append("Only a loose match about something of yours, so I won't guess")
                return .none
            }
            return .weak(best)
        }
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
            let lastIntent = IntentRouter.parse(lastQuestion)
            // "what about tomorrow" after the weather: the same place, another day.
            if case .weather(let place, let day)? = lastIntent {
                let when = DayWords.find(in: x)
                var newPlace = when?.rest ?? x
                for p in ["in ", "for ", "at ", "on "] where newPlace.hasPrefix(p) { newPlace = String(newPlace.dropFirst(p.count)) }
                if newPlace.isEmpty || ["there", "here", "then"].contains(newPlace) { newPlace = place ?? "" }
                // "and is it windy" isn't a place, so leave that one to the other follow-up checks.
                let looksLikePlace = newPlace.split(separator: " ").count <= 3
                    && !Rx.matches(#"^(is|it|will|does|do|what|how|can|should|would|the|a|an|my|your|i|you|about)\b"#, newPlace)
                if when != nil || looksLikePlace {
                    var q = "what is the weather"
                    if !newPlace.isEmpty { q += " in " + newPlace }
                    if let d = when?.label ?? day, d != "today" { q += " " + d.lowercased() }
                    return FollowUp(question: q, isAbout: true)
                }
            }
            // "what about saturday" after "what do I have tomorrow": the same question, another day.
            if DayWords.isOnlyDay(x), let li = lastIntent, li.kind == "calendarList" {
                let base = DayWords.find(in: last)?.rest ?? last
                let day = DayWords.find(in: x)?.label.lowercased() ?? x
                return FollowUp(question: base + (DayWords.weekdays.contains(day) ? " on " : " ") + day, isAbout: true)
            }
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
            // A word the knowledge pack uses only a few times ("capitol") can still be a typo of a common one ("capital").
            let own = bank.spellingFrequency(w)
            // Three-letter words too ("eet"), but only ones Ace has never seen anywhere.
            guard w.count >= 4 || (w.count == 3 && own == 0), w.allSatisfy({ $0.isLetter }), !Self.ruleWords.contains(w), bank.wordFrequency(w) == 0, own <= 5,
                  !TextKit.stopwords.contains(w) else { continue }
            let maxDistance = w.count >= 8 ? 2 : 1
            var found: [String: (d: Int, f: Int)] = [:]
            for candidate in bank.vocabulary(near: w) + Self.ruleWords.filter({ abs($0.count - w.count) <= maxDistance }) where candidate != w {
                let d = TextKit.editDistance(w, candidate, limit: maxDistance)
                guard d <= maxDistance else { continue }
                let f = max(1, bank.spellingFrequency(candidate)) + (Self.ruleWords.contains(candidate) ? 50 : 0)
                // A real word is only swapped for one that's used far more often.
                if own > 0 && f < own * 100 { continue }
                found[candidate] = (d, f)
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
        let text = IntentRouter.withoutGreeting(raw)
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
        lastInfoQuestion = ""
        lastAnswer = ""
        lastTopic = ""
        awaitingAnswerFor = nil
        pendingChoices = []
        pendingHome = nil
        pendingQuickRecipe = nil
        lastRecipe = nil
        resolvedQuestion = nil
        game = nil
        gameToken = ""
    }

    /// Sets the recipe follow-ups change (for tests).
    func noteRecipe(_ card: RecipeCard?) {
        lastRecipe = card
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

    /// "turn on sunny" -> "turn on the lamp", when you told Ace "my lamp is called Sunny". Nil when no name is in it.
    nonisolated static func withAliases(_ text: String, _ aliases: [String: String]) -> String? {
        guard !aliases.isEmpty else { return nil }
        var t = TextKit.normalize(text)
        var changed = false
        for (alias, thing) in aliases.sorted(by: { $0.key.count > $1.key.count }) {
            let pattern = #"(?<![a-z0-9'])(?:the |my )?"# + NSRegularExpression.escapedPattern(for: alias) + #"(?![a-z0-9])"#
            guard t.range(of: pattern, options: .regularExpression) != nil else { continue }
            t = t.replacingOccurrences(of: pattern, with: "the " + thing, options: .regularExpression)
            changed = true
        }
        return changed ? t : nil
    }

    /// Gives back the words the way you typed them ("Mova", not "mova") when they can be found.
    nonisolated static func originalCase(_ piece: String, in raw: String) -> String {
        let clean = raw.replacingOccurrences(of: "’", with: "'")
        guard let r = clean.range(of: piece, options: [.caseInsensitive]) else { return piece }
        return String(clean[r])
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
        let source = e.source == "builtin" || e.source == "pack" || e.source == nil ? "answer bank" : "learned"
        return BrainReply(text: text, source: source)
    }

    /// Now and then, adds a line about one of your favorites when the question touches it
    /// ("tell me about foxes" -> "That's your favorite animal, too!"). Paced so it never gets old.
    private func withFavorite(_ r: BrainReply, question: String) -> BrainReply {
        guard let host else { return r }
        let items = Favorites.all(host.memory.facts.map(\.text))
        guard !items.isEmpty, let hit = Favorites.touched(by: question, items: items),
              Favorites.takeTurn(hit.item) else { return r }
        var out = r
        out.text += " " + Favorites.aside(hit.item, valueSaid: hit.valueSaid)
        return out
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
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        for p in Self.sayItAnotherWay {
            t = t.replacingOccurrences(of: p.pattern, with: p.with, options: .regularExpression)
        }
        return t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    /// Everyday ways of asking that the answer bank says differently ("known as" is "called",
    /// "turn to ice" is "freeze"). Only used when the plain question didn't find a sure answer.
    static let sayItAnotherWay: [(pattern: String, with: String)] = [
        // "pluto still counts as a planet right" -> "is pluto a planet"
        (#"^((?!(?:what|which|how|who|whose|where|when|why|is that|is this|is it)\b)[a-z0-9]+(?: [a-z0-9]+){2,})\s+(?:right|correct|or not|am i right|is that right|yeah)$"#, "$1"),
        (#"^(?:an? |the )?([a-z]+) (?:still )?(?:counts?|is classed|is counted|classed|counted) as (an?|the) ([a-z]+)$"#, "is a $1 $2 $3"),
        // "what's a baby monkey known as" -> "what is a baby monkey called"
        (#"\b(?:known as|named|referred to as)$"#, "called"),
        // "what is lots of frogs together" -> "what is a group of frogs"
        (#"\b(?:lots|a lot|a bunch|loads|tons|many|a few) of ([a-z]+) (?:together|in a group)\b"#, "a group of $1"),
        // "which star is nearest to us" -> "which star is nearest"
        (#"\s+(?:to|from) (?:us|earth|the earth|our planet)$"#, ""),
        // "at what temp does water turn to ice" -> "... freeze"
        (#"\b(?:turn|turns|change|changes|become|becomes) (?:in)?to (?:ice|solid)\b"#, "freeze"),
        (#"\b(?:turn|turns|change|changes) (?:in)?to (?:steam|gas|vapor)\b"#, "boil"),
        // "what age is planet earth" -> "how old is planet earth"
        (#"\bwhat age (is|are|was)\b"#, "how old $1"),
        // "how many years can a turtle live" -> "how long do a turtle live"
        (#"\bhow many (?:years|yrs) (?:can|do|does|will|could) (.+?) live\b"#, "how long do $1 live"),
        (#"\bhow long (?:can|will|could|does) (.+?) live\b"#, "how long do $1 live"),
        // "what food do pandas like" -> "what do pandas eat"
        (#"^what (?:food|foods|kind of food|stuff) (?:do|does) ([a-z ]+?)(?: like| love| eat| need| enjoy)?(?: to eat)?$"#, "what do $1 eat"),
        // "am i supposed to drink" -> "should i drink"
        (#"\b(?:am i|are we|are you|is a person|are people) (?:supposed|meant) to\b"#, "should i"),
        (#"^(.+ .+ .+?)\s+(?:each|every|per|a) day$"#, "$1"),
        // "why do people yawn" -> "why do we yawn"
        (#"^why (?:do|does) (?:people|humans|a person|kids|you|your body|our body|the body) "#, "why do we "),
        // "how many continents does the world have" -> "how many continents are there"
        (#"\bhow many ([a-z ]+?) (?:does|do) (?:the )?(?:world|earth|planet|planet earth) have$"#, "how many $1 are there"),
        // "how does rain happen" -> "what causes rain"
        (#"^how (?:does|do) ([a-z ]+?) happen$"#, "what causes $1"),
        // "the english alphabet" -> "the alphabet"
        (#"\benglish alphabet\b"#, "alphabet"),
        // "the space station" -> "the iss"
        (#"\b(?:the )?(?:international )?space station\b"#, "the iss"),
        // "what's a bug in programming", "what does the cloud mean on computers"
        (#"\s+(?:in|on|for) (?:programming|coding|computers?|computing|tech|technology)$"#, ""),
        (#"^what does (?:the |a |an )?([a-z ]+?) mean$"#, "what is $1"),
    ]

    private func intent(for skill: IntentClassifier.Skill, text: String) -> Intent? {
        switch skill {
        case .recipe: return .recipe(Summarizer.topic(of: text))
        case .weather: return .weather(place: nil, day: nil)
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
        case .chat: return "chatting"
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
        case .recipeTweak: return "changing the recipe"
        case .script: return "a script"
        case .homework: return "homework"
        case .note: return "notes"
        case .voiceSpeed: return "how fast I talk"
        case .shopping: return "the shopping list"
        case .translate, .translateList: return "translating"
        case .game: return "a game"
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
        case .call: return "a voice call"
        case .pcPower: return "your PC's power"
        case .pcApp: return "an app window"
        case .pcStatus: return "your PC"
        case .syncNow: return "syncing"
        case .personality: return "Sassy mode"
        case .sounds: return "my sounds"
        case .tellMore: return "more on the last topic"
        case .repeatLast: return "repeating myself"
        case .correction: return "a correction"
        case .teach: return "teaching me"
        case .focus: return "a focus session"
        case .leader: return "who leads a country"
        case .piano: return "the piano"
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
            return goodbyeReply()

        case .chat(let kind):
            return chatReply(kind)

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

        case .focus(let what):
            return await FocusSession.handle(what)

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

        case .openSite(let target) where Chat.isPointer(target):
            // "open it": search the last thing you asked.
            guard let query = Chat.resolve(target, lastQuestion: lastInfoQuestion) else {
                return BrainReply(text: "Open what? Tell me the site or what to look up.", mood: .idle, kind: "clarify")
            }
            guard let link = Sites.searchLink(query, site: nil, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: Say.line(.searchTab, ["site": "the web", "query": query]), cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .openSite(let target):
            guard let link = Sites.link(for: target, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: Say.line(.openSite, ["site": link.title]), cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .searchTab(let asked, let site):
            // "search it": the last thing you asked. Nothing asked yet: ask what to search.
            guard let query = Chat.resolve(asked, lastQuestion: lastInfoQuestion) else {
                return BrainReply(text: "Search what?", mood: .idle, kind: "clarify")
            }
            guard let link = Sites.searchLink(query, site: site, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: Say.line(.searchTab, ["site": site.flatMap { Sites.lookup($0)?.name } ?? "the web", "query": query]), cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .recipe(let dish):
            // "with eggs and cheese": ideas from Ace's recipe book.
            if dish.hasPrefix("with ") {
                let items = RecipeBook.splitItems(String(dish.dropFirst(5)))
                let list = TextKit.joinList(items)
                await think("Looking for recipes with \(list)")
                let ideas = RecipeBook.ideas(with: items)
                guard let first = ideas.first else {
                    return BrainReply(text: Say.line(.recipeNoIdeas, ["items": list]), mood: .idle)
                }
                lastTopic = first.entry.name
                let names = TextKit.joinList(ideas.map { $0.entry.name.lowercased() }, last: "or")
                return BrainReply(text: TextKit.capitalizeFirst(Say.line(.recipeIdeas, ["items": list, "dishes": names, "first": first.entry.name])),
                                  cards: [.recipe(first.entry.card)], source: "Ace's recipe book")
            }
            // "what should I make for dinner": any idea.
            if dish.hasPrefix("idea") {
                let meal = dish.dropFirst(4).trimmingCharacters(in: .whitespaces)
                // Sometimes one of your favorite foods, if Ace has the recipe and it fits the meal.
                let favorites = Favorites.all(host.memory.facts.map(\.text))
                if Double.random(in: 0..<1) < 0.4, let fav = Favorites.recipe(for: meal, items: favorites) {
                    lastTopic = fav.name
                    return BrainReply(text: TextKit.capitalizeFirst(Say.line(.recipeIdea, ["name": fav.name])) + " It's one of your favorites!",
                                      cards: [.recipe(fav.card)], source: "Ace's recipe book")
                }
                guard let pick = RecipeBook.suggestion(for: meal) else {
                    return BrainReply(text: Say.line(.recipeNotFound, ["dish": meal.isEmpty ? "that" : meal]), mood: .idle)
                }
                lastTopic = pick.name
                return BrainReply(text: TextKit.capitalizeFirst(Say.line(.recipeIdea, ["name": pick.name])), cards: [.recipe(pick.card)], source: "Ace's recipe book")
            }
            // Ace's own recipe book works with no internet.
            if let e = RecipeBook.find(dish) {
                lastTopic = e.name
                var text = Say.line(.recipeFound, ["name": e.name, "ingredients": "\(e.ingredients.count)", "steps": "\(e.steps.count)"])
                var cards: [AceCard] = [.recipe(e.card)]
                // The full chocolate cake takes 2 hours, so offer the 5-minute mug cake too.
                if let quick = RecipeBook.quickVersion(of: e), let offer = RecipeBook.quickOffer(for: e) {
                    text += "\n\n" + offer
                    pendingQuickRecipe = quick.id
                    cards.append(.quickReplies(QuickReplies(token: "", replies: [quick.name + " recipe"], anytime: true)))
                }
                return BrainReply(text: text, cards: cards, source: "Ace's recipe book")
            }
            await think("Looking up a recipe for \(dish)")
            guard let card = await WebService.recipe(dish) else {
                return BrainReply(text: Say.line(.recipeNotFound, ["dish": dish]), mood: .idle)
            }
            lastTopic = card.name
            return BrainReply(text: Say.line(.recipeFound, ["name": card.name, "ingredients": "\(card.ingredients.count)", "steps": "\(card.steps.count)"]), cards: [.recipe(card)], source: "web")

        case .script(let ask):
            // Ace's built-in code library: Roblox Lua and C++.
            if let m = ScriptLibrary.find(ask) {
                let s = m.script
                await think("Found \(s.title) in my \(s.language) scripts")
                lastTopic = s.title
                return BrainReply(text: TextKit.capitalizeFirst(Say.line(.scriptFound, ["title": ScriptLibrary.spokenName(s.title), "language": s.language])),
                                  cards: [.code(s.card)], source: "Ace's script library", mood: .happy)
            }
            let words = ScriptLibrary.tokens(TextKit.normalize(ask))
            let language = ScriptLibrary.listAsk(ask).flatMap { $0.isEmpty ? nil : $0 }
                ?? ScriptLibrary.needsOne(ask).flatMap { $0.isEmpty ? nil : $0 }
                ?? ScriptLibrary.hints(words).language
            let examples = ScriptLibrary.examples(language).map(ScriptLibrary.spokenName)
            if ScriptLibrary.listAsk(ask) != nil {
                let pool = ScriptLibrary.all.filter { language == nil || $0.language == language }
                let count = language.map { "\(pool.count) \($0)" } ?? "\(pool.count)"
                return BrainReply(text: Say.line(.scriptList, ["count": count, "examples": TextKit.joinList(examples)]), source: "Ace's script library")
            }
            if ScriptLibrary.needsOne(ask) != nil {
                return BrainReply(text: Say.line(.scriptNeedOne, ["examples": TextKit.joinList(examples, last: "or")]), source: "Ace's script library")
            }
            return BrainReply(text: Say.line(.scriptNotFound, ["examples": TextKit.joinList(examples, last: "or")]), source: "Ace's script library", mood: .idle)

        case .translate(let phrase, let code):
            // Ace's phrasebook: everyday words and phrases in 12 languages, with no internet.
            let language = Phrasebook.languageName(code)
            guard let e = Phrasebook.find(phrase), let card = Phrasebook.card(e, code: code) else {
                return BrainReply(text: Say.line(.translateUnknown, ["phrase": phrase, "language": language,
                                                                     "examples": TextKit.joinList(Phrasebook.examples, last: "or")]),
                                  source: "Ace's phrasebook", mood: .idle)
            }
            await think("Found \"\(e.en)\" in my \(language) phrasebook")
            lastTopic = e.en
            let shown = card.say.map { "\(card.text) (\($0))" } ?? card.text
            return BrainReply(text: Say.line(.translated, ["phrase": e.en, "language": language, "text": shown]),
                              cards: [.translation(card)], source: "Ace's phrasebook")

        case .translateList:
            return BrainReply(text: Say.line(.translateLanguages, ["languages": TextKit.joinList(Phrasebook.languages.map(\.name))]),
                              source: "Ace's phrasebook")

        case .game(let which):
            return startGame(which)

        case .piano(let ask):
            return pianoReply(ask, host: host)

        case .homework(let problem):
            if !problem.isEmpty { await think("Working it out one step at a time") }
            return homeworkReply(problem)

        case .note(let action, let words):
            return notes(action, words)

        case .voiceSpeed(let how):
            return voiceSpeed(how, settings: host.settings)

        case .shopping(let what):
            return await shopping(what, think: think)

        case .recipeTweak(let ask):
            guard let change = RecipeTweaks.parse(ask) else { return nil }
            guard let base = lastRecipe else { return BrainReply(text: Say.line(.recipeNeedOne), mood: .idle) }
            let r = RecipeTweaks.apply(change, to: base)
            lastTopic = r.card.name
            switch change {
            case .people(let n):
                let note = r.guessedServings ? " " + Say.line(.recipeGuessedServings) : ""
                return BrainReply(text: Say.line(.recipeScaled, ["name": base.name, "people": "\(n) \(n == 1 ? "person" : "people")"]) + note,
                                  cards: [.recipe(r.card)], source: "Ace's recipe book")
            case .scale:
                return BrainReply(text: Say.line(.recipeBatch, ["name": base.name, "amount": r.changes.first ?? "more"]),
                                  cards: [.recipe(r.card)], source: "Ace's recipe book")
            case .style(let style):
                guard !r.changes.isEmpty else {
                    let said = ["milder": "mild", "less sweet": "not too sweet", "healthier": "pretty healthy"][style] ?? style
                    return BrainReply(text: Say.line(.recipeTweakNothing, ["name": base.name, "change": said]), mood: .idle)
                }
                return BrainReply(text: Say.line(.recipeTweaked, ["name": base.name, "change": style, "swaps": TextKit.joinList(Array(r.changes.prefix(3)))]),
                                  cards: [.recipe(r.card)], source: "Ace's recipe book")
            }

        case .weather(let place, let day):
            let saved = UserDefaults.standard.string(forKey: "weatherCity")
            guard let city = place ?? saved, !city.isEmpty else {
                return BrainReply(text: Say.line(.weatherAskCity), mood: .idle)
            }
            await think("Checking the forecast for \(city)")
            guard let card = await WebService.weather(place: city, fahrenheit: host.settings.useFahrenheit) else {
                return BrainReply(text: Say.line(.weatherFail, ["city": city]), mood: .idle)
            }
            UserDefaults.standard.set(city, forKey: "weatherCity")
            // "weather tomorrow" or "weather on saturday": that day's forecast.
            if let day, let when = DayWords.find(in: day), when.offset > 0 {
                guard when.offset < card.days.count else {
                    return BrainReply(text: Say.line(.weatherTooFar, ["day": when.label]), cards: [.weather(card)], source: "web", mood: .idle)
                }
                let f = card.days[when.offset]
                let rain = f.rainChance.map { ", \($0)% chance of rain" } ?? ""
                let text = Say.line(.weatherDay, ["day": TextKit.capitalizeFirst(when.label), "place": card.place,
                                                  "sky": WebService.describe(code: f.code).text.lowercased(),
                                                  "high": "\(Int(f.high.rounded()))\(card.unit)", "low": "\(Int(f.low.rounded()))\(card.unit)",
                                                  "rain": rain])
                return BrainReply(text: text, cards: [.weather(card)], source: "web")
            }
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

        case .remember(let said):
            let fact = Self.originalCase(said, in: text)
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
            if let thing = host.memory.aliases[TextKit.normalize(what)] {
                return BrainReply(text: Say.line(.aliasIs, ["alias": TextKit.capitalizeFirst(what), "thing": thing]), source: "memory")
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

        case .call(let on):
            return BrainReply(text: host.setCall(on), source: "call", mood: on ? .happy : .idle, kind: "call")

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

        case .personality(let on):
            // Turning sass on answers in character (already sassy, so nothing extra goes around it).
            return BrainReply(text: host.setPersonality(on), source: "personality", mood: .happy, kind: on ? "sassy" : "personality", chat: true)

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

        case .leader(let ask):
            guard let country = Leaders.country(id: ask.country) else { return nil }
            // Leaders change, so look them up fresh when Ace can, and say how old the built-in names are when it can't.
            var fresh: (state: String?, government: String?)?
            if host.settings.webAnswers, SystemMonitor.shared.online {
                await think("Checking who leads \(country.short) right now")
                fresh = await WebService.leaders(country.wikidata)
            }
            if fresh == nil { await think("Using my built-in facts from \(Leaders.checked)") }
            lastTopic = country.name
            return BrainReply(text: Leaders.answer(ask, fresh: fresh), source: fresh == nil ? "Ace's built-in facts" : "Wikidata")
        }
    }

    /// "yes", "sure", "the quick one", "mug version" after Ace offers a quick recipe.
    static func acceptsQuickOffer(_ text: String) -> Bool {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        return Rx.matches(#"^(?:(?:yes|yeah|yep|yup|ya|sure|yes please|sure thing|definitely|do that|y)\b[ ,]*)*(?:(?:the |a |that )?(?:quick|mug|fast|5 minute|five minute|microwave)(?: one| version| cake| mug cake| recipe)?)?(?: please| instead| thanks)?$"#, t)
            && !t.isEmpty && !Rx.matches(#"^(no|nope|nah)\b"#, t)
    }

    // MARK: Games

    /// Starts trivia ("trivia" or "trivia:Space") or 20 questions ("twenty").
    func startGame(_ which: String) -> BrainReply {
        if which == "trivia:records" { return triviaRecordsReply() }
        gameSerial += 1
        if which == "twenty" {
            let r = twentyMove(TwentyRound(), lead: Say.line(.twentyStart))
            return r
        }
        let category = which.hasPrefix("trivia:") ? String(which.dropFirst(7)) : nil
        let questions = Trivia.newRound(category: category, avoiding: Set(recentTrivia))
        guard !questions.isEmpty else { return BrainReply(text: Say.line(.empty), mood: .idle) }
        recentTrivia = Array((recentTrivia + questions.map(\.id)).suffix(120))
        let round = TriviaRound(category: category, questions: questions)
        let lead = Say.line(.triviaStart, ["count": "\(questions.count)", "topic": category?.lowercased() ?? "everything"])
        return triviaNext(round, lead: lead)
    }

    /// An answer (or "stop") while a game is on. Nil when the message is about something else, so Ace answers that instead.
    func playGame(_ text: String) -> BrainReply? {
        guard let current = game else { return nil }
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        let stop = Rx.matches(#"^(?:ok |okay )?(stop|quit|exit|end|done|i am done|i quit|stop playing|stop the game|end the game|quit the game|end game|game over|no more|that is enough|enough|never mind|nevermind|cancel|i do not want to play)(?: please| now| playing| the game| thanks| thank you)?$"#, t)
        // Starting a new game, or a whole new request ("what's the weather in Paris"), isn't an answer.
        var tappedChoice = false
        if case .trivia(let round) = current, let q = round.current {
            tappedChoice = q.choices.contains { TextKit.normalize($0) == t }
        }
        if !stop, !tappedChoice, let intent = IntentRouter.parse(text), intent.kind == "game" || t.split(separator: " ").count > 4 {
            if case .twenty(let r) = current, r.step == .whatWasIt { endGame() }
            return nil
        }
        switch current {
        case .trivia(var round):
            guard let q = round.current else { endGame(); return nil }
            if stop {
                endGame()
                return BrainReply(text: Say.line(.triviaStopped, ["score": "\(round.score)", "total": "\(round.index)"]), source: "trivia", mood: .idle)
            }
            let answer = "\(Trivia.letter(q.answer)): \(q.choices[q.answer])"
            let lead: String
            if Rx.matches(#"^(?:skip|pass|next|next one|next question|i do not know|i dont know|dont know|do not know|no idea|i have no idea|idk|not sure|i am not sure|i give up|give up|tell me|tell me the answer|what is it|what is the answer)(?: please| one| question| it| this one)?$"#, t) {
                lead = Say.line(.triviaSkipped, ["answer": answer])
                triviaRecords.answered(category: round.category, right: false)
            } else if let i = Trivia.pick(text, for: q) {
                if i == q.answer {
                    round.score += 1
                    var line = Say.line(.triviaRight, ["fact": q.fact])
                    let streak = triviaRecords.answered(category: round.category, right: true)
                    if TriviaRecords.isMilestone(streak) {
                        line += " " + Say.line(.triviaStreak, ["count": "\(streak)", "category": TriviaRecords.name(round.category)])
                    }
                    lead = line
                } else {
                    lead = Say.line(.triviaWrong, ["answer": answer, "fact": q.fact])
                    triviaRecords.answered(category: round.category, right: false)
                }
            } else {
                return nil
            }
            round.index += 1
            return triviaNext(round, lead: lead)

        case .twenty(var round):
            if stop {
                endGame()
                return BrainReply(text: Say.line(.twentyStopped), source: "20 questions", mood: .idle)
            }
            switch round.step {
            case .asking(let id):
                guard let reply = TwentyQuestions.reply(text) else { return nil }
                switch reply {
                case .dontKnow: round.answers.append(TwentyQuestions.Answer(question: id, value: nil))
                case .value(let v): round.answers.append(TwentyQuestions.Answer(question: id, value: v))
                }
                return twentyMove(round, lead: nil)
            case .guessing(let name):
                guard let reply = TwentyQuestions.reply(text) else { return nil }
                if case .value(let v) = reply, v > 0.9 {
                    endGame()
                    return BrainReply(text: Say.line(.twentyWin, ["thing": name, "count": "\(round.used)"]), source: "20 questions", mood: .happy)
                }
                round.wrong.insert(name.lowercased())
                return twentyMove(round, lead: Say.line(.twentyWrongGuess))
            case .whatWasIt:
                endGame()
                guard let thing = TwentyQuestions.thingName(text) else { return nil }
                // Remember it with your answers, so Ace can guess it next time.
                let known = TwentyQuestions.allThings().first { $0.name.lowercased() == thing.lowercased() }
                var answers = known?.answers ?? [:]
                for a in round.answers { if let v = a.value { answers[a.question] = v } }
                TwentyQuestions.learn(known?.name ?? thing, answers: answers)
                return BrainReply(text: TextKit.capitalizeFirst(Say.line(.twentyLearned, ["thing": known?.name ?? thing])), source: "20 questions")
            }
        }
    }

    private func endGame() {
        game = nil
        gameToken = ""
    }

    /// "What are my trivia scores": the best round and best streak in each category.
    func triviaRecordsReply() -> BrainReply {
        let list = triviaRecords.summary
        guard !list.isEmpty else { return BrainReply(text: Say.line(.triviaRecordsEmpty), source: "trivia", mood: .idle) }
        return BrainReply(text: Say.line(.triviaRecords, ["records": TextKit.joinList(list)]), source: "trivia")
    }

    /// The next trivia question, or the score when the round is over.
    private func triviaNext(_ round: TriviaRound, lead: String?) -> BrainReply {
        guard let q = round.current else {
            endGame()
            let total = round.questions.count
            let done = Say.line(.triviaDone, ["score": "\(round.score)", "total": "\(total)"])
            let name = TriviaRecords.name(round.category)
            let newBest = triviaRecords.finished(category: round.category, score: round.score, total: total)
            let best = triviaRecords.record(round.category)
            let record = newBest
                ? Say.line(.triviaNewBest, ["category": name, "score": "\(round.score)", "total": "\(total)"])
                : Say.line(.triviaBest, ["category": name, "best": "\(best.best)", "total": "\(best.total)"])
            return BrainReply(text: [lead, done + " " + record].compactMap { $0 }.joined(separator: "\n\n"), source: "trivia", mood: .happy)
        }
        game = .trivia(round)
        gameToken = "t\(gameSerial)-\(round.index)"
        let line = Say.line(.triviaQuestion, ["number": "\(round.index + 1)", "question": Trivia.spoken(q)])
        let card = TriviaCard(token: gameToken, number: round.index + 1, total: round.questions.count, category: q.category,
                              question: q.q, choices: q.choices, score: round.score)
        return BrainReply(text: [lead, line].compactMap { $0 }.joined(separator: "\n\n"), cards: [.trivia(card)], source: "trivia")
    }

    /// Ace's next 20 questions move: a question, a guess, or giving up and asking what it was.
    private func twentyMove(_ round: TwentyRound, lead: String?) -> BrainReply {
        var round = round
        let line: String
        switch TwentyQuestions.nextMove(round, things: TwentyQuestions.allThings()) {
        case .ask(let q):
            round.used += 1
            round.step = .asking(q.id)
            line = Say.line(.twentyQuestion, ["number": "\(round.used)", "question": q.ask])
        case .guess(let name):
            round.used += 1
            round.step = .guessing(name)
            line = Say.line(.twentyGuess, ["number": "\(round.used)", "thing": name])
        case .giveUp:
            round.step = .whatWasIt
            game = .twenty(round)
            gameToken = "w\(gameSerial)-ask"
            return BrainReply(text: [lead, Say.line(.twentyLose)].compactMap { $0 }.joined(separator: " "), source: "20 questions")
        }
        game = .twenty(round)
        gameToken = "w\(gameSerial)-\(round.used)"
        let buttons = QuickReplies(token: gameToken, replies: ["Yes", "No", "Maybe", "I don't know"])
        return BrainReply(text: [lead, line].compactMap { $0 }.joined(separator: "\n\n"), cards: [.quickReplies(buttons)], source: "20 questions")
    }

    // MARK: Calendar and reminders

    // MARK: Homework, notes, voice speed and the shopping list

    /// Ace's homework helper: sums, fractions, percents and equations, one step at a time.
    func homeworkReply(_ problem: String) -> BrainReply {
        let source = "Ace's homework helper"
        guard !problem.isEmpty else {
            return BrainReply(text: Say.line(.homeworkHelp, ["examples": TextKit.joinList(Homework.examples, last: "or")]), source: source)
        }
        guard let s = Homework.solve(problem) else {
            return BrainReply(text: Say.line(.homeworkCantSolve, ["kinds": TextKit.joinList(Homework.kinds)]), source: source, mood: .idle)
        }
        lastTopic = s.problem
        return BrainReply(text: Say.line(.homeworkSteps, ["problem": s.problem, "answer": s.answer]),
                          cards: [.steps(StepsCard(problem: s.problem, steps: s.steps, answer: s.answer))], source: source)
    }

    func notes(_ action: String, _ words: String, store: NotesStore = .shared) -> BrainReply {
        let source = "Ace's notes"
        switch action {
        case "add":
            let n = store.add(words)
            return BrainReply(text: Say.line(.noteSaved, ["note": n.text]), source: source)
        case "list":
            guard !store.notes.isEmpty else { return BrainReply(text: Say.line(.noteListEmpty), source: source, mood: .idle) }
            let newest = store.notes.prefix(5).map { "\"\($0.text)\"" }
            let text = Say.line(.noteList, ["count": "\(store.notes.count)", "notes": TextKit.joinList(Array(newest))])
            return BrainReply(text: Say.singular(text), source: source)
        case "delete":
            guard let gone = store.delete(matching: words) else {
                return BrainReply(text: Say.line(.noteNotFound, ["words": words]), source: source, mood: .idle)
            }
            return BrainReply(text: Say.line(.noteDeleted, ["note": gone.text]), source: source)
        default:
            let count = store.clearAll()
            guard count > 0 else { return BrainReply(text: Say.line(.noteListEmpty), source: source, mood: .idle) }
            return BrainReply(text: Say.singular(Say.line(.notesCleared, ["count": "\(count)"])), source: source)
        }
    }

    /// Talk slower, faster or at the normal speed. The speed goes from 0.6 to 1.5 times normal.
    func voiceSpeed(_ how: String, settings: SettingsStore) -> BrainReply {
        let old = settings.voiceSpeed
        var new: Double
        switch how {
        case "slower": new = max(SettingsStore.slowestVoice, old - 0.15)
        case "faster": new = min(SettingsStore.fastestVoice, old + 0.15)
        default: new = 1.0
        }
        new = (new * 100).rounded() / 100
        if how != "normal", abs(new - old) < 0.001 {
            return BrainReply(text: Say.line(.voiceSpeedLimit, ["speed": how == "slower" ? "slow" : "fast"]), mood: .idle)
        }
        settings.voiceSpeed = new
        return BrainReply(text: Say.line(.voiceSpeedSet, ["speed": how == "normal" ? "at my normal speed" : how]))
    }

    private func shopping(_ what: String, think: (String) async -> Void) async -> BrainReply {
        let source = "Reminders"
        var items: [String] = []
        var recipe: RecipeCard?
        if what == "recipe" {
            guard let r = lastRecipe else { return BrainReply(text: Say.line(.shoppingNoRecipe), mood: .idle) }
            recipe = r
            items = r.ingredients
        } else if what.hasPrefix("add:") {
            items = RecipeBook.splitItems(String(what.dropFirst(4)))
        }
        let cal = CalendarService.shared
        guard await cal.requestReminderAccess() else { return BrainReply(text: Say.line(.shoppingNoAccess), source: source, mood: .alert) }
        if what == "read" {
            guard let have = await cal.shoppingItems() else { return BrainReply(text: Say.line(.shoppingNoAccess), source: source, mood: .alert) }
            guard !have.isEmpty else { return BrainReply(text: Say.line(.shoppingListEmpty), source: source, mood: .idle) }
            let text = Say.line(.shoppingListRead, ["count": "\(have.count)", "items": TextKit.joinList(have.map { $0.lowercased() })])
            return BrainReply(text: Say.singular(text), source: source)
        }
        guard !items.isEmpty else { return BrainReply(text: Say.line(.shoppingNoRecipe), mood: .idle) }
        await think("Adding \(items.count) thing\(items.count == 1 ? "" : "s") to your Shopping list in Reminders")
        guard let result = await cal.addToShopping(items) else {
            return BrainReply(text: Say.line(.shoppingNoAccess), source: source, mood: .alert)
        }
        var text: String
        if let recipe {
            text = result.added.isEmpty ? "" : Say.line(.shoppingAdded, ["count": "\(result.added.count)", "recipe": recipe.name.lowercased(),
                                                                        "list": ShoppingList.name])
        } else {
            text = result.added.isEmpty ? "" : Say.line(.shoppingAddedItems, ["items": TextKit.joinList(result.added.map { $0.lowercased() }),
                                                                             "list": ShoppingList.name])
        }
        if !result.skipped.isEmpty {
            text += (text.isEmpty ? "" : " ") + Say.line(.shoppingSkipped, ["count": "\(result.skipped.count)"])
        }
        return BrainReply(text: Say.singular(TextKit.capitalizeFirst(text)), source: source)
    }

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
        if let day = DayWords.find(in: t), day.offset > 0 || day.label == "this weekend" {
            // "tomorrow", "on saturday", "this weekend".
            start = c.date(byAdding: .day, value: day.offset, to: today)!
            end = c.date(byAdding: .day, value: day.length, to: start)!
            label = DayWords.weekdays.contains(day.label.lowercased()) ? "on " + day.label : day.label
        } else if t.contains("week") {
            end = c.date(byAdding: .day, value: 7, to: today)!
            label = "in the next 7 days"
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
