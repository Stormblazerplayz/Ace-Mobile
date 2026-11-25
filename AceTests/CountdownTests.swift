import XCTest
@testable import Ace

@MainActor
final class CountdownTests: XCTestCase {
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    private func makeStore() -> CountdownStore {
        CountdownStore(fileName: nil, calendar: calendar)
    }

    @discardableResult
    private func add(_ store: CountdownStore, _ title: String, _ date: Date, allDay: Bool = true,
                     yearly: Bool = false, now: Date) -> Countdown? {
        store.add(title: title, date: date, allDay: allDay, repeatsYearly: yearly,
                  symbol: "star.fill", theme: .ocean, now: now)
    }

    func testANameIsNeededAndKeptShort() {
        let store = makeStore()
        let now = day(2026, 11, 25, 12)
        XCTAssertNil(add(store, "   ", day(2026, 12, 1), now: now))
        let long = String(repeating: "a", count: 60)
        let item = add(store, "  " + long, day(2026, 12, 1), now: now)
        XCTAssertEqual(item?.title.count, CountdownStore.maxTitle)
        XCTAssertEqual(store.countdowns.count, 1)
    }

    func testADayThatsOverIsRefusedUnlessItRepeats() {
        let store = makeStore()
        let now = day(2026, 11, 25, 12)
        XCTAssertNil(add(store, "Old trip", day(2026, 11, 20), now: now))
        XCTAssertNotNil(add(store, "My birthday", day(2026, 11, 20), yearly: true, now: now))
        XCTAssertEqual(store.countdowns.map(\.title), ["My birthday"])
    }

    func testUnknownIconsBecomeTheFirstOne() {
        let store = makeStore()
        let item = store.add(title: "Party", date: day(2026, 12, 1), allDay: true, repeatsYearly: false,
                             symbol: "not.a.symbol", theme: .candy, now: day(2026, 11, 25))
        XCTAssertEqual(item?.symbol, CountdownStore.symbols[0])
    }

    func testTodayIsHappeningAllDay() {
        let store = makeStore()
        let now = day(2026, 11, 25, 12)
        let item = add(store, "Thanksgiving trip", day(2026, 11, 25), now: now)!
        XCTAssertTrue(store.isHappening(item, now: now))
        XCTAssertTrue(store.left(item, now: now).isZero)
        XCTAssertFalse(store.isOver(item, now: now))
        XCTAssertEqual(store.upcoming(now: now).map(\.id), [item.id])
        // The next morning it's over.
        let tomorrow = day(2026, 11, 26, 0, 0, 1)
        XCTAssertTrue(store.isOver(item, now: tomorrow))
        XCTAssertEqual(store.past(now: tomorrow).map(\.id), [item.id])
        XCTAssertTrue(store.upcoming(now: tomorrow).isEmpty)
    }

    func testTimeLeftIsExact() {
        let store = makeStore()
        let now = day(2026, 11, 25, 10)
        let item = add(store, "Christmas", day(2026, 12, 25, 18, 30), now: now)!
        // All day counts to the start of the day.
        let left = store.left(item, now: now)
        XCTAssertEqual(left, CountdownLeft(days: 29, hours: 14, minutes: 0, seconds: 0))
        XCTAssertEqual(left.short, "29 days")
        XCTAssertEqual(store.occurrence(item, now: now), day(2026, 12, 25))
    }

    func testACountdownWithATime() {
        let store = makeStore()
        let item = add(store, "Game launch", day(2026, 11, 25, 18, 30), allDay: false, now: day(2026, 11, 25, 12))!
        XCTAssertEqual(store.left(item, now: day(2026, 11, 25, 12)),
                       CountdownLeft(days: 0, hours: 6, minutes: 30, seconds: 0))
        XCTAssertEqual(store.left(item, now: day(2026, 11, 25, 18, 29, 15)),
                       CountdownLeft(days: 0, hours: 0, minutes: 0, seconds: 45))
        XCTAssertTrue(store.isHappening(item, now: day(2026, 11, 25, 18, 45)))
        XCTAssertFalse(store.isOver(item, now: day(2026, 11, 25, 19, 29)))
        XCTAssertTrue(store.isOver(item, now: day(2026, 11, 25, 19, 31)))
    }

    func testYearlyOnesRollOnToNextYear() {
        let store = makeStore()
        let birthday = add(store, "My birthday", day(2014, 3, 14), yearly: true, now: day(2026, 11, 25))!
        XCTAssertEqual(store.occurrence(birthday, now: day(2026, 11, 25)), day(2027, 3, 14))
        XCTAssertEqual(store.occurrence(birthday, now: day(2027, 3, 14, 20)), day(2027, 3, 14))
        XCTAssertTrue(store.isHappening(birthday, now: day(2027, 3, 14, 20)))
        XCTAssertEqual(store.occurrence(birthday, now: day(2027, 3, 15, 0, 0, 1)), day(2028, 3, 14))
        XCTAssertFalse(store.isOver(birthday, now: day(2040, 1, 1)))
    }

    func testLeapDayBirthdays() {
        let store = makeStore()
        let leap = add(store, "Leap day", day(2024, 2, 29), yearly: true, now: day(2026, 11, 25))!
        XCTAssertEqual(store.occurrence(leap, now: day(2026, 11, 25)), day(2027, 2, 28))
        XCTAssertEqual(store.occurrence(leap, now: day(2027, 3, 1)), day(2028, 2, 29))
    }

    func testUpcomingIsSoonestFirst() {
        let store = makeStore()
        let now = day(2026, 11, 25, 12)
        add(store, "Christmas", day(2026, 12, 25), now: now)
        add(store, "Weekend", day(2026, 11, 28), now: now)
        add(store, "Birthday", day(2010, 12, 1), yearly: true, now: now)
        add(store, "Show", day(2026, 11, 25, 13), allDay: false, now: now)
        XCTAssertEqual(store.upcoming(now: now).map(\.title), ["Show", "Weekend", "Birthday", "Christmas"])
        let later = day(2026, 11, 29)
        XCTAssertEqual(store.upcoming(now: later).map(\.title), ["Birthday", "Christmas"])
        XCTAssertEqual(store.past(now: later).map(\.title), ["Weekend", "Show"])
    }

    func testHolidaysAddOnce() {
        let store = makeStore()
        let now = day(2026, 11, 25)
        let christmas = CountdownPreset.all.first { $0.title == "Christmas" }!
        XCTAssertFalse(store.has(christmas))
        let item = store.add(christmas, now: now)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.symbol, "gift.fill")
        XCTAssertTrue(item?.repeatsYearly == true)
        XCTAssertTrue(store.has(christmas))
        XCTAssertNil(store.add(christmas, now: now))
        XCTAssertEqual(store.countdowns.count, 1)
        XCTAssertEqual(store.occurrence(item!, now: day(2026, 12, 26)), day(2027, 12, 25))
        // A holiday earlier in the year than today still adds and rolls on to next year.
        let valentines = CountdownPreset.all.first { $0.title == "Valentine's Day" }!
        let v = store.add(valentines, now: now)!
        XCTAssertEqual(store.occurrence(v, now: now), day(2027, 2, 14))
    }

    func testHolidayListIsTidy() {
        let all = CountdownPreset.all
        XCTAssertEqual(all.count, 6)
        XCTAssertEqual(Set(all.map(\.title)).count, all.count)
        for preset in all {
            XCTAssertTrue(CountdownStore.symbols.contains(preset.symbol), preset.title)
            XCTAssertNotNil(calendar.date(from: DateComponents(year: 2027, month: preset.month, day: preset.day)))
        }
        XCTAssertEqual(Set(CountdownStore.symbols).count, CountdownStore.symbols.count)
    }

    func testProgressFillsUp() {
        let store = makeStore()
        let start = day(2026, 11, 15, 12)
        let item = add(store, "Trip", day(2026, 12, 5, 12), allDay: false, now: start)!
        XCTAssertEqual(store.progress(item, now: start), 0, accuracy: 0.001)
        XCTAssertEqual(store.progress(item, now: day(2026, 11, 25, 12)), 0.5, accuracy: 0.001)
        XCTAssertEqual(store.progress(item, now: day(2026, 12, 5, 12)), 1, accuracy: 0.001)
    }

    func testYearlyProgressStartsFromLastTime() {
        let store = makeStore()
        let item = add(store, "Birthday", day(2010, 5, 25), yearly: true, now: day(2000, 1, 1))!
        // From last May 25 to next May 25, halfway is about late November.
        let p = store.progress(item, now: day(2026, 11, 24))
        XCTAssertEqual(p, 0.5, accuracy: 0.01)
    }

    func testEditingAndDeleting() {
        let store = makeStore()
        let now = day(2026, 11, 25)
        var item = add(store, "Trip", day(2026, 12, 20), now: now)!
        item.title = "   "
        item.symbol = "nope"
        item.theme = .fire
        item.repeatsYearly = true
        store.update(item)
        let saved = store.countdowns.first!
        XCTAssertEqual(saved.title, "Trip")
        XCTAssertEqual(saved.symbol, "star.fill")
        XCTAssertEqual(saved.theme, .fire)
        XCTAssertTrue(saved.repeatsYearly)
        item.title = "Ski trip"
        store.update(item)
        XCTAssertEqual(store.countdowns.first?.title, "Ski trip")
        store.delete(item.id)
        XCTAssertTrue(store.countdowns.isEmpty)
    }

    func testCountdownsAreSaved() {
        let name = "countdowns-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let store = CountdownStore(fileName: name, calendar: calendar)
        store.add(title: "Last day of school", date: day(2030, 6, 12), allDay: true, repeatsYearly: false,
                  symbol: "graduationcap.fill", theme: .forest, now: day(2026, 11, 25))
        let again = CountdownStore(fileName: name, calendar: calendar)
        XCTAssertEqual(again.countdowns.count, 1)
        XCTAssertEqual(again.countdowns.first?.title, "Last day of school")
        XCTAssertEqual(again.countdowns.first?.symbol, "graduationcap.fill")
        XCTAssertEqual(again.countdowns.first?.theme, .forest)
        XCTAssertEqual(again.countdowns.first?.date, day(2030, 6, 12))
    }

    func testShortWords() {
        XCTAssertEqual(CountdownLeft(days: 1, hours: 3, minutes: 0, seconds: 0).short, "1 day")
        XCTAssertEqual(CountdownLeft(days: 0, hours: 5, minutes: 2, seconds: 0).short, "5 hours")
        XCTAssertEqual(CountdownLeft(days: 0, hours: 1, minutes: 0, seconds: 0).short, "1 hour")
        XCTAssertEqual(CountdownLeft(days: 0, hours: 0, minutes: 40, seconds: 9).short, "40 minutes")
        XCTAssertEqual(CountdownLeft(days: 0, hours: 0, minutes: 0, seconds: 1).short, "1 second")
        XCTAssertEqual(CountdownFormat.two(7), "07")
        XCTAssertEqual(CountdownFormat.two(12), "12")
    }

    func testThemes() {
        XCTAssertEqual(CountdownTheme.allCases.count, 6)
        for theme in CountdownTheme.allCases {
            XCTAssertEqual(theme.hexes.count, 3)
            XCTAssertFalse(theme.label.isEmpty)
        }
    }

    func testTheNewsMentionsCountdowns() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 65 }) else {
            return XCTFail("Build 65 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Countdowns") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
