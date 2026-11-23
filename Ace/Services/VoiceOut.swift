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
        let utterances = Self.utterances(parts, voiceID: voiceID)
        guard !utterances.isEmpty else { return }
        AudioRouter.shared.prepareForSpeaking()
        restart()
        self.onChange = onChange
        for u in utterances {
            queued[ObjectIdentifier(u)] = u
            synth.speak(u)
        }
    }

    /// The spoken lines for a reply, each with its voice, speed and pitch.
    /// A voice call with Ace uses the same lines, so Ace sounds the same on a call.
    static func utterances(_ parts: [SpokenPart], voiceID: String) -> [AVSpeechUtterance] {
        let lines = parts.map { p in
            SpokenPart(text: p.language == nil ? clean(p.text) : p.text.trimmingCharacters(in: .whitespacesAndNewlines),
                       language: p.language, sassy: p.sassy, drama: p.drama)
        }.filter { !$0.text.isEmpty }
        return lines.map { line -> AVSpeechUtterance in
            let u = AVSpeechUtterance(string: line.text)
            if let language = line.language {
                u.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
                u.rate = rate(0.85)
            } else {
                if !voiceID.isEmpty, let v = AVSpeechSynthesisVoice(identifier: voiceID) {
                    u.voice = v
                } else {
                    u.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
                }
                if line.sassy {
                    // Sassy delivery: drawn out, a bit higher, and a dramatic pause before the answer.
                    // More of each the higher the sass slider is.
                    let style = sassyStyle(drama: line.drama)
                    u.rate = rate(style.rate)
                    u.pitchMultiplier = style.pitch
                    u.postUtteranceDelay = style.pause
                } else {
                    u.rate = rate(1.02)
                    u.pitchMultiplier = 1.08
                }
            }
            return u
        }
    }

    /// How a sassy line sounds at each sass level (1 Mild, 2 Spicy, 3 Extra).
    static func sassyStyle(drama: Int) -> (rate: Float, pitch: Float, pause: TimeInterval) {
        switch drama {
        case ...1: return (0.98, 1.12, 0.08)
        case 2: return (0.93, 1.18, 0.16)
        default: return (0.88, 1.24, 0.25)
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
