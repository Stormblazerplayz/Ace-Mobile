import AVFoundation

/// Reads Ace's replies out loud when "Speak replies" is on.
@MainActor
final class VoiceOut: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceOut()

    private let synth = AVSpeechSynthesizer()
    private var onChange: ((Bool) -> Void)?

    private override init() {
        super.init()
        synth.delegate = self
    }

    var isSpeaking: Bool { synth.isSpeaking }

    func speak(_ text: String, voiceID: String, onChange: @escaping (Bool) -> Void) {
        let clean = text
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "°F", with: " degrees")
            .replacingOccurrences(of: "°C", with: " degrees")
        guard !clean.isEmpty else { return }
        AudioRouter.shared.prepareForSpeaking()
        synth.stopSpeaking(at: .immediate)
        self.onChange = onChange
        let u = AVSpeechUtterance(string: clean)
        if !voiceID.isEmpty, let v = AVSpeechSynthesisVoice(identifier: voiceID) {
            u.voice = v
        } else {
            u.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        u.pitchMultiplier = 1.08
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    static func englishVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in VoiceOut.shared.onChange?(true) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            VoiceOut.shared.onChange?(false)
            AudioRouter.shared.backToEffects()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in VoiceOut.shared.onChange?(false) }
    }
}
