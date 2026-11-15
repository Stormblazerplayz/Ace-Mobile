import XCTest
@testable import Ace

/// The orb's colors and labels for each thing Ace is doing.
final class OrbTests: XCTestCase {
    func testEveryMoodHasALabel() {
        for mood in OrbMood.allCases {
            XCTAssertFalse(mood.label.isEmpty, "\(mood) has no label")
            XCTAssertTrue((0...1).contains(mood.energy), "\(mood) energy is out of range")
        }
    }

    func testHomeMoodShowsEyes() {
        XCTAssertTrue(OrbMood.home.expands)
        XCTAssertEqual(OrbMood.home.label, "Home done")
        XCTAssertFalse(OrbMood.listening.expands)
        XCTAssertFalse(OrbMood.thinking.expands)
    }

    // MARK: The island

    func testIslandStretches() {
        XCTAssertLessThan(IslandStretch.compact.width, IslandStretch.medium.width)
        XCTAssertLessThan(IslandStretch.medium.width, IslandStretch.wide.width)
        XCTAssertLessThan(IslandStretch.compact.height, IslandStretch.medium.height)
        XCTAssertLessThan(IslandStretch.compact, IslandStretch.medium)
        XCTAssertLessThan(IslandStretch.medium, IslandStretch.wide)
        for mood in [OrbMood.idle, .sleeping] {
            XCTAssertEqual(mood.stretch, .compact, "\(mood) should be compact")
        }
        for mood in [OrbMood.listening, .thinking, .talking, .typing] {
            XCTAssertEqual(mood.stretch, .medium, "\(mood) should stretch to medium")
        }
        for mood in OrbMood.allCases where mood.expands {
            XCTAssertEqual(mood.stretch, .wide, "\(mood) shows eyes, so it should go wide")
        }
        // It never gets wider than the space, or narrower than it is tall.
        XCTAssertEqual(IslandStretch.wide.width(fitting: 200), 200)
        XCTAssertEqual(IslandStretch.wide.width(fitting: 1000), IslandStretch.wide.width)
        XCTAssertEqual(IslandStretch.medium.width(fitting: 10), IslandStretch.medium.height)
        // The medium pill fits between the two header buttons, even on a phone-sized window.
        XCTAssertLessThanOrEqual(IslandStretch.medium.width + 2 * 44, 375 - 24)
        // The thinking area (with an eye on each side) fits inside the medium pill.
        XCTAssertLessThan(ThinkingLayer.width(orbSize: IslandStretch.medium.height - 10), IslandStretch.medium.width - 20)
    }

    // MARK: Thinking looks

    func testThinkingCycleHasSideEyes() {
        let cycle = ThinkingAnimation.cycle(reduceMotion: false)
        XCTAssertTrue(cycle.contains(.sideEyes), "One of the thinking looks has an eye on each side of the orb")
        XCTAssertGreaterThanOrEqual(Set(cycle).count, 4)
        XCTAssertEqual(Set(cycle).count, cycle.count, "No look shows twice in a row of the cycle")
        XCTAssertFalse(cycle.contains(.calm))
    }

    func testReduceMotionStaysCalm() {
        XCTAssertEqual(ThinkingAnimation.cycle(reduceMotion: true), [.calm])
        for t in [0.0, 2.9, 100] {
            let f = ThinkingAnimation.frame(at: t, reduceMotion: true)
            XCTAssertEqual(f.current, .calm)
            XCTAssertEqual(f.next, .calm)
            XCTAssertEqual(f.mix, 0)
        }
    }

    func testThinkingLooksTakeTurnsAndFade() {
        let cycle = ThinkingAnimation.cycle(reduceMotion: false)
        let s = ThinkingAnimation.seconds
        let fade = ThinkingAnimation.fade
        XCTAssertGreaterThan(s, fade)

        let middle = ThinkingAnimation.frame(at: s / 2, reduceMotion: false)
        XCTAssertEqual(middle.current, cycle[0])
        XCTAssertEqual(middle.next, cycle[1])
        XCTAssertEqual(middle.mix, 0, "Nothing fades in the middle of a look")

        let fading = ThinkingAnimation.frame(at: s - fade / 2, reduceMotion: false)
        XCTAssertEqual(fading.current, cycle[0])
        XCTAssertEqual(fading.mix, 0.5, accuracy: 0.001)

        XCTAssertEqual(ThinkingAnimation.frame(at: s + 0.01, reduceMotion: false).current, cycle[1])
        XCTAssertEqual(ThinkingAnimation.frame(at: s * Double(cycle.count) + 0.1, reduceMotion: false).current, cycle[0],
                       "After the last look it starts again")
        XCTAssertEqual(ThinkingAnimation.frame(at: -5, reduceMotion: false).current, cycle[0])

        for i in 0..<400 {
            let f = ThinkingAnimation.frame(at: Double(i) * 0.137, reduceMotion: false)
            XCTAssertTrue((0...1).contains(f.mix), "mix \(f.mix) is out of range")
            XCTAssertNotEqual(f.current, f.next)
        }
    }

    // MARK: Outfits

    private func day(_ year: Int, _ month: Int, _ d: Int, _ calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: d, hour: 12)) ?? Date.distantPast
    }

    func testOutfitsByDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        func outfit(_ y: Int, _ m: Int, _ d: Int) -> OrbOutfit? { OrbOutfit.forDate(day(y, m, d, calendar), calendar: calendar) }

        XCTAssertEqual(outfit(2026, 12, 20), .santaHat)
        XCTAssertEqual(outfit(2026, 12, 1), .santaHat)
        XCTAssertEqual(outfit(2026, 12, 26), .santaHat)
        XCTAssertEqual(outfit(2026, 10, 31), .pumpkin)
        XCTAssertEqual(outfit(2026, 10, 24), .pumpkin)
        XCTAssertEqual(outfit(2026, 12, 31), .partyHat)
        XCTAssertEqual(outfit(2027, 1, 1), .partyHat)
        XCTAssertEqual(outfit(2027, 1, 2), .partyHat)
        XCTAssertEqual(outfit(2027, 1, 20), .snowflake)
        XCTAssertEqual(outfit(2027, 2, 14), .hearts)
        XCTAssertEqual(outfit(2027, 3, 17), .shamrock)
        XCTAssertEqual(outfit(2027, 7, 4), .fireworks)
        XCTAssertEqual(outfit(2027, 7, 3), .fireworks)
        XCTAssertNil(outfit(2027, 6, 10))
        XCTAssertNil(outfit(2027, 7, 5))
        XCTAssertNil(outfit(2027, 10, 23))

        // Easter 2027 is March 28: bunny ears from March 25 to Easter Monday (March 29).
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2027)?.month, 3)
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2027)?.day, 28)
        XCTAssertEqual(outfit(2027, 3, 28), .bunnyEars)
        XCTAssertEqual(outfit(2027, 3, 25), .bunnyEars)
        XCTAssertEqual(outfit(2027, 3, 29), .bunnyEars)
        XCTAssertNil(outfit(2027, 3, 24))
        XCTAssertNil(outfit(2027, 3, 30))
        // Other years' Easters: April 20, 2025 and April 5, 2026.
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2025)?.month, 4)
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2025)?.day, 20)
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2026)?.month, 4)
        XCTAssertEqual(OrbOutfit.easterSunday(year: 2026)?.day, 5)
    }

    func testEveryOutfitHasALabel() {
        for outfit in OrbOutfit.allCases {
            XCTAssertFalse(outfit.label.isEmpty, "\(outfit) has no label")
            XCTAssertFalse(outfit.when.isEmpty, "\(outfit) doesn't say when it shows")
        }
    }

    func testTiltStaysInRange() {
        XCTAssertEqual(OrbMotion.clamp(3), 1)
        XCTAssertEqual(OrbMotion.clamp(-3), -1)
        XCTAssertEqual(OrbMotion.clamp(0.25), 0.25)
    }
}
