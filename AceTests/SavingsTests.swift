import XCTest
@testable import Ace

@MainActor
final class SavingsTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1
        return cal
    }()

    private let us = Locale(identifier: "en_US")

    private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private func makeStore() -> SavingsStore {
        SavingsStore(fileName: nil, calendar: calendar)
    }

    func testMoneyText() {
        XCTAssertEqual(SavingsMoney.text(1250, locale: us), "$12.50")
        XCTAssertEqual(SavingsMoney.text(2000, locale: us), "$20")
        XCTAssertEqual(SavingsMoney.text(5, locale: us), "$0.05")
        XCTAssertEqual(SavingsMoney.text(0, locale: us), "$0")
        XCTAssertEqual(SavingsMoney.text(123_456_78, locale: us), "$123,456.78")
    }

    func testReadingTypedMoney() {
        XCTAssertEqual(SavingsMoney.cents(from: "12"), 1200)
        XCTAssertEqual(SavingsMoney.cents(from: "12.5"), 1250)
        XCTAssertEqual(SavingsMoney.cents(from: " $12.50 "), 1250)
        XCTAssertEqual(SavingsMoney.cents(from: "12,50"), 1250)
        XCTAssertEqual(SavingsMoney.cents(from: "1,250.00"), 125_000)
        XCTAssertEqual(SavingsMoney.cents(from: ".75"), 75)
        XCTAssertEqual(SavingsMoney.cents(from: "3."), 300)
        XCTAssertNil(SavingsMoney.cents(from: ""))
        XCTAssertNil(SavingsMoney.cents(from: "0"))
        XCTAssertNil(SavingsMoney.cents(from: "0.00"))
        XCTAssertNil(SavingsMoney.cents(from: "-5"))
        XCTAssertNil(SavingsMoney.cents(from: "1.234"))
        XCTAssertNil(SavingsMoney.cents(from: "1.2.3"))
        XCTAssertNil(SavingsMoney.cents(from: "five"))
        XCTAssertNil(SavingsMoney.cents(from: "."))
        XCTAssertNil(SavingsMoney.cents(from: "99999999"), "Too big")
        XCTAssertEqual(SavingsMoney.cents(from: "999999.99"), SavingsStore.maxCents)
    }

    func testEditorShowsPricesPlainly() {
        XCTAssertEqual(SavingsEditor.plain(1250), "12.50")
        XCTAssertEqual(SavingsEditor.plain(2000), "20")
        XCTAssertEqual(SavingsEditor.plain(5), "0.05")
        XCTAssertEqual(SavingsMoney.cents(from: SavingsEditor.plain(4999)), 4999)
    }

    func testAddingAGoalNeedsANameAndAPrice() {
        let store = makeStore()
        XCTAssertNil(store.add(title: "   ", targetCents: 1000, symbol: "bicycle", color: .sky))
        XCTAssertNil(store.add(title: "Bike", targetCents: 0, symbol: "bicycle", color: .sky))
        let bike = store.add(title: "  New bike\n", targetCents: 15_000, symbol: "bicycle", color: .sky)
        XCTAssertEqual(bike?.title, "New bike")
        XCTAssertEqual(bike?.savedCents, 0)
        XCTAssertEqual(bike?.progress, 0)
        let odd = store.add(title: String(repeating: "a", count: 90), targetCents: SavingsStore.maxCents * 2,
                            symbol: "not.a.symbol", color: .gold)
        XCTAssertEqual(odd?.title.count, SavingsStore.maxTitle)
        XCTAssertEqual(odd?.targetCents, SavingsStore.maxCents)
        XCTAssertEqual(odd?.symbol, SavingsStore.symbols[0])
        XCTAssertEqual(store.goals.count, 2)
    }

    func testDepositsAndWithdrawals() throws {
        let store = makeStore()
        let game = try XCTUnwrap(store.add(title: "Game", targetCents: 6000, symbol: "gamecontroller.fill", color: .grape))
        XCTAssertEqual(store.deposit(game.id, cents: 0), 0)
        XCTAssertEqual(store.deposit(game.id, cents: -100), 0)
        XCTAssertEqual(store.deposit(game.id, cents: 2000, note: "Birthday money"), 2000)
        XCTAssertEqual(store.deposit(game.id, cents: 500), 500)
        XCTAssertEqual(store.goal(game.id)?.savedCents, 2500)
        XCTAssertEqual(store.goal(game.id)?.leftCents, 3500)
        XCTAssertEqual(try XCTUnwrap(store.goal(game.id)?.progress), 2500.0 / 6000.0, accuracy: 0.0001)

        // You can't take out more than is in the jar.
        XCTAssertEqual(store.withdraw(game.id, cents: 9000), 2500)
        XCTAssertEqual(store.goal(game.id)?.savedCents, 0)
        XCTAssertEqual(store.withdraw(game.id, cents: 100), 0)
        XCTAssertEqual(store.goal(game.id)?.entries.count, 3)
        XCTAssertEqual(store.goal(game.id)?.entries.first?.note, "Birthday money")
    }

    func testReachingAGoalAndSorting() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.add(title: "Cheap", targetCents: 500, symbol: "star.fill", color: .gold))
        let b = try XCTUnwrap(store.add(title: "Big", targetCents: 50_000, symbol: "bicycle", color: .sky))
        store.deposit(a.id, cents: 700)
        XCTAssertEqual(store.goal(a.id)?.isReached, true)
        XCTAssertEqual(store.goal(a.id)?.progress, 1)
        XCTAssertEqual(store.goal(a.id)?.leftCents, 0)
        XCTAssertEqual(store.sorted.map(\.id), [b.id, a.id], "Reached jars go to the end")
        XCTAssertEqual(store.totalSaved, 700)
    }

    func testAJarCantOverflow() throws {
        let store = makeStore()
        let big = try XCTUnwrap(store.add(title: "Huge", targetCents: SavingsStore.maxCents, symbol: "star.fill", color: .gold))
        XCTAssertEqual(store.deposit(big.id, cents: SavingsStore.maxCents - 100), SavingsStore.maxCents - 100)
        XCTAssertEqual(store.deposit(big.id, cents: 500), 100)
        XCTAssertEqual(store.deposit(big.id, cents: 500), 0)
    }

    func testRemovingAnEntry() throws {
        let store = makeStore()
        let goal = try XCTUnwrap(store.add(title: "Shoes", targetCents: 8000, symbol: "star.fill", color: .rose))
        store.deposit(goal.id, cents: 1000)
        store.deposit(goal.id, cents: 9900, note: "Oops")
        let oops = try XCTUnwrap(store.goal(goal.id)?.entries.last)
        store.removeEntry(goal.id, entry: oops.id)
        XCTAssertEqual(store.goal(goal.id)?.savedCents, 1000)
    }

    func testEditingAndDeleting() throws {
        let store = makeStore()
        let goal = try XCTUnwrap(store.add(title: "Lego", targetCents: 4000, symbol: "cube.fill", color: .flame))
        store.edit(goal.id, title: "  ", targetCents: 0, symbol: "nope", color: .mint)
        XCTAssertEqual(store.goal(goal.id)?.title, "Lego", "A blank name is ignored")
        XCTAssertEqual(store.goal(goal.id)?.targetCents, 4000, "A zero price is ignored")
        XCTAssertEqual(store.goal(goal.id)?.symbol, "cube.fill")
        XCTAssertEqual(store.goal(goal.id)?.color, .mint)
        store.edit(goal.id, title: "Big Lego set", targetCents: 12_000, symbol: "crown.fill", color: .gold)
        XCTAssertEqual(store.goal(goal.id)?.title, "Big Lego set")
        XCTAssertEqual(store.goal(goal.id)?.targetCents, 12_000)
        XCTAssertEqual(store.goal(goal.id)?.symbol, "crown.fill")
        store.delete(goal.id)
        XCTAssertNil(store.goal(goal.id))
        XCTAssertEqual(store.deposit(goal.id, cents: 100), 0)
    }

    func testWeeklyTotals() throws {
        let store = makeStore()
        let goal = try XCTUnwrap(store.add(title: "Bike", targetCents: 20_000, symbol: "bicycle", color: .sky, now: day(2026, 10, 1)))
        // Wednesday Nov 25, 2026. Weeks start on Sunday: this week began Nov 22.
        let now = day(2026, 11, 25)
        store.deposit(goal.id, cents: 1000, now: day(2026, 11, 23))
        store.deposit(goal.id, cents: 500, now: day(2026, 11, 22, 0))
        store.withdraw(goal.id, cents: 200, now: day(2026, 11, 24))
        store.deposit(goal.id, cents: 700, now: day(2026, 11, 21, 23)) // last week
        store.deposit(goal.id, cents: 300, now: day(2026, 11, 3)) // three weeks back
        store.deposit(goal.id, cents: 999, now: day(2026, 10, 2)) // too long ago
        XCTAssertEqual(store.weekly(goal.id, weeks: 4, now: now), [300, 0, 700, 1300])
        XCTAssertEqual(store.weekly(goal.id, weeks: 0, now: now), [])
        XCTAssertEqual(store.weekly(UUID(), weeks: 4, now: now), [])
    }

    func testEstimate() throws {
        let store = makeStore()
        let goal = try XCTUnwrap(store.add(title: "Headphones", targetCents: 10_000, symbol: "headphones", color: .mint))
        let now = day(2026, 11, 25)
        XCTAssertNil(store.estimate(goal.id, now: now), "Nothing saved yet")
        // 28 days of saving at 1 dollar a day: 2800 cents in, 7200 left, so 72 more days.
        store.deposit(goal.id, cents: 2800, now: day(2026, 11, 10))
        let date = try XCTUnwrap(store.estimate(goal.id, now: now))
        XCTAssertEqual(calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: date).day, 72)
        // Old savings don't count toward the pace.
        let old = try XCTUnwrap(store.add(title: "Old", targetCents: 10_000, symbol: "star.fill", color: .gold))
        store.deposit(old.id, cents: 5000, now: day(2026, 9, 1))
        XCTAssertNil(store.estimate(old.id, now: now))
        // A reached goal has no estimate.
        store.deposit(goal.id, cents: 9000, now: now)
        XCTAssertNil(store.estimate(goal.id, now: now))
    }

    func testJarCoinsStayInside() {
        for i in 0..<72 {
            let spot = SavingsJar.coinSpot(i)
            XCTAssertGreaterThan(spot.x, 0)
            XCTAssertLessThan(spot.x, 1)
            XCTAssertGreaterThan(spot.y, 0)
        }
        XCTAssertEqual(SavingsJar.coinSpot(5).x, SavingsJar.coinSpot(5).x, "The same coin lands in the same spot")
    }

    func testGoalsAreSaved() throws {
        let name = "savings-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let first = SavingsStore(fileName: name, calendar: calendar)
        let goal = try XCTUnwrap(first.add(title: "Trip", targetCents: 30_000, symbol: "airplane", color: .sky))
        first.deposit(goal.id, cents: 4200, note: "Chores")

        let again = SavingsStore(fileName: name, calendar: calendar)
        XCTAssertEqual(again.goal(goal.id)?.title, "Trip")
        XCTAssertEqual(again.goal(goal.id)?.savedCents, 4200)
        XCTAssertEqual(again.goal(goal.id)?.entries.first?.note, "Chores")
    }

    func testWhatsNewHasBuild70() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 70 }) else {
            return XCTFail("Build 70 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Savings jars") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
