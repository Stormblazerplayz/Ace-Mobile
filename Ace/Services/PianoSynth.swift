import AVFoundation
import Foundation

/// Plays Ace Piano's notes live. The notes are made from math (see `PianoMixer`), so there
/// are no sound files. Taps go into a little queue, and the audio thread picks them up.
@MainActor
final class PianoSynth {
    static let shared = PianoSynth()

    /// What the main thread and the audio thread share. The audio thread never waits for the
    /// lock: if it's busy, new taps simply wait for the next tiny slice of sound.
    private final class Shared: @unchecked Sendable {
        enum Event {
            case on(Int, Float)
            case off(Int)
            case allOff
            case sound(PianoSound)
            case volume(Float)
        }

        private let lock = NSLock()
        private var pending: [Event] = []
        var mixer: PianoMixer

        init(sampleRate: Double) {
            mixer = PianoMixer(sampleRate: sampleRate)
        }

        func post(_ e: Event) {
            lock.lock()
            pending.append(e)
            lock.unlock()
        }

        /// Called on the audio thread before each slice of sound.
        func drain() {
            guard lock.try() else { return }
            let events = pending
            pending.removeAll(keepingCapacity: true)
            lock.unlock()
            for e in events {
                switch e {
                case .on(let m, let v): mixer.noteOn(m, velocity: v)
                case .off(let m): mixer.noteOff(m)
                case .allOff: mixer.allOff()
                case .sound(let s): mixer.sound = s
                case .volume(let v): mixer.volume = v
                }
            }
        }
    }

    private let engine = AVAudioEngine()
    private var shared: Shared?
    private var source: AVAudioSourceNode?
    private var stopTask: Task<Void, Never>?

    var sound: PianoSound = .grand {
        didSet { shared?.post(.sound(sound)) }
    }

    private init() {
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
            Task { @MainActor in PianoSynth.shared.restartIfNeeded() }
        }
    }

    /// Gets the sound ready when the piano opens. The piano plays even with the silent switch on,
    /// like a music app, and mixes with music that's already playing.
    func start() {
        stopTask?.cancel()
        AudioRouter.shared.holdMusic()
        if source == nil { build() }
        run()
    }

    /// The piano closed: let every note fade, then switch the sound off.
    func stop() {
        allOff()
        stopTask?.cancel()
        stopTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            engine.stop()
            AudioRouter.shared.releaseMusic()
        }
    }

    func noteOn(_ midi: Int, velocity: Float = 0.8) {
        run()
        shared?.post(.on(midi, velocity))
    }

    func noteOff(_ midi: Int) {
        shared?.post(.off(midi))
    }

    func allOff() {
        shared?.post(.allOff)
    }

    private func build() {
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sampleRate = rate > 0 ? rate : 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let shared = Shared(sampleRate: sampleRate)
        shared.mixer.sound = sound
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            shared.drain()
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let first = buffers.first, let data = first.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let frames = Int(frameCount)
            shared.mixer.render(into: data, frames: frames)
            // Any other channel gets the same sound.
            for b in buffers.dropFirst() {
                b.mData?.assumingMemoryBound(to: Float.self).update(from: data, count: frames)
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        self.shared = shared
        source = node
    }

    private func run() {
        guard source != nil, !engine.isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
        } catch {
            // No sound right now (another app has the audio). The keys still light up.
        }
    }

    /// Headphones came out or the audio changed: start again if the piano is open.
    private func restartIfNeeded() {
        guard AudioRouter.shared.musicHeld, source != nil else { return }
        engine.stop()
        run()
    }
}
