import AVFoundation

/// Picks the right audio session for what Ace is doing.
/// Effects use "ambient" (silent switch mutes them, music keeps playing).
/// Listening uses "play and record". Spoken replies use "playback" so you can hear them.
@MainActor
final class AudioRouter {
    static let shared = AudioRouter()

    enum Mode { case none, effects, speaking, listening }
    private(set) var mode: Mode = .none

    func prepareForEffects() {
        guard mode == .none else { return }
        set(.ambient, mode: .default, options: [.mixWithOthers])
        mode = .effects
    }

    func prepareForSpeaking() {
        guard mode != .listening else { return }
        set(.playback, mode: .spokenAudio, options: [.duckOthers])
        mode = .speaking
    }

    func prepareForListening() {
        set(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .duckOthers])
        mode = .listening
    }

    /// Goes back to quiet effects once listening or speaking is over.
    func backToEffects() {
        mode = .none
        prepareForEffects()
    }

    private func set(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(category, mode: mode, options: options)
            try s.setActive(true, options: [])
        } catch {
            // Another app may own the audio right now. Ace just stays quiet.
        }
    }
}
