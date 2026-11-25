import XCTest
@testable import Ace

@MainActor
final class HabitTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private func makeStore() -> HabitStore {
        HabitStore(fileName: nil, calendar: calendar)
    }

    private func finish(_ store: HabitStore, _ habit: Habit, on date: Date) {
        while !store.isDone(habit, on: date) { store.tap(habit, now: date) }
    }

    func testNamesAreNeededShortAndUnique() {
        let store = makeStore()
        XCTAssertNil(store.add(title: "  ", symbol: "book.fill", color: .grape, goal: 1))
        XCTAssertNotNil(store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1))
        XCTAssertNil(store.add(title: " read ", symbol: "book.fill", color: .grape, goal: 1))
        let long = store.add(title: String(repeating: "x", count: 70), symbol: "book.fill", color: .mint, goal: 1)
        XCTAssertEqual(long?.title.count, HabitStore.maxTitle)
        XCTAssertEqual(store.habits.count, 2)
    }

    func testGoalsAndIconsAreKeptSensible() {
        let store = makeStore()
        XCTAssertEqual(store.add(title: "A", symbol: "nope", color: .sky, goal: 0)?.goal, 1)
        XCTAssertEqual(store.add(title: "B", symbol: "drop.fill", color: .sky, goal: 99)?.goal, HabitStore.maxGoal)
        XCTAssertEqual(store.habits.first?.symbol, HabitStore.symbols[0])
    }

    func testTappingFillsUpThenStartsOver() {
        let store = makeStore()
        let now = day(2026, 11, 25)
        let water = store.add(title: "Drink water", symbol: "drop.fill", color: .sky, goal: 3)!
        XCTAssertFalse(store.tap(water, now: now))
        XCTAssertFalse(store.tap(water, now: now))
        XCTAssertEqual(store.count(water, on: now), 2)
        XCTAssertFalse(store.isDone(water, on: now))
        XCTAssertTrue(store.tap(water, now: now), "The third tap finishes it")
        XCTAssertTrue(store.isDone(water, on: now))
        XCTAssertFalse(store.tap(water, now: now))
        XCTAssertEqual(store.count(water, on: now), 0, "A tap on a done habit starts the day over")
        store.tap(water, now: now)
        store.undo(water, now: now)
        store.undo(water, now: now)
        XCTAssertEqual(store.count(water, on: now), 0)
        XCTAssertNil(store.checks[water.id], "Empty days aren't kept")
    }

    func testDaysAreSeparate() {
        let store = makeStore()
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1)!
        store.tap(read, now: day(2026, 11, 24, 23))
        XCTAssertTrue(store.isDone(read, on: day(2026, 11, 24, 1)))
        XCTAssertFalse(store.isDone(read, on: day(2026, 11, 25, 0)))
        XCTAssertEqual(store.dayKey(day(2026, 3, 7)), "2026-03-07")
    }

    func testStreaks() {
        let store = makeStore()
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1)!
        for d in [20, 21, 22, 23, 24] { finish(store, read, on: day(2026, 11, d)) }
        // Today isn't done yet, so the streak still counts up to yesterday.
        XCTAssertEqual(store.streak(read, now: day(2026, 11, 25)), 5)
        finish(store, read, on: day(2026, 11, 25))
        XCTAssertEqual(store.streak(read, now: day(2026, 11, 25)), 6)
        // Missing yesterday and today breaks it.
        XCTAssertEqual(store.streak(read, now: day(2026, 11, 27)), 0)
        finish(store, read, on: day(2026, 11, 10))
        finish(store, read, on: day(2026, 11, 11))
        XCTAssertEqual(store.bestStreak(read), 6)
    }

    func testAHalfDoneDayDoesntCount() {
        let store = makeStore()
        let water = store.add(title: "Water", symbol: "drop.fill", color: .sky, goal: 4)!
        finish(store, water, on: day(2026, 11, 24))
        store.tap(water, now: day(2026, 11, 25))
        XCTAssertEqual(store.streak(water, now: day(2026, 11, 25)), 1)
        XCTAssertEqual(store.week(water, now: day(2026, 11, 25)), [false, false, false, false, false, true, false])
    }

    func testWeekAndDays() {
        let store = makeStore()
        let days = store.lastDays(7, now: day(2026, 11, 25, 18))
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first, day(2026, 11, 19, 0))
        XCTAssertEqual(days.last, day(2026, 11, 25, 0))
        XCTAssertEqual(store.lastDays(84, now: day(2026, 11, 25)).count, 84)
        XCTAssertTrue(store.lastDays(0).isEmpty)
    }

    func testTodayProgress() {
        let store = makeStore()
        let now = day(2026, 11, 25)
        XCTAssertEqual(store.todayProgress(now: now), 0)
        let water = store.add(title: "Water", symbol: "drop.fill", color: .sky, goal: 4)!
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1)!
        store.tap(water, now: now)
        store.tap(water, now: now)
        XCTAssertEqual(store.todayProgress(now: now), 0.25, accuracy: 0.0001)
        store.tap(read, now: now)
        XCTAssertEqual(store.todayProgress(now: now), 0.75, accuracy: 0.0001)
        XCTAssertEqual(store.doneToday(now: now), 1)
        finish(store, water, on: now)
        XCTAssertEqual(store.todayProgress(now: now), 1, accuracy: 0.0001)
        XCTAssertEqual(store.doneToday(now: now), 2)
    }

    func testHeatMapScoresIgnoreHabitsThatDidntExistYet() {
        let store = makeStore()
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1, now: day(2026, 11, 1))!
        _ = store.add(title: "Stretch", symbol: "figure.cooldown", color: .rose, goal: 1, now: day(2026, 11, 20))
        finish(store, read, on: day(2026, 11, 10))
        finish(store, read, on: day(2026, 11, 21))
        XCTAssertEqual(store.dayScore(day(2026, 11, 10)), 1, accuracy: 0.0001)
        XCTAssertEqual(store.dayScore(day(2026, 11, 21)), 0.5, accuracy: 0.0001)
        XCTAssertEqual(store.dayScore(day(2026, 10, 1)), 0)
    }

    func testIdeas() {
        let store = makeStore()
        let all = HabitIdea.all
        XCTAssertEqual(Set(all.map(\.title)).count, all.count)
        for idea in all {
            XCTAssertTrue(HabitStore.symbols.contains(idea.symbol), idea.title)
            XCTAssertTrue((1...HabitStore.maxGoal).contains(idea.goal))
        }
        let water = all.first { $0.title == "Drink water" }!
        XCTAssertEqual(store.add(water)?.goal, 8)
        XCTAssertNil(store.add(water), "An idea adds once")
        XCTAssertTrue(store.has("drink water"))
        XCTAssertEqual(Set(HabitStore.symbols).count, HabitStore.symbols.count)
    }

    func testEditingMovingAndDeleting() {
        let store = makeStore()
        let now = day(2026, 11, 25)
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 1)!
        let walk = store.add(title: "Walk", symbol: "figure.run", color: .flame, goal: 1)!
        var changed = read
        changed.title = "Walk"
        changed.goal = 3
        changed.symbol = "not.real"
        store.update(changed)
        XCTAssertEqual(store.habits[0].title, "Read", "A name that's taken is kept as it was")
        XCTAssertEqual(store.habits[0].goal, 3)
        XCTAssertEqual(store.habits[0].symbol, "book.fill")
        changed.title = "Read 20 pages"
        store.update(changed)
        XCTAssertEqual(store.habits[0].title, "Read 20 pages")
        store.move(from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(store.habits.map(\.id), [walk.id, read.id])
        store.tap(walk, now: now)
        store.delete(walk.id)
        XCTAssertEqual(store.habits.map(\.id), [read.id])
        XCTAssertNil(store.checks[walk.id], "Deleting a habit deletes its ticks")
    }

    func testHabitsAreSaved() {
        let name = "habits-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let store = HabitStore(fileName: name, calendar: calendar)
        let read = store.add(title: "Read", symbol: "book.fill", color: .grape, goal: 2)!
        store.tap(read, now: day(2026, 11, 25))
        let again = HabitStore(fileName: name, calendar: calendar)
        XCTAssertEqual(again.habits.map(\.title), ["Read"])
        XCTAssertEqual(again.habits.first?.goal, 2)
        XCTAssertEqual(again.habits.first?.color, .grape)
        XCTAssertEqual(again.count(again.habits[0], on: day(2026, 11, 25)), 1)
    }

    func testColors() {
        XCTAssertEqual(HabitColor.allCases.count, 6)
        for color in HabitColor.allCases {
            XCTAssertFalse(color.label.isEmpty)
            XCTAssertNotEqual(color.hexes.0, color.hexes.1)
        }
    }

    func testTheNewsMentionsHabits() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 60 }) else {
            return XCTFail("Build 60 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Habits") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
