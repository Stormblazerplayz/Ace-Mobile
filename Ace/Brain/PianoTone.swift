import Foundation

/// The four sounds Ace Piano can make. Each is a mix of overtones with its own swell and fade.
enum PianoSound: String, CaseIterable, Identifiable {
    case grand = "Piano"
    case musicBox = "Music box"
    case organ = "Organ"
    case synth = "Synth"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .grand: return "pianokeys"
        case .musicBox: return "gift.fill"
        case .organ: return "building.columns.fill"
        case .synth: return "waveform"
        }
    }

    /// Overtones as (multiple of the note's pitch, loudness).
    var harmonics: [(multiple: Double, level: Float)] {
        switch self {
        case .grand: return [(1, 1), (2, 0.45), (3, 0.22), (4, 0.12), (5, 0.06)]
        case .musicBox: return [(1, 1), (3.01, 0.35), (5.4, 0.12)]
        case .organ: return [(0.5, 0.35), (1, 1), (2, 0.6), (3, 0.3), (4, 0.25)]
        case .synth: return [(1, 1), (3, 0.33), (5, 0.2), (7, 0.14), (9, 0.11)]
        }
    }

    /// Seconds to reach full loudness.
    var attack: Double {
        switch self {
        case .grand: return 0.004
        case .musicBox: return 0.002
        case .organ: return 0.025
        case .synth: return 0.012
        }
    }

    /// How loud a held note stays (0 means it fades away by itself, like a real piano).
    var sustain: Float {
        switch self {
        case .grand, .musicBox: return 0
        case .organ: return 0.9
        case .synth: return 0.6
        }
    }

    /// Seconds for a held note to fade to about a third (higher notes fade faster on a piano).
    func decay(_ frequency: Double) -> Double {
        switch self {
        case .grand: return min(3.2, max(0.45, 1.5 * (261.6 / frequency).squareRoot()))
        case .musicBox: return min(2.4, max(0.5, 1.3 * (523.3 / frequency).squareRoot()))
        case .organ: return 0.25
        case .synth: return 0.4
        }
    }

    /// Seconds for a let-go note to fade to about a third.
    var release: Double {
        switch self {
        case .grand: return 0.14
        case .musicBox: return 0.5
        case .organ: return 0.06
        case .synth: return 0.18
        }
    }
}

/// Mixes up to 12 notes at once into audio samples. It's plain math with no audio system,
/// so it runs the same on the iPad's audio thread and in tests.
struct PianoMixer {
    static let maxVoices = 12
    /// Below this a note is silent and is dropped.
    static let silence: Float = 0.0005

    struct Voice {
        var midi: Int
        var frequency: Double
        var velocity: Float
        var level: Float = 0
        var phases: [Double]
        var attacking = true
        var held = true
    }

    let sampleRate: Double
    var sound: PianoSound
    var volume: Float = 0.8
    private(set) var voices: [Voice] = []

    init(sampleRate: Double, sound: PianoSound = .grand) {
        self.sampleRate = max(8000, sampleRate)
        self.sound = sound
    }

    var isSilent: Bool { voices.isEmpty }
    var heldNotes: Set<Int> { Set(voices.filter(\.held).map(\.midi)) }

    /// Starts a note. Playing the same note again restarts it; past 12 notes the quietest one stops.
    mutating func noteOn(_ midi: Int, velocity: Float = 0.8) {
        voices.removeAll { $0.midi == midi }
        if voices.count >= PianoMixer.maxVoices, let quiet = voices.indices.min(by: { voices[$0].level < voices[$1].level }) {
            voices.remove(at: quiet)
        }
        let f = PianoTheory.frequency(midi)
        voices.append(Voice(midi: midi, frequency: f, velocity: max(0.05, min(1, velocity)),
                            phases: Array(repeating: 0, count: sound.harmonics.count)))
    }

    /// Lets go of a note, so it fades out.
    mutating func noteOff(_ midi: Int) {
        for i in voices.indices where voices[i].midi == midi {
            voices[i].held = false
            voices[i].attacking = false
        }
    }

    mutating func allOff() {
        for i in voices.indices {
            voices[i].held = false
            voices[i].attacking = false
        }
    }

    /// Fills `out` with `frames` samples from -1 to 1.
    mutating func render(into out: UnsafeMutablePointer<Float>, frames: Int) {
        for i in 0..<frames { out[i] = 0 }
        guard !voices.isEmpty, frames > 0 else { return }
        let harmonics = sound.harmonics
        let attackStep = Float(1 / (sound.attack * sampleRate))
        let releaseKeep = Float(exp(-1 / (sound.release * sampleRate)))
        let sustain = sound.sustain
        let nyquist = sampleRate * 0.45
        let total = harmonics.reduce(Float(0)) { $0 + $1.level }
        let perVoice: Float = 0.32 / total
        var keep: [Bool] = []
        for v in voices.indices {
            var voice = voices[v]
            let decayKeep = Float(exp(-1 / (sound.decay(voice.frequency) * sampleRate)))
            let steps = harmonics.map { 2 * Double.pi * voice.frequency * $0.multiple / sampleRate }
            let live = harmonics.indices.filter { voice.frequency * harmonics[$0].multiple < nyquist }
            for i in 0..<frames {
                // The swell and fade.
                if voice.attacking {
                    voice.level += attackStep
                    if voice.level >= 1 {
                        voice.level = 1
                        voice.attacking = false
                    }
                } else if voice.held {
                    voice.level = sustain + (voice.level - sustain) * decayKeep
                } else {
                    voice.level *= releaseKeep
                }
                var sample: Float = 0
                for h in live {
                    sample += Float(sin(voice.phases[h])) * harmonics[h].level
                    voice.phases[h] += steps[h]
                    if voice.phases[h] > 2 * Double.pi { voice.phases[h] -= 2 * Double.pi }
                }
                out[i] += sample * voice.level * voice.velocity * perVoice
            }
            voices[v] = voice
            keep.append(voice.attacking || voice.level > PianoMixer.silence || (voice.held && sustain > 0))
        }
        voices = zip(voices, keep).filter(\.1).map(\.0)
        // A soft limit, so lots of notes at once get fuller instead of crackling.
        for i in 0..<frames {
            out[i] = Float(tanh(Double(out[i] * volume * 1.6)))
        }
    }
}
