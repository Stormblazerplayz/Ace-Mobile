import XCTest
@testable import Ace

/// The mood journal: writing days, streaks, averages, the month grid, insights, search and saving.
@MainActor
final class JournalTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 1
        return c
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private var now: Date { day(2026, 11, 25, hour: 18) }

    private func store() -> JournalStore {
        JournalStore(fileName: nil, calendar: cal)
    }

    // MARK: Moods

    func testMoodsGoFromAwesomeToRough() {
        XCTAssertEqual(JournalMood.allCases.map(\.score), [5, 4, 3, 2, 1])
        XCTAssertEqual(Set(JournalMood.allCases.map(\.symbol)).count, 5, "Each mood needs its own icon")
        for mood in JournalMood.allCases { XCTAssertEqual(mood.hexes.count, 2) }
        XCTAssertEqual(JournalMood.nearest(to: 4.6), .awesome)
        XCTAssertEqual(JournalMood.nearest(to: 3.2), .okay)
        XCTAssertEqual(JournalMood.nearest(to: 1.4), .rough)
    }

    // MARK: Writing

    func testSavingADayKeepsTheMoodWordsAndTags() throws {
        let s = store()
        let entry = try XCTUnwrap(s.save(mood: .good, text: "  Built a new level  ", tags: ["Building", "Friends"], on: now, now: now))
        XCTAssertEqual(entry.day, "2026-11-25")
        XCTAssertEqual(entry.text, "Built a new level")
        XCTAssertEqual(entry.tags, ["Building", "Friends"])
        XCTAssertEqual(s.entry(on: day(2026, 11, 25, hour: 1))?.mood, .good, "Any time that day finds it")
        XCTAssertNil(s.entry(on: day(2026, 11, 24)))
    }

    func testWritingTheSameDayAgainReplacesIt() {
        let s = store()
        s.save(mood: .meh, text: "Tired", tags: [], on: now, now: now)
        s.save(mood: .awesome, text: "Got better!", tags: ["Sports"], on: now, now: now)
        XCTAssertEqual(s.entries.count, 1)
        XCTAssertEqual(s.entries.first?.mood, .awesome)
        XCTAssertEqual(s.entries.first?.text, "Got better!")
    }

    func testUnknownAndRepeatedTagsAreDropped() {
        let s = store()
        let e = s.save(mood: .okay, text: "", tags: ["Gaming", "Gaming", "Not a tag", "Rest"], on: now, now: now)
        XCTAssertEqual(e?.tags, ["Gaming", "Rest"])
    }

    func testYouCantWriteAboutTomorrow() {
        let s = store()
        XCTAssertNil(s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 26, hour: 9), now: now))
        XCTAssertTrue(s.entries.isEmpty)
        XCTAssertNotNil(s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 20), now: now), "Past days are fine")
    }

    func testVeryLongWordsAreCut() {
        let s = store()
        let e = s.save(mood: .good, text: String(repeating: "a", count: JournalStore.maxText + 50), tags: [], on: now, now: now)
        XCTAssertEqual(e?.text.count, JournalStore.maxText)
    }

    func testEntriesAreNewestFirstAndCanBeDeleted() {
        let s = store()
        s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 20), now: now)
        s.save(mood: .okay, text: "", tags: [], on: day(2026, 11, 25), now: now)
        s.save(mood: .meh, text: "", tags: [], on: day(2026, 11, 22), now: now)
        XCTAssertEqual(s.entries.map(\.day), ["2026-11-25", "2026-11-22", "2026-11-20"])
        s.delete(on: day(2026, 11, 22))
        XCTAssertEqual(s.entries.map(\.day), ["2026-11-25", "2026-11-20"])
    }

    // MARK: Streaks and trends

    func testTheStreakCountsDaysInARow() {
        let s = store()
        XCTAssertEqual(s.streak(now: now), 0)
        for d in [21, 23, 24, 25] { s.save(mood: .good, text: "", tags: [], on: day(2026, 11, d), now: now) }
        XCTAssertEqual(s.streak(now: now), 3, "The 22nd is missing, so it's the 23rd to the 25th")
    }

    func testTheStreakHoldsUntilTodayIsWritten() {
        let s = store()
        for d in [23, 24] { s.save(mood: .good, text: "", tags: [], on: day(2026, 11, d), now: now) }
        XCTAssertEqual(s.streak(now: now), 2, "Today isn't over yet")
        XCTAssertEqual(s.streak(now: day(2026, 11, 26)), 0, "A whole day missed ends it")
    }

    func testTheStreakCrossesAMonth() {
        let s = store()
        for d in [day(2026, 10, 30), day(2026, 10, 31), day(2026, 11, 1)] {
            s.save(mood: .okay, text: "", tags: [], on: d, now: now)
        }
        XCTAssertEqual(s.streak(now: day(2026, 11, 1, hour: 20)), 3)
    }

    func testTheTrendHasOnePointADayWithGaps() {
        let s = store()
        s.save(mood: .awesome, text: "", tags: [], on: day(2026, 11, 25), now: now)
        s.save(mood: .rough, text: "", tags: [], on: day(2026, 11, 23), now: now)
        s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 10), now: now)
        let week = s.trend(days: 7, now: now)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.last?.date, cal.startOfDay(for: now))
        XCTAssertEqual(week.map(\.score), [nil, nil, nil, nil, 1, nil, 5])
        XCTAssertEqual(s.average(days: 7, now: now)!, 3, accuracy: 0.0001)
        XCTAssertNil(s.average(days: 7, now: day(2026, 12, 20)), "No days written that week")
        XCTAssertEqual(s.trend(days: 30, now: now).compactMap(\.score).count, 3)
    }

    func testMoodCountsAreForOneMonth() {
        let s = store()
        s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 3), now: now)
        s.save(mood: .good, text: "", tags: [], on: day(2026, 11, 4), now: now)
        s.save(mood: .rough, text: "", tags: [], on: day(2026, 11, 5), now: now)
        s.save(mood: .good, text: "", tags: [], on: day(2026, 10, 5), now: now)
        let counts = s.moodCounts(inMonthOf: now)
        XCTAssertEqual(counts[.good], 2)
        XCTAssertEqual(counts[.rough], 1)
        XCTAssertNil(counts[.awesome])
    }

    // MARK: Insights and search

    func testTheBestTagIsTheOneOnYourHappiestDays() {
        let s = store()
        s.save(mood: .awesome, text: "", tags: ["Friends", "School"], on: day(2026, 11, 20), now: now)
        s.save(mood: .good, text: "", tags: ["Friends"], on: day(2026, 11, 21), now: now)
        s.save(mood: .meh, text: "", tags: ["School"], on: day(2026, 11, 22), now: now)
        s.save(mood: .rough, text: "", tags: ["School"], on: day(2026, 11, 23), now: now)
        s.save(mood: .awesome, text: "", tags: ["Music"], on: day(2026, 11, 24), now: now)
        let best = s.bestTag()
        XCTAssertEqual(best?.tag, "Friends", "Music is only on one day, so it doesn't count yet")
        XCTAssertEqual(best?.average ?? 0, 4.5, accuracy: 0.0001)
    }

    func testNoBestTagUntilThereIsOne() {
        let s = store()
        XCTAssertNil(s.bestTag())
        s.save(mood: .okay, text: "", tags: ["Gaming"], on: day(2026, 11, 20), now: now)
        s.save(mood: .okay, text: "", tags: ["Gaming"], on: day(2026, 11, 21), now: now)
        XCTAssertNil(s.bestTag(), "A tag on every day isn't better than average")
    }

    func testSearchLooksInWordsTagsAndMoods() {
        let s = store()
        s.save(mood: .awesome, text: "Won the robotics match", tags: ["School"], on: day(2026, 11, 20), now: now)
        s.save(mood: .meh, text: "Rainy and slow", tags: ["Rest"], on: day(2026, 11, 21), now: now)
        XCTAssertEqual(s.search("ROBOTICS").map(\.day), ["2026-11-20"])
        XCTAssertEqual(s.search("rest").map(\.day), ["2026-11-21"])
        XCTAssertEqual(s.search("meh").map(\.day), ["2026-11-21"])
        XCTAssertEqual(s.search("  ").count, 2)
        XCTAssertTrue(s.search("pizza").isEmpty)
    }

    // MARK: The month grid

    func testNovember2026StartsOnASunday() {
        let s = store()
        let cells = s.monthCells(for: now)
        XCTAssertEqual(cells.count, 30, "November 1, 2026 is a Sunday, so no blank squares")
        XCTAssertEqual(cells.first??.timeIntervalSince1970, day(2026, 11, 1, hour: 0).timeIntervalSince1970)
        XCTAssertEqual(s.weekdaySymbols.count, 7)
    }

    func testBlankSquaresLineTheFirstUpWithItsWeekday() {
        let s = store()
        let cells = s.monthCells(for: day(2026, 12, 10))
        // December 1, 2026 is a Tuesday: Sunday and Monday are blank.
        XCTAssertEqual(cells.prefix(2).filter { $0 == nil }.count, 2)
        XCTAssertNotNil(cells[2])
        XCTAssertEqual(cells.compactMap { $0 }.count, 31)

        var monday = cal
        monday.firstWeekday = 2
        let m = JournalStore(fileName: nil, calendar: monday)
        XCTAssertEqual(m.monthCells(for: day(2026, 12, 10)).prefix { $0 == nil }.count, 1, "Weeks starting Monday: one blank")
        XCTAssertEqual(m.weekdaySymbols.first, monday.veryShortStandaloneWeekdaySymbols[1])
    }

    // MARK: Saving

    func testTheJournalIsSavedForNextTime() {
        let name = "journal-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let first = JournalStore(fileName: name, calendar: cal)
        let saveTime = Date(timeIntervalSince1970: now.timeIntervalSince1970.rounded(.down))
        first.save(mood: .good, text: "Saved!", tags: ["Music"], on: day(2026, 11, 24), now: saveTime)
        first.save(mood: .awesome, text: "", tags: [], on: day(2026, 11, 25), now: saveTime)

        let again = JournalStore(fileName: name, calendar: cal)
        XCTAssertEqual(again.entries, first.entries)
        XCTAssertEqual(again.entries.map(\.day), ["2026-11-25", "2026-11-24"])
    }

    func testTheNewsMentionsTheJournal() {
        let release = WhatsNew.load().first { $0.build == 60 }
        XCTAssertNotNil(release, "Build 60 should have notes")
        XCTAssertTrue(release?.items.contains { $0.contains("Mood journal") } ?? false)
    }
}
