import Foundation

/// Ace Games in the chat: tic-tac-toe, hangman, guess the number and rock paper scissors,
/// plus the list of games and your scores. Trivia and 20 questions stay in Brain.swift.
extension Brain {
    // MARK: Starting

    /// Starts one of the Ace Games, or answers "open games" and "my game scores".
    /// Nil for trivia and 20 questions, which Brain.startGame handles.
    func startArcade(_ which: String) -> BrainReply? {
        let parts = which.split(separator: ":", maxSplits: 1).map(String.init)
        let extra = parts.count > 1 ? parts[1] : nil
        switch parts.first ?? "" {
        case "tictactoe":
            return startTicTacToe(level: extra.flatMap(TicTacToe.Level.init(rawValue:)) ?? .normal)
        case "hangman":
            return startHangman(category: extra)
        case "number":
            return startNumberGuess()
        case "rps":
            return startRPS()
        case "arcade":
            if extra == "scores" { return arcadeScores() }
            return arcadeMenu(open: extra == "open")
        default:
            return nil
        }
    }

    /// "What games can you play": the list, with buttons for a few, and the games screen when asked for.
    func arcadeMenu(open: Bool) -> BrainReply {
        if open { host?.showGames() }
        let names = ArcadeGame.allCases.map { $0.title.lowercased() }
        let lead = open ? "Here's Ace Games." : ArcadeLines.pick("menu", ["Let's play!", "Game time!", "Ooh, I love games."])
        let text = lead + " I can play " + TextKit.joinList(names) + ". Pick one, or say something like \"play hangman\"."
        return arcadeReply(text, game: nil, cards: [arcadeChips(["Tic-tac-toe", "Hangman", "Rock paper scissors"])], mood: .happy)
    }

    /// "What are my game scores".
    func arcadeScores() -> BrainReply {
        var parts: [String] = []
        for g in ArcadeGame.allCases {
            let s = gameStats.score(g)
            guard s.played > 0 else { continue }
            var counts = [ArcadeLines.count(s.wins, "win")]
            if s.losses > 0 { counts.append(ArcadeLines.count(s.losses, "loss")) }
            if s.draws > 0 { counts.append(ArcadeLines.count(s.draws, "draw")) }
            parts.append("\(g.title): " + TextKit.joinList(counts) + ".")
        }
        guard !parts.isEmpty else {
            return arcadeReply("No scores yet. Want to play something?", game: nil,
                         cards: [arcadeChips(["Tic-tac-toe", "Hangman", "Guess the number"])], mood: .idle)
        }
        var text = "You've won \(ArcadeLines.count(gameStats.totalWins, "game")) so far. " + parts.joined(separator: " ")
        if gameStats.bestStreak > 1 { text += " Your best streak is \(gameStats.bestStreak) wins in a row." }
        return arcadeReply(text, game: nil)
    }

    private func startTicTacToe(level: TicTacToe.Level) -> BrainReply {
        gameSerial += 1
        ticTacToeGames += 1
        var round = TicTacToeRound()
        round.level = level
        let aceFirst = ticTacToeGames % 2 == 0
        let mode = level == .normal ? "" : (level == .hard ? " I'm on hard mode, so good luck!" : " I'm on easy mode.")
        if aceFirst, let move = TicTacToe.aceMove(round.board, ace: round.ace, level: level) {
            round.board[move] = round.ace
            round.aceLast = move
            let text = "Tic-tac-toe! You're X, and I'll go first this time. I took the \(TicTacToe.names[move]). Your turn." + mode
            return ticTacToeReply(text, round: round)
        }
        let text = "Tic-tac-toe! You're X and you go first. Tap a square, or say one like \"top left\" or \"center\"." + mode
        return ticTacToeReply(text, round: round)
    }

    private func startHangman(category: String?) -> BrainReply {
        gameSerial += 1
        let pick = Hangman.pick(category: category, avoiding: Set(recentWords))
        recentWords = Array((recentWords + [pick.word]).suffix(60))
        let round = HangmanRound(word: pick.word, category: pick.category)
        let topic = ArcadeLines.topic(pick.category)
        let text = "Hangman! I'm thinking of \(topic) with \(pick.word.count) letters. Guess a letter."
        return hangmanReply(text, round: round)
    }

    private func startNumberGuess() -> BrainReply {
        gameSerial += 1
        let round = NumberRound(secret: Int.random(in: NumberGuess.low...NumberGuess.high))
        let text = "I'm thinking of a number from \(NumberGuess.low) to \(NumberGuess.high). You get \(NumberGuess.maxGuesses) guesses. What's your first one?"
        return numberReply(text, round: round)
    }

    private func startRPS() -> BrainReply {
        gameSerial += 1
        let text = "Rock paper scissors, first to \(RPS.target) wins! Rock, paper or scissors?"
        return rpsReply(text, round: RPSRound(), you: nil, ace: nil, result: nil)
    }

    // MARK: Playing

    /// A move in one of the Ace Games. Nil when the message isn't a move, so Ace answers it instead.
    func playArcade(_ current: ActiveGame, text: String, stop: Bool) -> BrainReply? {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ".!? "))
        let givesUp = Rx.matches(#"^(?:i give up|give up|i surrender|surrender|tell me|tell me the (?:answer|word|number)|what is (?:it|the word|the number|the answer)|i do not know|i dont know|no idea)(?: please)?$"#, t)
        switch current {
        case .ticTacToe(let round):
            if stop {
                endGame()
                return arcadeReply("Okay, we'll stop there. Say \"play tic-tac-toe\" for a new game.", game: .ticTacToe, mood: .idle)
            }
            guard let square = TicTacToe.square(from: text) else { return nil }
            return ticTacToeMove(round, square: square)

        case .hangman(let round):
            if stop || givesUp {
                endGame()
                gameStats.record(.hangman, .lost)
                let card = hangmanCard(round, outcome: .lost)
                return arcadeReply("The word was \(round.word.uppercased()). Want another one?", game: .hangman,
                             cards: [.hangman(card), arcadeChips(["Play hangman again", "Open games"])], mood: .idle)
            }
            guard let guess = Hangman.guess(from: text) else { return nil }
            return hangmanGuess(round, guess: guess)

        case .numberGuess(let round):
            if stop || givesUp {
                endGame()
                gameStats.record(.numberGuess, .lost)
                let card = numberCard(round, outcome: .lost)
                return arcadeReply("It was \(round.secret). Want to try again?", game: .numberGuess,
                             cards: [.numberGuess(card), arcadeChips(["Play guess the number again", "Open games"])], mood: .idle)
            }
            guard let n = NumberGuess.number(from: text) else { return nil }
            return numberGuess(round, n)

        case .rps(let round):
            if stop {
                endGame()
                return arcadeReply("Okay, we'll stop there. It was \(round.you) to \(round.ace).", game: .rps, mood: .idle)
            }
            guard let move = RPS.move(from: text) else { return nil }
            return rpsThrow(round, you: move)

        case .trivia, .twenty:
            return nil
        }
    }

    private func ticTacToeMove(_ round: TicTacToeRound, square: Int) -> BrainReply {
        var round = round
        guard round.board[square].isEmpty else {
            let free = TicTacToe.free(round.board).map { TicTacToe.names[$0] }
            return arcadeReply("The \(TicTacToe.names[square]) is taken. Free squares: " + TextKit.joinList(free) + ".",
                         game: .ticTacToe, mood: .idle)
        }
        round.board[square] = round.you
        round.aceLast = nil
        if let w = TicTacToe.winner(round.board), w.mark == round.you {
            return ticTacToeEnd(round, outcome: .won, line: w.line, lead: nil)
        }
        if TicTacToe.free(round.board).isEmpty {
            return ticTacToeEnd(round, outcome: .draw, line: nil, lead: nil)
        }
        let threat = TicTacToe.winningSquare(round.board, for: round.you)
        guard let move = TicTacToe.aceMove(round.board, ace: round.ace, level: round.level) else {
            return ticTacToeEnd(round, outcome: .draw, line: nil, lead: nil)
        }
        round.board[move] = round.ace
        round.aceLast = move
        let name = TicTacToe.names[move]
        if let w = TicTacToe.winner(round.board), w.mark == round.ace {
            return ticTacToeEnd(round, outcome: .lost, line: w.line, lead: "I took the \(name).")
        }
        if TicTacToe.free(round.board).isEmpty {
            return ticTacToeEnd(round, outcome: .draw, line: nil, lead: "I took the \(name).")
        }
        let text: String
        if threat == move {
            text = ArcadeLines.pick("ttt.block", ["Blocked you! I took the \(name).", "Not so fast! I took the \(name).",
                                                  "Nice try. I blocked the \(name)."]) + " Your turn."
        } else {
            text = ArcadeLines.pick("ttt.move", ["I took the \(name). Your turn.", "My turn: the \(name). Your move!",
                                                 "I'll go \(name). Your turn.", "\(TextKit.capitalizeFirst(name)) for me. Your move."])
        }
        return ticTacToeReply(text, round: round)
    }

    private func ticTacToeEnd(_ round: TicTacToeRound, outcome: GameOutcome, line: [Int]?, lead: String?) -> BrainReply {
        endGame()
        let s = gameStats.record(.ticTacToe, outcome)
        let end: String
        switch outcome {
        case .won:
            end = ArcadeLines.pick("ttt.won", ["Three in a row! You win!", "You got three in a row. You win!", "That's three in a row. You beat me!"])
                + " That's \(ArcadeLines.count(s.wins, "win")) at tic-tac-toe" + (s.streak > 1 ? ", and \(s.streak) in a row." : ".")
        case .lost:
            end = ArcadeLines.pick("ttt.lost", ["Three in a row for me. I win this one!", "And that's three in a row. I win!"])
        default:
            end = ArcadeLines.pick("ttt.draw", ["It's a draw. Nobody got three in a row.", "Board's full, so it's a draw!"])
        }
        let text = [lead, end].compactMap { $0 }.joined(separator: " ")
        let card = ticTacToeCard(round, outcome: outcome, line: line, score: s)
        let again = round.level == .hard ? ["Play tic-tac-toe again", "Play tic-tac-toe on easy"] : ["Play tic-tac-toe again", "Play tic-tac-toe on hard"]
        return arcadeReply(text, game: .ticTacToe, cards: [.ticTacToe(card), arcadeChips(again)], mood: outcome == .draw ? .idle : .happy)
    }

    private func hangmanGuess(_ round: HangmanRound, guess: Hangman.Guess) -> BrainReply {
        var round = round
        let left: () -> String = { ArcadeLines.count(Hangman.maxMisses - round.misses, "miss", plural: "misses") + " left" }
        switch guess {
        case .letter(let c):
            let upper = String(c).uppercased()
            if round.guessed.contains(c) {
                return arcadeReply("You already tried \(upper).", game: .hangman, mood: .idle)
            }
            round.guessed.append(c)
            let hits = round.word.filter { $0 == c }.count
            if hits > 0 {
                if round.solved { return hangmanEnd(round, won: true) }
                let found = hits == 1 ? "Yes, there's \(ArcadeLines.article(c)) \(upper)!" : "Yes, there are \(hits) \(upper)s!"
                return hangmanReply(found + " You've found \(round.found) of \(round.word.count) letters.", round: round)
            }
            round.misses += 1
            if round.misses >= Hangman.maxMisses { return hangmanEnd(round, won: false) }
            return hangmanReply(ArcadeLines.pick("hang.miss", ["No \(upper).", "Nope, no \(upper).", "Sorry, no \(upper) in this one."]) + " \(left()).", round: round)
        case .word(let w):
            if w == round.word {
                for ch in round.word where !round.guessed.contains(ch) { round.guessed.append(ch) }
                return hangmanEnd(round, won: true)
            }
            round.misses += 1
            if round.misses >= Hangman.maxMisses { return hangmanEnd(round, won: false) }
            return hangmanReply("Nope, it's not \(w). \(TextKit.capitalizeFirst(left())).", round: round)
        }
    }

    private func hangmanEnd(_ round: HangmanRound, won: Bool) -> BrainReply {
        endGame()
        let word = round.word.uppercased()
        let s = gameStats.record(.hangman, won ? .won : .lost, best: won ? round.misses : nil)
        let text: String
        if won {
            let misses = round.misses == 0 ? "without a single miss" : "with \(ArcadeLines.count(round.misses, "miss", plural: "misses"))"
            text = ArcadeLines.pick("hang.won", ["You got it!", "Yes! You solved it!", "Nailed it!"]) + " The word was \(word), \(misses)."
                + (s.streak > 1 ? " That's \(s.streak) in a row!" : "")
        } else {
            text = "Out of guesses! The word was \(word)."
        }
        let card = hangmanCard(round, outcome: won ? .won : .lost)
        return arcadeReply(text, game: .hangman, cards: [.hangman(card), arcadeChips(["Play hangman again", "Open games"])], mood: won ? .happy : .idle)
    }

    private func numberGuess(_ round: NumberRound, _ n: Int) -> BrainReply {
        var round = round
        guard (NumberGuess.low...NumberGuess.high).contains(n) else {
            return arcadeReply("Pick a number from \(NumberGuess.low) to \(NumberGuess.high).", game: .numberGuess, mood: .idle)
        }
        if round.guesses.contains(n) {
            return arcadeReply("You already guessed \(n). It's somewhere from \(round.low) to \(round.high).", game: .numberGuess, mood: .idle)
        }
        round.guesses.append(n)
        if n == round.secret {
            endGame()
            let old = gameStats.score(.numberGuess).best
            let s = gameStats.record(.numberGuess, .won, best: round.guesses.count)
            var text = "Yes! It was \(n). You got it in \(ArcadeLines.count(round.guesses.count, "guess", plural: "guesses"))."
            if let old, round.guesses.count < old { text += " That's your best yet!" }
            else if s.wins == 1 { text += " Nice work!" }
            let card = numberCard(round, outcome: .won)
            return arcadeReply(text, game: .numberGuess, cards: [.numberGuess(card), arcadeChips(["Play guess the number again", "Open games"])], mood: .happy)
        }
        if n < round.secret { round.low = max(round.low, n + 1) } else { round.high = min(round.high, n - 1) }
        if round.left <= 0 {
            endGame()
            gameStats.record(.numberGuess, .lost)
            let card = numberCard(round, outcome: .lost)
            return arcadeReply("Out of guesses! It was \(round.secret).", game: .numberGuess,
                         cards: [.numberGuess(card), arcadeChips(["Play guess the number again", "Open games"])], mood: .idle)
        }
        var text = n < round.secret ? "Higher than \(n)." : "Lower than \(n)."
        switch NumberGuess.warmth(n, secret: round.secret) {
        case "hot": text += " You're super close!"
        case "warm": text += " You're getting warm."
        default: break
        }
        text += " " + (round.left == 1 ? "Last guess!" : "\(round.left) guesses left.")
        return numberReply(text, round: round)
    }

    private func rpsThrow(_ round: RPSRound, you: String) -> BrainReply {
        var round = round
        let ace = RPS.moves.randomElement() ?? "rock"
        round.rounds += 1
        let r = RPS.beats(you, ace)
        let result: String
        var text = "I picked \(ace)."
        if r == 0 {
            result = "tie"
            text += " " + ArcadeLines.pick("rps.tie", ["We both picked \(ace)! Go again.", "Same! Go again."])
        } else {
            let winner = r > 0 ? you : ace
            text += " " + RPS.why(winner) + (r > 0 ? ", so you win this round." : ", so I win this round.")
            if r > 0 { round.you += 1 } else { round.ace += 1 }
            result = r > 0 ? "win" : "lose"
        }
        if round.you >= RPS.target || round.ace >= RPS.target {
            endGame()
            let won = round.you > round.ace
            let s = gameStats.record(.rps, won ? .won : .lost)
            text += won ? " You win the match, \(round.you) to \(round.ace)!" : " I win the match, \(round.ace) to \(round.you)!"
            if won, s.streak > 1 { text += " That's \(s.streak) matches in a row." }
            let card = RPSCard(token: "", you: you, ace: ace, result: result, yourScore: round.you, aceScore: round.ace,
                               outcome: won ? .won : .lost, round: round.rounds)
            return arcadeReply(text, game: .rps, cards: [.rps(card), arcadeChips(["Play rock paper scissors again", "Open games"])], mood: won ? .happy : .idle)
        }
        if r != 0 { text += " It's \(round.you) to \(round.ace)." }
        return rpsReply(text, round: round, you: you, ace: ace, result: result)
    }

    // MARK: Cards and replies

    private func ticTacToeReply(_ text: String, round: TicTacToeRound) -> BrainReply {
        game = .ticTacToe(round)
        gameToken = "x\(gameSerial)-\(round.board.filter { !$0.isEmpty }.count)"
        let card = ticTacToeCard(round, outcome: .playing, line: nil, score: gameStats.score(.ticTacToe))
        return arcadeReply(text, game: .ticTacToe, cards: [.ticTacToe(card)])
    }

    private func ticTacToeCard(_ round: TicTacToeRound, outcome: GameOutcome, line: [Int]?, score: GameStats.Score) -> TicTacToeCard {
        TicTacToeCard(token: outcome == .playing ? gameToken : "", board: round.board, you: round.you, level: round.level.rawValue,
                      outcome: outcome, winLine: line, aceLast: round.aceLast, wins: score.wins, losses: score.losses, draws: score.draws)
    }

    private func hangmanReply(_ text: String, round: HangmanRound) -> BrainReply {
        game = .hangman(round)
        gameToken = "h\(gameSerial)-\(round.guessed.count)-\(round.misses)"
        return arcadeReply(text, game: .hangman, cards: [.hangman(hangmanCard(round, outcome: .playing))])
    }

    private func hangmanCard(_ round: HangmanRound, outcome: GameOutcome) -> HangmanCard {
        let over = outcome != .playing
        let letters = over ? round.word.map { String($0).uppercased() } : Hangman.shown(round.word, guessed: round.guessed)
        return HangmanCard(token: over ? "" : gameToken, category: round.category, letters: letters,
                           guessed: round.guessed.map { String($0).uppercased() }, misses: round.misses, maxMisses: Hangman.maxMisses,
                           outcome: outcome, word: over ? round.word.uppercased() : nil, wins: gameStats.score(.hangman).wins)
    }

    private func numberReply(_ text: String, round: NumberRound) -> BrainReply {
        game = .numberGuess(round)
        gameToken = "n\(gameSerial)-\(round.guesses.count)"
        return arcadeReply(text, game: .numberGuess, cards: [.numberGuess(numberCard(round, outcome: .playing))])
    }

    private func numberCard(_ round: NumberRound, outcome: GameOutcome) -> NumberGuessCard {
        let hints = round.guesses.map { $0 < round.secret ? "higher" : ($0 > round.secret ? "lower" : "right") }
        return NumberGuessCard(token: outcome == .playing ? gameToken : "", low: round.low, high: round.high, guesses: round.guesses,
                               hints: hints, left: round.left, outcome: outcome, secret: outcome == .playing ? nil : round.secret,
                               best: gameStats.score(.numberGuess).best,
                               heat: round.guesses.last.flatMap { NumberGuess.warmth($0, secret: round.secret) })
    }

    private func rpsReply(_ text: String, round: RPSRound, you: String?, ace: String?, result: String?) -> BrainReply {
        game = .rps(round)
        gameToken = "r\(gameSerial)-\(round.rounds)"
        let card = RPSCard(token: gameToken, you: you, ace: ace, result: result, yourScore: round.you, aceScore: round.ace,
                           outcome: .playing, round: round.rounds)
        return arcadeReply(text, game: .rps, cards: [.rps(card)])
    }

    /// Buttons that work any time (starting another game, opening the games screen).
    private func arcadeChips(_ list: [String]) -> AceCard {
        .quickReplies(QuickReplies(token: "arcade", replies: list, anytime: true))
    }

    private func arcadeReply(_ text: String, game: ArcadeGame?, cards: [AceCard] = [], mood: OrbMood = .happy) -> BrainReply {
        BrainReply(text: text, cards: cards, source: game?.source ?? "Ace Games", mood: mood, kind: "game")
    }
}

/// Wordings for the Ace Games, with a few ways to say each thing.
@MainActor
enum ArcadeLines {
    static func pick(_ key: String, _ options: [String]) -> String {
        guard !options.isEmpty else { return "" }
        return options[VariantPicker.shared.pick("arcade." + key, count: options.count)]
    }

    /// "1 win", "3 wins", "1 miss", "2 misses".
    static func count(_ n: Int, _ word: String, plural: String? = nil) -> String {
        let many: String
        if let plural { many = plural } else { many = word.hasSuffix("s") ? word + "es" : word + "s" }
        return "\(n) \(n == 1 ? word : many)"
    }

    /// "an E", "a B": letters whose names start with a vowel sound take "an".
    static func article(_ c: Character) -> String {
        "aefhilmnorsx".contains(c) ? "an" : "a"
    }

    /// "an animal", "a country", "a space word".
    static func topic(_ category: String) -> String {
        switch category {
        case "Animals": return "an animal"
        case "Food": return "a food"
        case "Countries": return "a country"
        case "Sports": return "a sports word"
        case "Space": return "a space word"
        case "Nature": return "a nature word"
        case "Science": return "a science word"
        case "Technology": return "a tech word"
        default: return "a word"
        }
    }
}

extension RPS {
    /// "Paper covers rock", from the move that won.
    static func why(_ winner: String) -> String {
        switch winner {
        case "rock": return "Rock smashes scissors"
        case "paper": return "Paper covers rock"
        default: return "Scissors cut paper"
        }
    }
}
