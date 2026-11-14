import Foundation

/// What the brain hands back to the chat.
struct BrainReply {
    var text: String
    var thoughts: [String] = []
    var cards: [AceCard] = []
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
    func polish(_ text: String, question: String) async -> String?
    func freeAnswer(_ question: String) async -> String?
}

/// Ace V4's brain: rules + a big answer bank + a neural matcher + web research,
/// run as a think loop that keeps trying new ways until it's sure (or out of ideas).
@MainActor
final class Brain {
    let bank = QABank()
    let classifier = IntentClassifier()
    weak var host: BrainHost?

    private var lastQuestion = ""
    private var lastAnswer = ""
    private var lastTopic = ""
    private var awaitingAnswerFor: String?
    private var lastVariant: [String: Int] = [:]

    // MARK: Think loop

    func respond(to raw: String, onThought: @escaping (String) -> Void) async -> BrainReply {
        var thoughts: [String] = []
        let think: (String) async -> Void = { step in
            thoughts.append(step)
            onThought(step)
            try? await Task.sleep(nanoseconds: 140_000_000)
        }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return BrainReply(text: "I'm here. What's up?") }

        // Waiting for the right answer after "that's wrong"?
        if let q = awaitingAnswerFor {
            awaitingAnswerFor = nil
            if IntentRouter.parse(text) == nil, !text.hasSuffix("?") {
                bank.learn(question: q, answer: text, source: "taught", tag: "taught")
                await think("Saving your answer for \"\(q)\"")
                return finish(BrainReply(text: "Got it. Next time you ask \"\(q)\", I'll say: \(text)", thoughts: thoughts, source: "learned"), question: text)
            }
        }

        await think("Reading: \"\(text)\"")
        let parts = splitCompound(text)
        if parts.count > 1 {
            await think("That's \(parts.count) questions. I'll answer each one.")
            var replies: [BrainReply] = []
            for p in parts {
                replies.append(await solve(p, think: think))
            }
            var combined = BrainReply(text: replies.map(\.text).joined(separator: "\n\n"), thoughts: thoughts)
            combined.cards = replies.flatMap(\.cards)
            combined.source = replies.first?.source ?? "rules"
            combined.mood = replies.contains { $0.mood == .alert } ? .alert : .happy
            return finish(combined, question: text)
        }
        var reply = await solve(text, think: think)
        reply.thoughts = thoughts
        if let host, host.settings.useAppleModel || host.settings.useLocalModel,
           reply.source == "bank" || reply.source == "web" || reply.source == "learned" {
            await think("Polishing the wording")
            if let better = await host.polish(reply.text, question: text) {
                reply.text = better
                reply.thoughts = thoughts
            }
        }
        reply.thoughts = thoughts
        return finish(reply, question: text)
    }

    private func finish(_ r: BrainReply, question: String) -> BrainReply {
        lastQuestion = question
        lastAnswer = r.text
        return r
    }

    /// Splits "what's the capital of japan and how many moons does mars have" into two questions.
    private func splitCompound(_ text: String) -> [String] {
        let t = TextKit.normalize(text)
        let starts = #"^(what|who|how|when|where|why|which|is|are|can|do|does|tell|whats)\b"#
        for sep in [" and also ", "; ", " and then ", " and "] {
            let pieces = t.components(separatedBy: sep)
            if pieces.count == 2, pieces.allSatisfy({ Rx.matches(starts, $0) && $0.split(separator: " ").count >= 3 }) {
                return pieces
            }
        }
        return [text]
    }

    private func solve(_ text: String, think: (String) async -> Void) async -> BrainReply {
        // Pass 1: rules.
        if let intent = IntentRouter.parse(text) {
            await think("Rule match: \(describe(intent))")
            if let r = await run(intent, text: text, think: think) { return r }
        }

        // Pass 2: the answer bank (words + neural meaning).
        var matches = bank.search(text)
        if let best = matches.first {
            await think(String(format: "Answer bank: closest is \"%@\" (%.0f%% sure)", best.wording, best.score * 100))
            if best.score >= 0.74 { return answer(from: best, think: think) }
        } else {
            await think("Nothing close in my answer bank")
        }

        // Pass 3: the neural classifier, for skills said in unusual ways.
        if let c = classifier.classify(text), c.score >= 0.8 {
            await think(String(format: "Sounds like the %@ skill (%.0f%%)", c.skill.rawValue, c.score * 100))
            if let intent = intent(for: c.skill, text: text), let r = await run(intent, text: text, think: think) { return r }
        }

        // Pass 4: say it another way and look again.
        let rephrased = rephrase(text)
        if rephrased != TextKit.normalize(text), !rephrased.isEmpty {
            await think("Trying it another way: \"\(rephrased)\"")
            let again = bank.search(rephrased)
            if let best = again.first, best.score >= 0.72 { return answer(from: best, think: think) }
            matches = (matches + again).sorted { $0.score > $1.score }
        }

        // Pass 5: research it on the web, then learn it.
        if let host, host.settings.webAnswers, SystemMonitor.shared.online {
            await think("Not sure yet, so I'm researching it on the web")
            if let r = await WebService.research(text), r.confidence >= 0.5 {
                await think("Read \(max(1, r.sources.count)) source\(r.sources.count == 1 ? "" : "s") and picked the best sentences")
                lastTopic = r.title
                let learnedAnswer = r.summary
                bank.learn(question: text, answer: learnedAnswer, source: "learned", tag: "learned.web", url: r.sources.first?.url.absoluteString)
                await think("Saved it to my answer bank so I'll know it next time")
                let card = WebCard(title: r.title, summary: r.summary, bullets: r.bullets, imageURL: r.imageURL, sources: r.sources)
                return BrainReply(text: r.summary, cards: [.web(card)], source: "web")
            }
        }

        // Pass 6: a weaker match is better than nothing, but say so.
        if let best = matches.first, best.score >= 0.58 {
            await think("Going with my best guess")
            var r = answer(from: best, think: think)
            r.text = "I think you're asking \"\(best.wording)\". \(r.text)"
            return r
        }

        // Pass 7: ask the on-device model (LFM3 Omni or Apple's), if one is turned on.
        if let host, host.settings.useLocalModel || host.settings.useAppleModel {
            await think("Asking my on-device model")
            if let a = await host.freeAnswer(text) {
                await think("The model answered, so I'm going with that")
                return BrainReply(text: a, source: "model")
            }
        }

        await think("Out of ideas for now")
        lastTopic = Summarizer.topic(of: text)
        var r = BrainReply(text: "I don't know that one yet. You can teach me by saying \"the answer to \(TextKit.normalize(text)) is ...\", or I can search the web.", source: "none", mood: .idle)
        if let host, let link = Sites.searchLink(text, site: nil, engine: host.settings.searchEngine) {
            r.cards = [.links([LinkItem(title: link.title, url: link.url)])]
        }
        return r
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
        let parts = splitCompound(text)
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
    }

    private func understandOne(_ text: String) -> Understanding {
        if let intent = IntentRouter.parse(text) { return .skill(intent.kind) }
        var matches = bank.search(text)
        if let best = matches.first, best.score >= 0.74 { return .bank(best.entry.id) }
        if let c = classifier.classify(text), c.score >= 0.8, let intent = intent(for: c.skill, text: text) {
            return .skill(intent.kind)
        }
        let rephrased = rephrase(text)
        if rephrased != TextKit.normalize(text), !rephrased.isEmpty {
            let again = bank.search(rephrased)
            if let best = again.first, best.score >= 0.72 { return .bank(best.entry.id) }
            matches = (matches + again).sorted { $0.score > $1.score }
        }
        if let best = matches.first, best.score >= 0.58 { return .weakBank(best.entry.id) }
        return .unknown
    }

    private func answer(from m: QABank.Match, think: (String) async -> Void) -> BrainReply {
        let e = m.entry
        var i = Int.random(in: 0..<e.a.count)
        if e.a.count > 1, i == lastVariant[e.id] { i = (i + 1) % e.a.count }
        lastVariant[e.id] = i
        var text = e.a[i]
        let name = host?.settings.userName ?? ""
        text = text.replacingOccurrences(of: "{name}", with: name.isEmpty ? "" : name)
        lastTopic = Summarizer.topic(of: m.wording)
        let chatty = ["ace", "feelings", "fun", "school", "safety"].contains { e.tag.hasPrefix($0) }
        if !chatty, Int.random(in: 0..<5) == 0 {
            let openers = ["Sure! ", "Here you go: ", "Good question. ", "Easy one. ", "Okay! "]
            text = openers.randomElement()! + text
        }
        let source = e.source == "builtin" || e.source == nil ? "bank" : "learned"
        return BrainReply(text: text, source: source)
    }

    /// Drops filler like "can you tell me" and swaps a few words for ones the bank knows.
    private func rephrase(_ text: String) -> String {
        var t = " " + TextKit.normalize(text) + " "
        let fillers = ["can you tell me", "could you tell me", "do you know", "i want to know", "i wonder", "tell me",
                       "please", "hey ace", "ace", "real quick", "quick question", "i was wondering", "explain"]
        for f in fillers { t = t.replacingOccurrences(of: " \(f) ", with: " ") }
        let swaps = ["biggest": "largest", "huge": "big", "fastest": "fastest", "made you": "created you",
                     "built you": "created you", "whats": "what is", "kinda": "kind of", "smartest": "smartest",
                     "planets": "planet", "favourite": "favorite", "colour": "color"]
        for (a, b) in swaps { t = t.replacingOccurrences(of: " \(a) ", with: " \(b) ") }
        return t.trimmingCharacters(in: .whitespaces)
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
        }
    }

    // MARK: Skills

    private func run(_ intent: Intent, text: String, think: (String) async -> Void) async -> BrainReply? {
        guard let host else { return nil }
        let name = host.settings.userName
        let now = Date()
        switch intent {
        case .greeting:
            let hour = Calendar.current.component(.hour, from: now)
            let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
            let who = name.isEmpty ? "" : ", \(name)"
            let extra = ["What are we doing today?", "What can I help with?", "Need anything checked?", "Ready when you are."].randomElement()!
            return BrainReply(text: "\(part)\(who)! \(extra)")

        case .thanks:
            return BrainReply(text: ["You're welcome!", "Anytime!", "Happy to help.", "No problem!"].randomElement()!)

        case .goodbye:
            return BrainReply(text: ["See you later!", "Bye! I'll keep an eye on things.", "Talk soon!"].randomElement()!, mood: .idle)

        case .time:
            return BrainReply(text: "It's \(now.formatted(date: .omitted, time: .shortened)).")

        case .date:
            return BrainReply(text: "Today is \(now.formatted(.dateTime.weekday(.wide).month(.wide).day().year())).")

        case .daysUntil(let thing):
            guard let target = Holidays.date(for: thing, after: now) ?? DateParser.find(in: thing, now: now)?.date else { return nil }
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: target)).day ?? 0
            if days == 0 { return BrainReply(text: "That's today!") }
            return BrainReply(text: "\(days) day\(days == 1 ? "" : "s") until \(thing), on \(target.formatted(.dateTime.weekday(.wide).month(.wide).day())).")

        case .math(let expr):
            guard let v = try? MathEval.evaluate(expr) else { return nil }
            await think("Working it out: \(expr)")
            return BrainReply(text: "\(expr.replacingOccurrences(of: "pctof", with: "% of")) = \(MathEval.format(v))")

        case .convert(let q):
            guard let r = UnitConvert.convert(q) else { return nil }
            return BrainReply(text: r)

        case .roman(let s):
            if let n = Int(s), let r = Roman.toRoman(n) { return BrainReply(text: "\(n) in Roman numerals is \(r).") }
            if let n = Roman.fromRoman(s) { return BrainReply(text: "\(s.uppercased()) is \(n).") }
            return BrainReply(text: "Roman numerals only go from 1 to 3,999.")

        case .randomNumber(let a, let b):
            return BrainReply(text: "\(Int.random(in: a...b))")

        case .spell(let word):
            let letters = word.uppercased().map(String.init).joined(separator: "-")
            return BrainReply(text: "\(word) is spelled \(letters).")

        case .timer(let seconds, let label):
            let id = "timer-\(UUID().uuidString)"
            let fire = now.addingTimeInterval(seconds)
            let ok = await Notifier.schedule(id: id, title: label, body: "Your \(DateParser.sayDuration(seconds)) timer is done.", at: fire, category: "timer")
            let card = TimerCard(label: label, fireDate: fire, notificationID: id)
            let note = ok ? "" : " Notifications are off, so keep Ace open to see it finish."
            return BrainReply(text: "\(label) set for \(DateParser.sayDuration(seconds)).\(note)", cards: [.timer(card)])

        case .alarm:
            return BrainReply(text: "Apps can't set iPad Clock alarms, but I can set a timer or a reminder that rings. Try \"remind me at 7am to get up\".")

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
            return BrainReply(text: "Opening \(link.title).", cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .searchTab(let query, let site):
            guard let link = Sites.searchLink(query, site: site, engine: host.settings.searchEngine) else { return nil }
            host.openLink(link.url, title: link.title)
            return BrainReply(text: "Searching \(site.flatMap { Sites.lookup($0)?.name } ?? "the web") for \(query).", cards: [.links([LinkItem(title: link.title, url: link.url)])])

        case .recipe(let dish):
            await think("Looking up a recipe for \(dish)")
            guard let card = await WebService.recipe(dish) else {
                return BrainReply(text: "I couldn't find a recipe for \(dish). Try another name, like \"pancakes\" or \"chicken curry\".", mood: .idle)
            }
            lastTopic = card.name
            return BrainReply(text: "Here's \(card.name): \(card.ingredients.count) ingredients and \(card.steps.count) steps.", cards: [.recipe(card)], source: "web")

        case .weather(let place):
            let saved = UserDefaults.standard.string(forKey: "weatherCity")
            guard let city = place ?? saved, !city.isEmpty else {
                return BrainReply(text: "Which city should I check? Say \"weather in\" and your city, and I'll remember it.", mood: .idle)
            }
            await think("Checking the forecast for \(city)")
            guard let card = await WebService.weather(place: city, fahrenheit: host.settings.useFahrenheit) else {
                return BrainReply(text: "I couldn't get the weather for \(city) right now.", mood: .idle)
            }
            UserDefaults.standard.set(city, forKey: "weatherCity")
            let d = WebService.describe(code: card.code)
            var s = "It's \(Int(card.temperature.rounded()))\(card.unit) and \(d.text) in \(card.place)."
            if let today = card.days.first {
                s += " Today: high \(Int(today.high.rounded()))\(card.unit), low \(Int(today.low.rounded()))\(card.unit)"
                if let r = today.rainChance { s += ", \(r)% chance of rain" }
                s += "."
            }
            return BrainReply(text: s, cards: [.weather(card)], source: "web")

        case .check:
            await think("Waking up to look around")
            let report = await host.runCheck(spoken: false)
            return BrainReply(text: report.summary, cards: [.check(report)], mood: report.needsAttention ? .alert : .happy)

        case .battery:
            let s = SystemMonitor.shared.snapshot()
            guard let level = s.batteryLevel else { return BrainReply(text: "I can't read the battery right now.") }
            let pct = Int((level * 100).rounded())
            var t = "Your battery is at \(pct)%"
            switch s.batteryState {
            case .charging: t += " and charging."
            case .full: t += " and full."
            default: t += pct <= 20 ? ". Time to plug in soon." : "."
            }
            if s.lowPower { t += " Low Power Mode is on." }
            return BrainReply(text: t, mood: pct <= 20 && s.batteryState == .unplugged ? .alert : .happy)

        case .storage:
            let s = SystemMonitor.shared.snapshot()
            guard let free = s.freeBytes, let total = s.totalBytes, total > 0 else { return BrainReply(text: "I can't read storage right now.") }
            let pct = Int(Double(free) / Double(total) * 100)
            var t = "You have \(SystemMonitor.bytes(free)) free out of \(SystemMonitor.bytes(total)) (\(pct)% free)."
            if pct < 10 { t += " That's getting low. Offloading unused apps in Settings > General > iPad Storage helps." }
            return BrainReply(text: t, mood: pct < 10 ? .alert : .happy)

        case .memoryUsage:
            let s = SystemMonitor.shared.snapshot()
            return BrainReply(text: "Your iPad has \(SystemMonitor.bytes(s.deviceMemoryBytes)) of RAM. I'm using \(SystemMonitor.bytes(s.appMemoryBytes)), and about \(SystemMonitor.bytes(s.availableMemoryBytes)) more is free for me. iPadOS doesn't let apps see how much other apps use.")

        case .network:
            let s = SystemMonitor.shared.snapshot()
            if !s.online { return BrainReply(text: "You're offline right now. I can still answer from my answer bank.", mood: .alert) }
            return BrainReply(text: s.onWiFi ? "You're online over Wi-Fi." : "You're online over cellular.")

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
            return host.describeLastPhoto() ?? BrainReply(text: "Send me a picture with the photo or camera button first, then ask.")

        case .bedtime:
            let a = host.sleepCoach.advice(now: now)
            return BrainReply(text: a.text)

        case .remember(let fact):
            host.memory.add(fact)
            return BrainReply(text: "Got it, I'll remember \(MemoryStore.youForm(fact)).", source: "memory")

        case .setName(let n):
            let clean = n.split(separator: " ").map { TextKit.capitalizeFirst(String($0)) }.joined(separator: " ")
            host.settings.userName = clean
            return BrainReply(text: "Nice to meet you, \(clean)!", source: "memory")

        case .recall(let what):
            if ["name", "name again"].contains(what) {
                return BrainReply(text: name.isEmpty ? "You haven't told me your name yet. Say \"my name is ...\"." : "Your name is \(name).", source: "memory")
            }
            if let f = host.memory.recall("my " + what).first {
                return BrainReply(text: TextKit.capitalizeFirst(MemoryStore.youForm(f.text)) + ".", source: "memory")
            }
            return BrainReply(text: "You haven't told me your \(what) yet. Say \"remember my \(what) is ...\".", source: "memory", mood: .idle)

        case .recallAll:
            let facts = host.memory.facts
            if facts.isEmpty && name.isEmpty { return BrainReply(text: "I don't have anything saved about you yet.", source: "memory") }
            var lines: [String] = []
            if !name.isEmpty { lines.append("Your name is \(name).") }
            lines += facts.prefix(12).map { "• " + TextKit.capitalizeFirst(MemoryStore.youForm($0.text)) }
            return BrainReply(text: "Here's what I remember:\n" + lines.joined(separator: "\n"), source: "memory")

        case .forget(let what):
            let n = host.memory.forget(matching: what)
            return BrainReply(text: n == 0 ? "I didn't have anything saved about that." : "Done, I forgot \(n) thing\(n == 1 ? "" : "s").", source: "memory")

        case .handsFree(let on):
            return BrainReply(text: host.setHandsFree(on))

        case .pcPower(let action):
            guard host.pcPaired else {
                return BrainReply(text: "I'm not connected to your PC. Turn on PC Sync in Settings and pair with Nimbus first.", mood: .idle)
            }
            await think("Telling Nimbus to \(action)")
            let r = await host.pcCommand(action, target: nil)
            let card = PowerCard(action: action, status: r.ok ? .done : .failed, detail: r.detail)
            return BrainReply(text: r.ok ? (action == "restart" ? "Restarting your PC now." : "Shutting down your PC now.") : r.detail,
                              cards: [.power(card)], mood: r.ok ? .happy : .alert)

        case .pcApp(let action, let app, let onPC):
            if onPC || host.pcPaired {
                guard host.pcPaired else {
                    return BrainReply(text: "I can only \(action) apps on your PC once PC Sync is paired with Nimbus.", mood: .idle)
                }
                let r = await host.pcCommand(action, target: app)
                return BrainReply(text: r.ok ? "Done: \(action) \(app) on your PC." : r.detail, mood: r.ok ? .happy : .alert)
            }
            return BrainReply(text: "On iPad, apps can't \(action) other apps. You can swipe up from the bottom to switch or close apps. If you pair me with Nimbus, say \"\(action) \(app) on my PC\".", mood: .idle)

        case .pcStatus:
            guard host.pcPaired else { return BrainReply(text: "PC Sync is off, so I can't see your PC. You can turn it on in Settings.", mood: .idle) }
            let r = await host.pcCommand("status", target: nil)
            return BrainReply(text: r.detail, mood: r.ok ? .happy : .alert)

        case .syncNow:
            return BrainReply(text: await host.syncNow())

        case .sounds(let on):
            host.settings.soundsOn = on
            return BrainReply(text: on ? "Sounds are back on." : "Okay, I'll be quiet.")

        case .tellMore:
            let topic = lastTopic.isEmpty ? lastQuestion : lastTopic
            guard !topic.isEmpty, host.settings.webAnswers else { return BrainReply(text: "More about what? Ask me something first.") }
            await think("Researching more about \(topic)")
            guard let r = await WebService.research(topic) else { return BrainReply(text: "I couldn't find more about \(topic) right now.", mood: .idle) }
            let extra = r.bullets.isEmpty ? r.summary : r.bullets.joined(separator: " ")
            return BrainReply(text: extra, cards: [.web(WebCard(title: r.title, summary: r.summary, bullets: r.bullets, imageURL: r.imageURL, sources: r.sources))], source: "web")

        case .repeatLast:
            return BrainReply(text: lastAnswer.isEmpty ? "I haven't said anything yet." : lastAnswer)

        case .correction(let fix):
            guard !lastQuestion.isEmpty else { return nil }
            if let fix {
                bank.learn(question: lastQuestion, answer: TextKit.capitalizeFirst(fix), source: "taught", tag: "taught")
                return BrainReply(text: "Thanks for fixing that. I'll say \"\(TextKit.capitalizeFirst(fix))\" next time.", source: "learned")
            }
            awaitingAnswerFor = lastQuestion
            return BrainReply(text: "Oops. What should I have said?", mood: .idle)

        case .teach(let q, let a):
            bank.learn(question: q, answer: TextKit.capitalizeFirst(a), source: "taught", tag: "taught")
            return BrainReply(text: "Learned it! When you ask \"\(q)\", I'll say \"\(TextKit.capitalizeFirst(a))\".", source: "learned")

        case .ipadOnlyLimit(let msg):
            return BrainReply(text: msg, mood: .idle)
        }
    }

    // MARK: Calendar and reminders

    private func reminder(_ raw: String, think: (String) async -> Void) async -> BrainReply {
        let found = DateParser.find(in: raw)
        let fillers = ["remind me to", "remind me about", "remind me that", "remind me", "set a reminder to", "set a reminder for",
                       "set a reminder", "make a reminder to", "create a reminder to", "add a reminder to", "reminder to", "please", "ace"]
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
        if addedToReminders {
            return BrainReply(text: "I'll remind you to \(title.lowercased())\(when). It's in the Nimbus list in Reminders.")
        }
        if due != nil {
            return BrainReply(text: "I'll remind you to \(title.lowercased())\(when).")
        }
        return BrainReply(text: "When should I remind you? Try \"remind me to \(title.lowercased()) at 5pm\".", mood: .idle)
    }

    private func calendarAdd(_ raw: String, think: (String) async -> Void) async -> BrainReply {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else {
            return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert)
        }
        _ = cal.nimbusCalendar()
        guard let found = DateParser.find(in: raw) else {
            return BrainReply(text: "When is it? Try \"add soccer practice to my calendar tomorrow at 4pm\".", mood: .idle)
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
        return BrainReply(text: "Want me to add \"\(title)\" \(DateParser.say(found.date, allDay: found.allDay)) to your Nimbus calendar?",
                          cards: [.eventDraft(draft)], mood: .idle)
    }

    private func calendarEdit(_ raw: String, think: (String) async -> Void) async -> BrainReply? {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else { return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert) }
        let t = TextKit.normalize(raw)
        guard let g = Rx.groups(#"^(move|reschedule|change|push|rename|edit|update)\s+(?:my |the )?(.+?)\s+(?:to|from .+? to)\s+(.+)$"#, t) else { return nil }
        let verb = g[0], what = g[1], to = g[2]
        guard let event = cal.find(what, near: nil).first else {
            return BrainReply(text: "I couldn't find an event called \"\(what)\".", mood: .idle)
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
            return BrainReply(text: "When should I move \"\(event.title)\" to?", mood: .idle)
        }
        await think("Found \"\(event.title)\" \(DateParser.say(event.start, allDay: event.allDay))")
        let what2 = verb == "rename" ? "rename it to \"\(draft.title)\"" : "move it to \(DateParser.say(draft.start, allDay: draft.allDay))"
        return BrainReply(text: "Found \"\(event.title)\". Want me to \(what2)?", cards: [.eventDraft(draft)], mood: .idle)
    }

    private func calendarDelete(_ raw: String, think: (String) async -> Void) async -> BrainReply? {
        let cal = CalendarService.shared
        guard await cal.requestEventAccess() else { return BrainReply(text: CalendarService.CalendarError.noAccess.errorDescription ?? "", mood: .alert) }
        let found = DateParser.find(in: raw)
        let fillers = ["delete", "remove", "cancel", "clear", "my", "the", "event", "from my calendar", "from the calendar",
                       "off my calendar", "calendar", "please", "ace"]
        let what = DateParser.title(from: raw, removing: found?.phrases ?? [], fillers: fillers)
        guard let event = cal.find(what, near: found?.date).first else {
            return BrainReply(text: "I couldn't find \"\(what)\" on your calendar.", mood: .idle)
        }
        await think("Found \"\(event.title)\" \(DateParser.say(event.start, allDay: event.allDay))")
        let draft = EventDraft(action: .delete, title: event.title, start: event.start, end: event.end, allDay: event.allDay, eventID: event.id)
        return BrainReply(text: "Delete \"\(event.title)\" \(DateParser.say(event.start, allDay: event.allDay))?", cards: [.eventDraft(draft)], mood: .alert)
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
            guard let next = events.first else { return BrainReply(text: "Nothing coming up in the next 30 days.") }
            return BrainReply(text: "Next up: \(next.title), \(DateParser.say(next.start, allDay: next.allDay)).", cards: [.events([next])])
        }
        await think("Reading your calendars \(label)")
        let events = cal.events(from: start, to: end, nimbusOnly: false)
        if events.isEmpty { return BrainReply(text: "Nothing on your calendar \(label). You're free!") }
        let first = events.prefix(3).map { "\($0.title) \($0.allDay ? "(all day)" : "at " + $0.start.formatted(date: .omitted, time: .shortened))" }
        let more = events.count > 3 ? ", plus \(events.count - 3) more" : ""
        return BrainReply(text: "You have \(events.count) thing\(events.count == 1 ? "" : "s") \(label): \(first.joined(separator: ", "))\(more).", cards: [.events(events)])
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
