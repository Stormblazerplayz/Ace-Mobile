import XCTest
@testable import Ace

/// Trivia, 20 questions and the translator.
@MainActor
final class GamesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TwentyQuestions.forgetLearned()
    }

    override func tearDown() {
        TwentyQuestions.forgetLearned()
        super.tearDown()
    }

    // MARK: Data

    func testDataIsComplete() {
        XCTAssertGreaterThanOrEqual(Trivia.all.count, 4000)
        XCTAssertEqual(Trivia.categories.count, 10)
        XCTAssertEqual(Set(Trivia.all.map(\.id)).count, Trivia.all.count, "Two trivia questions share an id")
        for q in Trivia.all {
            XCTAssertEqual(q.choices.count, 4, q.id)
            XCTAssertTrue(q.choices.indices.contains(q.answer), q.id)
            XCTAssertEqual(Set(q.choices.map { TextKit.normalize($0) }).count, 4, "\(q.id) has the same choice twice")
            XCTAssertFalse(q.fact.isEmpty, q.id)
        }
        XCTAssertGreaterThanOrEqual(TwentyQuestions.builtIn.count, 650)
        XCTAssertGreaterThanOrEqual(TwentyQuestions.questions.count, 30)
        XCTAssertEqual(Phrasebook.languages.count, 12)
        XCTAssertGreaterThanOrEqual(Phrasebook.entries.count, 1150)
        for e in Phrasebook.entries {
            XCTAssertEqual(e.t.count, 12, "\(e.en) is missing a language")
        }
        for code in Phrasebook.languages.map(\.code) {
            XCTAssertNotNil(Phrasebook.speechCodes[code], code)
        }
    }

    // MARK: Translator

    func testTranslationAsks() {
        let cases: [(String, String, String)] = [
            ("how do you say thank you in spanish", "thank you", "es"),
            ("How do I say good night in Japanese?", "good night", "ja"),
            ("translate good morning to french", "good morning", "fr"),
            ("translate to german: where is the bathroom", "where is the bathroom", "de"),
            ("what is cat in italian", "cat", "it"),
            ("what's the korean word for dog", "dog", "ko"),
            ("spanish for hello", "hello", "es"),
            ("thank you in chinese", "thank you", "zh"),
            ("how are you in french", "how are you", "fr"),
            ("say goodbye in russian", "goodbye", "ru"),
        ]
        for (text, phrase, code) in cases {
            let got = Phrasebook.parse(text)
            XCTAssertEqual(got?.phrase, phrase, text)
            XCTAssertEqual(got?.code, code, text)
            XCTAssertEqual(IntentRouter.parse(text)?.kind, "translate", text)
        }
        for text in ["what is the capital of spain", "how are you", "say hello", "what is spanish", "the weather in paris",
                     "who speaks french", "translate this into klingon"] {
            XCTAssertNil(Phrasebook.parse(text), text)
        }
        XCTAssertEqual(IntentRouter.parse("what languages can you speak")?.kind, "translate")
    }

    func testPhrasebookFinds() {
        XCTAssertEqual(Phrasebook.find("thanks")?.en, "thank you")
        XCTAssertEqual(Phrasebook.find("the cat")?.en, "cat")
        XCTAssertEqual(Phrasebook.find("cats")?.en, "cat")
        XCTAssertEqual(Phrasebook.find("where's the bathroom")?.en, "where is the bathroom")
        XCTAssertEqual(Phrasebook.find("5")?.en, "five")
        XCTAssertNil(Phrasebook.find("zxqv blorp"))
        let hello = try! XCTUnwrap(Phrasebook.find("hello"))
        XCTAssertEqual(Phrasebook.card(hello, code: "ja")?.say, "konnichiwa")
        XCTAssertEqual(Phrasebook.card(hello, code: "es")?.text, "Hola")
        XCTAssertEqual(Phrasebook.card(hello, code: "es")?.language, "Spanish")
    }

    func testTranslationsAreSpokenInTheirAccent() {
        let thanks = TranslationCard(english: "thank you", language: "Spanish", code: "es", text: "gracias", say: nil)
        XCTAssertEqual(Phrasebook.spokenParts("In Spanish, \"thank you\" is gracias.", cards: [.translation(thanks)]), [
            SpokenPart(text: "In Spanish, \"thank you\" is", language: nil),
            SpokenPart(text: "gracias", language: "es-ES"),
        ])
        let jp = TranslationCard(english: "thank you", language: "Japanese", code: "ja", text: "ありがとう", say: "arigatou")
        let parts = Phrasebook.spokenParts("\"thank you\" in Japanese is ありがとう (arigatou). Give it a try!", cards: [.translation(jp)])
        XCTAssertEqual(parts.map(\.language), [nil, "ja-JP", nil])
        XCTAssertEqual(parts[1].text, "ありがとう")
        XCTAssertFalse(parts.contains { $0.text.contains("arigatou") }, "The real voice says it, not the spelling")
        let pizza = TranslationCard(english: "pizza", language: "Italian", code: "it", text: "pizza", say: nil)
        XCTAssertEqual(Phrasebook.spokenParts("\"pizza\" in Italian is pizza.", cards: [.translation(pizza)]).last,
                       SpokenPart(text: "pizza", language: "it-IT"), "The quoted English word isn't the translation")
        XCTAssertEqual(Phrasebook.spokenParts("Hi there!", cards: []), [SpokenPart(text: "Hi there!", language: nil)])
        // Every way Ace words a translation gets split, for every language.
        let hello = try! XCTUnwrap(Phrasebook.find("hello"))
        for code in Phrasebook.languages.map(\.code) {
            guard let card = Phrasebook.card(hello, code: code) else { continue }
            let shown = card.say.map { "\(card.text) (\($0))" } ?? card.text
            for wording in Say.wordings(.translated) {
                let text = wording.replacingOccurrences(of: "{phrase}", with: card.english)
                    .replacingOccurrences(of: "{language}", with: card.language)
                    .replacingOccurrences(of: "{text}", with: shown)
                let got = Phrasebook.spokenParts(text, cards: [.translation(card)])
                XCTAssertEqual(got.filter { $0.language != nil }, [SpokenPart(text: card.text, language: Phrasebook.speechCodes[code])], text)
                XCTAssertFalse(got.contains { $0.language == nil && $0.text.contains(card.text) && card.text != card.english }, text)
            }
        }
    }

    // MARK: Trivia

    private let mars = TriviaQuestion(id: "t", category: "Space", q: "Which planet is known as the Red Planet?",
                                      choices: ["Venus", "Mars", "Mercury", "Jupiter"], answer: 1, fact: "It's rusty.")

    func testTriviaPicks() {
        let cases: [(String, Int?)] = [
            ("b", 1), ("B", 1), ("it's b", 1), ("I think it is B", 1), ("mars", 1), ("Mars!", 1),
            ("i think it is mars", 1), ("the second one", 1), ("4", 3), ("last", 3), ("option c", 2),
            ("jupiter final answer", 3), ("pizza", nil),
        ]
        for (text, want) in cases {
            XCTAssertEqual(Trivia.pick(text, for: mars), want, text)
        }
    }

    func testTriviaRequests() {
        XCTAssertEqual(IntentRouter.parse("let's play trivia"), .game("trivia"))
        XCTAssertEqual(IntentRouter.parse("quiz me on space"), .game("trivia:Space"))
        XCTAssertEqual(IntentRouter.parse("trivia about animals"), .game("trivia:Animals"))
        XCTAssertEqual(IntentRouter.parse("can we play 20 questions"), .game("twenty"))
        XCTAssertEqual(IntentRouter.parse("guess what i'm thinking of"), .game("twenty"))
        XCTAssertNotEqual(IntentRouter.parse("what is trivia")?.kind, "game")
        XCTAssertEqual(IntentRouter.parse("what are my trivia scores"), .game("trivia:records"))
        XCTAssertEqual(IntentRouter.parse("what's my best trivia score"), .game("trivia:records"))
        XCTAssertEqual(IntentRouter.parse("show me my trivia streaks"), .game("trivia:records"))
        XCTAssertEqual(IntentRouter.parse("how am i doing at trivia"), .game("trivia:records"))
    }

    func testTriviaRecords() {
        let records = TriviaRecords(key: "ace.trivia.records.test")
        records.clearAll()
        defer { records.clearAll() }
        XCTAssertTrue(records.summary.isEmpty)
        XCTAssertEqual(records.answered(category: "Space", right: true), 1)
        XCTAssertEqual(records.answered(category: "Space", right: true), 2)
        XCTAssertEqual(records.answered(category: "Space", right: true), 3)
        XCTAssertEqual(records.answered(category: "Space", right: false), 0, "A miss ends the streak")
        XCTAssertEqual(records.record("Space").bestStreak, 3)
        XCTAssertEqual(records.answered(category: nil, right: true), 1, "Mixed rounds have their own streak")
        XCTAssertTrue(records.finished(category: "Space", score: 3, total: 5), "The first round is a new best")
        XCTAssertFalse(records.finished(category: "Space", score: 2, total: 5))
        XCTAssertFalse(records.finished(category: "Space", score: 3, total: 5), "A tie isn't a new best")
        XCTAssertTrue(records.finished(category: "Space", score: 5, total: 5))
        XCTAssertEqual(records.record("Space").best, 5)
        XCTAssertEqual(records.record("Space").rounds, 4)
        XCTAssertFalse(records.finished(category: "Animals", score: 0, total: 5), "Zero isn't a new best")
        XCTAssertEqual(records.record("Animals").rounds, 1)
        XCTAssertEqual(TriviaRecords(key: "ace.trivia.records.test").record("Space").best, 5, "Records are saved")
        XCTAssertEqual(records.summary, ["Space 5 out of 5 (best streak 3)", "Animals 0 out of 5 (best streak 0)"])
        XCTAssertEqual([1, 2, 3, 4, 5, 6, 10, 12, 15].filter(TriviaRecords.isMilestone), [3, 5, 10, 15])

        let brain = Brain()
        brain.triviaRecords = records
        let r = brain.startGame("trivia:records")
        XCTAssertTrue(r.text.contains("Space 5 out of 5"), r.text)
        XCTAssertNil(brain.game, "Asking for scores doesn't start a round")
        records.clearAll()
        XCTAssertEqual(brain.triviaRecordsReply().mood, .idle)
    }

    func testTriviaRound() throws {
        let brain = Brain()
        let records = TriviaRecords(key: "ace.trivia.records.round")
        records.clearAll()
        defer { records.clearAll() }
        brain.triviaRecords = records
        let first = brain.startGame("trivia:Space")
        guard case .trivia(let start)? = brain.game else { return XCTFail("No trivia round") }
        XCTAssertEqual(start.questions.count, Trivia.roundLength)
        XCTAssertTrue(start.questions.allSatisfy { $0.category == "Space" })
        guard case .trivia(let card)? = first.cards.first else { return XCTFail("No trivia card") }
        XCTAssertEqual(card.token, brain.gameToken)
        XCTAssertEqual(card.number, 1)

        // Right, wrong, skipped, then two right by name.
        for step in 0..<Trivia.roundLength {
            guard case .trivia(let round)? = brain.game, let q = round.current else { return XCTFail("Round ended early") }
            let before = round.score
            let oldToken = brain.gameToken
            let text: String
            switch step {
            case 1: text = Trivia.letter((q.answer + 1) % q.choices.count)
            case 2: text = "skip"
            case 0: text = Trivia.letter(q.answer).lowercased()
            default: text = q.choices[q.answer]
            }
            let r = try XCTUnwrap(brain.playGame(text), text)
            XCTAssertFalse(r.text.contains("{"), r.text)
            if step < Trivia.roundLength - 1 {
                guard case .trivia(let next)? = brain.game else { return XCTFail("Round ended early") }
                XCTAssertEqual(next.score, before + (step == 1 || step == 2 ? 0 : 1), "step \(step)")
                XCTAssertNotEqual(brain.gameToken, oldToken, "Old cards should stop taking taps")
            }
        }
        XCTAssertNil(brain.game, "The round should be over")
        XCTAssertEqual(brain.gameToken, "")
        // 3 right out of 5, ending on two right in a row.
        XCTAssertEqual(records.record("Space").best, 3)
        XCTAssertEqual(records.record("Space").rounds, 1)
        XCTAssertEqual(records.record("Space").streak, 2)
    }

    func testTriviaStopsAndLetsOtherQuestionsThrough() {
        let brain = Brain()
        _ = brain.startGame("trivia:Space")
        XCTAssertNil(brain.playGame("what is the weather in paris tomorrow"), "A new question isn't an answer")
        XCTAssertNotNil(brain.game, "The game keeps going")
        XCTAssertNil(brain.playGame("quiz me on history"), "A new game request starts over")
        let r = brain.playGame("stop")
        XCTAssertNotNil(r)
        XCTAssertNil(brain.game)
    }

    func testNewRoundAvoidsRecentQuestions() {
        let first = Trivia.newRound(category: "Animals", avoiding: [])
        let second = Trivia.newRound(category: "Animals", avoiding: Set(first.map(\.id)))
        XCTAssertTrue(Set(first.map(\.id)).isDisjoint(with: second.map(\.id)))
    }

    // MARK: 20 questions

    func testTwentyQuestionsAnswers() {
        XCTAssertEqual(TwentyQuestions.reply("yes"), .value(1))
        XCTAssertEqual(TwentyQuestions.reply("Yep!"), .value(1))
        XCTAssertEqual(TwentyQuestions.reply("no"), .value(0))
        XCTAssertEqual(TwentyQuestions.reply("it isn't"), .value(0))
        XCTAssertEqual(TwentyQuestions.reply("maybe"), .value(0.5))
        XCTAssertEqual(TwentyQuestions.reply("probably"), .value(0.85))
        XCTAssertEqual(TwentyQuestions.reply("probably not"), .value(0.15))
        XCTAssertEqual(TwentyQuestions.reply("I don't know"), .dontKnow)
        XCTAssertEqual(TwentyQuestions.reply("i dont know"), .dontKnow)
        XCTAssertNil(TwentyQuestions.reply("what's the weather"))
    }

    func testThingNames() {
        XCTAssertEqual(TwentyQuestions.thingName("it was a hedgehog"), "a hedgehog")
        XCTAssertEqual(TwentyQuestions.thingName("Hedgehog"), "a hedgehog")
        XCTAssertEqual(TwentyQuestions.thingName("an owl"), "an owl")
        XCTAssertEqual(TwentyQuestions.thingName("i was thinking of the eiffel tower"), "the eiffel tower")
        XCTAssertEqual(TwentyQuestions.thingName("octopus"), "an octopus")
        XCTAssertNil(TwentyQuestions.thingName("what is the weather?"))
        XCTAssertNil(TwentyQuestions.thingName("set a timer for 5 minutes"))
    }

    /// Ace plays against every built-in thing, answering yes, no or maybe, and should guess nearly all of them.
    func testTwentyQuestionsGuessesThings() throws {
        let brain = Brain()
        var wins = 0
        var missed: [String] = []
        for secret in TwentyQuestions.builtIn {
            _ = brain.startGame("twenty")
            var won = false
            turns: for _ in 0..<30 {
                guard case .twenty(let round)? = brain.game else { break }
                switch round.step {
                case .asking(let id):
                    let v = secret.answers[id] ?? 0.5
                    _ = try XCTUnwrap(brain.playGame(v >= 0.75 ? "yes" : v <= 0.25 ? "no" : "maybe"))
                case .guessing(let name):
                    _ = try XCTUnwrap(brain.playGame(name == secret.name ? "yes" : "no"))
                    if name == secret.name { won = true; break turns }
                case .whatWasIt:
                    break turns
                }
            }
            if won { wins += 1 } else { missed.append(secret.name) }
            brain.resetConversation()
        }
        print("20 QUESTIONS: won \(wins)/\(TwentyQuestions.builtIn.count), missed \(missed)")
        // With over a thousand things, a few near twins (like two kinds of bird) can't all be told apart in 20 questions.
        XCTAssertGreaterThanOrEqual(Double(wins), Double(TwentyQuestions.builtIn.count) * 0.95)
    }

    func testTwentyQuestionsLearns() throws {
        let brain = Brain()
        _ = brain.startGame("twenty")
        // Say no to everything: Ace runs out of questions and asks what it was.
        for _ in 0..<30 {
            guard case .twenty(let round)? = brain.game, round.step != .whatWasIt else { break }
            _ = try XCTUnwrap(brain.playGame("no"))
        }
        guard case .twenty(let round)? = brain.game else { return XCTFail("The game ended without asking") }
        XCTAssertEqual(round.step, .whatWasIt)
        XCTAssertLessThanOrEqual(round.used, TwentyQuestions.maxQuestions)
        let r = try XCTUnwrap(brain.playGame("it was a zorblax"))
        XCTAssertTrue(r.text.lowercased().contains("zorblax"), r.text)
        XCTAssertNil(brain.game)
        let learned = try XCTUnwrap(TwentyQuestions.learned.first { $0.name == "a zorblax" })
        XCTAssertFalse(learned.answers.isEmpty)
        XCTAssertTrue(TwentyQuestions.allThings().contains { $0.name == "a zorblax" })
    }

    func testTwentyQuestionsStops() {
        let brain = Brain()
        _ = brain.startGame("twenty")
        XCTAssertNotNil(brain.playGame("stop playing"))
        XCTAssertNil(brain.game)
    }
}
