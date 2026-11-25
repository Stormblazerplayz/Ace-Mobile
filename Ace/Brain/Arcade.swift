import Foundation

// MARK: The games in Ace Games

/// Every game in the Ace Games screen. Trivia and 20 questions were already in Ace;
/// tic-tac-toe, hangman, guess the number and rock paper scissors are new.
enum ArcadeGame: String, CaseIterable, Codable {
    case ticTacToe = "tictactoe"
    case hangman
    case trivia
    case twenty
    case numberGuess = "number"
    case rps

    var title: String {
        switch self {
        case .ticTacToe: return "Tic-tac-toe"
        case .hangman: return "Hangman"
        case .trivia: return "Trivia"
        case .twenty: return "20 questions"
        case .numberGuess: return "Guess the number"
        case .rps: return "Rock paper scissors"
        }
    }

    /// One line under the title in the games screen.
    var blurb: String {
        switch self {
        case .ticTacToe: return "Get three in a row before Ace does."
        case .hangman: return "Guess the word one letter at a time."
        case .trivia: return "Five questions from over 4,000."
        case .twenty: return "Think of something. Ace guesses it."
        case .numberGuess: return "Find Ace's number from 1 to 100."
        case .rps: return "First to two wins."
        }
    }

    var symbol: String {
        switch self {
        case .ticTacToe: return "number"
        case .hangman: return "textformat.abc"
        case .trivia: return "questionmark.bubble.fill"
        case .twenty: return "brain.head.profile"
        case .numberGuess: return "dice.fill"
        case .rps: return "scissors"
        }
    }

    /// What the games screen sends when you tap the tile (the same words work by voice).
    var ask: String {
        switch self {
        case .ticTacToe: return "Play tic-tac-toe"
        case .hangman: return "Play hangman"
        case .trivia: return "Play trivia"
        case .twenty: return "Play 20 questions"
        case .numberGuess: return "Play guess the number"
        case .rps: return "Play rock paper scissors"
        }
    }

    /// The name in the chat's "source" line, so Sassy mode treats it as a game.
    var source: String {
        switch self {
        case .ticTacToe: return "tic-tac-toe"
        case .hangman: return "hangman"
        case .trivia: return "trivia"
        case .twenty: return "20 questions"
        case .numberGuess: return "guess the number"
        case .rps: return "rock paper scissors"
        }
    }
}

/// How a game ended, from your side.
enum GameOutcome: String, Codable, Equatable {
    case playing, won, lost, draw
}

// MARK: Scores

/// Wins, losses and streaks for each game, kept on this device (trivia keeps its own records too).
final class GameStats {
    static let shared = GameStats()

    struct Score: Codable, Equatable {
        var wins = 0
        var losses = 0
        var draws = 0
        /// Wins in a row right now, and the most ever.
        var streak = 0
        var bestStreak = 0
        /// Guess the number: the fewest guesses it took you. Hangman: the fewest misses in a win.
        var best: Int?

        var played: Int { wins + losses + draws }
    }

    private(set) var scores: [String: Score] = [:]
    private let key: String

    init(key: String = "ace.games.scores") {
        self.key = key
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([String: Score].self, from: data) {
            scores = saved
        }
    }

    func score(_ game: ArcadeGame) -> Score { scores[game.rawValue] ?? Score() }

    /// Saves a finished game. `best` is a "lower is better" number (guesses or misses), only kept for wins.
    @discardableResult
    func record(_ game: ArcadeGame, _ outcome: GameOutcome, best: Int? = nil) -> Score {
        var s = score(game)
        switch outcome {
        case .won:
            s.wins += 1
            s.streak += 1
            s.bestStreak = max(s.bestStreak, s.streak)
            if let best { s.best = min(s.best ?? best, best) }
        case .lost:
            s.losses += 1
            s.streak = 0
        case .draw:
            s.draws += 1
        case .playing:
            return s
        }
        scores[game.rawValue] = s
        save()
        return s
    }

    var totalWins: Int { scores.values.reduce(0) { $0 + $1.wins } }
    var totalPlayed: Int { scores.values.reduce(0) { $0 + $1.played } }
    var bestStreak: Int { scores.values.map(\.bestStreak).max() ?? 0 }

    func clearAll() {
        scores = [:]
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(scores) { UserDefaults.standard.set(data, forKey: key) }
    }
}

// MARK: Tic-tac-toe

enum TicTacToe {
    enum Level: String, Codable, CaseIterable {
        case easy, normal, hard

        /// "medium" is normal, and "impossible" is hard.
        init?(word: String) {
            switch word {
            case "easy", "baby", "beginner": self = .easy
            case "normal", "medium", "regular": self = .normal
            case "hard", "impossible", "expert", "pro": self = .hard
            default: return nil
            }
        }
    }

    /// The 8 ways to get three in a row.
    static let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    /// What Ace calls each square, top left to bottom right.
    static let names = ["top left", "top middle", "top right", "middle left", "center", "middle right",
                        "bottom left", "bottom middle", "bottom right"]

    /// The winner and their row, if someone has three in a row.
    static func winner(_ board: [String]) -> (mark: String, line: [Int])? {
        for line in lines {
            let a = board[line[0]]
            if !a.isEmpty, a == board[line[1]], a == board[line[2]] { return (a, line) }
        }
        return nil
    }

    static func free(_ board: [String]) -> [Int] {
        board.indices.filter { board[$0].isEmpty }
    }

    /// The square that wins right now for `mark`, if there is one.
    static func winningSquare(_ board: [String], for mark: String) -> Int? {
        for i in free(board) {
            var b = board
            b[i] = mark
            if winner(b)?.mark == mark { return i }
        }
        return nil
    }

    /// Ace's move. Easy plays loosely, normal never misses a win or a block but can slip up
    /// otherwise, and hard plays perfectly (you can only draw). `roll` gives numbers from 0 to 1.
    static func aceMove(_ board: [String], ace: String, level: Level, roll: () -> Double = { Double.random(in: 0..<1) }) -> Int? {
        let open = free(board)
        guard !open.isEmpty else { return nil }
        let you = ace == "X" ? "O" : "X"
        func pick(_ list: [Int]) -> Int { list[min(list.count - 1, Int(roll() * Double(list.count)))] }
        switch level {
        case .easy:
            if roll() < 0.5, let w = winningSquare(board, for: ace) { return w }
            if roll() < 0.3, let b = winningSquare(board, for: you) { return b }
            return pick(open)
        case .normal:
            if let w = winningSquare(board, for: ace) { return w }
            if let b = winningSquare(board, for: you) { return b }
            if roll() < 0.35 { return pick(open) }
            return perfectMove(board, ace: ace, roll: roll)
        case .hard:
            return perfectMove(board, ace: ace, roll: roll)
        }
    }

    /// The best square by looking at every way the game can go. Ties are broken with `roll`.
    static func perfectMove(_ board: [String], ace: String, roll: () -> Double = { Double.random(in: 0..<1) }) -> Int? {
        let open = free(board)
        guard !open.isEmpty else { return nil }
        // An empty board: every square draws with perfect play, so take the center or a corner.
        if open.count == 9 {
            let good = [4, 0, 2, 6, 8]
            return good[min(good.count - 1, Int(roll() * Double(good.count)))]
        }
        var best: [Int] = []
        var bestScore = Int.min
        for i in open {
            var b = board
            b[i] = ace
            let s = minimax(b, turn: ace == "X" ? "O" : "X", ace: ace, depth: 1)
            if s > bestScore {
                bestScore = s
                best = [i]
            } else if s == bestScore {
                best.append(i)
            }
        }
        return best[min(best.count - 1, Int(roll() * Double(best.count)))]
    }

    /// Score for Ace: winning sooner is better, losing later is better.
    private static func minimax(_ board: [String], turn: String, ace: String, depth: Int) -> Int {
        if let w = winner(board) { return w.mark == ace ? 10 - depth : depth - 10 }
        let open = free(board)
        if open.isEmpty { return 0 }
        let next = turn == "X" ? "O" : "X"
        var best = turn == ace ? Int.min : Int.max
        for i in open {
            var b = board
            b[i] = turn
            let s = minimax(b, turn: next, ace: ace, depth: depth + 1)
            best = turn == ace ? max(best, s) : min(best, s)
        }
        return best
    }

    /// The square someone means: "top left", "the middle", "bottom right corner", "5", "number 7", "a1".
    static func square(from text: String) -> Int? {
        var t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        t = t.replacingOccurrences(of: #"^(?:(?:i will |i'll |i want |i pick |i choose |i go |i will go |i'll go |let me go |let me take |put (?:my |an |a )?(?:x|o|it|one) |put it |go |take |mark |play |my move is |how about |okay |ok |um |uh |hmm )+)"#,
                                   with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"^(?:in |on |at )?(?:the )?"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?: please| one| square| spot| box| space| corner| side| cell| for me)+$"#, with: "", options: .regularExpression)
        t = t.trimmingCharacters(in: .whitespaces)
        let numbers = ["1": 0, "2": 1, "3": 2, "4": 3, "5": 4, "6": 5, "7": 6, "8": 7, "9": 8,
                       "one": 0, "two": 1, "three": 2, "four": 3, "five": 4, "six": 5, "seven": 6, "eight": 7, "nine": 8,
                       "number 1": 0, "number 2": 1, "number 3": 2, "number 4": 3, "number 5": 4,
                       "number 6": 5, "number 7": 6, "number 8": 7, "number 9": 8]
        if let n = numbers[t] { return n }
        // Grid names like a spreadsheet: a1 is top left, c3 is bottom right.
        if let g = Rx.groups(#"^([abc])\s?([123])$"#, t), g.count == 2,
           let col = ["a", "b", "c"].firstIndex(of: g[0]), let row = Int(g[1]) {
            return (row - 1) * 3 + col
        }
        let rowWords: [(String, Int)] = [("top", 0), ("upper", 0), ("middle", 1), ("center", 1), ("centre", 1), ("bottom", 2), ("lower", 2)]
        let colWords: [(String, Int)] = [("left", 0), ("middle", 1), ("center", 1), ("centre", 1), ("right", 2)]
        let parts = t.split(separator: " ").map(String.init).filter { $0 != "and" }
        if parts.count == 1 {
            switch parts[0] {
            case "center", "centre", "middle": return 4
            case "top", "up": return 1
            case "bottom", "down": return 7
            case "left": return 3
            case "right": return 5
            default: return nil
            }
        }
        guard parts.count == 2 else { return nil }
        // Row then column ("top left"), or column then row ("left top", "middle top").
        let a = parts[0], b = parts[1]
        let columnFirst = ["left", "right"].contains(a) || ["top", "upper", "bottom", "lower"].contains(b)
        if columnFirst {
            guard let c = colWords.first(where: { $0.0 == a })?.1, let r = rowWords.first(where: { $0.0 == b })?.1 else { return nil }
            return r * 3 + c
        }
        guard let r = rowWords.first(where: { $0.0 == a })?.1, let c = colWords.first(where: { $0.0 == b })?.1 else { return nil }
        return r * 3 + c
    }
}

struct TicTacToeRound: Equatable {
    var board = Array(repeating: "", count: 9)
    var you = "X"
    var level: TicTacToe.Level = .normal
    var aceLast: Int?

    var ace: String { you == "X" ? "O" : "X" }
}

/// The tic-tac-toe board in the chat. Tap a free square to move.
struct TicTacToeCard: Codable, Equatable {
    var token: String
    var board: [String]
    var you: String
    var level: String
    var outcome: GameOutcome
    var winLine: [Int]?
    var aceLast: Int?
    var wins: Int
    var losses: Int
    var draws: Int
}

// MARK: Hangman

enum Hangman {
    /// Misses before the drawing is finished and the round is lost.
    static let maxMisses = 6

    /// Words to guess, by topic. Real everyday words, all letters, no spaces.
    static let words: [String: [String]] = [
        "Animals": ["elephant", "giraffe", "penguin", "dolphin", "kangaroo", "octopus", "cheetah", "hamster", "squirrel",
                    "tortoise", "crocodile", "flamingo", "gorilla", "jellyfish", "koala", "leopard", "lobster", "ostrich",
                    "panther", "parrot", "rabbit", "raccoon", "rhinoceros", "scorpion", "turtle", "walrus", "zebra", "hedgehog"],
        "Space": ["planet", "galaxy", "asteroid", "comet", "nebula", "rocket", "astronaut", "telescope", "satellite", "meteor",
                  "jupiter", "saturn", "mercury", "neptune", "uranus", "eclipse", "orbit", "gravity", "universe", "constellation",
                  "spaceship", "supernova", "moon", "venus"],
        "Food": ["pizza", "spaghetti", "pancake", "sandwich", "burrito", "pretzel", "avocado", "broccoli", "pineapple",
                 "strawberry", "watermelon", "blueberry", "cupcake", "popcorn", "noodles", "omelette", "cucumber", "lasagna",
                 "muffin", "waffle", "cookie", "banana", "cheese", "carrot", "potato", "tomato"],
        "Sports": ["soccer", "basketball", "baseball", "football", "hockey", "tennis", "volleyball", "swimming", "skateboard",
                   "karate", "gymnastics", "archery", "bowling", "cycling", "surfing", "skiing", "badminton", "wrestling",
                   "marathon", "trophy", "referee", "goalkeeper", "stadium", "olympics"],
        "Nature": ["volcano", "rainbow", "thunder", "lightning", "waterfall", "mountain", "glacier", "desert", "jungle",
                   "canyon", "island", "tornado", "hurricane", "meadow", "forest", "river", "ocean", "blizzard", "earthquake",
                   "sunflower", "cactus", "mushroom", "coral", "pebble"],
        "Science": ["magnet", "electric", "molecule", "battery", "microscope", "fossil", "crystal", "experiment", "oxygen",
                    "skeleton", "energy", "friction", "chemical", "dinosaur", "laboratory", "particle", "atom",
                    "photosynthesis", "evaporation", "volume", "thermometer"],
        "Technology": ["computer", "keyboard", "internet", "robot", "software", "printer", "headphones", "tablet", "camera",
                       "password", "website", "satellite", "battery", "charger", "microphone", "speaker", "joystick",
                       "controller", "processor", "download", "algorithm", "pixel"],
        "Countries": ["canada", "mexico", "brazil", "france", "germany", "italy", "spain", "japan", "china", "india",
                      "egypt", "kenya", "australia", "argentina", "norway", "sweden", "ireland", "portugal", "greece",
                      "iceland", "peru", "chile", "vietnam", "thailand"],
    ]

    static var categories: [String] { words.keys.sorted() }

    /// The topic a request names ("hangman with animals" -> Animals), or nil for any.
    static func category(in text: String) -> String? {
        let t = TextKit.normalize(text)
        let extra: [String: [String]] = [
            "Animals": ["animal", "animals", "pets"], "Space": ["space", "planets", "planet", "stars"],
            "Food": ["food", "foods", "snacks", "fruit"], "Sports": ["sport", "sports"],
            "Nature": ["nature", "weather", "earth"], "Science": ["science"],
            "Technology": ["technology", "tech", "computers"], "Countries": ["countries", "country", "geography", "the world"],
        ]
        for (cat, list) in extra.sorted(by: { $0.key < $1.key }) {
            for w in list where Rx.matches(#"(?<![a-z])"# + NSRegularExpression.escapedPattern(for: w) + #"(?![a-z])"#, t) {
                return cat
            }
        }
        return nil
    }

    /// A word you haven't had lately.
    static func pick(category: String?, avoiding recent: Set<String>) -> (word: String, category: String) {
        let cats = category.map { [$0] } ?? categories
        let pool = cats.flatMap { c in (words[c] ?? []).map { ($0, c) } }
        let fresh = pool.filter { !recent.contains($0.0) }
        let choice = (fresh.isEmpty ? pool : fresh).randomElement() ?? ("planet", "Space")
        return (choice.0, choice.1)
    }

    /// How each letter sounds, so "bee" or "the letter bee" by voice means B.
    static let sounds: [String: String] = [
        "ay": "a", "bee": "b", "be": "b", "see": "c", "sea": "c", "cee": "c", "dee": "d", "ef": "f", "eff": "f",
        "gee": "g", "aitch": "h", "eye": "i", "jay": "j", "kay": "k", "el": "l", "ell": "l", "em": "m", "en": "n",
        "oh": "o", "pee": "p", "pea": "p", "cue": "q", "queue": "q", "are": "r", "ar": "r", "es": "s", "ess": "s",
        "tee": "t", "tea": "t", "you": "u", "vee": "v", "double u": "w", "double you": "w", "ex": "x", "why": "y",
        "zee": "z", "zed": "z",
    ]

    enum Guess: Equatable {
        case letter(Character)
        case word(String)
    }

    /// A letter ("e", "letter e", "is there an e", "bee") or the whole word ("is it elephant").
    static func guess(from text: String) -> Guess? {
        var t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        t = t.replacingOccurrences(of: #"^(?:(?:okay |ok |um |uh |hmm |i guess |i will guess |i'll guess |guess |i pick |i choose |i say |my guess is |try |how about |what about |is there (?:an? )?|does it have (?:an? )?|do you have (?:an? )?|any |the )+)"#,
                                   with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?: please| in it| in the word)+$"#, with: "", options: .regularExpression)
        if let g = Rx.groups(#"^(?:the )?letter ([a-z]+(?: [a-z]+)?)$"#, t), let w = g.first {
            if w.count == 1, let c = w.first { return .letter(c) }
            if let s = sounds[w], let c = s.first { return .letter(c) }
            return nil
        }
        if t.count == 1, let c = t.first, c.isLetter, c.isASCII { return .letter(c) }
        if let s = sounds[t], let c = s.first { return .letter(c) }
        let word = t.replacingOccurrences(of: #"^(?:is it |it is |the word is |the answer is |is the word |i think it is |i think the word is |is it an? |it is an? )"#,
                                          with: "", options: .regularExpression)
        if Rx.matches(#"^[a-z]{2,20}$"#, word) { return .word(word) }
        return nil
    }

    /// "_ L E _ _ A _ _" for showing, one string per letter ("" means not found yet).
    static func shown(_ word: String, guessed: [Character]) -> [String] {
        word.map { guessed.contains($0) ? String($0).uppercased() : "" }
    }
}

struct HangmanRound: Equatable {
    var word: String
    var category: String
    var guessed: [Character] = []
    var misses = 0

    var solved: Bool { word.allSatisfy { guessed.contains($0) } }
    var found: Int { word.filter { guessed.contains($0) }.count }
}

/// The hangman card: the word with blanks, the drawing and a letter keyboard.
struct HangmanCard: Codable, Equatable {
    var token: String
    var category: String
    /// One entry per letter of the word: the letter once found, or "".
    var letters: [String]
    /// Letters tried so far, in capitals.
    var guessed: [String]
    var misses: Int
    var maxMisses: Int
    var outcome: GameOutcome
    /// The whole word, only once the round is over.
    var word: String?
    var wins: Int
}

// MARK: Guess the number

enum NumberGuess {
    static let low = 1
    static let high = 100
    /// Enough to always find it by halving (2^7 = 128).
    static let maxGuesses = 7

    /// A number someone said: "50", "is it 37", "seventy two", "how about 8".
    static func number(from text: String) -> Int? {
        var t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        t = t.replacingOccurrences(of: #"^(?:(?:okay |ok |um |uh |hmm |is it |it is |i guess |i will guess |i'll guess |guess |i say |i pick |i choose |my guess is |how about |what about |try |maybe |then |number |the number |is the number |i think it is |i think )+)"#,
                                   with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?: please| then| maybe)+$"#, with: "", options: .regularExpression)
        t = MathEval.numberWordsToDigits(t)
        guard let g = Rx.groups(#"^(\d{1,4})$"#, t), let s = g.first else { return nil }
        return Int(s)
    }

    /// "Hot", "warm" or nil, from how far off a guess is.
    static func warmth(_ guess: Int, secret: Int) -> String? {
        let d = abs(guess - secret)
        if d <= 3 { return "hot" }
        if d <= 10 { return "warm" }
        return nil
    }
}

struct NumberRound: Equatable {
    var secret: Int
    var guesses: [Int] = []
    var low = NumberGuess.low
    var high = NumberGuess.high

    var left: Int { NumberGuess.maxGuesses - guesses.count }
}

/// Guess the number: how close you are, and the range that's left.
struct NumberGuessCard: Codable, Equatable {
    var token: String
    var low: Int
    var high: Int
    var guesses: [Int]
    /// "higher" or "lower" after each guess.
    var hints: [String]
    var left: Int
    var outcome: GameOutcome
    /// Shown once the round is over.
    var secret: Int?
    var best: Int?
    /// How close the last guess was: "hot", "warm" or nil.
    var heat: String?
}

// MARK: Rock paper scissors

enum RPS {
    static let moves = ["rock", "paper", "scissors"]
    /// First to this many wins takes the match.
    static let target = 2

    static func emoji(_ move: String) -> String {
        switch move {
        case "rock": return "🪨"
        case "paper": return "📄"
        case "scissors": return "✂️"
        default: return "❔"
        }
    }

    /// 1 when `a` beats `b`, -1 when it loses, 0 for a tie.
    static func beats(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let wins = ["rock": "scissors", "paper": "rock", "scissors": "paper"]
        return wins[a] == b ? 1 : -1
    }

    static func move(from text: String) -> String? {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        if text.contains("🪨") || text.contains("✊") { return "rock" }
        if text.contains("📄") || text.contains("✋") { return "paper" }
        if text.contains("✂️") || text.contains("✌") { return "scissors" }
        let words = t.split(separator: " ").map(String.init)
        guard words.count <= 5 else { return nil }
        var found: Set<String> = []
        for w in words {
            switch w {
            case "rock", "rocks", "stone", "fist": found.insert("rock")
            case "paper", "papers", "sheet": found.insert("paper")
            case "scissors", "scissor", "sissors", "scizzors", "scisors": found.insert("scissors")
            default: break
            }
        }
        return found.count == 1 ? found.first : nil
    }
}

struct RPSRound: Equatable {
    var you = 0
    var ace = 0
    var rounds = 0
}

/// One throw of rock paper scissors and the match score.
struct RPSCard: Codable, Equatable {
    var token: String
    var you: String?
    var ace: String?
    /// "win", "lose" or "tie" for this throw.
    var result: String?
    var yourScore: Int
    var aceScore: Int
    var outcome: GameOutcome
    var round: Int
}

// MARK: Asking for a game

/// Reads asks for the Ace Games games and screen. Returns what `Intent.game` carries:
/// "tictactoe" (or "tictactoe:hard"), "hangman" (or "hangman:Animals"), "number", "rps",
/// "arcade" (the list of games), "arcade:open" (the games screen) and "arcade:scores".
enum ArcadeAsk {
    private static let lead = #"^(?:(?:can we|can you|could we|could you|let us|lets|i want to|want to|i would like to|i'd like to|please|ok|okay|yes|yeah|sure|hey ace|ace|now|so)\s+)*"#
    private static let play = #"(?:(?:play|start|do|have|try|begin)\s+(?:a\s+|an\s+|another\s+|some\s+|the\s+|one more\s+|a new\s+|new\s+)?(?:(?:quick\s+|fun\s+|new\s+)?(?:game|round|match) of\s+)?)"#
    private static let tail = #"(?:\s+(?:again|with me|against you|with you|vs you|versus you|now|please|together|game|instead|one more time))*$"#

    static func parse(_ t: String) -> String? {
        // Tic-tac-toe, with an optional level ("tic tac toe on hard").
        let ttt = #"(?:tic[ -]?tac[ -]?toe|tick[ -]?tack[ -]?toe|noughts and crosses|naughts and crosses|x s and o s|xs and os|x and o s|x and os)"#
        if let g = Rx.groups(lead + play + "?" + ttt + #"(?:\s+(?:on\s+|in\s+)?(easy|normal|medium|hard|impossible|expert)(?:\s+mode|\s+level|\s+difficulty)?)?"# + tail, t) {
            if let w = g.first, let level = TicTacToe.Level(word: w) { return "tictactoe:" + level.rawValue }
            return "tictactoe"
        }
        if let g = Rx.groups(lead + play + "?" + #"(easy|normal|medium|hard|impossible|expert)\s+"# + ttt + tail, t),
           let w = g.first, let level = TicTacToe.Level(word: w) {
            return "tictactoe:" + level.rawValue
        }
        // Hangman, with an optional topic ("hangman with animals").
        if let g = Rx.groups(lead + play + "?" + #"hangman(?:\s+game)?(?:\s+(?:about|with|on|using|for|from)\s+(.+?))?"# + tail, t) {
            if let topic = g.first, !topic.isEmpty, let cat = Hangman.category(in: topic) { return "hangman:" + cat }
            return "hangman"
        }
        // Guess the number.
        let number = #"(?:guess the number|guess my number|guess your number|guess a number|guess the number game|number guessing(?: game)?|number guess(?:ing)?(?: game)?|guessing number game|higher or lower|higher lower)"#
        if Rx.matches(lead + play + "?" + number + tail, t)
            || Rx.matches(#"^(?:can i|let me) guess (?:a|your|the) number$"#, t)
            || Rx.matches(#"^think of a number (?:and|so) (?:i will|i'll|i can|let me) guess(?: it)?$"#, t) {
            return "number"
        }
        // Rock paper scissors.
        if Rx.matches(lead + play + "?" + #"rocks? papers? (?:and )?scissors?(?: shoot)?"# + tail, t) {
            return "rps"
        }
        // Scores across the games.
        if Rx.matches(#"^(?:(?:what (?:is|are)|show(?: me)?|tell me|check|read(?: me)?) )?(?:my |the |our )?(?:game|games|arcade|ace games) (?:scores?|stats|records?|wins|high scores?|scoreboard)(?: please)?$"#, t)
            || Rx.matches(#"^how many games (?:have i|did i) (?:won|win)$"#, t) {
            return "arcade:scores"
        }
        // The games screen ("open games"), or "let's play a game" (the list, with buttons).
        if Rx.matches(#"^(?:open|show|show me|go to|take me to|bring up|launch|pull up)\s+(?:the\s+|my\s+|your\s+)?(?:ace\s+)?(?:games?|arcade|game screen|games screen|games page|game page|mini games|minigames|mini-games)(?:\s+screen|\s+page|\s+menu)?(?: please)?$"#, t)
            || Rx.matches(#"^(?:ace games|the arcade|arcade)$"#, t) {
            return "arcade:open"
        }
        if Rx.matches(#"^(?:what|which)\s+(?:games|mini games)\s+(?:can|do|could)\s+(?:you|we|i)\s+(?:play|have|know)(?:\s+with you|\s+together|\s+with me)?$"#, t)
            || Rx.matches(#"^(?:do|can) you (?:have|play|know) (?:any )?games$"#, t)
            || Rx.matches(lead + #"(?:play|have)\s+(?:a|some|another)\s+(?:fun\s+|quick\s+|little\s+|mini\s+)?games?(?:\s+with me|\s+with you|\s+together)?(?: please)?$"#, t)
            || Rx.matches(#"^(?:games|mini games)$"#, t) {
            return "arcade"
        }
        return nil
    }
}
