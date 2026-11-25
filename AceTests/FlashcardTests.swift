import XCTest
@testable import Ace

/// Flashcards: spaced repetition, study sessions, reminders, ready-made decks, the saved store,
/// and the words that ask for them.
@MainActor
final class FlashcardTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: Spaced repetition

    func testNewCardSteps() {
        let c = Flashcard(front: "hola", back: "hello", now: t0)
        XCTAssertTrue(c.isNew)
        XCTAssertTrue(c.isDue(at: t0))
        XCTAssertEqual(SpacedRepetition.nextInterval(c, .again), 0)
        XCTAssertEqual(SpacedRepetition.nextInterval(c, .hard), 0.5)
        XCTAssertEqual(SpacedRepetition.nextInterval(c, .good), 1)
        XCTAssertEqual(SpacedRepetition.nextInterval(c, .easy), 4)
    }

    func testGoodAnswersGrowTheGap() {
        var c = Flashcard(front: "gato", back: "cat", now: t0)
        var now = t0
        var gaps: [Double] = []
        for _ in 0..<5 {
            c = SpacedRepetition.review(c, grade: .good, at: now)
            gaps.append(c.interval)
            now = c.due
        }
        XCTAssertEqual(gaps, [1, 3, 8, 20, 50])
        XCTAssertEqual(c.streak, 5)
        XCTAssertEqual(c.reviews, 5)
        XCTAssertEqual(c.ease, 2.5, accuracy: 0.0001)
        XCTAssertTrue(c.isMastered)
        XCTAssertEqual(c.due.timeIntervalSince(c.lastReviewed!), 50 * SpacedRepetition.day, accuracy: 1)
    }

    func testMissingACardBringsItBackSoon() {
        var c = Flashcard(front: "perro", back: "dog", now: t0)
        c = SpacedRepetition.review(c, grade: .good, at: t0)
        c = SpacedRepetition.review(c, grade: .good, at: c.due)
        XCTAssertEqual(c.interval, 3)
        let before = c.ease
        let missedAt = c.due
        c = SpacedRepetition.review(c, grade: .again, at: missedAt)
        XCTAssertEqual(c.interval, 0)
        XCTAssertEqual(c.streak, 0)
        XCTAssertEqual(c.lapses, 1)
        XCTAssertEqual(c.ease, before - 0.2, accuracy: 0.0001)
        XCTAssertEqual(c.due.timeIntervalSince(missedAt), 60, accuracy: 0.5)
        // Missing a brand-new card isn't a lapse (you never knew it).
        let fresh = SpacedRepetition.review(Flashcard(front: "a", back: "b", now: t0), grade: .again, at: t0)
        XCTAssertEqual(fresh.lapses, 0)
    }

    func testEaseStaysInBounds() {
        var c = Flashcard(front: "x", back: "y", now: t0)
        for _ in 0..<30 { c = SpacedRepetition.review(c, grade: .again, at: t0) }
        XCTAssertEqual(c.ease, SpacedRepetition.minEase, accuracy: 0.0001)
        for _ in 0..<30 { c = SpacedRepetition.review(c, grade: .easy, at: c.due) }
        XCTAssertEqual(c.ease, SpacedRepetition.maxEase, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(c.interval, SpacedRepetition.maxInterval)
    }

    func testButtonsAlwaysOrderedHardGoodEasy() {
        var c = Flashcard(front: "x", back: "y", now: t0)
        for grade in [FlashGrade.good, .hard, .easy, .good, .hard] {
            let h = SpacedRepetition.nextInterval(c, .hard)
            let g = SpacedRepetition.nextInterval(c, .good)
            let e = SpacedRepetition.nextInterval(c, .easy)
            XCTAssertLessThan(h, g)
            XCTAssertLessThan(g, e)
            c = SpacedRepetition.review(c, grade: grade, at: c.due)
        }
    }

    func testLabels() {
        let c = Flashcard(front: "x", back: "y", now: t0)
        XCTAssertEqual(SpacedRepetition.label(.again, for: c), "1 min")
        XCTAssertEqual(SpacedRepetition.label(.hard, for: c), "12 hr")
        XCTAssertEqual(SpacedRepetition.label(.good, for: c), "1 day")
        XCTAssertEqual(SpacedRepetition.label(.easy, for: c), "4 days")
        XCTAssertEqual(SpacedRepetition.label(days: 45), "2 mo")
        XCTAssertEqual(SpacedRepetition.label(days: 30), "1 mo")
        XCTAssertEqual(SpacedRepetition.label(days: 438), "1.2 yr")
    }

    // MARK: Study sessions

    private func deck(_ name: String, _ count: Int, now: Date? = nil) -> FlashDeck {
        let at = now ?? t0
        let cards = (0..<count).map { i in Flashcard(front: "\(name) \(i)", back: "\(i)", now: at.addingTimeInterval(Double(i))) }
        return FlashDeck(name: name, cards: cards, now: at)
    }

    func testMissedCardComesBackThreeCardsLater() {
        let d = deck("A", 6)
        var q = StudyQueue.due(in: [d], at: t0.addingTimeInterval(100))
        XCTAssertEqual(q.total, 6)
        let first = q.current
        q.answer(.again)
        XCTAssertEqual(q.left, 6)
        XCTAssertEqual(q.missed.count, 1)
        q.answer(.good)
        q.answer(.good)
        q.answer(.good)
        XCTAssertEqual(q.current, first)
        while !q.isDone { q.answer(.good) }
        XCTAssertEqual(q.answered, 7)
        XCTAssertEqual(q.right, 6)
        XCTAssertEqual(q.progress, 1)
    }

    func testDueQueueOrderAndNewLimit() {
        var d = deck("A", 30)
        // Two seen cards: the more overdue one comes first, before any new cards.
        d.cards[5] = SpacedRepetition.review(d.cards[5], grade: .good, at: t0)
        d.cards[9] = SpacedRepetition.review(d.cards[9], grade: .hard, at: t0)
        let now = t0.addingTimeInterval(2 * SpacedRepetition.day)
        let q = StudyQueue.due(in: [d], at: now)
        XCTAssertEqual(q.total, 2 + StudyQueue.newPerSession)
        XCTAssertEqual(q.current?.card, d.cards[9].id)
        // Nothing due yet: empty.
        let early = StudyQueue.due(in: [d], at: t0.addingTimeInterval(-10))
        XCTAssertEqual(early.total, 0)
    }

    func testPracticeTakesTheSoonestCards() {
        var d = deck("A", 3)
        d.cards = d.cards.map { SpacedRepetition.review($0, grade: .easy, at: t0) }
        XCTAssertEqual(StudyQueue.due(in: [d], at: t0).total, 0)
        let q = StudyQueue.practice(in: [d], size: 2)
        XCTAssertEqual(q.total, 2)
    }

    // MARK: Reminders

    func testReminderLandsAtTheReminderTime() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let morning = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 9))!
        // New cards are due now, so the reminder is today at 5 PM.
        let d = deck("A", 2, now: morning)
        let fire = FlashcardReminder.fireDate(for: [d], now: morning, minutes: 17 * 60, calendar: cal)!
        XCTAssertEqual(cal.component(.day, from: fire), 25)
        XCTAssertEqual(cal.component(.hour, from: fire), 17)
        // After 5 PM, it waits for tomorrow.
        let evening = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 20))!
        let next = FlashcardReminder.fireDate(for: [d], now: evening, minutes: 17 * 60, calendar: cal)!
        XCTAssertEqual(cal.component(.day, from: next), 26)
        // Cards due in 3 days: the reminder is on that day.
        var later = deck("B", 1, now: morning)
        later.cards[0].due = morning.addingTimeInterval(3 * SpacedRepetition.day)
        let then = FlashcardReminder.fireDate(for: [later], now: morning, minutes: 18 * 60 + 30, calendar: cal)!
        XCTAssertEqual(cal.component(.day, from: then), 28)
        XCTAssertEqual(cal.component(.hour, from: then), 18)
        XCTAssertEqual(cal.component(.minute, from: then), 30)
        // No cards, no reminder.
        XCTAssertNil(FlashcardReminder.fireDate(for: [FlashDeck(name: "Empty")], now: morning, minutes: 600, calendar: cal))
        XCTAssertEqual(FlashcardReminder.body(count: 1), "1 flashcard is ready to review. Say \"study my flashcards\" to start.")
    }

    // MARK: Ready-made decks

    func testLanguageDeckFromThePhrasebook() throws {
        let d = try XCTUnwrap(FlashcardSources.deck(.language("es"), now: t0))
        XCTAssertEqual(d.name, "Spanish")
        XCTAssertEqual(d.source, "phrasebook:es")
        XCTAssertEqual(d.cards.count, FlashcardSources.deckSize)
        XCTAssertNotNil(d.speech)
        XCTAssertTrue(d.cards.allSatisfy { !$0.front.isEmpty && !$0.back.isEmpty && !$0.front.contains("...") })
        let ja = try XCTUnwrap(FlashcardSources.deck(.language("ja"), now: t0))
        XCTAssertTrue(ja.cards.contains { $0.note?.hasPrefix("Say it: ") == true }, "Other alphabets say how to say it")
    }

    func testTriviaDeck() throws {
        let d = try XCTUnwrap(FlashcardSources.deck(.trivia("Space"), now: t0))
        XCTAssertEqual(d.name, "Space")
        XCTAssertEqual(d.cards.count, FlashcardSources.deckSize)
        for card in d.cards {
            let q = try XCTUnwrap(Trivia.all.first { $0.q == card.front })
            XCTAssertEqual(card.back, q.choices[q.answer])
        }
    }

    func testTopicsFindTheRightSource() {
        XCTAssertEqual(FlashcardSources.source(for: "spanish"), .language("es"))
        XCTAssertEqual(FlashcardSources.source(for: "French words"), .language("fr"))
        XCTAssertEqual(FlashcardSources.source(for: "spanish greetings"), .language("es"))
        XCTAssertEqual(FlashcardSources.source(for: "space"), .trivia("Space"))
        XCTAssertEqual(FlashcardSources.source(for: "the planets"), .trivia("Space"))
        XCTAssertNil(FlashcardSources.source(for: "the french revolution"))
        XCTAssertNil(FlashcardSources.source(for: "my science test"))
    }

    // MARK: The words

    private func ask(_ text: String) -> FlashcardAsk? {
        if case .flashcards(let a) = IntentRouter.parse(text) { return a }
        return nil
    }

    func testStudyWords() {
        XCTAssertEqual(ask("study my flashcards"), .study(deck: nil))
        XCTAssertEqual(ask("Study my Spanish flashcards"), .study(deck: "Spanish"))
        XCTAssertEqual(ask("let's study flashcards"), .study(deck: nil))
        XCTAssertEqual(ask("quiz me on my space flashcards"), .study(deck: "Space"))
        XCTAssertEqual(ask("review my cards"), .study(deck: nil))
        XCTAssertEqual(ask("flashcard time"), .study(deck: nil))
        XCTAssertEqual(ask("i want to study my spanish deck"), .study(deck: "Spanish"))
        XCTAssertEqual(ask("practice my flashcards"), .study(deck: nil))
    }

    func testOpenAndDueWords() {
        XCTAssertEqual(ask("flashcards"), .open)
        XCTAssertEqual(ask("show my flashcards"), .open)
        XCTAssertEqual(ask("open my flashcard decks"), .open)
        XCTAssertEqual(ask("delete my spanish deck"), .open)
        XCTAssertEqual(ask("how many flashcards are due"), .due)
        XCTAssertEqual(ask("do I have any cards to review?"), .due)
        XCTAssertEqual(ask("any flashcards due today"), .due)
    }

    func testMakeWords() {
        XCTAssertEqual(ask("make spanish flashcards"), .make("spanish"))
        XCTAssertEqual(ask("Make me some flashcards about space"), .make("space"))
        XCTAssertEqual(ask("make flashcards"), .make(""))
        XCTAssertEqual(ask("make me a french deck"), .make("french"))
        XCTAssertEqual(ask("make a flashcard deck called Science Test"), .newDeck("Science Test"))
        XCTAssertEqual(ask("create a new deck named History unit 3"), .newDeck("History unit 3"))
        XCTAssertEqual(ask("make flashcards about the french revolution"), .newDeck("French revolution"))
        XCTAssertEqual(ask("make flashcards for my science test"), .newDeck("Science test"))
    }

    func testAddWords() {
        XCTAssertEqual(ask("add a flashcard: hola = hello"), .add(front: "Hola", back: "Hello", deck: nil))
        XCTAssertEqual(ask("Add a flashcard to Spanish: gato = cat"), .add(front: "Gato", back: "Cat", deck: "Spanish"))
        XCTAssertEqual(ask("add perro = dog to my spanish deck"), .add(front: "Perro", back: "Dog", deck: "Spanish"))
        XCTAssertEqual(ask("new flashcard: H2O means water"), .add(front: "H2O", back: "Water", deck: nil))
        XCTAssertEqual(ask("Hey Ace, can you add a flashcard: capital of France = Paris?"),
                       .add(front: "Capital of France", back: "Paris", deck: nil))
        XCTAssertEqual(ask("add a flashcard for loop: a loop that repeats"),
                       .add(front: "For loop", back: "A loop that repeats", deck: nil))
        XCTAssertEqual(ask("add a card to my science deck: mitochondria = powerhouse of the cell"),
                       .add(front: "Mitochondria", back: "Powerhouse of the cell", deck: "Science"))
        XCTAssertEqual(ask("add a flashcard"), .help)
    }

    func testNotFlashcards() {
        for text in ["quiz me", "quiz me on space", "trivia", "study session for 1 hour", "focus for 25 minutes",
                     "how do i make flashcards", "flashcard tips", "quizlet flashcards", "what is a steam deck",
                     "make a steam deck", "review the steam deck", "how many cards are in a deck",
                     "how do i shuffle a deck of cards", "when is my report card due", "when is my credit card payment due",
                     "add milk to my shopping list", "add 2 + 2", "make a card for mom's birthday", "make a birthday card",
                     "what are flashcards", "are flashcards good to study with", "remind me to study my flashcards at 5",
                     "set a timer for 10 minutes", "solve 2x + 3 = 11"] {
            XCTAssertNil(ask(text), text)
        }
    }

    func testPairs() {
        XCTAssertEqual(FlashcardText.pair("front: Paris, back: capital of France")?.back, "Capital of France")
        XCTAssertEqual(FlashcardText.pair("question: 2+2 answer: 4")?.front, "2+2")
        XCTAssertEqual(FlashcardText.pair("hola, hello")?.back, "Hello")
        XCTAssertNil(FlashcardText.pair("just some words"))
        let lines = FlashcardText.pairs(fromLines: "1. hola = hello\n- perro - dog\n\nnot a card\ngato\tcat")
        XCTAssertEqual(lines.map(\.front), ["Hola", "Perro", "Gato"])
        XCTAssertEqual(lines.map(\.back), ["Hello", "Dog", "Cat"])
    }

    // MARK: The store

    private func makeStore() -> (FlashcardStore, String) {
        let file = "flashcards-test-\(UUID().uuidString).json"
        let defaults = UserDefaults(suiteName: "flashcard-tests-\(UUID().uuidString)")!
        return (FlashcardStore(fileName: file, schedulesReminders: false, defaults: defaults), file)
    }

    private func cleanUp(_ file: String) {
        try? FileManager.default.removeItem(at: Persistence.url(file))
    }

    func testStoreSavesAndLoads() {
        let (store, file) = makeStore()
        defer { cleanUp(file) }
        let d = store.newDeck(named: "  science test ", now: t0)
        XCTAssertEqual(d.name, "Science test")
        XCTAssertEqual(store.addCard(front: "H2O", back: "water", to: d.id, now: t0)?.isNew, true)
        XCTAssertEqual(store.addCard(front: "h2o", back: "Water!", to: d.id, now: t0)?.isNew, false, "Same front updates the card")
        XCTAssertNil(store.addCard(front: " ", back: "x", to: d.id))
        XCTAssertEqual(store.deck(d.id)?.cards.count, 1)
        XCTAssertEqual(store.deck(d.id)?.cards.first?.back, "Water!")
        let again = FlashcardStore(fileName: file, schedulesReminders: false,
                                   defaults: UserDefaults(suiteName: "flashcard-tests-\(UUID().uuidString)")!)
        XCTAssertEqual(again.decks.count, 1)
        XCTAssertEqual(again.decks.first?.cards.first?.front, "H2O")
        XCTAssertEqual(again.lastDeckID, d.id)
        XCTAssertTrue(again.remindersOn)
        XCTAssertEqual(again.reminderMinutes, FlashcardReminder.defaultMinutes)
    }

    func testStoreFindsDecksByName() {
        let (store, file) = makeStore()
        defer { cleanUp(file) }
        let spanish = store.addDeck(FlashDeck(name: "Spanish words"))
        let science = store.newDeck(named: "Science test")
        XCTAssertEqual(store.deck(named: "spanish")?.id, spanish.id)
        XCTAssertEqual(store.deck(named: "Spanish Words deck")?.id, spanish.id)
        XCTAssertEqual(store.deck(named: "science test flashcards")?.id, science.id)
        XCTAssertNil(store.deck(named: "french"))
        // A second deck with the same name gets a number.
        XCTAssertEqual(store.newDeck(named: "science test").name, "Science test 2")
    }

    func testStoreGradesAndPractice() {
        let (store, file) = makeStore()
        defer { cleanUp(file) }
        let d = store.addDeck(deck("A", 3))
        let item = StudyItem(deck: d.id, card: d.cards[0].id)
        store.grade(item, .good, at: t0, practice: true)
        XCTAssertTrue(store.card(item)!.isNew, "Practice doesn't move cards")
        store.grade(item, .good, at: t0)
        XCTAssertEqual(store.card(item)?.interval, 1)
        XCTAssertEqual(store.dueCount(at: t0.addingTimeInterval(10)), 2)
        XCTAssertEqual(store.queue(deckID: d.id, practice: false, at: t0.addingTimeInterval(10)).total, 2)
        store.resetProgress(d.id, now: t0)
        XCTAssertTrue(store.card(item)!.isNew)
        XCTAssertEqual(store.card(item)?.id, item.card, "Starting over keeps the same cards")
    }

    func testStoreImportsAndDeletes() {
        let (store, file) = makeStore()
        defer { cleanUp(file) }
        let d = store.newDeck(named: "Spanish")
        let added = store.importPairs(FlashcardText.pairs(fromLines: "hola = hello\nperro = dog\nhola = hi"), to: d.id)
        XCTAssertEqual(added, 2)
        XCTAssertEqual(store.deck(d.id)?.cards.first?.back, "Hi")
        let card = store.deck(d.id)!.cards[1]
        store.deleteCard(card.id, from: d.id)
        XCTAssertEqual(store.deck(d.id)?.cards.count, 1)
        store.renameDeck(d.id, to: "spanish basics")
        XCTAssertEqual(store.deck(d.id)?.name, "Spanish basics")
        store.deleteDeck(d.id)
        XCTAssertTrue(store.decks.isEmpty)
        XCTAssertNil(store.lastDeckID)
    }

    // MARK: What Ace says

    func testWhenWords() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let now = cal.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 10))!
        XCTAssertEqual(FlashcardSkill.when(now.addingTimeInterval(30), now: now, calendar: cal), "now")
        XCTAssertEqual(FlashcardSkill.when(now.addingTimeInterval(20 * 60), now: now, calendar: cal), "in 20 minutes")
        XCTAssertTrue(FlashcardSkill.when(now.addingTimeInterval(3 * 3600), now: now, calendar: cal).hasPrefix("at "))
        XCTAssertTrue(FlashcardSkill.when(now.addingTimeInterval(SpacedRepetition.day), now: now, calendar: cal).hasPrefix("tomorrow at "))
        XCTAssertEqual(FlashcardSkill.list(["Spanish", "Space", "Science"]), "Spanish, Space and Science")
        XCTAssertEqual(FlashcardSkill.count(1), "1 card")
    }
}
