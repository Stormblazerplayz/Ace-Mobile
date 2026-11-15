import Foundation

// MARK: Trivia

struct TriviaQuestion: Decodable, Equatable {
    let id: String
    let category: String
    let q: String
    let choices: [String]
    let answer: Int
    let fact: String
}

/// Ace's offline trivia: 200 questions in 10 categories (trivia.json).
enum Trivia {
    private struct File: Decodable { let questions: [TriviaQuestion] }

    static let all: [TriviaQuestion] = {
        guard let url = Bundle.main.url(forResource: "trivia", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.questions
    }()

    /// Questions per round.
    static let roundLength = 5

    static var categories: [String] {
        var out: [String] = []
        for q in all where !out.contains(q.category) { out.append(q.category) }
        return out
    }

    /// Other words for each category ("planets" -> Space, "the body" -> Human Body).
    static let categoryWords: [String: [String]] = [
        "Space": ["space", "planets", "planet", "stars", "the solar system", "solar system", "astronomy", "the moon"],
        "Animals": ["animals", "animal", "pets", "wildlife", "nature"],
        "Science": ["science", "chemistry", "physics", "experiments"],
        "Earth": ["earth", "the earth", "weather", "volcanoes", "oceans", "the planet earth"],
        "Human Body": ["the human body", "human body", "the body", "body", "bones", "health"],
        "History": ["history", "the past", "inventions", "inventors"],
        "Geography": ["geography", "countries", "maps", "capitals", "the world", "flags"],
        "Sports": ["sports", "sport", "soccer", "football", "basketball", "the olympics", "olympics"],
        "Technology": ["technology", "tech", "computers", "coding", "gadgets", "video games", "games"],
        "Food": ["food", "foods", "cooking", "fruit", "snacks"],
    ]

    /// The category a request names ("quiz me on space" -> Space), or nil for any.
    static func category(in text: String) -> String? {
        let t = TextKit.normalize(text)
        var best: (String, Int)?
        for (cat, words) in categoryWords {
            for w in words where Rx.matches(#"(?<![a-z])"# + NSRegularExpression.escapedPattern(for: w) + #"(?![a-z])"#, t) {
                if best == nil || w.count > best!.1 { best = (cat, w.count) }
            }
        }
        return best?.0
    }

    /// A new round: questions you haven't had lately, from one category or all of them.
    static func newRound(category: String?, avoiding recent: Set<String>, count: Int = roundLength) -> [TriviaQuestion] {
        let pool = all.filter { category == nil || $0.category == category }
        let fresh = pool.filter { !recent.contains($0.id) }
        var picked = Array((fresh.count >= count ? fresh : pool).shuffled().prefix(count))
        if picked.isEmpty { picked = Array(all.shuffled().prefix(count)) }
        return picked
    }

    static func letter(_ i: Int) -> String { ["A", "B", "C", "D", "E", "F"][min(max(i, 0), 5)] }

    /// "Which planet...? A) Venus, B) Mars, C) Mercury or D) Jupiter?"
    static func spoken(_ q: TriviaQuestion) -> String {
        let options = q.choices.enumerated().map { "\(letter($0.offset)): \($0.element)" }
        return q.q + " " + TextKit.joinList(options, last: "or") + "."
    }

    /// The choice someone picked: a letter ("b", "it's b"), a number or "second", or the answer itself ("mars").
    static func pick(_ text: String, for q: TriviaQuestion) -> Int? {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        let lead = #"^(?:(?:i think |i think it is |i say |i pick |i choose |i will go with |my answer is |the answer is |answer |it is |is it |maybe |definitely |um |uh |hmm |option |letter |choice )+)?"#
        let tail = #"(?:\s+(?:please|final answer|is my answer|is the answer))?\??$"#
        // Said exactly ("4" when the choices are numbers, "mars").
        if let i = q.choices.firstIndex(where: { TextKit.normalize($0) == t }) { return i }
        if let g = Rx.groups(lead + #"(?:the )?(?:(a|b|c|d)|(1|2|3|4|one|two|three|four|first|second|third|fourth|last))(?: one| answer| option)?"# + tail, t) {
            if let l = g.first, !l.isEmpty, let i = ["a", "b", "c", "d"].firstIndex(of: l), i < q.choices.count { return i }
            let words = ["1": 0, "2": 1, "3": 2, "4": 3, "one": 0, "two": 1, "three": 2, "four": 3,
                         "first": 0, "second": 1, "third": 2, "fourth": 3, "last": q.choices.count - 1]
            if g.count > 1, let i = words[g[1]], i < q.choices.count { return i }
        }
        // The answer itself. The longest choice that fits wins ("mars" vs "mars rover").
        var best: (Int, Int)?
        for (i, c) in q.choices.enumerated() {
            let n = TextKit.normalize(c)
            guard !n.isEmpty else { continue }
            let fits = t == n || Rx.matches(#"(?<![a-z0-9])"# + NSRegularExpression.escapedPattern(for: n) + #"(?![a-z0-9])"#, t)
            if fits, best == nil || n.count > best!.1 { best = (i, n.count) }
        }
        return best?.0
    }
}

struct TriviaRound: Equatable {
    var category: String?
    var questions: [TriviaQuestion]
    var index = 0
    var score = 0

    var current: TriviaQuestion? { index < questions.count ? questions[index] : nil }
}

// MARK: 20 questions (Ace guesses what you're thinking of)

/// Ace asks yes-or-no questions and guesses the thing you picked. Things it doesn't know, it learns.
enum TwentyQuestions {
    struct Ask: Decodable, Equatable {
        let id: String
        let ask: String
    }

    struct Thing: Codable, Equatable {
        var name: String
        var answers: [String: Double]
    }

    private struct File: Decodable {
        let questions: [Ask]
        let things: [Thing]
    }

    private static let file: File? = {
        guard let url = Bundle.main.url(forResource: "twenty_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(File.self, from: data)
    }()

    static var questions: [Ask] { file?.questions ?? [] }
    static var builtIn: [Thing] { file?.things ?? [] }

    // Things you taught Ace ("it was a hedgehog"), kept on this device.
    private static let learnedKey = "ace.twentyQuestions.learned"

    static var learned: [Thing] {
        guard let data = UserDefaults.standard.data(forKey: learnedKey),
              let things = try? JSONDecoder().decode([Thing].self, from: data) else { return [] }
        return things
    }

    static func learn(_ name: String, answers: [String: Double]) {
        var list = learned.filter { $0.name.lowercased() != name.lowercased() }
        list.append(Thing(name: name, answers: answers))
        if let data = try? JSONEncoder().encode(Array(list.suffix(200))) {
            UserDefaults.standard.set(data, forKey: learnedKey)
        }
    }

    static func forgetLearned() { UserDefaults.standard.removeObject(forKey: learnedKey) }

    /// Built-in things plus learned ones (a learned thing replaces a built-in one with the same name).
    static func allThings() -> [Thing] {
        let mine = learned
        let names = Set(mine.map { $0.name.lowercased() })
        return builtIn.filter { !names.contains($0.name.lowercased()) } + mine
    }

    /// How sure Ace is about each thing, from the answers so far. Wrong guesses are ruled out.
    static func weights(_ things: [Thing], answers: [Answer], wrong: Set<String>) -> [Double] {
        things.map { t in
            if wrong.contains(t.name.lowercased()) { return 0 }
            var penalty = 0.0
            for a in answers {
                guard let v = a.value else { continue }
                penalty += abs(v - (t.answers[a.question] ?? 0.5))
            }
            return exp(-4 * penalty)
        }
    }

    /// The question that splits the likely things best (the most spread-out answers).
    static func nextQuestion(_ things: [Thing], weights: [Double], asked: Set<String>) -> Ask? {
        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }
        var best: (Double, Ask)?
        for q in questions where !asked.contains(q.id) {
            var mean = 0.0
            for (t, w) in zip(things, weights) { mean += w * (t.answers[q.id] ?? 0.5) }
            mean /= total
            var spread = 0.0
            for (t, w) in zip(things, weights) {
                let d = (t.answers[q.id] ?? 0.5) - mean
                spread += w * d * d
            }
            spread /= total
            if spread > 1e-6, best == nil || spread > best!.0 { best = (spread, q) }
        }
        return best?.1
    }

    /// Most questions (and guesses) Ace gets.
    static let maxQuestions = 20

    enum Move: Equatable {
        case ask(Ask)
        case guess(String)
        case giveUp
    }

    /// What Ace does next: guess when it's fairly sure (or nearly out of questions), otherwise ask the question that splits things best.
    static func nextMove(_ round: TwentyRound, things: [Thing]) -> Move {
        guard round.used < maxQuestions else { return .giveUp }
        let w = weights(things, answers: round.answers, wrong: round.wrong)
        let total = w.reduce(0, +)
        guard total > 0, let top = w.indices.max(by: { w[$0] < w[$1] }) else { return .giveUp }
        let sure = w[top] / total
        let q = nextQuestion(things, weights: w, asked: Set(round.answers.map(\.question)))
        if (sure > 0.6 && round.answers.count >= 3) || q == nil || round.used >= maxQuestions - 1 {
            return .guess(things[top].name)
        }
        return .ask(q!)
    }

    /// "it was a hedgehog" -> "a hedgehog". Nil when it sounds like a question or a request instead.
    static func thingName(_ text: String) -> String? {
        if text.trimmingCharacters(in: .whitespaces).hasSuffix("?") { return nil }
        var t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        for p in ["i was thinking of ", "i was thinking about ", "i thought of ", "i picked ", "i chose ", "it was ", "it is ",
                  "its ", "that was ", "the answer is ", "the answer was ", "oh "] where t.hasPrefix(p) {
            t = String(t.dropFirst(p.count))
        }
        t = t.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, t.count <= 40, t.split(separator: " ").count <= 5 else { return nil }
        if Rx.matches(#"^(what|who|why|how|when|where|can|could|would|will|do|does|is|are|tell|show|turn|set|play|stop|open)\b"#, t) { return nil }
        if IntentRouter.parse(t) != nil { return nil }
        let hasArticle = ["a ", "an ", "the ", "some ", "my "].contains { t.hasPrefix($0) }
        let plural = t.count > 3 && t.hasSuffix("s") && !t.hasSuffix("ss") && !t.hasSuffix("us")
        if !hasArticle && !plural {
            t = ("aeiou".contains(t.first ?? "x") ? "an " : "a ") + t
        }
        return t
    }

    struct Answer: Equatable {
        var question: String
        /// 1 is yes, 0 is no, 0.5 is "sometimes"; nil is "I don't know".
        var value: Double?
    }

    enum Reply: Equatable { case value(Double), dontKnow }

    /// Reads a yes, no, maybe or "I don't know".
    static func reply(_ text: String) -> Reply? {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        if Rx.matches(#"^(i do not know|do not know|i dont know|dont know|i dunno|dunno|idk|not sure|i am not sure|no idea|i have no idea|unsure|skip|pass|no clue|who knows)\b"#, t) { return .dontKnow }
        if Rx.matches(#"^(probably not|likely not|i do not think so|i dont think so|not really|not usually|mostly not|rarely|hardly)\b"#, t) { return .value(0.15) }
        if Rx.matches(#"^(probably|likely|usually|mostly|i think so|i guess so|pretty much|most of them|often)\b"#, t) { return .value(0.85) }
        if Rx.matches(#"^(maybe|sometimes|sort of|kind of|kinda|partly|possibly|it depends|depends|a little|a bit|some are|some of them|half|50 50|either)\b"#, t) { return .value(0.5) }
        if Rx.matches(#"^(it is not|it isnt|it is no|it does not|it doesnt|it can not|it cant|it has not|it hasnt|not at all|not)\b"#, t) { return .value(0) }
        if Rx.matches(#"^(yes|yeah|yep|yup|ya|yea|ye|sure|correct|right|it is|it does|it can|it has|of course|definitely|absolutely|totally|y|affirmative|true|you got it|uh huh)\b"#, t) { return .value(1) }
        if Rx.matches(#"^(no|nope|nah|nay|n|it is not|it isnt|it does not|it can not|it cant|never|not at all|negative|false|no way|wrong)\b"#, t) { return .value(0) }
        return nil
    }
}

struct TwentyRound: Equatable {
    enum Step: Equatable {
        case asking(String)        // waiting for an answer to this question id
        case guessing(String)      // "Is it a dog?"
        case whatWasIt             // Ace lost: "What were you thinking of?"
    }

    var answers: [TwentyQuestions.Answer] = []
    var wrong: Set<String> = []
    /// Questions and guesses used so far (20 at most).
    var used = 0
    var step: Step = .asking("")
}

enum ActiveGame: Equatable {
    case trivia(TriviaRound)
    case twenty(TwentyRound)

    var name: String {
        switch self {
        case .trivia: return "trivia"
        case .twenty: return "20 questions"
        }
    }
}

/// The card for a trivia question: tap a choice to answer.
struct TriviaCard: Codable, Equatable {
    /// Matches Brain.gameToken while this is the question being played, so old cards stop taking taps.
    var token: String
    var number: Int
    var total: Int
    var category: String
    var question: String
    var choices: [String]
    var score: Int
}
