import AVFoundation
import SwiftUI
import UIKit

/// What the call needs from the rest of Ace: its brain, its voice and its words.
@MainActor
protocol CallHost: AnyObject {
    /// You finished saying something: Ace's brain answers it (and the answer comes back through `say`).
    func callHeard(_ text: String)
    /// What Ace says when the call connects, when nobody has talked for a while, and when it hangs up for that.
    func callLine(_ moment: CallController.Moment) -> String
    /// The voice from Settings.
    var callVoiceID: String { get }
    /// Ace started (true) or stopped (false) talking on the call, so the orb can show it.
    func callTalking(_ talking: Bool)
    /// The call screen changed what it shows (listening, hearing you...), so the orb can follow.
    func callPhaseChanged(_ phase: CallLogic.Phase)
    /// The call ended. `length` is nil when it never connected. `failed` is true when Ace couldn't start it.
    func callEnded(length: TimeInterval?, failed: Bool)
}

/// A voice call with Ace: you talk, Ace answers out loud, back and forth, until someone hangs up.
/// It uses Ace's real brain (the same one as the chat), so everything said also lands in the chat.
@MainActor
final class CallController: ObservableObject {
    enum Moment { case hello, stillThere, quietHangUp }

    @Published private(set) var phase: CallLogic.Phase = .off
    @Published private(set) var startedAt: Date?
    @Published private(set) var endedAt: Date?
    @Published private(set) var muted = false
    @Published private(set) var speakerOn = true
    /// The finished lines of this call.
    @Published private(set) var lines: [CallLogic.Caption] = []
    /// What you're saying right now, while you say it.
    @Published private(set) var live = ""
    /// How loud you are, 0...1.
    @Published private(set) var level: Double = 0

    /// Ace hangs up once it finishes what it's saying (you said bye, or "hang up").
    var endAfterSpeaking = false

    weak var host: CallHost?

    var isLive: Bool { phase.isLive }
    var captions: [CallLogic.Caption] { CallLogic.captions(lines, live: live) }

    private let audio = CallAudio.shared
    private var silenceTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var offTask: Task<Void, Never>?
    private var lastActivity = Date()
    private var nudged = false
    /// What Ace was saying when you talked over it, so its echo can be taken out of your words.
    private var bargeText: String?
    /// What Ace is saying right now.
    private var aceSaying = ""
    private var onTalk: ((Bool) -> Void)?
    /// Headphones were in, the last time the call looked.
    private var headphones = false

    init() {
        audio.onWords = { [weak self] text, ended in self?.heard(text, ended: ended) }
        audio.onLevel = { [weak self] level in
            // Small changes don't redraw the screen.
            guard let self, !self.muted, abs(level - self.level) > 0.03 || (level == 0) != (self.level == 0) else { return }
            self.level = level
        }
        audio.onInterrupted = { [weak self] in self?.hangUp() }
        audio.onRouteChange = { [weak self] in self?.routeChanged() }
    }

    // MARK: Starting and ending

    /// Starts a call. Does nothing if one is already going.
    func start() {
        guard phase == .off || phase == .ended else { return }
        offTask?.cancel()
        lines = []
        live = ""
        level = 0
        muted = false
        speakerOn = true
        endAfterSpeaking = false
        nudged = false
        bargeText = nil
        startedAt = nil
        endedAt = nil
        setPhase(.connecting)
        // Ace's other ways of listening and talking step aside for the call.
        VoiceOut.shared.stop()
        VoiceIn.shared.callStarted(true)
        UIApplication.shared.isIdleTimerDisabled = true
        Task {
            let ok = await audio.start()
            guard phase == .connecting else {
                // You hung up while it was connecting.
                if ok { audio.stop() }
                VoiceIn.shared.callStarted(false)
                return
            }
            guard ok else {
                failed()
                return
            }
            startedAt = Date()
            lastActivity = Date()
            // The loudspeaker, unless headphones are in (like a phone call on speaker).
            headphones = AudioRouter.shared.callHasHeadphones
            speakerOn = !headphones
            audio.setSpeaker(speakerOn)
            setPhase(.listening)
            startTicker()
            let hello = host?.callLine(.hello) ?? "Hi!"
            say([SpokenPart(text: hello, language: nil)], caption: hello)
        }
    }

    /// The red button: ends the call right away.
    func hangUp() {
        guard phase.isLive else { return }
        finish()
    }

    private func failed() {
        tickTask?.cancel()
        VoiceIn.shared.callStarted(false)
        UIApplication.shared.isIdleTimerDisabled = false
        setPhase(.off)
        host?.callEnded(length: nil, failed: true)
    }

    private func finish() {
        let began = startedAt
        silenceTask?.cancel()
        tickTask?.cancel()
        // Cut off mid-sentence: the orb stops talking too.
        if phase == .speaking, !aceSaying.isEmpty { stoppedTalking() }
        onTalk = nil
        audio.stop()
        // After the call's audio is off, so "Hey Ace" gets the microphone back.
        VoiceIn.shared.callStarted(false)
        UIApplication.shared.isIdleTimerDisabled = false
        live = ""
        level = 0
        aceSaying = ""
        bargeText = nil
        endAfterSpeaking = false
        endedAt = Date()
        setPhase(.ended)
        SoundFX.shared.play(.sleepWhoosh, gain: 0.6)
        Haptics.shared.play(.tick)
        host?.callEnded(length: began.map { Date().timeIntervalSince($0) }, failed: false)
        // "Call ended" shows for a moment, then the call screen goes away.
        offTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            guard let self, !Task.isCancelled, self.phase == .ended else { return }
            self.setPhase(.off)
        }
    }

    /// Closes the "Call ended" screen now.
    func dismissEnded() {
        guard phase == .ended else { return }
        offTask?.cancel()
        setPhase(.off)
    }

    // MARK: Buttons

    func toggleMute() {
        guard phase.isLive else { return }
        muted.toggle()
        audio.setMuted(muted)
        if muted { level = 0 }
        Haptics.shared.play(.tick)
    }

    func toggleSpeaker() {
        guard phase.isLive else { return }
        speakerOn.toggle()
        audio.setSpeaker(speakerOn)
        Haptics.shared.play(.tick)
    }

    /// Stops Ace mid-sentence (tap the orb while it talks) so you can talk.
    func interrupt() {
        guard phase == .speaking else { return }
        audio.stopSpeaking()
        endAfterSpeaking = false
        stoppedTalking()
        lastActivity = Date()
        setPhase(.listening)
        audio.listen()
        Haptics.shared.play(.tick)
    }

    // MARK: Ace talking

    /// Says something on the call. `caption` is what the captions show (the words as written).
    /// `onTalk` hears true when Ace starts and false when it's done or cut off.
    func say(_ parts: [SpokenPart], caption: String, onTalk: ((Bool) -> Void)? = nil) {
        guard phase.isLive, phase != .connecting else { return }
        silenceTask?.cancel()
        live = ""
        bargeText = nil
        let shown = CallLogic.captionText(caption)
        if !shown.isEmpty {
            lines.append(CallLogic.Caption(who: .ace, text: shown))
            if lines.count > 60 { lines.removeFirst(lines.count - 60) }
        }
        // A line that was still going is cut off by this one.
        if phase == .speaking { audio.stopSpeaking(); stoppedTalking() }
        self.onTalk = onTalk
        let utterances = VoiceOut.utterances(parts, voiceID: host?.callVoiceID ?? "")
        aceSaying = parts.map(\.text).joined(separator: " ")
        guard !utterances.isEmpty else {
            doneSpeaking()
            return
        }
        setPhase(.speaking)
        if let onTalk { onTalk(true) } else { host?.callTalking(true) }
        // Keep listening while Ace talks, so you can talk over it.
        audio.listen()
        audio.speak(utterances) { [weak self] in self?.doneSpeaking() }
    }

    /// The orb stops showing talking (the reply's own hook does it for a reply, the call does it otherwise).
    private func stoppedTalking() {
        if let talk = onTalk { talk(false) } else { host?.callTalking(false) }
        onTalk = nil
        aceSaying = ""
    }

    private func doneSpeaking() {
        guard phase.isLive else { return }
        stoppedTalking()
        if endAfterSpeaking {
            finish()
            return
        }
        lastActivity = Date()
        setPhase(.listening)
        // A fresh start, so Ace's own voice isn't taken for your words.
        audio.listen()
    }

    // MARK: You talking

    private func heard(_ text: String, ended: Bool) {
        switch phase {
        case .speaking:
            if !muted, CallLogic.shouldInterrupt(heard: text, aceSaying: aceSaying) {
                // You talked over Ace: it stops and listens.
                bargeText = aceSaying
                audio.stopSpeaking()
                endAfterSpeaking = false
                stoppedTalking()
                setPhase(.hearing)
                update(text)
                if ended { finishUtterance() }
            } else if ended {
                // Listening stopped by itself while Ace talks: start again, so you can still cut in.
                audio.listen()
            }
        case .listening, .hearing:
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if phase != .hearing { setPhase(.hearing) }
                update(text)
            }
            if ended { finishUtterance() }
        default:
            // Connecting, thinking or ended: nothing to hear.
            break
        }
    }

    private func update(_ text: String) {
        let mine = bargeText.map { CallLogic.userPart(heard: text, aceSaying: $0) }
            ?? text.trimmingCharacters(in: .whitespacesAndNewlines)
        live = mine
        lastActivity = Date()
        nudged = false
        waitForSilence()
    }

    /// A pause of about 1.3 seconds means you've finished talking.
    private func waitForSilence() {
        silenceTask?.cancel()
        silenceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            guard let self, !Task.isCancelled, self.phase == .hearing else { return }
            self.finishUtterance()
        }
    }

    private func finishUtterance() {
        silenceTask?.cancel()
        let text = live.trimmingCharacters(in: .whitespacesAndNewlines)
        live = ""
        bargeText = nil
        guard !text.isEmpty else {
            // Nothing (or only Ace's own echo): keep listening.
            if phase.isLive {
                setPhase(.listening)
                audio.listen()
            }
            return
        }
        audio.stopListening()
        lines.append(CallLogic.Caption(who: .you, text: text))
        if lines.count > 60 { lines.removeFirst(lines.count - 60) }
        setPhase(.thinking)
        host?.callHeard(text)
    }

    // MARK: Quiet calls and the timer

    private func startTicker() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard phase == .listening, !muted else {
            // Only quiet listening counts toward "still there?".
            if phase.isLive { lastActivity = Date() }
            return
        }
        let quiet = Date().timeIntervalSince(lastActivity)
        switch CallLogic.idleStep(silentFor: quiet, nudged: nudged) {
        case .wait:
            // Speech recognition stops itself after about a minute, so start fresh before then.
            if Date().timeIntervalSince(audio.listeningSince) > 50 { audio.listen() }
        case .nudge:
            nudged = true
            let line = host?.callLine(.stillThere) ?? "Still there?"
            say([SpokenPart(text: line, language: nil)], caption: line)
        case .hangUp:
            endAfterSpeaking = true
            let line = host?.callLine(.quietHangUp) ?? "Okay, bye!"
            say([SpokenPart(text: line, language: nil)], caption: line)
        }
    }

    private func routeChanged() {
        guard phase.isLive else { return }
        switch phase {
        case .speaking:
            // Ace's voice was cut off by the change: carry on listening.
            doneSpeaking()
        case .listening, .hearing:
            if phase == .hearing { finishUtterance() } else { audio.listen() }
        default:
            break
        }
        // Headphones went in or came out: follow them, like a phone does.
        let now = AudioRouter.shared.callHasHeadphones
        if now != headphones {
            headphones = now
            speakerOn = !now
            audio.setSpeaker(speakerOn)
        }
    }

    private func setPhase(_ p: CallLogic.Phase) {
        guard phase != p else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = p }
        host?.callPhaseChanged(p)
    }
}
