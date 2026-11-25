import XCTest
@testable import Ace

@MainActor
final class WorldClockTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!
    private let london = TimeZone(identifier: "Europe/London")!
    private let newYork = TimeZone(identifier: "America/New_York")!
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let kolkata = TimeZone(identifier: "Asia/Kolkata")!
    private let kathmandu = TimeZone(identifier: "Asia/Kathmandu")!
    private let honolulu = TimeZone(identifier: "Pacific/Honolulu")!
    private let auckland = TimeZone(identifier: "Pacific/Auckland")!

    /// A moment in UTC.
    private func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testEveryCityHasARealTimeZone() {
        XCTAssertGreaterThan(WorldCity.all.count, 30)
        for city in WorldCity.all {
            XCTAssertNotNil(city.zone, "\(city.name) has an unknown time zone")
        }
        XCTAssertEqual(Set(WorldCity.all.map(\.id)).count, WorldCity.all.count, "No city twice")
    }

    func testHourThere() {
        let date = at(2026, 11, 25, 12, 30)
        XCTAssertEqual(WorldTime.hour(at: date, in: london), 12.5, accuracy: 0.001)
        XCTAssertEqual(WorldTime.hour(at: date, in: newYork), 7.5, accuracy: 0.001)
        XCTAssertEqual(WorldTime.hour(at: date, in: tokyo), 21.5, accuracy: 0.001)
        XCTAssertEqual(WorldTime.hour(at: date, in: kathmandu), 18.25, accuracy: 0.001)
    }

    func testDifferences() {
        let date = at(2026, 11, 25, 12)
        XCTAssertEqual(WorldTime.difference(tokyo, from: newYork, at: date), 14 * 3600)
        XCTAssertEqual(WorldTime.differenceText(WorldTime.difference(tokyo, from: newYork, at: date)), "14 hours ahead")
        XCTAssertEqual(WorldTime.differenceText(WorldTime.difference(kolkata, from: london, at: date)), "5 hours 30 minutes ahead")
        XCTAssertEqual(WorldTime.differenceText(WorldTime.difference(newYork, from: london, at: date)), "5 hours behind")
        XCTAssertEqual(WorldTime.differenceText(0), "Same time")
        XCTAssertEqual(WorldTime.differenceText(3600), "1 hour ahead")
        XCTAssertEqual(WorldTime.differenceText(-60), "1 minute behind")
        // In July, New York is on daylight saving time and only 13 hours behind Tokyo.
        XCTAssertEqual(WorldTime.difference(tokyo, from: newYork, at: at(2026, 7, 1, 12)), 13 * 3600)
    }

    func testTodayTomorrowYesterday() {
        let evening = at(2026, 11, 25, 20)
        XCTAssertEqual(WorldTime.dayWord(at: evening, in: tokyo, here: newYork), "Tomorrow")
        XCTAssertEqual(WorldTime.dayWord(at: evening, in: london, here: newYork), "Today")
        let early = at(2026, 11, 25, 5)
        XCTAssertEqual(WorldTime.dayWord(at: early, in: honolulu, here: london), "Yesterday")
        // Across the new year.
        let newYearsEve = at(2026, 12, 31, 20)
        XCTAssertEqual(WorldTime.dayWord(at: newYearsEve, in: auckland, here: london), "Tomorrow")
        XCTAssertEqual(WorldTime.dayOffset(at: newYearsEve, in: auckland, here: london), 1)
    }

    func testSkyForTheTimeOfDay() {
        XCTAssertEqual(WorldSky.at(hour: 3), .night)
        XCTAssertEqual(WorldSky.at(hour: 6), .dawn)
        XCTAssertEqual(WorldSky.at(hour: 7.5), .day)
        XCTAssertEqual(WorldSky.at(hour: 12), .day)
        XCTAssertEqual(WorldSky.at(hour: 17.5), .dusk)
        XCTAssertEqual(WorldSky.at(hour: 20), .night)
        XCTAssertEqual(WorldSky.at(hour: 23.9), .night)
    }

    func testSunAndMoonPath() {
        XCTAssertEqual(WorldSkyView.arcPosition(hour: 6), 0, accuracy: 0.001)
        XCTAssertEqual(WorldSkyView.arcPosition(hour: 12), 0.5, accuracy: 0.001)
        XCTAssertEqual(WorldSkyView.arcPosition(hour: 18), 0, accuracy: 0.001)
        XCTAssertEqual(WorldSkyView.arcPosition(hour: 0), 0.5, accuracy: 0.001)
        XCTAssertEqual(WorldSkyView.arcPosition(hour: 5), 11.0 / 12.0, accuracy: 0.001)
    }

    func testClockHands() {
        let half = WorldAnalogClock.angles(hour: 3.5)
        XCTAssertEqual(half.hour, 105, accuracy: 0.001)
        XCTAssertEqual(half.minute, 180, accuracy: 0.001)
        XCTAssertEqual(half.second, 0, accuracy: 0.001)
        let afternoon = WorldAnalogClock.angles(hour: 15.25)
        XCTAssertEqual(afternoon.hour, 97.5, accuracy: 0.001)
        XCTAssertEqual(afternoon.minute, 90, accuracy: 0.001)
        let withSeconds = WorldAnalogClock.angles(hour: 10 + 10.0 / 60 + 30.0 / 3600)
        XCTAssertEqual(withSeconds.second, 180, accuracy: 0.01)
    }

    func testGoodTimeToCall() {
        XCTAssertFalse(WorldTime.isAwakeHours(7.9))
        XCTAssertTrue(WorldTime.isAwakeHours(8))
        XCTAssertTrue(WorldTime.isAwakeHours(20.9))
        XCTAssertFalse(WorldTime.isAwakeHours(21))
        XCTAssertFalse(WorldTime.isAwakeHours(2))
    }

    func testPlannerText() {
        XCTAssertEqual(WorldClockView.shiftText(2.25), "2 hours 15 minutes from now")
        XCTAssertEqual(WorldClockView.shiftText(-0.75), "45 minutes ago")
        XCTAssertEqual(WorldClockView.shiftText(1), "1 hour from now")
        XCTAssertEqual(WorldClockView.shiftText(0), "Now")
    }

    func testStoreStartsWithLondonAndTokyo() {
        let store = WorldClockStore(fileName: nil)
        XCTAssertEqual(store.cities.map(\.name), ["London", "Tokyo"])
    }

    func testAddingAndRemovingCities() throws {
        let store = WorldClockStore(fileName: nil)
        let paris = try XCTUnwrap(WorldCity.all.first { $0.name == "Paris" })
        XCTAssertTrue(store.add(paris))
        XCTAssertFalse(store.add(paris), "No city twice")
        XCTAssertFalse(store.add(WorldCity(name: "Nowhere", country: "None", zoneID: "Not/AZone")))
        XCTAssertTrue(store.has(paris))
        store.remove(paris)
        XCTAssertFalse(store.has(paris))

        for city in WorldCity.all { store.add(city) }
        XCTAssertEqual(store.cities.count, WorldClockStore.maxCities)
    }

    func testMovingCities() throws {
        let store = WorldClockStore(fileName: nil)
        let sydney = try XCTUnwrap(WorldCity.all.first { $0.name == "Sydney" })
        store.add(sydney)
        store.move(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(store.cities.map(\.name), ["Sydney", "London", "Tokyo"])
    }

    func testSearch() {
        XCTAssertEqual(WorldClockStore.search("tok").map(\.name), ["Tokyo"])
        XCTAssertEqual(WorldClockStore.search("sao paulo").map(\.name), ["São Paulo"], "Accents don't matter")
        XCTAssertTrue(WorldClockStore.search("united states").count >= 5)
        XCTAssertEqual(WorldClockStore.search("  ").count, WorldCity.all.count)
        XCTAssertTrue(WorldClockStore.search("zzzz").isEmpty)
    }

    func testCitiesAreSaved() throws {
        let name = "world-clocks-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let first = WorldClockStore(fileName: name)
        let cairo = try XCTUnwrap(WorldCity.all.first { $0.name == "Cairo" })
        first.add(cairo)
        let again = WorldClockStore(fileName: name)
        XCTAssertEqual(again.cities.map(\.name), ["London", "Tokyo", "Cairo"])
    }

    func testWhatsNewHasBuild71() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 71 }) else {
            return XCTFail("Build 71 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("World clocks") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
