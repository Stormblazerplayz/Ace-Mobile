import XCTest
@testable import Ace

/// Study cards: the Leitner boxes, sessions, streaks, your own cards and saving.
@MainActor
final class StudyTests: XCTestCase {
    private let day: TimeInterval = 86_400
    private var noon: Date {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 25; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private func question(_ id: String, _ category: String, answer: Int = 1) -> TriviaQuestion {
        TriviaQuestion(id: id, category: category, q: "Question \(id)?", choices: ["A", "B", "C", "D"], answer: answer, fact: "Fact \(id).")
    }

    private func smallStore(_ perDeck: Int = 30) -> StudyStore {
        var qs: [TriviaQuestion] = []
        for cat in ["Space", "Animals"] {
            for i in 0..<perDeck { qs.append(question("\(cat)-\(i)", cat)) }
        }
        return StudyStore(fileName: nil, trivia: qs)
    }

    // MARK: Leitner

    func testKnowingACardMovesItUpABoxAndItWaitsLonger() {
        var p = Leitner.next(after: nil, knew: true, now: noon)
        XCTAssertEqual(p.box, 1)
        XCTAssertEqual(p.due.timeIntervalSince(noon), 1 * day, accuracy: 1)
        p = Leitner.next(after: p, knew: true, now: noon)
        XCTAssertEqual(p.box, 2)
        XCTAssertEqual(p.due.timeIntervalSince(noon), 2 * day, accuracy: 1)
        XCTAssertEqual(p.seen, 2)
        XCTAssertEqual(p.right, 2)
    }

    func testMissingACardSendsItBackToTheStart() {
        var p = CardProgress(box: 4, due: noon, seen: 6, right: 5)
        p = Leitner.next(after: p, knew: false, now: noon)
        XCTAssertEqual(p.box, 0)
        XCTAssertEqual(p.due, noon, "A missed card is due again right away")
        XCTAssertEqual(p.seen, 7)
        XCTAssertEqual(p.right, 5)
    }

    func testTheTopBoxIsTheLimit() {
        var p: CardProgress?
        for _ in 0..<20 { p = Leitner.next(after: p, knew: true, now: noon) }
        XCTAssertEqual(p?.box, Leitner.topBox)
        XCTAssertEqual(p!.due.timeIntervalSince(noon), Leitner.intervals.last! * day, accuracy: 1)
        for i in 1..<Leitner.intervals.count {
            XCTAssertGreaterThan(Leitner.intervals[i], Leitner.intervals[i - 1], "Each box waits longer than the one before")
        }
        XCTAssertLessThanOrEqual(Leitner.masteredBox, Leitner.topBox)
    }

    // MARK: Decks

    func testEveryTriviaQuestionBecomesACard() {
        let cards = StudyStore.cards(from: Trivia.all)
        XCTAssertEqual(cards.count, Trivia.all.count)
        XCTAssertEqual(Set(cards.map(\.id)).count, cards.count, "Two cards share an id")
        let first = Trivia.all[0]
        let card = cards[0]
        XCTAssertEqual(card.front, first.q)
        XCTAssertEqual(card.back, first.choices[first.answer])
        XCTAssertEqual(card.note, first.fact)
        XCTAssertFalse(card.mine)
    }

    func testABrokenQuestionIsSkipped() {
        let cards = StudyStore.cards(from: [question("ok", "Space"), question("bad", "Space", answer: 9)])
        XCTAssertEqual(cards.map(\.id), ["t-ok"])
    }

    func testTheRealDecksMatchTheTriviaCategories() {
        let store = StudyStore(fileName: nil)
        XCTAssertEqual(store.decks.map(\.name), Trivia.categories)
        XCTAssertEqual(store.decks.reduce(0) { $0 + $1.cards.count }, Trivia.all.count)
        for deck in store.decks {
            XCTAssertFalse(deck.cards.isEmpty, deck.name)
            XCTAssertEqual(deck.colors.count, 2, deck.name)
            XCTAssertNotEqual(deck.symbol, StudyDeck.style(for: "Something else").symbol, "\(deck.name) needs its own icon")
            XCTAssertTrue(deck.cards.allSatisfy { $0.deck == deck.name })
        }
    }

    // MARK: Sessions

    func testANewDeckHandsOutTenNewCards() {
        let store = smallStore()
        let deck = store.deck(named: "Space")!
        let session = store.session(for: deck, now: noon)
        XCTAssertEqual(session.count, StudyStore.newPerSession)
        XCTAssertEqual(Set(session.map(\.id)).count, session.count)
        XCTAssertTrue(session.allSatisfy { $0.deck == "Space" })
    }

    func testDueCardsComeFirstAndCardsThatArentDueStayAway() {
        let store = smallStore()
        let deck = store.deck(named: "Space")!
        let cards = deck.cards
        store.grade(cards[0], knew: false, now: noon)                 // due right away
        store.grade(cards[1], knew: false, now: noon.addingTimeInterval(-60)) // due a minute earlier
        store.grade(cards[2], knew: true, now: noon)                  // due tomorrow

        let session = store.session(for: deck, now: noon, shuffle: false)
        XCTAssertEqual(session.first?.id, cards[1].id, "The most overdue card comes first")
        XCTAssertEqual(session[1].id, cards[0].id)
        XCTAssertFalse(session.contains { $0.id == cards[2].id }, "A card due tomorrow isn't in today's session")
        XCTAssertEqual(session.count, 2 + StudyStore.newPerSession)

        let tomorrow = store.session(for: deck, now: noon.addingTimeInterval(day + 60), shuffle: false)
        XCTAssertTrue(tomorrow.contains { $0.id == cards[2].id }, "It comes back when it's due")
    }

    func testASessionNeverGetsTooBig() {
        let store = smallStore(60)
        let deck = store.deck(named: "Space")!
        for card in deck.cards.prefix(40) { store.grade(card, knew: false, now: noon) }
        XCTAssertEqual(store.session(for: deck, now: noon).count, StudyStore.sessionSize)
    }

    func testStatsCountMasteredDueAndNewCards() {
        let store = smallStore()
        let deck = store.deck(named: "Animals")!
        let card = deck.cards[0]
        for i in 0..<Leitner.masteredBox {
            store.grade(card, knew: true, now: noon.addingTimeInterval(Double(i)))
        }
        store.grade(deck.cards[1], knew: false, now: noon)
        let stats = store.stats(for: store.deck(named: "Animals")!, now: noon.addingTimeInterval(10))
        XCTAssertEqual(stats.total, 30)
        XCTAssertEqual(stats.mastered, 1)
        XCTAssertEqual(stats.learning, 1)
        XCTAssertEqual(stats.due, 1)
        XCTAssertEqual(stats.fresh, 28)
        XCTAssertEqual(stats.progress, 1.0 / 30, accuracy: 0.0001)
        XCTAssertEqual(store.masteredCount, 1)
        XCTAssertEqual(store.dueCount(now: noon.addingTimeInterval(10)), 1)
    }

    func testQuickReviewHoldsOnlyDueCardsFromEveryDeck() {
        let store = smallStore()
        let space = store.deck(named: "Space")!.cards[0]
        let animal = store.deck(named: "Animals")!.cards[0]
        let later = store.deck(named: "Animals")!.cards[1]
        store.grade(space, knew: false, now: noon)
        store.grade(animal, knew: false, now: noon)
        store.grade(later, knew: true, now: noon)
        let review = store.reviewDeck(now: noon)
        XCTAssertEqual(Set(review.cards.map(\.id)), [space.id, animal.id])
        XCTAssertEqual(review.name, StudyStore.reviewDeckName)
        XCTAssertEqual(store.session(for: review, now: noon).count, 2)
    }

    func testStartingADeckOverForgetsItsProgress() {
        let store = smallStore()
        let deck = store.deck(named: "Space")!
        store.grade(deck.cards[0], knew: true, now: noon)
        store.grade(store.deck(named: "Animals")!.cards[0], knew: true, now: noon)
        store.reset(deck)
        XCTAssertNil(store.progress[deck.cards[0].id])
        XCTAssertEqual(store.progress.count, 1, "Other decks keep their progress")
    }

    // MARK: Streaks and the daily goal

    func testStudyingOnDaysInARowBuildsAStreak() {
        let store = smallStore()
        let card = store.decks[0].cards[0]
        XCTAssertEqual(store.currentStreak(now: noon), 0)
        store.grade(card, knew: true, now: noon)
        store.grade(card, knew: true, now: noon.addingTimeInterval(60))
        XCTAssertEqual(store.currentStreak(now: noon), 1, "Two cards on one day is still one day")
        store.grade(card, knew: true, now: noon.addingTimeInterval(day))
        store.grade(card, knew: true, now: noon.addingTimeInterval(2 * day))
        XCTAssertEqual(store.currentStreak(now: noon.addingTimeInterval(2 * day)), 3)
        XCTAssertEqual(store.currentStreak(now: noon.addingTimeInterval(3 * day)), 3, "It holds through the next day")
        XCTAssertEqual(store.currentStreak(now: noon.addingTimeInterval(4 * day)), 0, "A missed day ends it")
        XCTAssertEqual(store.bestStreak, 3)
    }

    func testSkippingADayStartsTheStreakOver() {
        let store = smallStore()
        let card = store.decks[0].cards[0]
        store.grade(card, knew: true, now: noon)
        store.grade(card, knew: true, now: noon.addingTimeInterval(day))
        store.grade(card, knew: true, now: noon.addingTimeInterval(3 * day))
        XCTAssertEqual(store.currentStreak(now: noon.addingTimeInterval(3 * day)), 1)
        XCTAssertEqual(store.bestStreak, 2)
    }

    func testTheDailyGoalCountsTodaysCardsOnly() {
        let store = smallStore()
        let cards = store.decks[0].cards
        for i in 0..<5 { store.grade(cards[i], knew: true, now: noon) }
        XCTAssertEqual(store.reviewsToday(now: noon), 5)
        XCTAssertEqual(store.goalProgress(now: noon), 5.0 / Double(StudyStore.dailyGoal), accuracy: 0.0001)
        XCTAssertEqual(store.reviewsToday(now: noon.addingTimeInterval(day)), 0, "A new day starts at zero")
        store.grade(cards[5], knew: true, now: noon.addingTimeInterval(day))
        XCTAssertEqual(store.reviewsToday(now: noon.addingTimeInterval(day)), 1)
        for i in 0..<30 { store.grade(cards[i], knew: true, now: noon.addingTimeInterval(day)) }
        XCTAssertEqual(store.goalProgress(now: noon.addingTimeInterval(day)), 1, "The ring stops at full")
        XCTAssertEqual(store.totalReviews, 36)
    }

    // MARK: Your own cards

    func testYouCanAddYourOwnCards() throws {
        let store = smallStore()
        XCTAssertEqual(store.decks.count, 2, "No My cards deck until you make one")
        let card = try store.addCard(front: "  What is 7 x 8?  ", back: " 56 ", note: "Five, six, seven, eight").get()
        XCTAssertEqual(card.front, "What is 7 x 8?")
        XCTAssertEqual(card.back, "56")
        XCTAssertTrue(card.mine)
        XCTAssertEqual(store.decks.first?.name, StudyDeck.myDeckName, "Your deck comes first")
        XCTAssertEqual(store.decks.first?.cards, [card])
    }

    func testBadCardsAreTurnedAway() {
        let store = smallStore()
        XCTAssertEqual(store.addCard(front: "   ", back: "x"), .failure(.emptyFront))
        XCTAssertEqual(store.addCard(front: "Q", back: "\n"), .failure(.emptyBack))
        XCTAssertEqual(store.addCard(front: String(repeating: "a", count: StudyStore.maxFront + 1), back: "x"), .failure(.tooLong))
        XCTAssertEqual(store.addCard(front: "Q", back: String(repeating: "b", count: StudyStore.maxBack + 1)), .failure(.tooLong))
        XCTAssertNoThrow(try store.addCard(front: "Capital of Peru?", back: "Lima").get())
        XCTAssertEqual(store.addCard(front: "capital of peru?", back: "Lima"), .failure(.duplicate))
        XCTAssertEqual(store.myCards.count, 1)
    }

    func testDeletingYourCardRemovesItAndItsProgress() throws {
        let store = smallStore()
        let card = try store.addCard(front: "Q", back: "A").get()
        store.grade(card, knew: true, now: noon)
        store.deleteCard(card)
        XCTAssertTrue(store.myCards.isEmpty)
        XCTAssertNil(store.progress[card.id])
        XCTAssertEqual(store.decks.count, 2)

        let trivia = store.decks[0].cards[0]
        store.deleteCard(trivia)
        XCTAssertEqual(store.decks[0].cards.count, 30, "Ace's own cards can't be deleted")
    }

    // MARK: Saving

    func testEverythingIsSavedForNextTime() throws {
        let name = "study-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let qs = [question("s1", "Space"), question("s2", "Space")]

        // Whole seconds, since dates are saved to the second.
        let now = Date(timeIntervalSince1970: Date().timeIntervalSince1970.rounded(.down))
        let store = StudyStore(fileName: name, trivia: qs)
        let mine = try store.addCard(front: "Q", back: "A").get()
        store.grade(store.deck(named: "Space")!.cards[0], knew: true, now: now)
        store.grade(mine, knew: false, now: now)

        let again = StudyStore(fileName: name, trivia: qs)
        XCTAssertEqual(again.myCards, [mine])
        XCTAssertEqual(again.progress, store.progress)
        XCTAssertEqual(again.streak, 1)
        XCTAssertEqual(again.totalReviews, 2)
        XCTAssertEqual(again.reviewsToday(now: now), 2)
        XCTAssertEqual(again.lastStudyDay, Persistence.dayKey(now))
    }

    func testTheNewsMentionsStudyCards() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 60 }) else {
            return XCTFail("Build 60 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Study") })
    }
}
