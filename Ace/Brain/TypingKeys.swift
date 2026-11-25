import Foundation

/// The on-screen keyboard for typing practice: its rows, and which key to press for a character.
enum TypingKeys {
    static let shift = "shift"
    static let delete = "delete"
    static let space = " "

    /// Each row's keys, top to bottom. Letters are lowercase ids; the keyboard shows capitals when Shift is on.
    static let rows: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", delete],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l", "'"],
        [shift, "z", "x", "c", "v", "b", "n", "m", ",", ".", shift],
        ["!", space, "?"],
    ]

    /// Every key you can type with (not Shift or Delete).
    static var typingKeys: Set<String> {
        Set(rows.joined().filter { $0 != shift && $0 != delete })
    }

    /// The key that types `c`, and whether Shift is needed for it. Nil if the keyboard can't type it.
    static func key(for c: Character) -> (key: String, shift: Bool)? {
        let lower = String(c).lowercased()
        guard typingKeys.contains(lower) else { return nil }
        return (lower, c.isUppercase)
    }

    /// What a key types, with Shift on or off.
    static func character(for key: String, shift: Bool) -> Character? {
        guard key != TypingKeys.shift, key != delete, let c = key.first, key.count == 1 else { return nil }
        return shift ? Character(String(c).uppercased()) : c
    }

    /// Which finger types each letter key (for the colored dots on the keys), 0 is the left pinky, 7 the right pinky.
    static func finger(for key: String) -> Int? {
        switch key {
        case "q", "a", "z": return 0
        case "w", "s", "x": return 1
        case "e", "d", "c": return 2
        case "r", "f", "v", "t", "g", "b": return 3
        case "y", "h", "n", "u", "j", "m": return 4
        case "i", "k", ",": return 5
        case "o", "l", ".": return 6
        case "p", "'", "!", "?": return 7
        default: return nil
        }
    }

    /// The home keys where fingers rest (they get little bumps, like F and J on a real keyboard).
    static let bumps: Set<String> = ["f", "j"]

    /// Every character in a lesson's texts can be typed on this keyboard.
    static func canType(_ text: String) -> Bool {
        text.allSatisfy { key(for: $0) != nil }
    }
}
