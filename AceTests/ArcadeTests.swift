import XCTest
@testable import Ace

/// Ace Games: asking for games, reading moves, and playing whole games through the brain.
@MainActor
final class ArcadeTests: XCTestCase {
    private let statsKey = "ace.games.scores.tests"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: statsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: statsKey)
        super.tearDown()
    }

    /// A brain whose scores go to a test key, so tests never touch your real wins.
    private func makeBrain() -> Brain {
        let brain = Brain()
        brain.gameStats = GameStats(key: statsKey)
        return brain
    }

    private func gameAsk(_ text: String) -> String? {
        if case .game(let g)? = IntentRouter.parse(text) { return g }
        return nil
    }

    // MARK: Asking

    func testGameAsksRoute() {
        let cases: [(String, String)] = [
            ("play tic tac toe", "tictactoe"),
            ("Let's play tic-tac-toe on hard", "tictactoe:hard"),
            ("can we play noughts and crosses", "tictactoe"),
            ("play hangman", "hangman"),
            ("play hangman with animals", "hangman:Animals"),
            ("let's play rock paper scissors", "rps"),
            ("play guess the number", "number"),
            ("open ace games", "arcade:open"),
            ("show me the games", "arcade:open"),
            ("what games can you play", "arcade"),
            ("let's play a game", "arcade"),
            ("what are my game scores", "arcade:scores"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(gameAsk(text), want, text)
        }
    }

    func testOtherAsksAreNotGames() {
        for text in ["can you give me a c++ hangman game", "who will win the game tonight",
                     "what game am i going to play tonight", "what's the score of the game right now",
                     "what is the capital of france", "set a timer for 5 minutes"] {
            XCTAssertNil(gameAsk(text), text)
        }
    }

    // MARK: Reading moves

    func testSquares() {
        let cases: [(String, Int?)] = [("top left", 0), ("the middle", 4), ("put an x in the top right corner", 2),
                                       ("bottom middle", 7), ("middle top", 1), ("left middle", 3), ("5", 4),
                                       ("number 9", 8), ("a1", 0), ("c3", 8), ("lower right", 8), ("hello there", nil)]
        for (text, want) in cases {
            XCTAssertEqual(TicTacToe.square(from: text), want, text)
        }
        for (i, name) in TicTacToe.names.enumerated() {
            XCTAssertEqual(TicTacToe.square(from: name), i, "The tapped square's name must read back as the same square")
        }
    }

    func testHangmanGuesses() {
        let cases: [(String, Hangman.Guess?)] = [("e", .letter("e")), ("E", .letter("e")), ("the letter bee", .letter("b")),
                                                 ("is there an a", .letter("a")), ("is it elephant", .word("elephant")),
                                                 ("what's the weather", nil)]
        for (text, want) in cases {
            XCTAssertEqual(Hangman.guess(from: text), want, text)
        }
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            XCTAssertEqual(Hangman.guess(from: String(letter)), .letter(Character(letter.lowercased())), "Tapping \(letter)")
        }
    }

    func testNumbersAndThrows() {
        XCTAssertEqual(NumberGuess.number(from: "is it 37"), 37)
        XCTAssertEqual(NumberGuess.number(from: "seventy two"), 72)
        XCTAssertNil(NumberGuess.number(from: "hello"))
        for move in RPS.moves {
            XCTAssertEqual(RPS.move(from: move.capitalized), move)
        }
        XCTAssertNil(RPS.move(from: "rock or paper"))
    }

    func testWordListsAreReal() {
        XCTAssertEqual(Hangman.categories.count, 8)
        for (category, words) in Hangman.words {
            XCTAssertGreaterThanOrEqual(words.count, 15, category)
            XCTAssertEqual(Set(words).count, words.count, "\(category) has a word twice")
            for w in words {
                XCTAssertTrue(w.allSatisfy { $0 >= "a" && $0 <= "z" }, "\(w) should be plain lowercase letters")
                XCTAssertGreaterThanOrEqual(w.count, 3, w)
            }
        }
    }

    // MARK: Tic-tac-toe brain

    func testHardAceNeverLoses() {
        for _ in 0..<150 {
            var board = Array(repeating: "", count: 9)
            var turn = Bool.random() ? "X" : "O"
            while TicTacToe.winner(board) == nil, !TicTacToe.free(board).isEmpty {
                if turn == "O" {
                    let m = try! XCTUnwrap(TicTacToe.aceMove(board, ace: "O", level: .hard))
                    board[m] = "O"
                } else {
                    board[TicTacToe.free(board).randomElement()!] = "X"
                }
                turn = turn == "X" ? "O" : "X"
            }
            XCTAssertNotEqual(TicTacToe.winner(board)?.mark, "X", "\(board)")
        }
    }

    func testNormalAceWinsOrBlocks() {
        // Ace can win at 2.
        XCTAssertEqual(TicTacToe.aceMove(["O", "O", "", "X", "X", "", "", "", ""], ace: "O", level: .normal, roll: { 0 }), 2)
        // Ace must block at 5.
        XCTAssertEqual(TicTacToe.aceMove(["O", "", "", "X", "X", "", "", "", ""], ace: "O", level: .normal, roll: { 0 }), 5)
    }

    // MARK: Playing through the brain

    func testTicTacToePlaysToTheEnd() throws {
        let brain = makeBrain()
        let start = brain.startGame("tictactoe:hard")
        XCTAssertTrue(start.cards.contains { if case .ticTacToe = $0 { return true }; return false })
        var turns = 0
        while case .ticTacToe(let round)? = brain.game, turns < 10 {
            let square = try XCTUnwrap(TicTacToe.free(round.board).first)
            let token = brain.gameToken
            _ = try XCTUnwrap(brain.playGame(TicTacToe.names[square]))
            XCTAssertNotEqual(brain.gameToken, token, "Old boards stop taking taps")
            turns += 1
        }
        XCTAssertNil(brain.game)
        XCTAssertEqual(brain.gameToken, "")
        let s = brain.gameStats.score(.ticTacToe)
        XCTAssertEqual(s.played, 1)
        XCTAssertEqual(s.wins, 0, "Hard Ace can't lose")
    }

    func testATakenSquareKeepsTheBoard() throws {
        let brain = makeBrain()
        _ = brain.startGame("tictactoe")
        if case .ticTacToe(let round)? = brain.game, round.aceLast == nil {
            _ = try XCTUnwrap(brain.playGame("center"))
        }
        guard case .ticTacToe(let round)? = brain.game else { return XCTFail("Game should still be on") }
        let taken = try XCTUnwrap(round.board.indices.first { !round.board[$0].isEmpty })
        let token = brain.gameToken
        let r = try XCTUnwrap(brain.playGame(TicTacToe.names[taken]))
        XCTAssertTrue(r.cards.isEmpty || !r.cards.contains { if case .ticTacToe = $0 { return true }; return false })
        XCTAssertEqual(brain.gameToken, token)
    }

    func testHangmanWinsByWord() throws {
        let brain = makeBrain()
        _ = brain.startGame("hangman:Space")
        guard case .hangman(let round)? = brain.game else { return XCTFail("No hangman round") }
        XCTAssertEqual(round.category, "Space")
        XCTAssertTrue(Hangman.words["Space"]?.contains(round.word) == true)
        let r = try XCTUnwrap(brain.playGame("is it " + round.word))
        XCTAssertNil(brain.game)
        guard case .hangman(let card)? = r.cards.first(where: { if case .hangman = $0 { return true }; return false }) else {
            return XCTFail("No hangman card")
        }
        XCTAssertEqual(card.outcome, .won)
        XCTAssertEqual(card.word, round.word)
        XCTAssertEqual(brain.gameStats.score(.hangman).wins, 1)
    }

    func testHangmanLosesAfterSixMisses() throws {
        let brain = makeBrain()
        _ = brain.startGame("hangman")
        guard case .hangman(let round)? = brain.game else { return XCTFail("No hangman round") }
        let wrong = "abcdefghijklmnopqrstuvwxyz".filter { !round.word.contains($0) }
        for letter in wrong.prefix(Hangman.maxMisses) {
            _ = try XCTUnwrap(brain.playGame(String(letter)))
        }
        XCTAssertNil(brain.game)
        XCTAssertEqual(brain.gameStats.score(.hangman).losses, 1)
    }

    func testNumberGuessBinarySearchWins() throws {
        let brain = makeBrain()
        _ = brain.startGame("number")
        var low = NumberGuess.low, high = NumberGuess.high, guesses = 0
        while case .numberGuess? = brain.game, guesses < NumberGuess.maxGuesses {
            let mid = (low + high) / 2
            _ = try XCTUnwrap(brain.playGame("\(mid)"))
            guesses += 1
            guard case .numberGuess(let r)? = brain.game else { break }
            low = r.low
            high = r.high
        }
        XCTAssertNil(brain.game)
        XCTAssertEqual(brain.gameStats.score(.numberGuess).wins, 1, "Halving always finds 1 to 100 in 7 guesses")
        XCTAssertLessThanOrEqual(guesses, 7)
    }

    func testRockPaperScissorsEnds() throws {
        let brain = makeBrain()
        _ = brain.startGame("rps")
        var throwsLeft = 60
        while case .rps? = brain.game, throwsLeft > 0 {
            _ = try XCTUnwrap(brain.playGame(RPS.moves.randomElement()!))
            throwsLeft -= 1
        }
        XCTAssertNil(brain.game)
        XCTAssertEqual(brain.gameStats.score(.rps).played, 1)
    }

    func testQuestionsPassThroughAndStopEnds() throws {
        let brain = makeBrain()
        _ = brain.startGame("hangman")
        XCTAssertNil(brain.playGame("what is the capital of france"), "A question isn't a guess")
        XCTAssertNotNil(brain.game)
        _ = try XCTUnwrap(brain.playGame("stop"))
        XCTAssertNil(brain.game)
    }

    func testStatsAddUpAndReset() {
        let stats = GameStats(key: statsKey)
        stats.record(.ticTacToe, .won)
        stats.record(.ticTacToe, .won)
        stats.record(.hangman, .lost)
        stats.record(.numberGuess, .won, best: 6)
        stats.record(.numberGuess, .won, best: 4)
        XCTAssertEqual(stats.totalWins, 4)
        XCTAssertEqual(stats.totalPlayed, 5)
        XCTAssertEqual(stats.score(.ticTacToe).bestStreak, 2)
        XCTAssertEqual(stats.score(.numberGuess).best, 4)
        XCTAssertEqual(GameStats(key: statsKey).totalWins, 4, "Scores are saved")
        stats.clearAll()
        XCTAssertEqual(GameStats(key: statsKey).totalPlayed, 0)
    }

    func testChangelogHasGames() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 61)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Games") } == true)
    }
}
