import XCTest
@testable import Ace

/// Ace Breathe: the patterns, where a session is at any second, the minutes log, and asking for it.
@MainActor
final class BreatheTests: XCTestCase {

    // MARK: Patterns

    func testPatternsAndLengths() {
        XCTAssertEqual(BreathPattern.box.cycle, 16)
        XCTAssertEqual(BreathPattern.fourSevenEight.cycle, 19)
        XCTAssertEqual(BreathPattern.calm.cycle, 10)
        XCTAssertEqual(BreathPattern.balloon.cycle, 7)
        XCTAssertEqual(BreathPattern.box.breaths(minutes: 1), 4)
        XCTAssertEqual(BreathPattern.fourSevenEight.breaths(minutes: 2), 6)
        XCTAssertEqual(BreathPattern.calm.breaths(minutes: 3), 18)
        XCTAssertEqual(BreathPattern.balloon.breaths(minutes: 1), 9)
        for p in BreathPattern.allCases {
            XCTAssertEqual(p.steps.first?.step, .breatheIn, p.title)
            XCTAssertTrue(p.steps.contains { $0.step == .breatheOut }, p.title)
            XCTAssertGreaterThanOrEqual(p.breaths(minutes: 1), 1)
        }
    }

    // MARK: A session

    func testBoxBreathingMoments() {
        let s = BreathSession(pattern: .box, minutes: 1)
        XCTAssertEqual(s.breaths, 4)
        XCTAssertEqual(s.length, 64)

        let start = s.moment(at: 0)
        XCTAssertEqual(start.step, .breatheIn)
        XCTAssertEqual(start.fullness, 0, accuracy: 0.001)
        XCTAssertEqual(start.secondsLeft, 4)

        let halfIn = s.moment(at: 2)
        XCTAssertEqual(halfIn.fullness, 0.5, accuracy: 0.001)
        XCTAssertEqual(halfIn.secondsLeft, 2)

        let hold = s.moment(at: 6)
        XCTAssertEqual(hold.step, .hold)
        XCTAssertEqual(hold.fullness, 1)

        let out = s.moment(at: 10)
        XCTAssertEqual(out.step, .breatheOut)
        XCTAssertEqual(out.fullness, 0.5, accuracy: 0.001)
        XCTAssertEqual(out.cycleProgress, 0.625, accuracy: 0.001)

        let rest = s.moment(at: 13)
        XCTAssertEqual(rest.step, .rest)
        XCTAssertEqual(rest.fullness, 0)

        let second = s.moment(at: 16)
        XCTAssertEqual(second.breath, 1)
        XCTAssertEqual(second.step, .breatheIn)
        XCTAssertFalse(s.moment(at: 63.9).finished)
        XCTAssertTrue(s.moment(at: 64).finished)
        XCTAssertTrue(s.moment(at: 500).finished)
    }

    func testFourSevenEightSteps() {
        let s = BreathSession(pattern: .fourSevenEight, minutes: 1)
        XCTAssertEqual(s.moment(at: 3.9).step, .breatheIn)
        XCTAssertEqual(s.moment(at: 4).step, .hold)
        XCTAssertEqual(s.moment(at: 4).secondsLeft, 7)
        XCTAssertEqual(s.moment(at: 10.9).step, .hold)
        XCTAssertEqual(s.moment(at: 11).step, .breatheOut)
        XCTAssertEqual(s.moment(at: 11).secondsLeft, 8)
        XCTAssertEqual(s.moment(at: 19).breath, 1)
    }

    func testOrbGrowsSmoothly() {
        XCTAssertEqual(BreathSession.ease(0), 0, accuracy: 0.0001)
        XCTAssertEqual(BreathSession.ease(1), 1, accuracy: 0.0001)
        XCTAssertEqual(BreathSession.ease(0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(BreathSession.ease(2), 1, accuracy: 0.0001)
        var last = -1.0
        for i in 0...40 {
            let v = BreathSession.ease(Double(i) / 40)
            XCTAssertGreaterThanOrEqual(v, last)
            last = v
        }
        let idle = BreathSession.idle(at: Date())
        XCTAssertGreaterThanOrEqual(idle.fullness, 0.25)
        XCTAssertLessThanOrEqual(idle.fullness, 0.75)
    }

    // MARK: Log

    func testMinutesAndStreak() {
        let log = BreathLog(key: "test.breathe.\(UUID().uuidString)")
        addTeardownBlock { log.clearAll() }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = ISO8601DateFormatter().date(from: "2026-11-25T12:00:00Z")!
        let day = { (n: Int) in cal.date(byAdding: .day, value: n, to: today)! }

        XCTAssertEqual(log.streak(today: today, calendar: cal), 0)
        log.add(seconds: 120, on: day(-1))
        XCTAssertEqual(log.streak(today: today, calendar: cal), 1, "Yesterday still counts before today's breathing")
        log.add(seconds: 60, on: day(-2))
        log.add(seconds: 90, on: day(-4))
        XCTAssertEqual(log.streak(today: today, calendar: cal), 2)
        log.add(seconds: 30, on: today)
        XCTAssertEqual(log.streak(today: today, calendar: cal), 3)
        XCTAssertEqual(log.totalMinutes, 5)
        log.add(seconds: 0, on: day(-3))
        XCTAssertEqual(log.streak(today: today, calendar: cal), 3, "Zero seconds isn't a day")
    }

    func testLengthWords() {
        XCTAssertEqual(BreatheDoneCard.length(45), "45 seconds")
        XCTAssertEqual(BreatheDoneCard.length(60), "1 minute")
        XCTAssertEqual(BreatheDoneCard.length(150), "2 minutes 30 seconds")
    }

    // MARK: Asking

    private func breatheAsk(_ text: String) -> String? {
        if case .breathe(let ask)? = IntentRouter.parse(text) { return ask }
        return nil
    }

    func testBreatheAsksRoute() {
        let cases: [(String, String)] = [
            ("breathe with me", "open"),
            ("Start a breathing exercise", "open"),
            ("let's do some deep breathing", "open"),
            ("I need to take a breathing break", "open"),
            ("help me calm down with breathing", "open"),
            ("box breathing exercise", "box"),
            ("let's do box breathing", "box"),
            ("can we do calm breathing please", "calm"),
            ("do 4 7 8 breathing", "fourSevenEight"),
            ("start balloon breathing", "balloon"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(breatheAsk(text), want, text)
        }
    }

    func testBreathingQuestionsGetAnswers() {
        for text in ["breathing exercise", "breathing exercise for anxiety", "how do fish breathe", "can you breathe on mars",
                     "box breathing", "4 7 8 breathing", "diaphragm breathing", "i cant breathe", "why do we breathe"] {
            XCTAssertNil(breatheAsk(text), text)
        }
    }

    func testChangelogHasBreathe() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 60)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Breathe") } == true)
    }
}
