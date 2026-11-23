import AVFoundation

/// Picks the right audio session for what Ace is doing.
/// Effects use "ambient" (silent switch mutes them, music keeps playing).
/// Listening uses "play and record". Spoken replies use "playback" so you can hear them.
/// A voice call uses "voice chat", which cancels Ace's own voice out of the microphone,
/// and nothing else changes the audio until the call ends.
@MainActor
final class AudioRouter {
    static let shared = AudioRouter()

    enum Mode { case none, effects, speaking, listening, call }
    private(set) var mode: Mode = .none

    func prepareForEffects() {
        guard mode == .none else { return }
        set(.ambient, mode: .default, options: [.mixWithOthers])
        mode = .effects
    }

    func prepareForSpeaking() {
        guard mode != .listening, mode != .call else { return }
        set(.playback, mode: .spokenAudio, options: [.duckOthers])
        mode = .speaking
    }

    func prepareForListening() {
        guard mode != .call else { return }
        set(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP, .duckOthers])
        mode = .listening
    }

    /// A voice call: talk and listen at the same time, with echo cancelling. True when the iPad agreed.
    @discardableResult
    func prepareForCall() -> Bool {
        mode = .call
        return set(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothA2DP])
    }

    /// Headphones, AirPods, a car or a speaker are plugged in or connected.
    var callHasHeadphones: Bool {
        let external: Set<AVAudioSession.Port> = [.headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .usbAudio, .carAudio, .airPlay]
        return AVAudioSession.sharedInstance().currentRoute.outputs.contains { external.contains($0.portType) }
    }

    /// The call is over: back to quiet effects.
    func endCall() {
        guard mode == .call else { return }
        mode = .none
        prepareForEffects()
    }

    /// Plays a call out of the loudspeaker (true) or the normal way (false: headphones when they're in,
    /// or the earpiece on an iPhone).
    func callSpeaker(_ on: Bool) {
        guard mode == .call else { return }
        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(on ? .speaker : .none)
    }

    /// Goes back to quiet effects once listening or speaking is over (not during a call).
    func backToEffects() {
        guard mode != .call else { return }
        mode = .none
        prepareForEffects()
    }

    @discardableResult
    private func set(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) -> Bool {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(category, mode: mode, options: options)
            try s.setActive(true, options: [])
            return true
        } catch {
            // Another app may own the audio right now. Ace just stays quiet.
            return false
        }
    }
}
