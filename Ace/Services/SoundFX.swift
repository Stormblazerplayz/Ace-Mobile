import AVFoundation
import Foundation

/// Ace's sound effects. File names match Ace/Resources/Sounds/*.wav.
enum Sfx: String, CaseIterable {
    case orbWake = "orb_wake"
    case eyesPop = "eyes_pop"
    case blink
    case lookWhir = "look_whir"
    case thinkLoop = "think_loop"
    case success
    case alert
    case listenStart = "listen_start"
    case listenStop = "listen_stop"
    case typeTick = "type_tick"
    case greeting
    case sleepWhoosh = "sleep_whoosh"
    case send
}

/// Plays the sound set through one audio engine, with stereo pan (so a glance left
/// sounds left), a little random pitch so repeats never sound robotic, and fades.
/// It uses the "ambient" audio session, so the silent switch mutes it.
@MainActor
final class SoundFX {
    static let shared = SoundFX()

    private final class Voice {
        let player = AVAudioPlayerNode()
        let speed = AVAudioUnitVarispeed()
        let mixer = AVAudioMixerNode()
        var busyUntil = Date.distantPast
    }

    private let engine = AVAudioEngine()
    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private var voices: [Voice] = []
    private let loopVoice = Voice()
    private var loopFadeTask: Task<Void, Never>?
    private var started = false
    private var format: AVAudioFormat?

    var enabled = true
    var volume: Float = 0.8 {
        didSet { engine.mainMixerNode.outputVolume = volume }
    }

    private init() {
        loadBuffers()
        guard let format else { return }
        for _ in 0..<6 {
            let v = Voice()
            attach(v, format: format)
            voices.append(v)
        }
        attach(loopVoice, format: format)
        engine.mainMixerNode.outputVolume = volume
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
            Task { @MainActor in SoundFX.shared.restart() }
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            let ended = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.ended.rawValue
            if ended {
                Task { @MainActor in SoundFX.shared.restart() }
            }
        }
    }

    private func loadBuffers() {
        for sfx in Sfx.allCases {
            guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav"),
                  let file = try? AVAudioFile(forReading: url),
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            else { continue }
            do {
                try file.read(into: buffer)
                buffers[sfx] = buffer
                if format == nil { format = file.processingFormat }
            } catch {
                continue
            }
        }
    }

    private func attach(_ v: Voice, format: AVAudioFormat) {
        engine.attach(v.player)
        engine.attach(v.speed)
        engine.attach(v.mixer)
        engine.connect(v.player, to: v.speed, format: format)
        engine.connect(v.speed, to: v.mixer, format: format)
        engine.connect(v.mixer, to: engine.mainMixerNode, format: nil)
    }

    private func ensureRunning() -> Bool {
        if engine.isRunning { return true }
        AudioRouter.shared.prepareForEffects()
        do {
            engine.prepare()
            try engine.start()
            started = true
            return true
        } catch {
            return false
        }
    }

    func restart() {
        guard started else { return }
        engine.stop()
        _ = ensureRunning()
    }

    /// Plays one sound. `pan` is -1 (left) to 1 (right). `jitter` is how much the pitch may wander.
    func play(_ sfx: Sfx, pan: Float = 0, jitter: Float = 0.04, gain: Float = 1) {
        guard enabled, volume > 0.001, let buffer = buffers[sfx], ensureRunning() else { return }
        let now = Date()
        let voice = voices.first(where: { $0.busyUntil < now }) ?? voices.min(by: { $0.busyUntil < $1.busyUntil })
        guard let voice else { return }
        voice.player.stop()
        voice.mixer.pan = max(-1, min(1, pan))
        voice.mixer.outputVolume = gain
        voice.speed.rate = 1 + Float.random(in: -jitter...jitter)
        let seconds = Double(buffer.frameLength) / buffer.format.sampleRate
        voice.busyUntil = now.addingTimeInterval(seconds + 0.05)
        voice.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        voice.player.play()
    }

    /// Starts a looping sound (the thinking hum) with a fade in.
    func startLoop(_ sfx: Sfx = .thinkLoop, gain: Float = 0.35) {
        guard enabled, volume > 0.001, let buffer = buffers[sfx], ensureRunning() else { return }
        if loopVoice.player.isPlaying { return }
        loopVoice.mixer.outputVolume = 0
        loopVoice.speed.rate = 1
        loopVoice.player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        loopVoice.player.play()
        fadeLoop(to: gain, seconds: 0.5, stopAfter: false)
    }

    /// Fades the loop out and stops it.
    func stopLoop() {
        guard loopVoice.player.isPlaying else { return }
        fadeLoop(to: 0, seconds: 0.4, stopAfter: true)
    }

    private func fadeLoop(to target: Float, seconds: Double, stopAfter: Bool) {
        loopFadeTask?.cancel()
        let mixer = loopVoice.mixer
        let player = loopVoice.player
        let startGain = mixer.outputVolume
        loopFadeTask = Task { @MainActor in
            let steps = 20
            for i in 1...steps {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: UInt64(seconds / Double(steps) * 1_000_000_000))
                mixer.outputVolume = startGain + (target - startGain) * Float(i) / Float(steps)
            }
            if stopAfter { player.stop() }
        }
    }
}
