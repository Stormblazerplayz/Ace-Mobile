import XCTest
import SwiftUI
@testable import Ace

/// The bouncy UI: the springs, the cascade timing, the press squish and the setting behind it.
@MainActor
final class MotionTests: XCTestCase {

    // MARK: Springs

    func testEveryKindIsARealBouncySpring() {
        for kind in AceMotion.Kind.allCases {
            let s = AceMotion.spring(kind)
            XCTAssertGreaterThan(s.response, 0.1, "\(kind) should take a moment to move")
            XCTAssertLessThan(s.response, 0.8, "\(kind) shouldn't feel slow")
            XCTAssertGreaterThan(s.damping, 0.3, "\(kind) shouldn't wobble forever")
            XCTAssertLessThan(s.damping, 1, "\(kind) has to overshoot a little to feel bouncy")
        }
    }

    func testPopIsTheBounciestAndSnappyIsTheQuickest() {
        let pop = AceMotion.spring(.pop), snappy = AceMotion.spring(.snappy), gentle = AceMotion.spring(.gentle)
        for kind in AceMotion.Kind.allCases {
            XCTAssertLessThanOrEqual(pop.damping, AceMotion.spring(kind).damping)
            XCTAssertLessThanOrEqual(snappy.response, AceMotion.spring(kind).response)
        }
        XCTAssertGreaterThan(gentle.damping, pop.damping)
    }

    func testReduceMotionMeansNoAnimationAtAll() {
        for kind in AceMotion.Kind.allCases {
            XCTAssertNil(AceMotion.animation(kind, bouncy: true, reduceMotion: true))
            XCTAssertNil(AceMotion.animation(kind, bouncy: false, reduceMotion: true))
        }
    }

    func testThereIsAlwaysAnAnimationWithoutReduceMotion() {
        for kind in AceMotion.Kind.allCases {
            XCTAssertNotNil(AceMotion.animation(kind, bouncy: true, reduceMotion: false))
            XCTAssertNotNil(AceMotion.animation(kind, bouncy: false, reduceMotion: false), "Off is calm, not frozen")
        }
        XCTAssertLessThanOrEqual(AceMotion.calmDuration, 0.3)
    }

    func testThingsOnlyMoveAroundWithTheBounceOnAndReduceMotionOff() {
        XCTAssertTrue(AceMotion.moves(bouncy: true, reduceMotion: false))
        XCTAssertFalse(AceMotion.moves(bouncy: false, reduceMotion: false))
        XCTAssertFalse(AceMotion.moves(bouncy: true, reduceMotion: true))
        XCTAssertFalse(AceMotion.moves(bouncy: false, reduceMotion: true))
    }

    // MARK: Cascades

    func testRowsCascadeInOrder() {
        XCTAssertEqual(AceMotion.stagger(0), 0)
        XCTAssertEqual(AceMotion.stagger(1), 0.04, accuracy: 0.0001)
        XCTAssertEqual(AceMotion.stagger(3), 0.12, accuracy: 0.0001)
        for i in 0..<12 {
            XCTAssertLessThanOrEqual(AceMotion.stagger(i), AceMotion.stagger(i + 1))
        }
    }

    func testALongListNeverMakesYouWait() {
        XCTAssertEqual(AceMotion.stagger(500), 0.48, accuracy: 0.0001)
        XCTAssertEqual(AceMotion.stagger(17), AceMotion.stagger(1_000), accuracy: 0.0001)
        XCTAssertEqual(AceMotion.stagger(4, step: 0.1, cap: 0.25), 0.25, accuracy: 0.0001)
    }

    func testANegativeRowStartsRightAway() {
        XCTAssertEqual(AceMotion.stagger(-3), 0)
    }

    // MARK: Pressing

    func testButtonsSquishOnlyWhilePressedAndOnlyWhenMoving() {
        XCTAssertEqual(AceMotion.pressScale(pressed: true, moving: true), 0.92, accuracy: 0.0001)
        XCTAssertEqual(AceMotion.pressScale(pressed: false, moving: true), 1)
        XCTAssertEqual(AceMotion.pressScale(pressed: true, moving: false), 1)
        XCTAssertEqual(AceMotion.pressScale(pressed: true, moving: true, depth: 0.8), 0.8, accuracy: 0.0001)
    }

    func testTheSwitchIsTheUsualSize() {
        XCTAssertEqual(BouncySwitch.size.width, 51)
        XCTAssertEqual(BouncySwitch.size.height, 31)
    }

    // MARK: The setting

    func testBouncyIsOnByDefaultAndSaves() {
        let d = UserDefaults.standard
        let before = d.object(forKey: AceMotion.settingKey)
        defer {
            if let before { d.set(before, forKey: AceMotion.settingKey) } else { d.removeObject(forKey: AceMotion.settingKey) }
        }

        d.removeObject(forKey: AceMotion.settingKey)
        XCTAssertTrue(AceMotion.isOn, "Bouncy is on until you turn it off")
        XCTAssertTrue(SettingsStore().bouncyMotion)

        let settings = SettingsStore()
        settings.bouncyMotion = false
        XCTAssertFalse(AceMotion.isOn)
        XCTAssertFalse(SettingsStore().bouncyMotion, "It stays off next time Ace opens")

        settings.bouncyMotion = true
        XCTAssertTrue(AceMotion.isOn)
    }

    func testTheNewsMentionsTheBounce() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 59 }) else {
            return XCTFail("Build 59 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Bouncy animations") })
        XCTAssertEqual(releases.map(\.build), releases.map(\.build).sorted(by: >), "Newest build first")
    }
}
