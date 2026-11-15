import XCTest
@testable import Ace

/// Focus sessions: the words that start, stop and check one.
final class FocusTests: XCTestCase {
    private func focus(_ text: String) -> String? {
        if case .focus(let what) = IntentRouter.parse(text) { return what }
        return nil
    }

    func testFocusWords() {
        XCTAssertEqual(focus("focus for 25 minutes"), "start 1500")
        XCTAssertEqual(focus("start a focus session"), "start 1500")
        XCTAssertEqual(focus("pomodoro"), "start 1500")
        XCTAssertEqual(focus("start a pomodoro"), "start 1500")
        XCTAssertEqual(focus("help me focus for 45 minutes"), "start 2700")
        XCTAssertEqual(focus("study session for 1 hour"), "start 3600")
        XCTAssertEqual(focus("focus timer for 10 minutes"), "start 600")
        XCTAssertEqual(focus("stop focus"), "stop")
        XCTAssertEqual(focus("end my focus session"), "stop")
        XCTAssertEqual(focus("how much focus time is left"), "left")
        XCTAssertEqual(focus("how long is left in my focus session"), "left")
    }

    func testNotFocus() {
        XCTAssertNil(focus("run the focus scene"))
        XCTAssertNil(focus("what does focus mean"))
        XCTAssertNil(focus("set a timer for 5 minutes"))
        XCTAssertNil(focus("I can't focus on my homework"))
    }

    func testProgress() {
        let t = KitchenTimers.Running(label: "Focus", end: Date().addingTimeInterval(300), total: 600)
        XCTAssertEqual(FocusSession.progress(of: t, at: Date()), 0.5, accuracy: 0.01)
        XCTAssertEqual(FocusSession.progress(of: t, at: Date().addingTimeInterval(400)), 1, accuracy: 0.001)
    }
}
