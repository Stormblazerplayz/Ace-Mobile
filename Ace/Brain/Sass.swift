import Foundation

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
    }

    private struct File: Codable {
        var version: Int
        var lines: [String: [String]]
        var answers: [Entry]
    }

    let lines: [String: [String]]
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

    /// A sassy answer for a question, picked so it doesn't repeat the last few.
    func answer(_ question: String) -> (entry: Entry, text: String)? {
        guard let e = match(question), !e.a.isEmpty else { return nil }
        return (e, e.a[VariantPicker.shared.pick("sass.answer." + e.id, count: e.a.count)])
    }

    /// One line of a kind ("answer.open", "timer", "repeat.2"...), or "" when there are none.
    func line(_ key: String, fill: [String: String] = [:]) -> String {
        guard let all = lines[key], !all.isEmpty else { return "" }
        var s = all[VariantPicker.shared.pick("sass." + key, count: all.count)]
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
        if kind == "sassy" { return "sassy" }
        if kind == "dontKnow" { return "unknown" }
        if mood == .alert { return "error" }
        for card in cards {
            switch card {
            case .timer: return "timer"
            case .weather: return "weather"
            case .recipe: return "recipe"
            case .code: return "script"
            case .translation: return "translate"
            case .trivia: return "game"
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
        case "game": return "game"
        case "homework": return "homework"
        case "note", "remember", "setName", "recall", "recallAll", "forget", "teach": return "memory"
        case "voiceSpeed", "handsFree", "sounds": return "settings"
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
    /// 30 minutes before this one. `chance` is a random number from 0 to 1 (fixed in tests).
    static func dress(_ answer: String, category: String, repeats: Int, hour: Int, pack: SassPack = .shared,
                      chance: () -> Double = { Double.random(in: 0..<1) }) -> Dressed {
        var before = ""
        var after = ""
        if repeats > 0 {
            before = pack.line("repeat.\(min(repeats, 3))")
        } else if category == "sassy" {
            // The sassy set's own answers already have their attitude.
        } else if isLate(hour: hour), ["answer", "recipe", "unknown", "math"].contains(category), chance() < 0.35 {
            before = pack.line("latenight")
        } else if afterKinds.contains(category) {
            after = pack.line(category)
        } else {
            before = pack.line(pack.lines[category] == nil ? "answer.open" : category)
        }
        // Plain answers often get a line after, too, for extra attitude.
        if after.isEmpty, category == "answer", repeats == 0, chance() < 0.4 {
            after = pack.line("answer.close")
        }
        let text = [before, answer, after]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: answer.contains("\n") ? "\n\n" : " ")
        let eyes: Eyes
        if repeats > 0 {
            eyes = .roll
        } else if category == "unknown" || category == "error" || category == "clarify" {
            eyes = .side
        } else {
            let r = chance()
            eyes = r < 0.55 ? .roll : r < 0.9 ? .side : .none
        }
        return Dressed(text: text, before: before, after: after, eyes: eyes)
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
    static func greetingLines(hour: Int, name: String, pack: SassPack = .shared) -> [String] {
        let part = Greeter.partOfDay(hour: hour)
        let n = name.trimmingCharacters(in: .whitespaces)
        let fill = ["part": part, "who": n.isEmpty ? "" : ", \(n)", "hey": n.isEmpty ? " there" : " \(n)"]
        var keys = pack.lines["greeting"] ?? []
        if isLate(hour: hour) { keys += pack.lines["greeting.late"] ?? [] }
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
