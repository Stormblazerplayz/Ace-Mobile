import AVFoundation
import Speech

/// Ace's ears. Hold the orb to talk, or say "Hey Ace" while the app is open (hands-free).
/// Speech is turned into text on the iPad when it can be (no internet needed on newer iPads).
@MainActor
final class VoiceIn: ObservableObject {
    static let shared = VoiceIn()

    enum State: Equatable { case off, holding, waitingForWakeWord, hearingCommand }

    @Published private(set) var state: State = .off
    /// What Ace has heard so far (shown under the orb while you talk).
    @Published private(set) var heard = ""
    /// How loud you are, 0...1 (makes the orb's rings bigger).
    @Published private(set) var level: Double = 0

    /// Called with what you said, once you finish.
    var onCommand: ((String) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var handsFree = false
    private var silenceTask: Task<Void, Never>?
    private var restartTask: Task<Void, Never>?
    private var commandStart: Int?
    private var lastText = ""
    private var paused = false
    /// A voice call has the microphone, so hold-to-talk and "Hey Ace" wait until it ends.
    private var inCall = false

    private init() {}

    var isHandsFree: Bool { handsFree }

    // MARK: Permission

    /// Asks for the microphone and speech recognition. True when both are allowed.
    func allowed() async -> Bool {
        let speech: Bool = await withCheckedContinuation { cont in
            let now = SFSpeechRecognizer.authorizationStatus()
            if now == .authorized { cont.resume(returning: true); return }
            if now != .notDetermined { cont.resume(returning: false); return }
            SFSpeechRecognizer.requestAuthorization { status in cont.resume(returning: status == .authorized) }
        }
        guard speech else { return false }
        return await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { ok in cont.resume(returning: ok) }
        }
    }

    // MARK: Hold to talk

    /// Starts listening while you hold the orb. False if Ace can't listen.
    func startHold() async -> Bool {
        guard !inCall, await allowed(), recognizer?.isAvailable == true, !inCall else { return false }
        VoiceOut.shared.stop()
        stopRecognition()
        heard = ""
        state = .holding
        guard begin() else { state = handsFree ? .waitingForWakeWord : .off; return false }
        return true
    }

    /// You let go of the orb: waits a moment for the last words, then gives back what you said.
    func endHold() async -> String {
        guard state == .holding else { return "" }
        request?.endAudio()
        // The last words can take a moment to come in.
        for _ in 0..<8 {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        let text = heard.trimmingCharacters(in: .whitespacesAndNewlines)
        stopRecognition()
        heard = ""
        state = .off
        if handsFree { startWakeWord() } else { AudioRouter.shared.backToEffects() }
        return text
    }

    // MARK: Hands-free ("Hey Ace")

    /// Turns "Hey Ace" listening on or off. Only works while the app is open.
    func setHandsFree(_ on: Bool) async -> Bool {
        if on {
            guard await allowed(), recognizer?.isAvailable == true else { return false }
            handsFree = true
            startWakeWord()   // waits until a call ends, if one is going
            return true
        }
        handsFree = false
        stopRecognition()
        state = .off
        heard = ""
        AudioRouter.shared.backToEffects()
        return true
    }

    /// Stops listening while the app is in the background, and picks up again when it's back.
    func appActive(_ active: Bool) {
        guard handsFree, !inCall else { return }
        if active {
            startWakeWord()
        } else {
            stopRecognition()
            state = .off
        }
    }

    /// Ace stops listening while it talks, so it doesn't hear itself.
    func aceSpeaking(_ speaking: Bool) {
        guard handsFree, !inCall, state != .holding else { return }
        paused = speaking
        if speaking {
            stopRecognition()
        } else {
            restartTask?.cancel()
            restartTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard let self, !Task.isCancelled, self.handsFree, !self.paused else { return }
                self.startWakeWord()
            }
        }
    }

    /// A voice call started (true) or ended (false). During a call the call has the microphone.
    func callStarted(_ on: Bool) {
        inCall = on
        restartTask?.cancel()
        if on {
            stopRecognition()
            heard = ""
            lastText = ""
            commandStart = nil
            paused = false
            state = .off
        } else if handsFree {
            paused = false
            startWakeWord()
        }
    }

    private func startWakeWord() {
        guard handsFree, !paused, !inCall else { return }
        stopRecognition()
        heard = ""
        commandStart = nil
        state = .waitingForWakeWord
        guard begin() else { state = .off; return }
        // Apple stops recognition after about a minute, so start fresh before then.
        restartTask?.cancel()
        restartTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 50_000_000_000)
            guard let self, !Task.isCancelled, self.handsFree, self.state == .waitingForWakeWord else { return }
            self.startWakeWord()
        }
    }

    /// Finds "hey ace" (and the ways speech recognition likes to spell it) in what was heard.
    /// Gives back where your command starts, right after the wake word.
    nonisolated static func wakeWordEnd(in text: String) -> String.Index? {
        let lower = text.lowercased()
        let forms = ["hey ace", "hey, ace", "hey ase", "hey a's", "hey ice", "hay ace", "hey asse", "hey eighth"]
        var best: Range<String.Index>?
        for f in forms {
            if let r = lower.range(of: f, options: .backwards), best == nil || r.upperBound > best!.upperBound { best = r }
        }
        guard let best else { return nil }
        // The wake word has to be its own words ("hey aces" doesn't count, "hey ace," does).
        if best.upperBound < lower.endIndex, lower[best.upperBound].isLetter { return nil }
        let offset = lower.distance(from: lower.startIndex, to: best.upperBound)
        return text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
    }

    /// The command after the wake word, without commas or spaces at the start.
    nonisolated static func command(after text: String, from index: String.Index) -> String {
        String(text[index...]).trimmingCharacters(in: CharacterSet(charactersIn: " ,.!?").union(.whitespaces))
    }

    // MARK: Recognition

    private func begin() -> Bool {
        guard let recognizer, recognizer.isAvailable else { return false }
        AudioRouter.shared.prepareForListening()
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        req.addsPunctuation = false
        request = req

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return false }
        input.removeTap(onBus: 0)
        Self.tap(input, format: format, into: req)
        engine.prepare()
        do { try engine.start() } catch { input.removeTap(onBus: 0); return false }
        task = Self.recognize(recognizer, req)
        return true
    }

    /// Sends the microphone's sound to speech recognition (runs on the audio thread).
    nonisolated private static func tap(_ input: AVAudioInputNode, format: AVAudioFormat, into req: SFSpeechAudioBufferRecognitionRequest) {
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)
            let level = loudness(buffer)
            Task { @MainActor in VoiceIn.shared.level = level }
        }
    }

    nonisolated private static func recognize(_ recognizer: SFSpeechRecognizer, _ req: SFSpeechAudioBufferRecognitionRequest) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: req) { result, error in
            let text = result?.bestTranscription.formattedString
            let final = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor in VoiceIn.shared.got(text, final: final, failed: failed) }
        }
    }

    private func stopRecognition() {
        silenceTask?.cancel()
        restartTask?.cancel()
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        level = 0
    }

    private func got(_ text: String?, final: Bool, failed: Bool) {
        switch state {
        case .holding:
            if let text { heard = text }
        case .waitingForWakeWord, .hearingCommand:
            if let text, text != lastText {
                lastText = text
                let wake = Self.wakeWordEnd(in: text)
                if state == .waitingForWakeWord, wake == nil, CallLogic.saysCallAce(text) {
                    // "Call Ace" on its own starts a voice call, no "Hey Ace" needed.
                    SoundFX.shared.play(.orbWake, gain: 0.7)
                    Haptics.shared.play(.pop)
                    stopRecognition()
                    heard = ""
                    lastText = ""
                    state = .off
                    // The call takes the microphone now. If it can't start, "Hey Ace" listening comes back then.
                    onCommand?("call Ace")
                    return
                }
                if state == .waitingForWakeWord, let wake {
                    commandStart = text.distance(from: text.startIndex, to: wake)
                    state = .hearingCommand
                    SoundFX.shared.play(.orbWake, gain: 0.7)
                    Haptics.shared.play(.pop)
                }
                if state == .hearingCommand, let offset = commandStart {
                    // Speech recognition rewrites earlier words as it goes, so look for the wake word again.
                    let start = wake ?? text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
                    heard = Self.command(after: text, from: start)
                    waitForSilence()
                }
            }
            if failed || final {
                // Recognition ended (silence, an error or the time limit). Finish a command if there was one.
                if state == .hearingCommand { finishCommand() } else if handsFree && !paused { startWakeWord() }
            }
        case .off:
            break
        }
    }

    /// A pause of about 1.3 seconds means you've finished talking
    /// (4 seconds right after "Hey Ace", to give you time to start).
    private func waitForSilence() {
        silenceTask?.cancel()
        let wait: UInt64 = heard.isEmpty ? 4_000_000_000 : 1_300_000_000
        silenceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: wait)
            guard let self, !Task.isCancelled, self.state == .hearingCommand else { return }
            self.finishCommand()
        }
    }

    private func finishCommand() {
        let text = heard.trimmingCharacters(in: .whitespacesAndNewlines)
        stopRecognition()
        heard = ""
        lastText = ""
        commandStart = nil
        state = .off
        if !text.isEmpty { onCommand?(text) }
        if handsFree && !paused { startWakeWord() }
    }

    nonisolated private static func loudness(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in stride(from: 0, to: n, by: 4) { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(max(1, n / 4)))
        return Double(min(1, rms * 12))
    }
}
