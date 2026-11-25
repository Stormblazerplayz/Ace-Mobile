import Combine
import SwiftUI
import UIKit
import WidgetKit

/// A web page to show in the in-app browser sheet.
struct WebPage: Identifiable, Equatable {
    var id: String { url.absoluteString }
    var url: URL
}

/// A flashcard study session to open full screen: one deck or all of them, and whether it's practice.
struct StudyTarget: Identifiable, Equatable {
    let id = UUID()
    var deckID: UUID?
    var practice: Bool
}

/// Runs Ace: the chat, the orb's mood, the wake-up checks, greetings and bedtime nudges.
@MainActor
final class AceCore: ObservableObject, BrainHost {
    let settings: SettingsStore
    let memory = MemoryStore()
    let sleepCoach = SleepCoach()
    let brain = Brain()
    /// A voice call with Ace (the call screen).
    let call = CallController()

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
    /// The Flashcards screen is open, and the deck it should show first (nil for the list of decks).
    @Published var flashcardsOpen = false
    @Published var flashcardsDeck: UUID?
    /// A study session that's open full screen.
    @Published var studyTarget: StudyTarget?
    /// The Ace Games screen is open.
    @Published var gamesOpen = false
    /// Ace Piano is open (full screen), and how it opened.
    @Published var pianoScreen: PianoScreen?
    /// The solar system map is open (full screen), and how it opened.
    @Published var spaceScreen: SpaceScreen?
    private(set) var lastImageReport: ImageReport?

    private var wakeTask: Task<Void, Never>?
    private var moodResetTask: Task<Void, Never>?
    /// Sassy mode: notices the same question asked again within 30 minutes.
    private var repeats = RepeatTracker()
    /// True while the orb rolls its eyes, so talking doesn't cut the eye-roll short.
    private var holdMood = false
    private var lastInteraction = Date()
    /// When the app went to the background (for the hello when you come back).
    private var awaySince: Date?
    /// False until the app has been in front once since it started.
    private var openedOnce = false
    private var typing = false
    private let chatFile = "chat.json"
    private let checksFile = "checks.json"
    private var voiceWatch: AnyCancellable?
    private var holdDown = false
    /// A call was just started from something you said or typed, so that reply isn't read out
    /// (the call says hello itself once it connects).
    private var callJustStarted = false

    init(settings: SettingsStore) {
        self.settings = settings
        messages = Persistence.load([ChatMessage].self, from: chatFile) ?? []
        checkHistory = Persistence.load([CheckReport].self, from: checksFile) ?? []
        brain.host = self
        call.host = self
        applySoundSettings()
        setUpVoice()
        // Siri, Shortcuts and widgets hand their asks to Ace here.
        IntentInbox.shared.connect { [weak self] text in self?.send(text) }
        IntentInbox.shared.connectCall { [weak self] in self?.startCall() }
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
        guard !call.isLive else { return }
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
        // Ace says hello when the app starts, and when you come back after 5 minutes or more.
        let now = Date()
        let first = !openedOnce
        openedOnce = true
        let away = awaySince
        awaySince = nil
        let greetNow = !call.isLive
            && Greeter.shouldGreet(now: now, lastGreeting: settings.lastGreetingAt, awaySince: away, firstOpen: first)
        var full = false
        if greetNow {
            settings.lastGreetingAt = now
            // The first hello of the day also shows today's calendar and battery.
            let today = Persistence.dayKey()
            full = settings.lastGreetingDay != today
            settings.lastGreetingDay = today
        }
        let fullHello = full
        Task {
            if greetNow { await greet(full: fullHello) }
            // After an update, the What's new card comes after the hello (once per build).
            showWhatsNew(force: false)
        }
    }

    func wentToBackground() {
        // iPadOS doesn't let a call keep the microphone in the background, so it ends.
        call.hangUp()
        awaySince = Date()
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
        // Sassy mode: a sassy line around the answer (the answer itself stays the same).
        let plain = reply.text
        var sass: Sass.Dressed?
        if Sass.isOn(settings.personality), !Sass.isSerious(text) {
            let category = Sass.category(kind: reply.kind, source: reply.source, mood: reply.mood, cards: reply.cards)
            let again = Sass.countsRepeats(category) && !text.isEmpty ? repeats.note(text) : 0
            let dressed = Sass.dress(plain, category: category, repeats: again,
                                     hour: Calendar.current.component(.hour, from: Date()), level: sassLevel)
            reply.text = dressed.text
            sass = dressed
        }
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
        case .idle, .sleeping:
            SoundFX.shared.play(.blink, gain: 0.6)
        default:
            SoundFX.shared.play(.success, gain: 0.55)
            Haptics.shared.play(.success)
        }
        let finalMood: OrbMood = reply.mood == .idle ? .talking : reply.mood
        // A goodbye: the orb dozes off once it's done talking.
        restAfterTalk = reply.mood == .sleeping
        // Saying bye on a call hangs up once Ace says bye back.
        if call.isLive, reply.kind == "goodbye" { call.endAfterSpeaking = true }
        if callJustStarted {
            // "Call Ace": the call screen takes over and says hello itself.
            callJustStarted = false
            restAfterTalk = false
            setMood(.happy, thenIdleAfter: 1.5)
            saveChat()
            return
        }
        if let sass, sass.eyes != .none {
            // Set before speaking, so the voice starting doesn't cut the eye-roll short.
            holdMood = true
            speak(plain, cards: reply.cards, sassBefore: sass.before, sassAfter: sass.after)
            Task { await sassyEyes(sass.eyes, then: finalMood) }
        } else {
            speak(plain, cards: reply.cards, sassBefore: sass?.before ?? "", sassAfter: sass?.after ?? "")
            setMood(finalMood, thenIdleAfter: finalMood == .sleeping ? Self.napLength : 2.2)
        }
        saveChat()
    }

    /// Reads a reply out loud. A translation in it is said in that language's accent.
    /// `force` says it even when spoken replies are off (the hello when the app opens has its own switch).
    /// In Sassy mode, `sassBefore` and `sassAfter` are the sassy lines, said with extra drama.
    func speak(_ text: String, cards: [AceCard] = [], force: Bool = false, sassBefore: String = "", sassAfter: String = "") {
        // A call that's still connecting says hello itself once it's ready.
        if call.phase == .connecting { return }
        // On a call, Ace always talks.
        guard force || settings.speakReplies || handsFree || call.isLive else { return }
        var parts = Phrasebook.spokenParts(text, cards: cards)
        if Sass.isOn(settings.personality) {
            // "*sigh*" is said as a sigh, and other *stage directions* aren't read out.
            parts = parts.map { $0.language == nil ? SpokenPart(text: Sass.spoken($0.text), language: nil) : $0 }
            let before = Sass.spoken(sassBefore)
            let after = Sass.spoken(sassAfter)
            // The sassy lines get more drama the higher the slider is.
            let drama = sassLevel.rawValue
            if !before.isEmpty { parts.insert(SpokenPart(text: before, language: nil, sassy: true, drama: drama), at: 0) }
            if !after.isEmpty { parts.append(SpokenPart(text: after, language: nil, sassy: true, drama: drama)) }
        }
        let onChange: (Bool) -> Void = { [weak self] speaking in
            guard let self else { return }
            VoiceIn.shared.aceSpeaking(speaking)
            guard !self.holdMood else { return }
            if speaking {
                self.setMood(.talking)
            } else if !self.busy {
                if self.restAfterTalk {
                    self.restAfterTalk = false
                    self.setMood(.sleeping, thenIdleAfter: Self.napLength)
                } else {
                    self.setMood(.idle)
                }
            }
        }
        if call.isLive {
            // On a call, Ace talks through the call (so you can talk over it), with captions.
            let caption = [sassBefore, text, sassAfter].filter { !$0.isEmpty }.joined(separator: " ")
            call.say(parts, caption: caption, onTalk: onChange)
            return
        }
        VoiceOut.shared.speak(parts, voiceID: settings.voiceID, onChange: onChange)
    }

    /// After a goodbye, the orb sleeps once it's done talking.
    private var restAfterTalk = false
    /// How long the orb naps after a goodbye before it wakes back up to idle.
    static let napLength: Double = 8

    /// The sass slider as a level.
    var sassLevel: SassLevel { SassLevel(setting: settings.sassLevel) }

    /// Sassy mode: a big eye-roll (the eyes swing down, across and up, and stay up there for a moment)
    /// or a long side-eye, then the orb goes on as usual. Smaller and quicker at Mild, biggest at Extra.
    private func sassyEyes(_ eyes: Sass.Eyes, then next: OrbMood) async {
        let drama = Sass.EyeDrama(level: sassLevel)
        holdMood = true
        setMood(.checking)
        withAnimation(.easeInOut(duration: 0.15)) { eyeOpen = drama.squint }
        try? await Task.sleep(nanoseconds: 220_000_000)
        switch eyes {
        case .roll:
            SoundFX.shared.play(.lookWhir, pan: -0.6, jitter: 0.05, gain: Float(0.45 * drama.size))
            for p in drama.rollPath {
                withAnimation(.easeInOut(duration: drama.step)) { look = p }
                try? await Task.sleep(nanoseconds: UInt64(drama.step * 1_000_000_000))
            }
            SoundFX.shared.play(.lookWhir, pan: 0.3, jitter: 0.05, gain: Float(0.35 * drama.size))
            // Hold the "ugh, really?" look.
            try? await Task.sleep(nanoseconds: UInt64(drama.hold * 1_000_000_000))
        case .side:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { look = CGPoint(x: 1.15 * drama.size, y: 0.1) }
            withAnimation(.easeInOut(duration: 0.2)) { eyeOpen = drama.squint - 0.17 }
            SoundFX.shared.play(.lookWhir, pan: 0.8, jitter: 0.05, gain: Float(0.45 * drama.size))
            try? await Task.sleep(nanoseconds: UInt64(drama.sideHold * 1_000_000_000))
            // A quick glance back, still unimpressed.
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { look = CGPoint(x: -0.2, y: 0.1) }
            try? await Task.sleep(nanoseconds: 300_000_000)
        case .none:
            break
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            look = .zero
            eyeOpen = 1
        }
        holdMood = false
        // A new question came in meanwhile: leave the orb to it.
        guard !busy else { return }
        setMood(VoiceOut.shared.isSpeaking ? .talking : next, thenIdleAfter: next == .sleeping ? Self.napLength : 2.2)
    }

    /// Settings changed Normal / Sassy: Ace says so, in character.
    func personalityChanged(to personality: String) {
        let on = Sass.isOn(personality)
        let line = SassPack.shared.line(on ? "sassy.on" : "sassy.off", level: sassLevel)
        guard !line.isEmpty else { return }
        messages.append(ChatMessage(speaker: .ace, text: line, source: "personality"))
        saveChat()
        if on {
            holdMood = true
            Task { await sassyEyes(sassLevel == .mild ? .side : .roll, then: .happy) }
        } else {
            setMood(.happy, thenIdleAfter: 1.5)
        }
    }

    /// The sass slider moved: Ace shows off the new level.
    func sassLevelChanged(to setting: String) {
        guard Sass.isOn(settings.personality) else { return }
        let level = SassLevel(setting: setting)
        let line = SassPack.shared.line("level." + level.setting, level: level)
        guard !line.isEmpty else { return }
        // Moving the slider back and forth replaces the last slider line instead of piling them up.
        if let last = messages.last, last.source == "sass level" { messages.removeLast() }
        messages.append(ChatMessage(speaker: .ace, text: line, source: "sass level"))
        saveChat()
        holdMood = true
        Task { await sassyEyes(level == .mild ? .side : .roll, then: .happy) }
    }

    /// Opens the Ace Games screen (from "open games"). It stays shut during a voice call,
    /// where the call screen covers everything and games are played by voice.
    func showGames() {
        guard !call.isLive else { return }
        gamesOpen = true
    }

    /// Opens Ace Piano. It stays shut during a voice call, where the call screen covers everything.
    func showPiano(_ start: PianoStart) -> Bool {
        guard !call.isLive else { return false }
        pianoScreen = PianoScreen(start: start)
        return true
    }

    /// A piano lesson was finished: Ace cheers in the chat, so you see it when the piano closes.
    func pianoLessonDone(_ song: PianoSong, stars: Int, newBest: Bool) {
        let starWords = stars == 1 ? "1 star" : "\(stars) stars"
        var line = "You played \(song.title) on the piano and got \(starWords)!"
        if newBest, stars < 3 {
            line += " That's your best yet. Go for 3 next time."
        } else if stars == 3 {
            line += " Perfect!"
        }
        messages.append(ChatMessage(speaker: .ace, text: line, source: "Ace Piano"))
        saveChat()
    }

    /// Opens the solar system map. It stays shut during a voice call, where the call screen covers everything.
    func showSpace(_ start: SpaceStart) -> Bool {
        guard !call.isLive else { return false }
        spaceScreen = SpaceScreen(start: start)
        return true
    }

    /// The What's new card: once after each update, or any time from Settings (`force`).
    func showWhatsNew(force: Bool) {
        let releases = WhatsNew.load()
        let build = WhatsNew.currentBuild
        let release = force ? (WhatsNew.release(forBuild: build, in: releases) ?? releases.first)
            : WhatsNew.due(currentBuild: build, lastShown: settings.lastWhatsNewBuild, releases: releases)
        guard let release else { return }
        // Busy answering something: it shows next time instead.
        if !force, busy { return }
        settings.lastWhatsNewBuild = max(settings.lastWhatsNewBuild, release.build)
        let shown = max(build, release.build)
        let card = WhatsNewCard(build: shown, date: release.date, items: release.items)
        messages.append(ChatMessage(speaker: .ace, text: WhatsNew.intro(build: shown, sassy: Sass.isOn(settings.personality), level: sassLevel),
                                    cards: [.whatsNew(card)], source: "what's new"))
        saveChat()
        SoundFX.shared.play(.success, gain: 0.5)
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
        if settings.moodSounds { SoundFX.shared.playMood(from: mood, to: m) }
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
        // Not in the middle of a call (a manual check said on the call is fine).
        guard !busy, !call.isLive || reason == .manual else { return }
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

    /// The hello when the app opens: the orb wakes up, the greeting sound plays, and Ace says hi
    /// (out loud too, unless that's off in Settings). `full` adds today's calendar and battery.
    private func greet(full: Bool) async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        // No hello over a call that's starting or going.
        guard !busy, call.phase == .off else { return }
        // The orb wakes up: the island stretches and the eyes pop out.
        SoundFX.shared.play(.orbWake, gain: 0.7)
        Haptics.shared.play(.wake)
        setMood(.checking)
        try? await Task.sleep(nanoseconds: 650_000_000)
        let hour = Calendar.current.component(.hour, from: Date())
        let part = Greeter.partOfDay(hour: hour)
        let name = settings.userName.isEmpty ? "" : ", \(settings.userName)"
        SoundFX.shared.play(.greeting, gain: 0.8)
        Haptics.shared.play(.success)
        setMood(.happy)
        let sassy = Sass.isOn(settings.personality)
        let sassyLines = sassy ? Sass.greetingLines(hour: hour, name: settings.userName, level: sassLevel) : []
        let options = sassyLines.isEmpty ? Greeter.lines(hour: hour, name: settings.userName) : sassyLines
        var lines = [options[VariantPicker.shared.pick("greeting.open", count: options.count)]]
        // Now and then, one of your favorites ("Up for some Minecraft today?").
        if let fav = Favorites.all(memory.facts.map(\.text)).reversed().first(where: { Favorites.greetingLine($0) != nil }),
           Double.random(in: 0..<1) < 0.35, Favorites.takeTurn(fav), let line = Favorites.greetingLine(fav) {
            lines.append(line)
        }
        let cal = CalendarService.shared
        var today: [EventItem] = []
        if full, cal.eventAccess {
            let c = Calendar.current
            let end = c.date(byAdding: .day, value: 1, to: c.startOfDay(for: Date()))!
            let events = cal.events(from: Date(), to: end, nimbusOnly: false).sorted { $0.start < $1.start }
            today = events
            lines.append(events.isEmpty ? "Your calendar is clear for the rest of today." :
                            "You have \(events.count) thing\(events.count == 1 ? "" : "s") today, starting with \(events[0].title).")
        }
        let card = GreetingCard(hello: "\(part)\(name)!", date: Date(), events: today, calendarAllowed: cal.eventAccess)
        if full, let level = SystemMonitor.shared.snapshot().batteryLevel, level < 0.25 {
            lines.append("Your battery is at \(Int(level * 100))%, so you may want to charge.")
        }
        messages.append(ChatMessage(speaker: .ace, text: lines.joined(separator: " "), cards: full ? [.greeting(card)] : [], source: "greeting"))
        saveChat()
        if settings.speakGreeting { speak(lines.joined(separator: " "), force: true) }
        if sassy {
            holdMood = true
            await sassyEyes(sassLevel == .mild ? .side : Bool.random() ? .roll : .side, then: .happy)
        } else {
            setMood(.happy, thenIdleAfter: 2.5)
        }
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

    func setPersonality(_ sassy: Bool) -> String {
        if Sass.isOn(settings.personality) == sassy {
            return sassy ? "Sassy mode is already on. Can't you tell?" : "Sassy mode is already off."
        }
        settings.personality = sassy ? "sassy" : "normal"
        let line = SassPack.shared.line(sassy ? "sassy.on" : "sassy.off", level: sassLevel)
        if sassy {
            holdMood = true
            Task { await sassyEyes(sassLevel == .mild ? .side : .roll, then: .happy) }
        }
        return line.isEmpty ? (sassy ? "Sassy mode is on." : "Sassy mode is off.") : line
    }

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

    func setCall(_ on: Bool) -> String {
        if on {
            if call.isLive { return Say.line(.callAlready) }
            callJustStarted = true
            startCall()
            return Say.line(.callStarting)
        }
        guard call.isLive else { return Say.line(.callNotOn) }
        call.endAfterSpeaking = true
        return Say.line(.callBye)
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
        // Homework in the picture: solve each problem step by step.
        if let ocr = report.text, let math = Self.photoMath(ocr, question: question) {
            note(math.cards.count == 1 ? "Found a math problem" : "Found \(math.cards.count) math problems")
            return BrainReply(text: math.text, thoughts: thoughts, cards: math.cards.map { AceCard.steps($0) } + [AceCard.image(report)],
                              source: "vision + Ace's homework helper")
        }
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

    /// Math problems in a photo's text, solved. Without a question that asks about math, only lines with an "="
    /// count, so a date or a page number isn't taken for a sum.
    static func photoMath(_ ocr: String, question: String) -> (text: String, cards: [StepsCard])? {
        let q = question.lowercased()
        let asksMath = Rx.matches(#"\b(math|maths|solve|homework|worksheet|answers?|equations?|sums?|problems?|fractions?|check my|work out)\b"#, q)
        guard q.isEmpty || asksMath else { return nil }
        let found = Homework.problems(inText: ocr, needEquals: !asksMath)
        let cards = found.compactMap { p in Homework.solve(p).map { StepsCard(problem: $0.problem, steps: $0.steps, answer: $0.answer) } }
        guard let first = cards.first else { return nil }
        if cards.count == 1 {
            return (Say.line(.photoMathOne, ["problem": first.problem, "answer": first.answer]), cards)
        }
        return (Say.line(.photoMathMany, ["count": "\(cards.count)"]), cards)
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

    /// Opens the Flashcards screen, or a study session. During a voice call the call screen
    /// covers everything, so nothing opens then (the reply's card still has the buttons).
    func showFlashcards(deckID: UUID?, study: Bool, practice: Bool) {
        guard !call.isLive else { return }
        if study {
            let target = StudyTarget(deckID: deckID, practice: practice)
            guard flashcardsOpen else { studyTarget = target; return }
            // Let the Flashcards sheet slide away first, so the study screen can open.
            flashcardsOpen = false
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(600))
                self?.studyTarget = target
            }
        } else {
            studyTarget = nil
            flashcardsDeck = deckID
            flashcardsOpen = true
        }
    }
}

// MARK: Voice calls

extension AceCore: CallHost {
    /// Starts a voice call (the phone button, "call Ace", Siri or ace://call).
    func startCall() {
        guard !call.isLive else { return }
        noteInteraction()
        holdDown = false
        if VoiceIn.shared.state == .holding { Task { _ = await VoiceIn.shared.endHold() } }
        SoundFX.shared.play(.orbWake, gain: 0.7)
        Haptics.shared.play(.pop)
        call.start()
    }

    func callHeard(_ text: String) {
        send(text)
    }

    func callLine(_ moment: CallController.Moment) -> String {
        let name = settings.userName
        switch moment {
        case .hello: return Say.line(.callHello, ["who": name.isEmpty ? "" : ", \(name)"])
        case .stillThere: return Say.line(.callStillThere)
        case .quietHangUp: return Say.line(.callQuietBye)
        }
    }

    var callVoiceID: String { settings.voiceID }

    func callTalking(_ talking: Bool) {
        guard !holdMood else { return }
        if talking {
            setMood(.talking)
        } else if !busy {
            setMood(.idle)
        }
    }

    func callPhaseChanged(_ phase: CallLogic.Phase) {
        switch phase {
        case .hearing:
            noteInteraction()
            if !holdMood { setMood(.listening) }
            statusLine = "Listening"
        case .listening, .ended, .off:
            if mood == .listening && !busy { setMood(.idle) }
            if !busy { statusLine = "Ready" }
        case .connecting:
            statusLine = "Calling"
        case .thinking, .speaking:
            break
        }
    }

    func callEnded(length: TimeInterval?, failed: Bool) {
        callJustStarted = false
        if failed {
            messages.append(ChatMessage(speaker: .ace, text: Say.line(.voiceNoPermission), source: "voice"))
            saveChat()
            setMood(.alert, thenIdleAfter: 2.5)
            return
        }
        guard let length else { return }
        messages.append(ChatMessage(speaker: .ace, text: "Call ended after \(CallLogic.lengthInWords(length)).", source: "call"))
        saveChat()
        if !busy { setMood(.idle) }
    }
}
