import XCTest
@testable import Ace

/// Ace Space: the planets' numbers, where they are on real dates, asking for the solar system,
/// the map's clock and where things go on the map.
@MainActor
final class SpaceTests: XCTestCase {
    private func day(_ text: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: text + "T00:00:00Z")!
    }

    /// The gap between two angles, 0 to 180 degrees.
    private func gap(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    // MARK: The planets

    func testEightPlanetsInOrder() {
        let names = SolarSystem.planets.map(\.name)
        XCTAssertEqual(names, ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"])
        let distances = SolarSystem.planets.map(\.au)
        XCTAssertEqual(distances, distances.sorted(), "Each planet is farther out than the last")
        XCTAssertEqual(SolarSystem.everything.first?.id, "sun")
        XCTAssertEqual(Set(SolarSystem.everything.map(\.id)).count, 9)
    }

    func testRealNumbers() {
        let earth = SolarSystem.planet("earth")!
        XCTAssertEqual(earth.au, 1)
        XCTAssertEqual(earth.moons, 1)
        XCTAssertEqual(earth.earthsWide, 1, accuracy: 0.001)
        XCTAssertEqual(SolarSystem.planet("jupiter")!.earthsWide, 11.2, accuracy: 0.1)
        XCTAssertEqual(SolarSystem.sun.earthsWide, 109, accuracy: 1)
        XCTAssertEqual(SolarSystem.planet("neptune")!.yearInEarthYears, 164, accuracy: 1)
        XCTAssertEqual(SolarSystem.planet("mars")!.gravity / 9.8, 0.38, accuracy: 0.01)
        let biggest = SolarSystem.planets.max { $0.diameterKm < $1.diameterKm }
        XCTAssertEqual(biggest?.id, "jupiter")
        XCTAssertTrue(SolarSystem.planet("saturn")!.rings)
        for p in SolarSystem.everything {
            XCTAssertGreaterThanOrEqual(p.colors.count, 3, p.id)
            XCTAssertFalse(p.fact.isEmpty, p.id)
        }
    }

    func testWords() {
        XCTAssertEqual(SolarSystem.yearText(SolarSystem.planet("mercury")!), "88 days")
        XCTAssertEqual(SolarSystem.yearText(SolarSystem.planet("mars")!), "687 days")
        XCTAssertEqual(SolarSystem.yearText(SolarSystem.planet("jupiter")!), "11.9 years")
        XCTAssertEqual(SolarSystem.yearText(SolarSystem.planet("neptune")!), "164 years")
        XCTAssertEqual(SolarSystem.dayText(SolarSystem.planet("earth")!), "24 hours")
        XCTAssertEqual(SolarSystem.dayText(SolarSystem.planet("mercury")!), "176 days")
        XCTAssertEqual(SolarSystem.lightTime(1), "8 minutes")
        XCTAssertEqual(SolarSystem.lightTime(30), "4 hours and 10 minutes")
        XCTAssertEqual(SolarSystem.kilometers(1), "about 150 million km")
        XCTAssertEqual(SolarSystem.kilometers(10), "about 1.5 billion km")
        XCTAssertEqual(SolarSystem.weight(10, on: SolarSystem.planet("mars")!), 3.78, accuracy: 0.01)
    }

    // MARK: Where they are

    /// At opposition a planet is straight out from Earth, so they line up around the Sun.
    func testPlanetsLineUpOnRealDates() {
        let lineUps = [("saturn", "2026-10-04"), ("jupiter", "2026-01-10"), ("mars", "2025-01-16"), ("neptune", "2025-09-23")]
        for (id, date) in lineUps {
            let p = SolarSystem.planet(id)!, earth = SolarSystem.planet("earth")!
            let a = SolarSystem.longitude(p, at: day(date)), b = SolarSystem.longitude(earth, at: day(date))
            XCTAssertLessThan(gap(a, b), 8, "\(id) on \(date)")
        }
        // Venus passed between Earth and the Sun on 23 March 2025.
        let venus = SolarSystem.longitude(SolarSystem.planet("venus")!, at: day("2025-03-23"))
        XCTAssertLessThan(gap(venus, SolarSystem.longitude(SolarSystem.planet("earth")!, at: day("2025-03-23"))), 8)
    }

    func testDistancesFromEarth() {
        // Mars is closest at opposition and far away behind the Sun.
        let close = SolarSystem.distanceFromEarth(SolarSystem.planet("mars")!, at: day("2025-01-16"))
        XCTAssertEqual(close, 0.52, accuracy: 0.12)
        let far = SolarSystem.distanceFromEarth(SolarSystem.planet("mars")!, at: day("2026-01-09"))
        XCTAssertGreaterThan(far, 2.2)
        XCTAssertEqual(SolarSystem.distanceFromEarth(SolarSystem.planet("earth")!, at: day("2026-11-25")), 0, accuracy: 0.0001)
        XCTAssertTrue(SolarSystem.whereNow(SolarSystem.planet("mars")!, at: day("2026-11-25")).contains("from Earth"))
        XCTAssertTrue(SolarSystem.whereNow(SolarSystem.planet("earth")!).contains("standing on it"))
    }

    func testMoonIsOppositeTheSunAtFullMoon() {
        // Full moon on 24 November 2026: the Moon is on the far side of Earth from the Sun.
        let date = day("2026-11-24").addingTimeInterval(15 * 3_600)
        let moon = SolarSystem.moonLongitude(at: date)
        let earth = SolarSystem.longitude(SolarSystem.planet("earth")!, at: date)
        XCTAssertLessThan(gap(moon, earth), 12)
    }

    // MARK: Asking

    private func spaceAsk(_ text: String) -> String? {
        if case .space(let ask)? = IntentRouter.parse(text) { return ask }
        return nil
    }

    func testSpaceAsksRoute() {
        let cases: [(String, String)] = [
            ("show me the solar system", "open"),
            ("Open the solar system", "open"),
            ("solar system", "open"),
            ("show me the planets", "open"),
            ("explore space", "open"),
            ("let's explore the solar system", "open"),
            ("where are the planets right now", "open"),
            ("show me Saturn", "planet:saturn"),
            ("take me to mars", "planet:mars"),
            ("zoom in on jupiter", "planet:jupiter"),
            ("show me the sun", "planet:sun"),
            ("can you show me venus please", "planet:venus"),
            ("where is mars right now", "where:mars"),
            ("Where is Jupiter right now?", "where:jupiter"),
            ("how far is mars from earth right now", "where:mars"),
            ("how far away is saturn right now", "where:saturn"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(spaceAsk(text), want, text)
        }
    }

    func testOtherAsksAreNotSpace() {
        for text in ["how far is mars from earth", "tell me about saturn", "how many moons does jupiter have",
                     "what is the biggest planet", "show me a picture of saturn", "space", "go to the store",
                     "where is my phone right now", "open spotify", "show me my calendar", "what is the solar system",
                     "how big is the sun"] {
            XCTAssertNil(spaceAsk(text), text)
        }
    }

    func testSpaceStartsFromAsks() {
        XCTAssertEqual(SpaceStart(ask: "open"), .overview)
        XCTAssertEqual(SpaceStart(ask: "planet:mars"), .planet("mars"))
        XCTAssertEqual(SpaceStart(ask: "planet:sun"), .planet("sun"))
        XCTAssertNil(SpaceStart(ask: "planet:pluto"))
        XCTAssertNil(SpaceStart(ask: "where:mars"))
    }

    // MARK: The clock

    func testClockRunsPausesAndJumps() {
        let start = day("2026-01-01"), real = day("2030-01-01")
        var clock = SpaceClock(date: start, warp: .week, now: real)
        XCTAssertTrue(clock.running)
        let twoSeconds = real.addingTimeInterval(2)
        XCTAssertEqual(clock.date(at: twoSeconds).timeIntervalSince(start) / 86_400, 14, accuracy: 0.001)
        clock.set(.paused, now: twoSeconds)
        XCTAssertFalse(clock.running)
        XCTAssertEqual(clock.date(at: twoSeconds.addingTimeInterval(100)).timeIntervalSince(start) / 86_400, 14, accuracy: 0.001,
                       "Pausing keeps the planets where they were")
        clock.shift(days: -30, now: twoSeconds)
        XCTAssertEqual(clock.date(at: twoSeconds).timeIntervalSince(start) / 86_400, -16, accuracy: 0.001)
        clock.set(.year, now: twoSeconds)
        XCTAssertEqual(clock.date(at: twoSeconds.addingTimeInterval(1)).timeIntervalSince(start) / 86_400, 349.25, accuracy: 0.001)
        clock.jump(to: start, now: twoSeconds)
        XCTAssertTrue(clock.isToday(at: twoSeconds, today: start))
        XCTAssertEqual(SpaceClock.Warp.allCases.map(\.daysPerSecond), [0, 1, 7, 30.44, 365.25])
    }

    // MARK: The map

    func testMapKeepsOrderAndFitsTheRing() {
        let radii = SolarSystem.planets.map { SpaceMap.radius($0.au, inner: 60, outer: 400) }
        XCTAssertEqual(radii.first!, 60, accuracy: 0.01)
        XCTAssertEqual(radii.last!, 400, accuracy: 0.01)
        XCTAssertEqual(radii, radii.sorted())
        XCTAssertEqual(SpaceMap.radius(0, inner: 60, outer: 400), 0)
        for p in SolarSystem.planets {
            XCTAssertGreaterThanOrEqual(SpaceMap.dotRadius(p), 9, "\(p.name) is big enough to tap")
        }
        XCTAssertGreaterThan(SpaceMap.dotRadius(SolarSystem.planet("jupiter")!), SpaceMap.dotRadius(SolarSystem.planet("earth")!))
    }

    func testTappingFindsThePlanet() {
        let date = day("2026-11-25"), center = (x: 500.0, y: 500.0)
        for p in SolarSystem.everything {
            let at = SpaceMap.point(p, at: date, center: center, inner: 60, outer: 400)
            let hit = SpaceMap.planet(near: (at.x + 4, at.y - 3), at: date, center: center, inner: 60, outer: 400)
            XCTAssertEqual(hit?.id, p.id, p.name)
        }
        XCTAssertNil(SpaceMap.planet(near: (5, 5), at: date, center: center, inner: 60, outer: 400))
        // Up on the map is counterclockwise: a planet at 90 degrees sits straight above the Sun.
        let earth = SolarSystem.planet("earth")!
        let a = SolarSystem.longitude(earth, at: date) * .pi / 180
        let at = SpaceMap.point(earth, at: date, center: center, inner: 60, outer: 400)
        XCTAssertEqual((at.y - center.y) < 0, sin(a) > 0)
    }

    func testChangelogHasSpace() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 67)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Space") } == true)
    }
}
