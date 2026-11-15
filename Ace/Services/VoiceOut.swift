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

    /// The lines still to be said, so a reply in parts only counts as finished after its last part.
    private var queued: [ObjectIdentifier: AVSpeechUtterance] = [:]
    /// Lines that were cut off, kept a little longer so a new line can't reuse their id before their "cancelled" call comes in.
    private var retired: [AVSpeechUtterance] = []

    func speak(_ text: String, voiceID: String, onChange: @escaping (Bool) -> Void) {
        speak([SpokenPart(text: text, language: nil)], voiceID: voiceID, onChange: onChange)
    }

    /// Reads a reply in parts: Ace's own voice, and a translation in the accent of its language.
    func speak(_ parts: [SpokenPart], voiceID: String, onChange: @escaping (Bool) -> Void) {
        let lines = parts.map { p in
            SpokenPart(text: p.language == nil ? Self.clean(p.text) : p.text.trimmingCharacters(in: .whitespacesAndNewlines), language: p.language)
        }.filter { !$0.text.isEmpty }
        guard !lines.isEmpty else { return }
        AudioRouter.shared.prepareForSpeaking()
        restart()
        self.onChange = onChange
        for line in lines {
            let u = AVSpeechUtterance(string: line.text)
            if let language = line.language {
                u.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
                u.rate = Self.rate(0.85)
            } else {
                if !voiceID.isEmpty, let v = AVSpeechSynthesisVoice(identifier: voiceID) {
                    u.voice = v
                } else {
                    u.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
                }
                u.rate = Self.rate(1.02)
                u.pitchMultiplier = 1.08
            }
            queued[ObjectIdentifier(u)] = u
            synth.speak(u)
        }
    }

    /// Says a word or phrase in another language (the translator's "Say it" button).
    func speak(_ text: String, language: String) {
        guard !text.isEmpty else { return }
        AudioRouter.shared.prepareForSpeaking()
        restart()
        onChange = nil
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        u.rate = Self.rate(0.85)
        queued[ObjectIdentifier(u)] = u
        synth.speak(u)
    }

    static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "°F", with: " degrees")
            .replacingOccurrences(of: "°C", with: " degrees")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Cuts off whatever was being said, without telling anyone it finished (something new is about to start).
    private func restart() {
        retire()
        synth.stopSpeaking(at: .immediate)
    }

    private func retire() {
        retired = Array((retired + Array(queued.values)).suffix(30))
        queued.removeAll()
    }

    /// The talking speed, with the speed from Settings ("talk slower") on top.
    static func rate(_ base: Float) -> Float {
        let r = AVSpeechUtteranceDefaultSpeechRate * base * Float(SettingsStore.voiceSpeedNow)
        return min(AVSpeechUtteranceMaximumSpeechRate, max(AVSpeechUtteranceMinimumSpeechRate, r))
    }

    func stop() {
        let wasTalking = !queued.isEmpty
        retire()
        synth.stopSpeaking(at: .immediate)
        if wasTalking { onChange?(false) }
    }

    static func englishVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard VoiceOut.shared.queued[id] != nil else { return }
            VoiceOut.shared.onChange?(true)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            let me = VoiceOut.shared
            guard me.queued.removeValue(forKey: id) != nil, me.queued.isEmpty else { return }
            me.onChange?(false)
            AudioRouter.shared.backToEffects()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            let me = VoiceOut.shared
            guard me.queued.removeValue(forKey: id) != nil, me.queued.isEmpty else { return }
            me.onChange?(false)
        }
    }
}
