import AVFoundation
import Speech

/// The sound side of a voice call with Ace: one audio engine that listens and talks at the same time.
///
/// The microphone runs the iPad's voice processing (the echo cancelling FaceTime uses), and Ace's voice
/// is played through that same engine, so the iPad can take Ace's voice back out of what the microphone
/// hears. That's what lets you talk over Ace. Speech is turned into text on the iPad when it can be.
@MainActor
final class CallAudio {
    static let shared = CallAudio()

    /// What was heard so far in this stretch of listening, and true when the recognizer stopped
    /// (you went quiet for a long time, an error, or its time limit).
    var onWords: ((String, Bool) -> Void)?
    /// How loud you are, 0...1.
    var onLevel: ((Double) -> Void)?
    /// Something else took the audio (a phone or FaceTime call): the call has to end.
    var onInterrupted: (() -> Void)?
    /// Headphones came or went, and the engine started again.
    var onRouteChange: (() -> Void)?

    private(set) var running = false
    /// When the current stretch of listening started (speech recognition stops itself after about a minute).
    private(set) var listeningSince = Date()
    private(set) var echoCancelling = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var attached = false
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let feed = CallMicFeed()
    private var listenGen = 0

    private let synth = AVSpeechSynthesizer()
    /// Ace's voice is turned into this one format, so lines in other voices (a translation) play back to back.
    private let speechFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44_100, channels: 1, interleaved: false)!
    private var converter: AVAudioConverter?
    private var speechGen = 0
    private var lines: [AVSpeechUtterance] = []
    private var playing = 0
    private var writing = false
    private var onSpoken: (() -> Void)?
    private var watchdog: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    private init() {}

    // MARK: Start and stop

    /// Asks for the microphone and speech recognition, then starts the engine. False if Ace can't listen.
    func start() async -> Bool {
        guard await VoiceIn.shared.allowed(), recognizer?.isAvailable == true else { return false }
        guard !running else { return true }
        AudioRouter.shared.prepareForCall()
        guard startEngine() else {
            AudioRouter.shared.endCall()
            return false
        }
        running = true
        watchAudio()
        return true
    }

    private func startEngine() -> Bool {
        let input = engine.inputNode
        // Echo cancelling. If the iPad can't do it, Ace still filters its own words out by what it's saying.
        do {
            try input.setVoiceProcessingEnabled(true)
            echoCancelling = true
        } catch {
            echoCancelling = false
        }
        if !attached {
            engine.attach(player)
            attached = true
        }
        engine.connect(player, to: engine.mainMixerNode, format: speechFormat)
        engine.mainMixerNode.outputVolume = 1
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return false }
        input.removeTap(onBus: 0)
        Self.tap(input, format: format, into: feed)
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            return false
        }
        player.play()
        return true
    }

    /// Hangs up: stops listening, talking and the engine, and gives the audio back.
    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
        stopSpeaking()
        stopListening()
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        if engine.isRunning { engine.stop() }
        if echoCancelling { try? engine.inputNode.setVoiceProcessingEnabled(false) }
        echoCancelling = false
        feed.muted = false
        running = false
        AudioRouter.shared.endCall()
    }

    /// Mutes or unmutes the microphone. Ace still talks while you're muted.
    func setMuted(_ muted: Bool) {
        feed.muted = muted
        if echoCancelling { engine.inputNode.isVoiceProcessingInputMuted = muted }
        if muted { onLevel?(0) }
    }

    func setSpeaker(_ on: Bool) {
        AudioRouter.shared.callSpeaker(on)
    }

    /// Phone calls and headphones change the audio under Ace.
    private func watchAudio() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            let began = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue
            guard began else { return }
            MainActor.assumeIsolated { CallAudio.shared.interrupted() }
        })
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
            MainActor.assumeIsolated { CallAudio.shared.configurationChanged() }
        })
    }

    private func interrupted() {
        guard running else { return }
        onInterrupted?()
    }

    private func configurationChanged() {
        // Only when the change stopped the engine (it keeps going for small changes).
        guard running, !engine.isRunning else { return }
        // The engine stopped itself. Start it again with the new microphone or headphones.
        stopSpeaking()
        stopListening()
        player.stop()
        engine.inputNode.removeTap(onBus: 0)
        if engine.isRunning { engine.stop() }
        AudioRouter.shared.prepareForCall()
        if startEngine() {
            onRouteChange?()
        } else {
            onInterrupted?()
        }
    }

    // MARK: Listening

    /// Starts a fresh stretch of listening (what was heard before is dropped).
    func listen() {
        stopListening()
        guard running, let recognizer, recognizer.isAvailable else { return }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        req.addsPunctuation = true
        request = req
        feed.request = req
        listenGen += 1
        listeningSince = Date()
        task = Self.recognize(recognizer, req, gen: listenGen)
    }

    /// Stops turning speech into text (the microphone stays on for the call).
    func stopListening() {
        listenGen += 1
        feed.request = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
    }

    /// Sends the microphone's sound to speech recognition (runs on the audio thread).
    nonisolated private static func tap(_ input: AVAudioInputNode, format: AVAudioFormat, into feed: CallMicFeed) {
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            guard feed.append(buffer) else { return }
            let level = loudness(buffer)
            DispatchQueue.main.async {
                MainActor.assumeIsolated { CallAudio.shared.heardLevel(level) }
            }
        }
    }

    private func heardLevel(_ level: Double) {
        guard running else { return }
        onLevel?(level)
    }

    nonisolated private static func recognize(_ recognizer: SFSpeechRecognizer, _ req: SFSpeechAudioBufferRecognitionRequest, gen: Int) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: req) { result, error in
            let text = result?.bestTranscription.formattedString ?? ""
            let ended = (result?.isFinal ?? false) || error != nil
            DispatchQueue.main.async {
                MainActor.assumeIsolated { CallAudio.shared.recognized(text, ended: ended, gen: gen) }
            }
        }
    }

    private func recognized(_ text: String, ended: Bool, gen: Int) {
        guard running, gen == listenGen else { return }
        if ended {
            // This stretch is over; a new one starts when the call asks for it.
            task = nil
            request = nil
            feed.request = nil
            listenGen += 1
        }
        onWords?(text, ended)
    }

    nonisolated private static func loudness(_ buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in stride(from: 0, to: n, by: 4) { sum += data[i] * data[i] }
        let rms = sqrt(sum / Float(max(1, n / 4)))
        return Double(min(1, rms * 12))
    }

    // MARK: Talking

    var isSpeaking: Bool { onSpoken != nil }

    /// Says the lines one after another through the call, then calls `done`.
    /// `done` isn't called when the lines are cut off by `stopSpeaking()` or a new `speak`.
    func speak(_ utterances: [AVSpeechUtterance], done: @escaping () -> Void) {
        stopSpeaking()
        guard running, !utterances.isEmpty else { done(); return }
        speechGen += 1
        lines = utterances
        playing = 0
        writing = true
        onSpoken = done
        if engine.isRunning, !player.isPlaying { player.play() }
        writeNext()
    }

    /// Cuts Ace off right away (you talked over it, or the call ended).
    func stopSpeaking() {
        speechGen += 1
        watchdog?.cancel()
        watchdog = nil
        onSpoken = nil
        lines = []
        playing = 0
        writing = false
        converter = nil
        synth.stopSpeaking(at: .immediate)
        player.stop()
        if running, engine.isRunning { player.play() }
    }

    private func writeNext() {
        guard !lines.isEmpty else {
            writing = false
            finishIfDone()
            return
        }
        let line = lines.removeFirst()
        let gen = speechGen
        converter = nil
        keepAlive(gen)
        synth.write(line) { buffer in
            guard let pcm = buffer as? AVAudioPCMBuffer else { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated { CallAudio.shared.gotSpeech(pcm, gen: gen) }
            }
        }
    }

    private func gotSpeech(_ pcm: AVAudioPCMBuffer, gen: Int) {
        guard gen == speechGen, writing else { return }
        keepAlive(gen)
        // An empty buffer means this line is done.
        guard pcm.frameLength > 0 else {
            writeNext()
            return
        }
        guard engine.isRunning, let out = convert(pcm) else { return }
        playing += 1
        player.scheduleBuffer(out, completionCallbackType: .dataPlayedBack) { _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { CallAudio.shared.played(gen: gen) }
            }
        }
    }

    private func played(gen: Int) {
        guard gen == speechGen else { return }
        playing = max(0, playing - 1)
        finishIfDone()
    }

    private func finishIfDone() {
        guard !writing, playing == 0, let done = onSpoken else { return }
        onSpoken = nil
        watchdog?.cancel()
        watchdog = nil
        done()
    }

    /// If the voice stops sending sound without saying it's done, Ace moves on after a few seconds.
    private func keepAlive(_ gen: Int) {
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard let self, !Task.isCancelled, gen == self.speechGen, self.writing else { return }
            self.lines = []
            self.writing = false
            self.finishIfDone()
        }
    }

    /// Turns one piece of the voice into the engine's format.
    private func convert(_ input: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if converter == nil || converter?.inputFormat != input.format {
            converter = AVAudioConverter(from: input.format, to: speechFormat)
        }
        guard let converter, input.format.sampleRate > 0 else { return nil }
        let ratio = speechFormat.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount(Double(input.frameLength) * ratio + 64)
        guard let out = AVAudioPCMBuffer(pcmFormat: speechFormat, frameCapacity: capacity) else { return nil }
        let once = GivenOnce()
        var error: NSError?
        let status = converter.convert(to: out, error: &error) { _, inputStatus in
            if once.given {
                inputStatus.pointee = .noDataNow
                return nil
            }
            once.given = true
            inputStatus.pointee = .haveData
            return input
        }
        guard status != .error, out.frameLength > 0 else { return nil }
        return out
    }
}

/// Hands the microphone's sound to the current speech request. The audio thread and the app both use it,
/// so a lock keeps them from getting in each other's way.
final class CallMicFeed: @unchecked Sendable {
    private let lock = NSLock()
    private var _request: SFSpeechAudioBufferRecognitionRequest?
    private var _muted = false

    var request: SFSpeechAudioBufferRecognitionRequest? {
        get { lock.withLock { _request } }
        set { lock.withLock { _request = newValue } }
    }

    var muted: Bool {
        get { lock.withLock { _muted } }
        set { lock.withLock { _muted = newValue } }
    }

    /// Passes the sound on. False when muted (nothing is passed on).
    func append(_ buffer: AVAudioPCMBuffer) -> Bool {
        lock.lock()
        let muted = _muted
        let req = muted ? nil : _request
        lock.unlock()
        req?.append(buffer)
        return !muted
    }
}

/// Lets the converter hand over each piece of Ace's voice only once.
private final class GivenOnce: @unchecked Sendable {
    var given = false
}
