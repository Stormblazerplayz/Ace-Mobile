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

    func testTiltStaysInRange() {
        XCTAssertEqual(OrbMotion.clamp(3), 1)
        XCTAssertEqual(OrbMotion.clamp(-3), -1)
        XCTAssertEqual(OrbMotion.clamp(0.25), 0.25)
    }
}
