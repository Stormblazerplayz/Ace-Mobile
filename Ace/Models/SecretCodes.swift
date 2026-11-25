import Foundation

/// The secret codes you can use.
enum SecretCode: String, CaseIterable, Identifiable {
    case caesar, morse, mirror

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caesar: return "Code wheel"
        case .morse: return "Morse code"
        case .mirror: return "Mirror code"
        }
    }

    var symbol: String {
        switch self {
        case .caesar: return "circle.dashed.inset.filled"
        case .morse: return "light.beacon.max.fill"
        case .mirror: return "arrow.left.arrow.right"
        }
    }

    /// One line on how the code works.
    var howItWorks: String {
        switch self {
        case .caesar: return "Every letter moves along the alphabet by the same number. With 3, A becomes D."
        case .morse: return "Letters become short and long signals: dots and dashes. Flash it with a light!"
        case .mirror: return "The alphabet is flipped: A swaps with Z, B with Y, and so on."
        }
    }

    /// Glow colors for the screen behind each code.
    var hexes: (UInt32, UInt32) {
        switch self {
        case .caesar: return (0x7C5CFF, 0x2BD9C5)
        case .morse: return (0xFFB020, 0xFF5F8F)
        case .mirror: return (0x3FA2FF, 0xB18CFF)
        }
    }
}

/// The Caesar code, Julius Caesar's own: each letter moves along the alphabet by a shift.
enum Caesar {
    static let alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// Any shift, as 0 to 25.
    static func normalize(_ shift: Int) -> Int {
        ((shift % 26) + 26) % 26
    }

    /// Moves one letter, keeping capitals. Anything that isn't A to Z stays as it is.
    static func shifted(_ c: Character, by shift: Int) -> Character {
        guard let ascii = c.asciiValue else { return c }
        let s = UInt8(normalize(shift))
        switch ascii {
        case 65...90: return Character(UnicodeScalar((ascii - 65 + s) % 26 + 65))
        case 97...122: return Character(UnicodeScalar((ascii - 97 + s) % 26 + 97))
        default: return c
        }
    }

    static func encode(_ text: String, shift: Int) -> String {
        String(text.map { shifted($0, by: shift) })
    }

    static func decode(_ text: String, shift: Int) -> String {
        encode(text, shift: -shift)
    }

    /// How often each letter A to Z shows up in English, in percent.
    static let englishFrequency: [Double] = [
        8.2, 1.5, 2.8, 4.3, 12.7, 2.2, 2.0, 6.1, 7.0, 0.15, 0.77, 4.0, 2.4,
        6.7, 7.5, 1.9, 0.095, 6.0, 6.3, 9.1, 2.8, 0.98, 2.4, 0.15, 2.0, 0.074
    ]

    static func letterCount(_ text: String) -> Int {
        var count = 0
        for c in text {
            guard let ascii = c.asciiValue else { continue }
            if (65...90).contains(ascii) || (97...122).contains(ascii) { count += 1 }
        }
        return count
    }

    /// How un-English the letters look (a chi-squared score). Lower looks more like English.
    static func score(_ text: String) -> Double {
        var counts = [Double](repeating: 0, count: 26)
        var total = 0.0
        for c in text.uppercased() {
            guard let ascii = c.asciiValue, (65...90).contains(ascii) else { continue }
            counts[Int(ascii - 65)] += 1
            total += 1
        }
        guard total > 0 else { return .infinity }
        let sum = englishFrequency.reduce(0, +)
        var score = 0.0
        for i in 0..<26 {
            let expected = total * englishFrequency[i] / sum
            score += (counts[i] - expected) * (counts[i] - expected) / expected
        }
        return score
    }

    /// Cracks a message without knowing the shift: tries all 26 and keeps the one that reads most like English.
    /// Nil when there are fewer than 3 letters to go on. Short messages can fool it.
    static func crack(_ text: String) -> (shift: Int, text: String)? {
        guard letterCount(text) >= 3 else { return nil }
        var best = (shift: 0, text: text, score: Double.infinity)
        for shift in 0..<26 {
            let plain = decode(text, shift: shift)
            let s = score(plain)
            if s < best.score { best = (shift, plain, s) }
        }
        return (best.shift, best.text)
    }
}

/// The mirror code (Atbash): A swaps with Z, B with Y. Doing it twice gives the message back.
enum MirrorCode {
    static func flipped(_ c: Character) -> Character {
        guard let ascii = c.asciiValue else { return c }
        switch ascii {
        case 65...90: return Character(UnicodeScalar(90 - (ascii - 65)))
        case 97...122: return Character(UnicodeScalar(122 - (ascii - 97)))
        default: return c
        }
    }

    static func apply(_ text: String) -> String {
        String(text.map(flipped))
    }
}

/// One step of flashing Morse code: the light on or off for a number of beats.
struct MorseSignal: Equatable {
    var on: Bool
    var units: Int
    /// Which dot or dash this is, counting from 0 across the whole message (nil for gaps).
    var symbol: Int?
}

/// International Morse code.
enum Morse {
    static let table: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.", "H": "....",
        "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---", "P": ".--.",
        "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
        "Y": "-.--", "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
        "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.",
        ".": ".-.-.-", ",": "--..--", "?": "..--..", "'": ".----.", "!": "-.-.--", "/": "-..-.",
        "(": "-.--.", ")": "-.--.-", "&": ".-...", ":": "---...", ";": "-.-.-.", "=": "-...-",
        "+": ".-.-.", "-": "-....-", "_": "..--.-", "\"": ".-..-.", "$": "...-..-", "@": ".--.-."
    ]

    static let reverse: [String: Character] = {
        var r: [String: Character] = [:]
        for (letter, code) in table { r[code] = letter }
        return r
    }()

    /// "SOS" becomes "... --- ...". Letters are split by spaces and words by " / ".
    /// Characters Morse doesn't have are left out.
    static func encode(_ text: String) -> String {
        text.uppercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map { word in word.compactMap { table[$0] }.joined(separator: " ") }
            .filter { !$0.isEmpty }
            .joined(separator: " / ")
    }

    /// Turns other dot and dash marks into plain . and -.
    static func clean(_ code: String) -> String {
        var s = code
        for (from, to) in [("•", "."), ("·", "."), ("∙", "."), ("—", "-"), ("–", "-"), ("−", "-"), ("_", "-"), ("|", "/")] {
            s = s.replacingOccurrences(of: from, with: to)
        }
        return s
    }

    /// "... --- ..." becomes "SOS". A code it doesn't know becomes "?".
    static func decode(_ code: String) -> String {
        clean(code)
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { word in
                word.split(whereSeparator: { $0.isWhitespace })
                    .map { mark -> String in
                        guard let letter = reverse[String(mark)] else { return "?" }
                        return String(letter)
                    }
                    .joined()
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Whether the text is only dots, dashes, slashes and spaces, with at least one dot or dash.
    static func looksLikeMorse(_ text: String) -> Bool {
        let s = clean(text)
        guard s.contains(where: { $0 == "." || $0 == "-" }) else { return false }
        return s.allSatisfy { $0 == "." || $0 == "-" || $0 == "/" || $0.isWhitespace }
    }

    /// The light's on and off steps: a dot is 1 beat, a dash 3, with 1 beat between signals,
    /// 3 between letters and 7 between words.
    static func signals(_ code: String) -> [MorseSignal] {
        var result: [MorseSignal] = []
        var symbol = 0
        let words = clean(code).split(separator: "/").map { $0.split(whereSeparator: { $0.isWhitespace }) }.filter { !$0.isEmpty }
        for (w, word) in words.enumerated() {
            if w > 0 { result.append(MorseSignal(on: false, units: 7)) }
            for (l, letter) in word.enumerated() {
                if l > 0 { result.append(MorseSignal(on: false, units: 3)) }
                var first = true
                for mark in letter where mark == "." || mark == "-" {
                    if !first { result.append(MorseSignal(on: false, units: 1)) }
                    result.append(MorseSignal(on: true, units: mark == "." ? 1 : 3, symbol: symbol))
                    symbol += 1
                    first = false
                }
            }
        }
        return result
    }

    static func totalUnits(_ signals: [MorseSignal]) -> Int {
        signals.reduce(0) { $0 + $1.units }
    }
}

/// Encoding or decoding a message with a code.
enum SecretCodes {
    static let maxLength = 300

    static func run(_ code: SecretCode, text: String, hiding: Bool, shift: Int) -> String {
        let text = String(text.prefix(maxLength))
        switch code {
        case .caesar: return hiding ? Caesar.encode(text, shift: shift) : Caesar.decode(text, shift: shift)
        case .morse: return hiding ? Morse.encode(text) : Morse.decode(text)
        case .mirror: return MirrorCode.apply(text)
        }
    }
}
