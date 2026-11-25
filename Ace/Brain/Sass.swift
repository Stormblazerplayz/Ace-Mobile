import Foundation
import CoreGraphics

/// How much attitude Sassy Ace has: the slider in Settings, under Personality.
enum SassLevel: Int, CaseIterable, Comparable {
    /// A light quip on some replies.
    case mild = 1
    /// A sassy line on most replies.
    case spicy = 2
    /// Full attitude: every reply, big eye-rolls, lots of drama.
    case extra = 3

    /// From the setting ("mild", "spicy" or "extra"). Anything else is Extra, the default.
    init(setting: String) {
        switch setting {
        case "mild": self = .mild
        case "spicy": self = .spicy
        default: self = .extra
        }
    }

    var setting: String {
        switch self {
        case .mild: return "mild"
        case .spicy: return "spicy"
        case .extra: return "extra"
        }
    }

    var title: String {
        switch self {
        case .mild: return "Mild"
        case .spicy: return "Spicy"
        case .extra: return "Extra"
        }
    }

    /// Which tagged lines each stop picks from (tools/sass_pack/build.py tags every line 1, 2 or 3).
    var pool: Set<Int> {
        switch self {
        case .mild: return [1]
        case .spicy: return [2]
        case .extra: return [2, 3]
        }
    }

    static func < (a: SassLevel, b: SassLevel) -> Bool { a.rawValue < b.rawValue }
}

/// Sassy mode's own small data set (sass_pack.json, made by tools/sass_pack/build.py):
/// sassy answers for common questions, and sassy lines to wrap every other answer.
/// In Sassy mode Ace looks here first, then uses its normal answers with a sassy line, then the web.
/// The normal data set is never changed by any of this.
@MainActor
final class SassPack {
    static let shared = SassPack()

    struct Entry: Codable, Equatable {
        var id: String
        var topic: String
        /// Small talk only matches when it's said (almost) exactly like one of the questions,
        /// so "what is my name" never gets the answer to "what is your name".
        var exact: Bool
        var q: [String]
        var a: [String]
        /// The sass level of each answer: 1 Mild, 2 Spicy, 3 Extra.
        var lv: [Int]?

        /// The answers that fit a slider stop.
        func answers(for level: SassLevel) -> [String] {
            let levels = lv ?? Array(repeating: 2, count: a.count)
            return zip(a, levels).filter { level.pool.contains($0.1) }.map(\.0)
        }
    }

    private struct File: Codable {
        var version: Int
        var lines: [String: [String]]
        var levels: [String: [Int]]?
        var answers: [Entry]
    }

    let lines: [String: [String]]
    /// The sass level of each line, in the same order as `lines`.
    let levels: [String: [Int]]
    let answers: [Entry]
    private var byPhrase: [String: Int] = [:]
    private var byKeywords: [String: Int] = [:]

    init(data: Data? = nil) {
        var file: File?
        if let data {
            file = try? JSONDecoder().decode(File.self, from: data)
        } else if let url = Bundle.main.url(forResource: "sass_pack", withExtension: "json"),
                  let d = try? Data(contentsOf: url) {
            file = try? JSONDecoder().decode(File.self, from: d)
        }
        lines = file?.lines ?? [:]
        levels = file?.levels ?? [:]
        answers = file?.answers ?? []
        for (i, e) in answers.enumerated() {
            for q in e.q {
                let p = Self.phraseKey(q)
                if !p.isEmpty, byPhrase[p] == nil { byPhrase[p] = i }
                if !e.exact, let k = Self.keywordKey(q), byKeywords[k] == nil { byKeywords[k] = i }
            }
        }
    }

    /// Lines plus sassy answers, for Settings and the tests.
    var size: Int { lines.values.reduce(0) { $0 + $1.count } + answers.reduce(0) { $0 + $1.a.count } }

    /// Words that don't change a small-talk question ("hey ace, how are you please").
    static let filler: Set<String> = ["hey", "hi", "hello", "ace", "please", "pls", "plz", "so", "um", "uh", "oh", "well", "yo"]

    static func phraseKey(_ text: String) -> String {
        TextKit.words(text).filter { !filler.contains($0) }.joined(separator: " ")
    }

    static func keywordKey(_ text: String) -> String? {
        let k = Set(TextKit.keywords(text)).sorted()
        return k.isEmpty ? nil : k.joined(separator: " ")
    }

    /// The sassy entry for a question, if the sassy set has one.
    func match(_ question: String) -> Entry? {
        let p = Self.phraseKey(question)
        guard !p.isEmpty else { return nil }
        if let i = byPhrase[p] { return answers[i] }
        if let k = Self.keywordKey(question), let i = byKeywords[k] { return answers[i] }
        return nil
    }

    /// A sassy answer for a question at a slider stop, picked so it doesn't repeat the last few.
    /// nil when the sassy set has none at that level, so Ace's normal answers take it.
    func answer(_ question: String, level: SassLevel = .extra) -> (entry: Entry, text: String)? {
        guard let e = match(question) else { return nil }
        let fit = e.answers(for: level)
        guard !fit.isEmpty else { return nil }
        return (e, fit[VariantPicker.shared.pick("sass.answer.\(level.rawValue)." + e.id, count: fit.count)])
    }

    /// The lines of a kind that fit a slider stop (all of them if the kind has none at that level).
    func linesFor(_ key: String, level: SassLevel) -> [String] {
        guard let all = lines[key], !all.isEmpty else { return [] }
        guard let lv = levels[key], lv.count == all.count else { return all }
        let fit = zip(all, lv).filter { level.pool.contains($0.1) }.map(\.0)
        return fit.isEmpty ? all : fit
    }

    /// One line of a kind ("answer.open", "timer", "repeat.2"...) at a slider stop, or "" when there are none.
    func line(_ key: String, level: SassLevel = .extra, fill: [String: String] = [:]) -> String {
        let all = linesFor(key, level: level)
        guard !all.isEmpty else { return "" }
        var s = all[VariantPicker.shared.pick("sass.\(level.rawValue)." + key, count: all.count)]
        for (k, v) in fill { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
        return s
    }
}

/// Puts sassy lines around Ace's answers. The answer itself never changes.
@MainActor
enum Sass {
    /// What the orb does with a sassy line.
    enum Eyes: Equatable { case roll, side, none }

    struct Dressed: Equatable {
        /// The whole message: line before, answer, line after.
        var text: String
        var before: String
        var after: String
        var eyes: Eyes
    }

    static func isOn(_ personality: String) -> Bool { personality == "sassy" }

    /// Insults and swears that never appear in anything sassy (kept in step with tools/sass_pack/build.py).
    static let banned = ["stupid", "dumb", "idiot", "moron", "ugly", "fat", "loser", "shut up", "hate you", "damn", "hell",
                         "crap", "suck", "sucks", "pathetic", "worthless", "brainless", "freak", "weirdo", "shut it",
                         "drunk", "beer", "wine"]
    /// Fine in a checked fact ("your heart pumps blood"), never in a sassy line, small talk or a joke.
    static let grim = ["kill", "die", "dead", "blood"]

    static func hasBannedWord(_ text: String, grimToo: Bool = true) -> Bool {
        let low = " " + text.lowercased().replacingOccurrences(of: #"[^a-z' ]"#, with: " ", options: .regularExpression) + " "
        return (banned + (grimToo ? grim : [])).contains { low.contains(" \($0) ") }
    }

    /// Sad, scary or serious things get Ace's normal, kind answer with no sass at all.
    static func isSerious(_ question: String) -> Bool {
        let t = " " + TextKit.normalize(question) + " "
        let phrases = ["kill myself", "kill me", "want to die", "wanna die", "hurt myself", "self harm", "suicide",
                       "being bullied", "bullied", "bully", "abuse", "emergency", "call 911", "hospital", "bleeding",
                       "i am sad", "i feel sad", "im sad", "i am scared", "i feel scared", "i am lonely", "lonely",
                       "depressed", "anxious", "anxiety", "panic", "crying", "i cried", "i am hurt", "got hurt",
                       "i am sick", "i feel sick", "passed away", "funeral", "grief", "someone died", "my pet died",
                       "nightmare", "i am upset", "i feel bad", "i am angry", "i hate myself", "nobody likes me"]
        // A phrase at the start of a word, so "bully" also catches "bullying".
        return phrases.contains { t.contains(" \($0)") }
    }

    /// Which kind of sassy line fits a reply. nil means no sass (it was already handled).
    static func category(kind: String, source: String, mood: OrbMood, cards: [AceCard]) -> String {
        // Sassy-set answers and banter already have their attitude.
        if kind == "sassy" || kind == "chat" { return "sassy" }
        if kind == "dontKnow" { return "unknown" }
        if mood == .alert { return "error" }
        for card in cards {
            switch card {
            case .timer: return "timer"
            case .weather: return "weather"
            case .recipe: return "recipe"
            case .code: return "script"
            case .translation: return "translate"
            case .trivia, .ticTacToe, .hangman, .numberGuess, .rps: return "game"
            case .steps: return "homework"
            default: break
            }
        }
        switch kind {
        case "greeting", "summon": return "hello"
        case "thanks": return "thanks"
        case "goodbye": return "bye"
        case "math", "convert", "roman", "randomNumber", "spell": return "math"
        case "timer", "alarm", "focus": return "timer"
        case "reminder", "calendarAdd", "calendarEdit", "calendarDelete", "calendarList": return "calendar"
        case "openSite", "searchTab": return "web"
        case "recipe", "recipeTweak", "shopping": return "recipe"
        case "script": return "script"
        case "translate": return "translate"
        case "game", "flashcards", "piano", "space", "typing": return "game"
        case "homework", "graph": return "homework"
        case "note", "remember", "setName", "recall", "recallAll", "forget", "teach": return "memory"
        case "voiceSpeed", "handsFree", "sounds", "call": return "settings"
        case "weather": return "weather"
        case "check", "battery", "storage", "memoryUsage", "network", "largeFiles", "findFiles", "findScreenshots",
             "describePhoto", "pcPower", "pcApp", "pcStatus", "syncNow", "ipadOnlyLimit": return "device"
        case "bedtime": return "bedtime"
        case "correction": return "correction"
        case "home": return "home"
        case "clarify": return "clarify"
        default: break
        }
        let s = source.lowercased()
        if s.contains("20 questions") || s.contains("trivia") { return "game" }
        if s.contains("recipe") { return "recipe" }
        if s.contains("script") { return "script" }
        if s.contains("phrasebook") { return "translate" }
        return "answer"
    }

    /// Kinds of question where asking again gets an extra-sassy comeback. Not games ("yes" is
    /// a normal thing to say twice), timers, hellos or settings.
    static func countsRepeats(_ category: String) -> Bool {
        ["answer", "sassy", "recipe", "weather", "script", "translate", "math", "homework"].contains(category)
    }

    /// The line kind that comes after the answer instead of before it.
    static let afterKinds: Set<String> = ["timer"]

    static func isLate(hour: Int) -> Bool { hour >= 22 || hour < 5 }

    /// Wraps an answer in sass. `repeats` is how many times the same question was asked in the last
    /// 30 minutes before this one. `level` is the slider: Mild adds a light quip to some replies,
    /// Spicy a sassy line to most, Extra a line to every reply. `chance` is a random number from 0 to 1
    /// (fixed in tests).
    static func dress(_ answer: String, category: String, repeats: Int, hour: Int, level: SassLevel = .extra,
                      pack: SassPack = .shared, chance: () -> Double = { Double.random(in: 0..<1) }) -> Dressed {
        var before = ""
        var after = ""
        if repeats > 0 {
            // A repeat always gets a comeback, gentle at Mild.
            before = pack.line("repeat.\(min(repeats, 3))", level: level)
        } else if category == "sassy" {
            // The sassy set's own answers already have their attitude.
        } else if chance() >= often(level) {
            // Mild and Spicy let some replies go by without a line.
        } else if isLate(hour: hour), ["answer", "recipe", "unknown", "math"].contains(category), chance() < 0.35 {
            before = pack.line("latenight", level: level)
        } else if afterKinds.contains(category) {
            after = pack.line(category, level: level)
        } else {
            before = pack.line(pack.lines[category] == nil ? "answer.open" : category, level: level)
        }
        // Plain answers often get a line after, too, for extra attitude.
        if after.isEmpty, category == "answer", repeats == 0, chance() < closeOften(level) {
            after = pack.line("answer.close", level: level)
        }
        let text = [before, answer, after]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: answer.contains("\n") ? "\n\n" : " ")
        let eyes: Eyes
        if before.isEmpty, after.isEmpty, category != "sassy" {
            eyes = .none
        } else if repeats > 0 {
            eyes = level == .mild ? .side : .roll
        } else if category == "unknown" || category == "error" || category == "clarify" {
            eyes = .side
        } else {
            let r = chance()
            switch level {
            case .mild: eyes = r < 0.3 ? .side : .none
            case .spicy: eyes = r < 0.4 ? .roll : r < 0.75 ? .side : .none
            case .extra: eyes = r < 0.55 ? .roll : r < 0.9 ? .side : .none
            }
        }
        return Dressed(text: text, before: before, after: after, eyes: eyes)
    }

    /// How often a reply gets a sassy line at each stop.
    static func often(_ level: SassLevel) -> Double {
        switch level {
        case .mild: return 0.35
        case .spicy: return 0.8
        case .extra: return 1
        }
    }

    /// How often a plain answer also gets a line after it.
    static func closeOften(_ level: SassLevel) -> Double {
        switch level {
        case .mild: return 0
        case .spicy: return 0.15
        case .extra: return 0.4
        }
    }

    /// How big the orb's eye-roll and side-eye are at each slider stop.
    struct EyeDrama: Equatable {
        /// 1 is the full Extra eye-roll.
        var size: Double
        /// Seconds per step of the eye-roll.
        var step: Double
        /// Seconds the eyes stay rolled up.
        var hold: Double
        /// Seconds of side-eye.
        var sideHold: Double
        /// How open the eyes are (smaller is a stronger squint).
        var squint: Double

        init(level: SassLevel) {
            switch level {
            case .mild: size = 0.55; step = 0.12; hold = 0.3; sideHold = 0.6; squint = 0.8
            case .spicy: size = 0.8; step = 0.14; hold = 0.5; sideHold = 0.85; squint = 0.7
            case .extra: size = 1; step = 0.15; hold = 0.75; sideHold = 1.1; squint = 0.62
            }
        }

        /// Down, across and up, then stuck up there.
        var rollPath: [CGPoint] {
            [CGPoint(x: -0.8, y: 0.7), CGPoint(x: -1.1, y: 0), CGPoint(x: -0.75, y: -1.2),
             CGPoint(x: 0, y: -1.5), CGPoint(x: 0.75, y: -1.2), CGPoint(x: 0.2, y: -1.45)]
                .map { CGPoint(x: $0.x * size, y: $0.y * size) }
        }
    }

    /// How a sassy line is said out loud: "*sigh*" becomes a sigh word, other *stage directions* are left out.
    static func spoken(_ line: String) -> String {
        var s = line
        let sounds: [(String, String)] = [("*sigh*", "Sigh."), ("*dramatic sigh*", "Sigh."), ("*sighs very loudly*", "Siiigh."),
                                          ("*yawn*", "Yawn."), ("*gasp*", "Gasp!"), ("*laughs in orb*", "Ha ha."),
                                          ("*clears throat*", "Ahem."), ("*taps foot*", "Tap, tap, tap.")]
        for (a, b) in sounds { s = s.replacingOccurrences(of: a, with: b) }
        // Only words between stars, so math like "2 * 3 * 4" is left alone.
        s = s.replacingOccurrences(of: #"\*[A-Za-z][A-Za-z ']{0,38}\*"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Hello lines for when the app opens.
    static func greetingLines(hour: Int, name: String, level: SassLevel = .extra, pack: SassPack = .shared) -> [String] {
        let part = Greeter.partOfDay(hour: hour)
        let n = name.trimmingCharacters(in: .whitespaces)
        let fill = ["part": part, "who": n.isEmpty ? "" : ", \(n)", "hey": n.isEmpty ? " there" : " \(n)"]
        var keys = pack.linesFor("greeting", level: level)
        if isLate(hour: hour) { keys += pack.linesFor("greeting.late", level: level) }
        return keys.map { line in
            var s = line
            for (k, v) in fill { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
            return s
        }
    }
}

/// Notices when you ask the same thing again within 30 minutes, so Sassy Ace can make a big deal of it.
struct RepeatTracker {
    static let window: TimeInterval = 30 * 60

    private struct Asked {
        var phrase: String
        var keys: Set<String>
        var at: Date
    }
    private var asked: [Asked] = []

    /// Notes a question and returns how many times it was already asked in the last 30 minutes.
    @MainActor
    mutating func note(_ question: String, at now: Date = Date()) -> Int {
        asked.removeAll { now.timeIntervalSince($0.at) > Self.window || $0.at > now }
        let phrase = SassPack.phraseKey(question)
        guard !phrase.isEmpty else { return 0 }
        let keys = Set(TextKit.keywords(question))
        let before = asked.filter { Self.same(phrase, keys, $0.phrase, $0.keys) }.count
        asked.append(Asked(phrase: phrase, keys: keys, at: now))
        if asked.count > 80 { asked.removeFirst(asked.count - 80) }
        return before
    }

    /// The same question, or nearly ("what's the capital of France?" and "capital of france").
    static func same(_ p1: String, _ k1: Set<String>, _ p2: String, _ k2: Set<String>) -> Bool {
        if p1 == p2 { return true }
        guard !k1.isEmpty, !k2.isEmpty else { return false }
        if k1 == k2 { return true }
        let overlap = Double(k1.intersection(k2).count) / Double(k1.union(k2).count)
        return k1.count >= 3 && k2.count >= 3 && overlap >= 0.8
    }
}
