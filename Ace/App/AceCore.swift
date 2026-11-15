import Combine
import SwiftUI
import UIKit
import WidgetKit

/// A web page to show in the in-app browser sheet.
struct WebPage: Identifiable, Equatable {
    var id: String { url.absoluteString }
    var url: URL
}

/// Runs Ace: the chat, the orb's mood, the wake-up checks, greetings and bedtime nudges.
@MainActor
final class AceCore: ObservableObject, BrainHost {
    let settings: SettingsStore
    let memory = MemoryStore()
    let sleepCoach = SleepCoach()
    let brain = Brain()

    @Published var messages: [ChatMessage] = []
    @Published var mood: OrbMood = .idle
    @Published var look: CGPoint = .zero
    @Published var eyeOpen: CGFloat = 1
    @Published var liveThoughts: [String] = []
    @Published var busy = false
    @Published var statusLine = "Ready"
    @Published var webPage: WebPage?
    @Published var checkHistory: [CheckReport] = []
    @Published var nextWake: Date?
    @Published var handsFree = false
    private(set) var lastImageReport: ImageReport?

    private var wakeTask: Task<Void, Never>?
    private var moodResetTask: Task<Void, Never>?
    private var lastInteraction = Date()
    private var typing = false
    private let chatFile = "chat.json"
    private let checksFile = "checks.json"
    private var voiceWatch: AnyCancellable?
    private var holdDown = false

    init(settings: SettingsStore) {
        self.settings = settings
        messages = Persistence.load([ChatMessage].self, from: chatFile) ?? []
        checkHistory = Persistence.load([CheckReport].self, from: checksFile) ?? []
        brain.host = self
        applySoundSettings()
        setUpVoice()
    }

    // MARK: Talking to Ace

    private func setUpVoice() {
        let voice = VoiceIn.shared
        voice.onCommand = { [weak self] text in self?.send(text) }
        voiceWatch = voice.$state.combineLatest(voice.$heard)
            .receive(on: RunLoop.main)
            .sink { [weak self] state, heard in self?.voiceChanged(state, heard: heard) }
    }

    private func voiceChanged(_ state: VoiceIn.State, heard: String) {
        switch state {
        case .holding, .hearingCommand:
            if mood != .listening { setMood(.listening) }
            statusLine = heard.isEmpty ? "Listening" : heard
        case .waitingForWakeWord, .off:
            if mood == .listening && !busy {
                setMood(.idle)
                statusLine = "Ready"
            }
        }
    }

    /// You pressed and held the orb (down), or let go (up).
    func holdToTalk(_ down: Bool) {
        holdDown = down
        if down {
            noteInteraction()
            SoundFX.shared.play(.orbWake, gain: 0.7)
            Haptics.shared.play(.pop)
            Task {
                let started = await VoiceIn.shared.startHold()
                if !started {
                    messages.append(ChatMessage(speaker: .ace, text: Say.line(.voiceNoPermission), source: "voice"))
                    saveChat()
                    setMood(.alert, thenIdleAfter: 2.5)
                } else if !holdDown {
                    // You let go before the microphone was ready.
                    finishHold()
                }
            }
        } else {
            finishHold()
        }
    }

    private func finishHold() {
        guard VoiceIn.shared.state == .holding else { return }
        Task {
            let text = await VoiceIn.shared.endHold()
            if text.isEmpty {
                SoundFX.shared.play(.blink, gain: 0.6)
                let line = Say.line(.voiceDidntHear)
                statusLine = line
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                if statusLine == line { statusLine = "Ready" }
            } else {
                send(text)
            }
        }
    }

    var latestCheck: CheckReport? { checkHistory.first }

    func applySoundSettings() {
        SoundFX.shared.enabled = settings.soundsOn
        SoundFX.shared.volume = Float(settings.volume)
        Haptics.shared.enabled = settings.hapticsOn
    }

    // MARK: App life

    func becameActive() {
        noteInteraction()
        CalendarService.shared.refreshStatus()
        scheduleWake()
        if settings.heyAce && !handsFree {
            _ = setHandsFree(true)
        } else {
            VoiceIn.shared.appActive(true)
        }
        KitchenTimers.shared.refresh()
        let today = Persistence.dayKey()
        if settings.lastGreetingDay != today {
            settings.lastGreetingDay = today
            Task { await greet() }
        }
    }

    func wentToBackground() {
        wakeTask?.cancel()
        wakeTask = nil
        SoundFX.shared.stopLoop()
        saveChat()
        BackgroundWake.schedule()
        VoiceIn.shared.appActive(false)
    }

    func noteInteraction() {
        lastInteraction = Date()
        sleepCoach.noteActive()
    }

    // MARK: Chat

    func setTyping(_ isTyping: Bool) {
        typing = isTyping
        if !busy, mood == .idle || mood == .typing {
            mood = isTyping ? .typing : .idle
        }
    }

    func typedKey() {
        if settings.soundsOn { SoundFX.shared.play(.typeTick, pan: Float.random(in: -0.3...0.3), jitter: 0.12, gain: 0.35) }
    }

    func send(_ raw: String, imageFile: String? = nil) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || imageFile != nil else { return }
        noteInteraction()
        messages.append(ChatMessage(speaker: .user, text: text, imageFile: imageFile))
        SoundFX.shared.play(.send, jitter: 0.03, gain: 0.7)
        Haptics.shared.play(.tick)
        Task { await think(about: text, imageFile: imageFile) }
    }

    private func think(about text: String, imageFile: String? = nil) async {
        busy = true
        liveThoughts = []
        setMood(.thinking)
        statusLine = "Thinking"
        SoundFX.shared.startLoop()
        let onThought: (String) -> Void = { [weak self] step in
            self?.liveThoughts.append(step)
            self?.statusLine = step
        }
        var reply: BrainReply
        if let imageFile {
            reply = await lookAt(imageFile: imageFile, question: text, onThought: onThought)
        } else {
            reply = await brain.respond(to: text, onThought: onThought)
        }
        SoundFX.shared.stopLoop()
        reply.text = TextKit.stripModelTags(reply.text)
        if reply.text.isEmpty && reply.cards.isEmpty { reply.text = Say.line(.empty) }
        let msg = ChatMessage(speaker: .ace, text: reply.text, thoughts: settings.showThinking ? reply.thoughts : [],
                              cards: reply.cards, source: reply.source)
        messages.append(msg)
        busy = false
        liveThoughts = []
        statusLine = "Ready"
        switch reply.mood {
        case .alert:
            SoundFX.shared.play(.alert, gain: 0.8)
            Haptics.shared.play(.alert)
        case .idle:
            SoundFX.shared.play(.blink, gain: 0.6)
        default:
            SoundFX.shared.play(.success, gain: 0.55)
            Haptics.shared.play(.success)
        }
        speak(reply.text)
        setMood(reply.mood == .idle ? .talking : reply.mood, thenIdleAfter: 2.2)
        saveChat()
    }

    func speak(_ text: String) {
        guard settings.speakReplies || handsFree else { return }
        VoiceOut.shared.speak(text, voiceID: settings.voiceID) { [weak self] speaking in
            guard let self else { return }
            VoiceIn.shared.aceSpeaking(speaking)
            if speaking { self.setMood(.talking) } else if !self.busy { self.setMood(.idle) }
        }
    }

    func clearChat() {
        messages = []
        saveChat()
    }

    private func saveChat() {
        Persistence.save(Array(messages.suffix(300)), to: chatFile)
    }

    func setMood(_ m: OrbMood, thenIdleAfter seconds: Double? = nil) {
        moodResetTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { mood = m }
        if let seconds {
            moodResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard let self, !Task.isCancelled, !self.busy else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.mood = self.typing ? .typing : .idle
                    self.look = .zero
                }
            }
        }
    }

    // MARK: Calendar confirm cards

    func answerDraft(messageID: UUID, draftID: UUID, yes: Bool) {
        guard let mi = messages.firstIndex(where: { $0.id == messageID }) else { return }
        for ci in messages[mi].cards.indices {
            guard case .eventDraft(var d) = messages[mi].cards[ci], d.id == draftID, d.status == .waiting else { continue }
            if yes {
                do {
                    d.resultText = try CalendarService.shared.apply(d)
                    d.status = .done
                    SoundFX.shared.play(.success)
                    Haptics.shared.play(.success)
                    WidgetCenter.shared.reloadAllTimelines()
                } catch {
                    d.status = .failed
                    d.resultText = error.localizedDescription
                    SoundFX.shared.play(.alert)
                }
            } else {
                d.status = .cancelled
                d.resultText = "Okay, I left your calendar alone."
                SoundFX.shared.play(.blink)
            }
            messages[mi].cards[ci] = .eventDraft(d)
            saveChat()
            return
        }
    }

    // MARK: Links

    func openLink(_ url: URL, title: String) {
        let scheme = url.scheme?.lowercased() ?? ""
        if (scheme == "http" || scheme == "https") && settings.openLinksIn == "ace" {
            webPage = WebPage(url: url)
        } else {
            UIApplication.shared.open(url)
        }
    }

    // MARK: Wake-ups

    /// Picks a random time 15 to 30 minutes from now for Ace to wake up and look around.
    func scheduleWake() {
        wakeTask?.cancel()
        guard settings.wakeChecks else { nextWake = nil; return }
        let seconds = Double.random(in: 15 * 60...30 * 60)
        nextWake = Date().addingTimeInterval(seconds)
        wakeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            await self.wakeUp(reason: .timer)
            self.scheduleWake()
        }
    }

    enum WakeReason { case timer, manual, greeting }

    /// The eyes come out, look around (with whirs panned left and right), then Ace checks things.
    func wakeUp(reason: WakeReason) async {
        guard !busy else { return }
        busy = true
        statusLine = "Waking up"
        SoundFX.shared.play(.orbWake, gain: 0.8)
        Haptics.shared.play(.wake)
        try? await Task.sleep(nanoseconds: 450_000_000)
        setMood(.checking)
        SoundFX.shared.play(.eyesPop, gain: 0.8)
        Haptics.shared.play(.pop)
        statusLine = "Checking things"
        let task = Task { await self.lookAround(times: 5) }
        let report = await runCheck(spoken: reason == .manual)
        await task.value
        busy = false
        statusLine = "Ready"
        if reason == .manual {
            messages.append(ChatMessage(speaker: .ace, text: report.summary, cards: [.check(report)], source: "check"))
            saveChat()
            speak(report.summary)
        }
        if report.needsAttention {
            setMood(.alert)
            SoundFX.shared.play(.alert)
            Haptics.shared.play(.alert)
            if reason != .manual {
                messages.append(ChatMessage(speaker: .ace, text: "I woke up to check on things. " + report.summary, cards: [.check(report)], source: "check"))
                saveChat()
                speak(report.summary)
            }
            setMood(.alert, thenIdleAfter: 3.5)
        } else {
            setMood(.happy)
            SoundFX.shared.play(.success, gain: 0.45)
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            SoundFX.shared.play(.sleepWhoosh, gain: 0.6)
            setMood(.happy, thenIdleAfter: 0.3)
        }
        bedtimeNudgeIfNeeded()
    }

    private func lookAround(times: Int) async {
        for i in 0..<times {
            let target = CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -0.6...0.6))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { look = target }
            SoundFX.shared.play(.lookWhir, pan: Float(target.x) * 0.9, jitter: 0.08, gain: 0.5)
            try? await Task.sleep(nanoseconds: 520_000_000)
            if i == 2 || Int.random(in: 0..<3) == 0 {
                withAnimation(.easeInOut(duration: 0.08)) { eyeOpen = 0.08 }
                SoundFX.shared.play(.blink, pan: Float(target.x) * 0.5, gain: 0.5)
                Haptics.shared.play(.blink)
                try? await Task.sleep(nanoseconds: 110_000_000)
                withAnimation(.easeInOut(duration: 0.1)) { eyeOpen = 1 }
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { look = .zero }
    }

    /// Looks at everything iPadOS lets an app see and writes a short report.
    func runCheck(spoken: Bool) async -> CheckReport {
        var items: [CheckItem] = []
        let s = SystemMonitor.shared.snapshot()

        if let level = s.batteryLevel {
            let pct = Int((level * 100).rounded())
            let charging = s.batteryState == .charging || s.batteryState == .full
            let low = pct <= 20 && !charging
            items.append(CheckItem(icon: charging ? "battery.100.bolt" : low ? "battery.25" : "battery.75",
                                   title: "Battery \(pct)%", detail: charging ? "Charging" : low ? "Plug in soon" : "Doing fine",
                                   level: low ? .warn : .ok))
        }
        if s.lowPower {
            items.append(CheckItem(icon: "bolt.slash", title: "Low Power Mode", detail: "On, so some things run slower", level: .info))
        }
        if let free = s.freeBytes, let total = s.totalBytes, total > 0 {
            let pct = Double(free) / Double(total)
            items.append(CheckItem(icon: "internaldrive", title: "Storage", detail: "\(SystemMonitor.bytes(free)) free",
                                   level: pct < 0.08 ? .warn : pct < 0.15 ? .info : .ok))
        }
        let memPct = s.deviceMemoryBytes > 0 ? Double(s.appMemoryBytes) / Double(s.deviceMemoryBytes) : 0
        items.append(CheckItem(icon: "memorychip", title: "Memory", detail: "Ace uses \(SystemMonitor.bytes(s.appMemoryBytes)) of \(SystemMonitor.bytes(s.deviceMemoryBytes))",
                               level: memPct > 0.4 ? .info : .ok))
        if s.thermal == .serious || s.thermal == .critical {
            items.append(CheckItem(icon: "thermometer.high", title: "Temperature", detail: "Your iPad is \(SystemMonitor.thermalText(s.thermal)). Give it a break.", level: .warn))
        }
        items.append(CheckItem(icon: s.online ? "wifi" : "wifi.slash", title: s.online ? "Online" : "Offline",
                               detail: s.online ? (s.onWiFi ? "Wi-Fi" : "Cellular") : "Web answers are paused", level: s.online ? .ok : .info))

        // Time and how long you've been away.
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        items.append(CheckItem(icon: "clock", title: now.formatted(date: .omitted, time: .shortened),
                               detail: now.formatted(.dateTime.weekday(.wide).month().day()), level: hour >= 22 || hour < 5 ? .info : .ok))
        let away = now.timeIntervalSince(lastInteraction)
        if away > 10 * 60 {
            items.append(CheckItem(icon: "person.fill.questionmark", title: "You've been away",
                                   detail: "About \(DateParser.sayDuration(away.rounded()))", level: .info))
        }
        let locked = !UIApplication.shared.isProtectedDataAvailable
        items.append(CheckItem(icon: locked ? "lock.fill" : "rectangle.inset.filled", title: locked ? "Screen locked" : "Screen on",
                               detail: locked ? "The iPad is locked" : "Ace is open", level: .ok))

        // Calendar: what's coming up in the next 2 hours.
        let cal = CalendarService.shared
        if cal.eventAccess {
            let soon = cal.events(from: now, to: now.addingTimeInterval(2 * 3600), nimbusOnly: false).filter { !$0.allDay }
            if let next = soon.first {
                let mins = Int(next.start.timeIntervalSince(now) / 60)
                items.append(CheckItem(icon: "calendar", title: next.title,
                                       detail: mins <= 0 ? "Happening now" : "Starts in \(mins) min", level: mins <= 30 ? .warn : .info))
            } else {
                items.append(CheckItem(icon: "calendar", title: "Calendar", detail: "Nothing in the next 2 hours", level: .ok))
            }
        }
        if cal.reminderAccess {
            let due = await cal.openReminders(dueBefore: now)
            let overdue = due.filter { $0.due != nil }
            if !overdue.isEmpty {
                items.append(CheckItem(icon: "checklist", title: "\(overdue.count) reminder\(overdue.count == 1 ? "" : "s") due",
                                       detail: overdue.prefix(2).map(\.title).joined(separator: ", "), level: .warn))
            }
        }

        // Ace's own notifications that are still waiting.
        let delivered = await Notifier.delivered()
        if !delivered.isEmpty {
            items.append(CheckItem(icon: "bell.badge", title: "\(delivered.count) notification\(delivered.count == 1 ? "" : "s") from me",
                                   detail: delivered.prefix(2).map(\.title).joined(separator: ", "), level: .info))
        }
        let timers = await Notifier.pending().filter { $0.id.hasPrefix("timer-") }
        if let t = timers.compactMap(\.fireDate).min() {
            items.append(CheckItem(icon: "timer", title: "Timer running", detail: "Done \(DateParser.say(t))", level: .ok))
        }

        let warns = items.filter { $0.level == .warn }
        let summary: String
        if warns.isEmpty {
            summary = ["Everything looks good.", "All clear. Nothing needs you right now.", "Looked around. All good!"].randomElement()!
        } else {
            summary = "\(warns.count) thing\(warns.count == 1 ? "" : "s") need\(warns.count == 1 ? "s" : "") you: " + warns.map(\.title).joined(separator: ", ") + "."
        }
        let report = CheckReport(items: items, summary: summary)
        checkHistory.insert(report, at: 0)
        if checkHistory.count > 40 { checkHistory.removeLast(checkHistory.count - 40) }
        Persistence.save(checkHistory, to: checksFile)
        return report
    }

    // MARK: Greeting and bedtime

    private func greet() async {
        try? await Task.sleep(nanoseconds: 700_000_000)
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let name = settings.userName.isEmpty ? "" : ", \(settings.userName)"
        SoundFX.shared.play(.greeting, gain: 0.8)
        Haptics.shared.play(.success)
        setMood(.happy)
        var lines = ["\(part)\(name)! Ace V4 is awake."]
        let cal = CalendarService.shared
        if cal.eventAccess {
            let c = Calendar.current
            let end = c.date(byAdding: .day, value: 1, to: c.startOfDay(for: Date()))!
            let events = cal.events(from: Date(), to: end, nimbusOnly: false)
            lines.append(events.isEmpty ? "Your calendar is clear for the rest of today." :
                            "You have \(events.count) thing\(events.count == 1 ? "" : "s") today, starting with \(events[0].title).")
        }
        if let level = SystemMonitor.shared.snapshot().batteryLevel, level < 0.25 {
            lines.append("Your battery is at \(Int(level * 100))%, so you may want to charge.")
        }
        messages.append(ChatMessage(speaker: .ace, text: lines.joined(separator: " "), source: "greeting"))
        saveChat()
        speak(lines.joined(separator: " "))
        setMood(.happy, thenIdleAfter: 2.5)
    }

    private func bedtimeNudgeIfNeeded() {
        guard settings.bedtimeTips, sleepCoach.isNearBedtime() else { return }
        let key = "bedtimeNudge-" + Persistence.dayKey()
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        let advice = sleepCoach.advice()
        messages.append(ChatMessage(speaker: .ace, text: "It's almost your bedtime. " + advice.text, source: "bedtime"))
        saveChat()
        SoundFX.shared.play(.sleepWhoosh)
    }

    // MARK: BrainHost (features that come in the next update say so honestly)

    var pcPaired: Bool { false }

    func setHandsFree(_ on: Bool) -> String {
        settings.heyAce = on
        handsFree = on
        Task {
            let ok = await VoiceIn.shared.setHandsFree(on)
            if !ok {
                settings.heyAce = false
                handsFree = false
                messages.append(ChatMessage(speaker: .ace, text: Say.line(.voiceNoPermission), source: "voice"))
                saveChat()
            }
        }
        return Say.line(on ? .heyAceOn : .heyAceOff)
    }

    func pcCommand(_ action: String, target: String?) async -> (ok: Bool, detail: String) {
        (false, "PC Sync with Nimbus is coming in the next update.")
    }

    func syncNow() async -> String {
        "PC Sync with Nimbus is coming in the next update."
    }

    func findFiles(_ query: String, largest: Bool) async -> (text: String, hits: [FileHit]) {
        ("File search is coming in the next update.", [])
    }

    func findScreenshots(_ query: String) async -> (text: String, hits: [ScreenshotHit]) {
        ("Screenshot search is coming in the next update.", [])
    }

    func describeLastPhoto() -> BrainReply? {
        guard let r = lastImageReport else { return nil }
        return BrainReply(text: r.summary, cards: [.image(r)], source: "vision")
    }

    // MARK: Pictures

    /// Looks at a picture with Vision, then (if a model is on) answers the question about it.
    private func lookAt(imageFile: String, question: String, onThought: @escaping (String) -> Void) async -> BrainReply {
        var thoughts: [String] = []
        func note(_ s: String) { thoughts.append(s); onThought(s) }
        note("Looking at your picture")
        guard let image = UIImage(contentsOfFile: Persistence.imageURL(imageFile).path) else {
            return BrainReply(text: "I couldn't open that picture.", thoughts: thoughts, source: "vision", mood: .idle)
        }
        let report = await ImageAnalyzer.analyze(image)
        lastImageReport = report
        note(report.labels.isEmpty ? "Didn't recognize objects" : "Spotted: " + report.labels.prefix(3).joined(separator: ", "))
        if report.text != nil { note("Read the text in it") }
        var text = report.summary
        var source = "vision"
        if !question.isEmpty, settings.lfmAllowed || settings.useAppleModel {
            note("Asking my on-device model about it")
            let facts = "What the picture shows (from the iPad's vision): \(report.summary)"
                + (report.text.map { "\nText in the picture:\n\($0.prefix(1500))" } ?? "")
            if let a = await askModel(system: Self.modelInstructions + " Answer questions about a picture using only the description given.",
                                      user: facts + "\n\nQuestion: \(question)") {
                text = a.text
                source = "vision + " + a.model
            }
        }
        return BrainReply(text: text, thoughts: thoughts, cards: [.image(report)], source: source)
    }

    // MARK: On-device models

    static let modelInstructions = "You are Ace, a friendly, upbeat assistant on an iPad. Keep answers short, clear and correct. Never make up facts. If you don't know, say so."

    /// LFM3 Omni first (if it's switched on and downloaded), then Apple's model (if it's switched on).
    /// Both are off unless turned on in Settings. Thinking tags are always stripped.
    private func askModel(system: String, user: String, maxTokens: Int = 320) async -> (text: String, model: String)? {
        if settings.lfmAllowed, LocalModel.shared.filesPresent,
           let a = await LocalModel.shared.generate(system: system, user: user, maxTokens: maxTokens) {
            let clean = TextKit.stripModelTags(a)
            if !clean.isEmpty { return (clean, "LFM3 Omni") }
        }
        if settings.useAppleModel, let a = await AppleModel.respond(instructions: system, prompt: user) {
            let clean = TextKit.stripModelTags(a)
            if !clean.isEmpty { return (clean, "Apple model") }
        }
        return nil
    }

    func homeCommand(_ cmd: HomeCommand, confirmed: Bool) async -> (reply: BrainReply, confirm: HomeCommand?) {
        await HomeService.shared.run(cmd, confirmed: confirmed, fahrenheit: settings.useFahrenheit)
    }

    /// LFM3 Omni is downloaded and this build has the engine to run it.
    var modelReady: Bool { LocalModel.engineIncluded && LocalModel.shared.filesPresent }

    func freeAnswer(_ question: String) async -> (text: String, model: String)? {
        await askModel(system: Self.modelInstructions, user: question)
    }
}
