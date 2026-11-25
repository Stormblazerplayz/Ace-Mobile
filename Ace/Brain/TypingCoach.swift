import Foundation

/// Typing lessons: which keys each one practices, and the practice text it hands out.
enum TypingLesson: String, CaseIterable, Identifiable {
    case homeRow, topRow, bottomRow, allLetters, words, sentences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeRow: return "Home row"
        case .topRow: return "Top row"
        case .bottomRow: return "Bottom row"
        case .allLetters: return "All letters"
        case .words: return "Common words"
        case .sentences: return "Sentences"
        }
    }

    var blurb: String {
        switch self {
        case .homeRow: return "Fingers rest on A S D F and J K L. Start here."
        case .topRow: return "Reach up to Q W E R T Y U I O P."
        case .bottomRow: return "Reach down to Z X C V B N M."
        case .allLetters: return "Words that use the whole keyboard."
        case .words: return "The 100 words people type most."
        case .sentences: return "Real sentences with capitals and punctuation."
        }
    }

    var symbol: String {
        switch self {
        case .homeRow: return "house.fill"
        case .topRow: return "arrow.up.circle.fill"
        case .bottomRow: return "arrow.down.circle.fill"
        case .allLetters: return "keyboard.fill"
        case .words: return "text.word.spacing"
        case .sentences: return "text.quote"
        }
    }

    /// The keys this lesson is about, for lighting them up on the keyboard.
    var focusKeys: Set<Character> {
        switch self {
        case .homeRow: return Set("asdfghjkl")
        case .topRow: return Set("qwertyuiop")
        case .bottomRow: return Set("zxcvbnm")
        default: return []
        }
    }

    /// Words made only from this lesson's keys (plus the rows learned before it).
    var pool: [String] {
        switch self {
        case .homeRow: return TypingWords.homeRow
        case .topRow: return TypingWords.topRow
        case .bottomRow: return TypingWords.bottomRow
        case .allLetters: return TypingWords.allLetters
        case .words: return TypingWords.common
        case .sentences: return TypingWords.sentences
        }
    }

    /// A practice text: about `count` words picked from the pool (or two sentences).
    func text(count: Int = 18, seed: UInt64) -> String {
        var rng = SeededRandom(seed: seed)
        if self == .sentences {
            let pool = TypingWords.sentences
            let first = Int(rng.next() % UInt64(pool.count))
            var second = Int(rng.next() % UInt64(pool.count))
            if second == first { second = (second + 1) % pool.count }
            return pool[first] + " " + pool[second]
        }
        var words: [String] = []
        let pool = self.pool
        while words.count < count {
            let w = pool[Int(rng.next() % UInt64(pool.count))]
            // No word twice in a row.
            if words.last != w { words.append(w) }
        }
        return words.joined(separator: " ")
    }
}

/// A small random number maker that gives the same numbers for the same seed, so tests can check texts.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// One go at a practice text: what's been typed, the mistakes, and the speed.
struct TypingRun: Equatable {
    enum Press: Equatable { case right, wrong(expected: Character), finished, ignored }

    let target: [Character]
    private(set) var typed: [Character] = []
    /// Was each typed letter right when it was typed?
    private(set) var correct: [Bool] = []
    private(set) var mistakes = 0
    /// Which keys were missed (the key you should have pressed), lowercased.
    private(set) var missedKeys: [Character: Int] = [:]
    private(set) var startedAt: Date?
    private(set) var finishedAt: Date?

    init(text: String) { target = Array(text) }

    var position: Int { typed.count }
    var done: Bool { finishedAt != nil }
    var next: Character? { position < target.count ? target[position] : nil }
    var progress: Double { target.isEmpty ? 1 : Double(position) / Double(target.count) }

    /// Types one character. Curly quotes from the iPad keyboard count as straight ones.
    mutating func type(_ raw: Character, at now: Date = Date()) -> Press {
        guard !done, let want = next else { return .ignored }
        let c = TypingRun.plain(raw)
        if startedAt == nil { startedAt = now }
        typed.append(c)
        let right = c == want
        correct.append(right)
        if !right {
            mistakes += 1
            let key = Character(want.lowercased())
            missedKeys[key, default: 0] += 1
        }
        if position == target.count {
            finishedAt = now
            return .finished
        }
        return right ? .right : .wrong(expected: want)
    }

    /// Takes back the last character (a mistake still counts against accuracy).
    mutating func backspace() {
        guard !done, !typed.isEmpty else { return }
        typed.removeLast()
        correct.removeLast()
    }

    static func plain(_ c: Character) -> Character {
        switch c {
        case "’", "‘": return "'"
        case "“", "”": return "\""
        default: return c
        }
    }

    /// Words a minute: every 5 right characters count as a word.
    func wordsPerMinute(at now: Date = Date()) -> Double {
        guard let start = startedAt else { return 0 }
        let seconds = (finishedAt ?? now).timeIntervalSince(start)
        guard seconds >= 1 else { return 0 }
        let good = correct.filter { $0 }.count
        return Double(good) / 5 / (seconds / 60)
    }

    /// Right key presses out of all key presses, 0 to 100.
    var accuracy: Double {
        let presses = correct.count + (mistakes - correct.filter { !$0 }.count)
        guard presses > 0 else { return 100 }
        return max(0, Double(presses - mistakes) / Double(presses) * 100)
    }

    /// Stars for a finished run: speed and care both count.
    func stars(at now: Date = Date()) -> Int {
        guard done else { return 0 }
        let wpm = wordsPerMinute(at: now)
        if accuracy >= 97, wpm >= 25 { return 3 }
        if accuracy >= 90, wpm >= 12 { return 2 }
        return 1
    }
}

/// Your best speed on each lesson, kept on the iPad.
struct TypingBests {
    static let shared = TypingBests(key: "ace.typing.best")
    let key: String

    private var all: [String: Double] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: Double]) ?? [:]
    }

    func best(_ lesson: TypingLesson) -> Double { all[lesson.rawValue] ?? 0 }

    /// Saves a speed if it beats the old best. True if it's a new best.
    @discardableResult
    func record(_ wpm: Double, for lesson: TypingLesson) -> Bool {
        guard wpm > best(lesson) else { return false }
        var d = all
        d[lesson.rawValue] = wpm
        UserDefaults.standard.set(d, forKey: key)
        return true
    }

    func clearAll() { UserDefaults.standard.removeObject(forKey: key) }
}

/// Understands typing asks: "typing practice", "teach me to type", "typing test", "how fast can I type".
/// Returns "open" or a lesson's id.
enum TypingAsk {
    private static let polite = #"^(?:(?:please|ok|okay|hey ace|ace|can you|could you|can i|let us|i want to|want to|i would like to|help me|time to)\s+)*"#

    static func parse(_ t: String) -> String? {
        if Rx.matches(polite + #"(?:teach me (?:how )?to type|learn (?:how )?to type|learn touch typing|practice (?:my )?typing|do (?:some )?typing(?: practice)?|test my typing(?: speed)?)(?: please| now)?$"#, t)
            || Rx.matches(polite + #"(?:(?:open|start|show me|give me|do|have|try)\s+)?(?:the |a |my |some )?(?:typing|touch typing|keyboard) (?:practice|lesson|lessons|test|trainer|game|speed test|coach)(?: please| now)?$"#, t)
            || Rx.matches(#"^(?:ace )?typing$"#, t)
            || Rx.matches(#"^how fast (?:can|do) i type$"#, t) {
            return "open"
        }
        if let g = Rx.groups(polite + #"(?:practice|start|do) (?:the )?(home row|top row|bottom row)(?: keys)?(?: typing)?$"#, t) {
            switch g[0] {
            case "home row": return TypingLesson.homeRow.rawValue
            case "top row": return TypingLesson.topRow.rawValue
            default: return TypingLesson.bottomRow.rawValue
            }
        }
        return nil
    }
}
