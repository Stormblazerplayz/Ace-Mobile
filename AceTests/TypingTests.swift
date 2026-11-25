import XCTest
@testable import Ace

/// Ace Typing: the lessons' words, a run's speed and accuracy, the keyboard, asking for it, and the screen's model.
@MainActor
final class TypingTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    // MARK: Lessons

    func testRowLessonsOnlyUseTheirKeys() {
        let home = Set("asdfghjkl")
        let top = home.union("qwertyuiop")
        XCTAssertGreaterThan(TypingWords.homeRow.count, 30)
        XCTAssertGreaterThan(TypingWords.topRow.count, 50)
        for w in TypingWords.homeRow { XCTAssertTrue(w.allSatisfy(home.contains), w) }
        for w in TypingWords.topRow { XCTAssertTrue(w.allSatisfy(top.contains), w) }
        for w in TypingWords.bottomRow { XCTAssertTrue(w.contains { "zxcvbnm".contains($0) }, w) }
        XCTAssertEqual(TypingWords.common.count, 100)
        XCTAssertEqual(Set(TypingWords.common).count, 100, "No word twice")
    }

    func testEveryLessonCanBeTypedOnTheKeyboard() {
        for lesson in TypingLesson.allCases {
            for seed in [1, 7, 42, 999] as [UInt64] {
                let text = lesson.text(seed: seed)
                XCTAssertTrue(TypingKeys.canType(text), "\(lesson): \(text)")
                XCTAssertFalse(text.hasPrefix(" ") || text.hasSuffix(" ") || text.contains("  "), text)
            }
        }
        for s in TypingWords.sentences { XCTAssertTrue(TypingKeys.canType(s), s) }
    }

    func testTextsAreTheSameForASeedAndChangeWithIt() {
        XCTAssertEqual(TypingLesson.homeRow.text(seed: 5), TypingLesson.homeRow.text(seed: 5))
        XCTAssertNotEqual(TypingLesson.homeRow.text(seed: 5), TypingLesson.homeRow.text(seed: 6))
        XCTAssertEqual(TypingLesson.words.text(count: 12, seed: 3).split(separator: " ").count, 12)
        let words = TypingLesson.topRow.text(count: 30, seed: 11).split(separator: " ")
        for i in 1..<words.count { XCTAssertNotEqual(words[i], words[i - 1], "No word twice in a row") }
        let two = TypingLesson.sentences.text(seed: 9)
        XCTAssertEqual(two.filter { ".!?".contains($0) }.count, 2, two)
    }

    // MARK: A run

    func testTypingRightWrongAndBackspace() {
        var run = TypingRun(text: "ask dad")
        XCTAssertEqual(run.next, "a")
        XCTAssertEqual(run.type("a", at: t0), .right)
        XCTAssertEqual(run.type("s", at: t0), .right)
        XCTAssertEqual(run.type("x", at: t0), .wrong(expected: "k"))
        XCTAssertEqual(run.mistakes, 1)
        XCTAssertEqual(run.missedKeys["k"], 1)
        run.backspace()
        XCTAssertEqual(run.position, 2)
        XCTAssertEqual(run.type("k", at: t0), .right)
        for c in " da" { _ = run.type(c, at: t0) }
        XCTAssertEqual(run.type("d", at: t0.addingTimeInterval(6)), .finished)
        XCTAssertTrue(run.done)
        XCTAssertEqual(run.type("x", at: t0), .ignored, "Nothing after the end")
        XCTAssertEqual(run.mistakes, 1, "A fixed mistake still counts")
        XCTAssertEqual(run.accuracy, 87.5, accuracy: 0.01, "7 right out of 8 presses")
        // 7 right characters in 6 seconds = 1.4 words in 0.1 minutes = 14 words a minute.
        XCTAssertEqual(run.wordsPerMinute(), 14, accuracy: 0.01)
        XCTAssertEqual(run.stars(), 1)
    }

    func testCurlyQuotesCountAsStraight() {
        var run = TypingRun(text: "it's")
        for c in "it’s" { _ = run.type(c, at: t0) }
        XCTAssertEqual(run.mistakes, 0)
    }

    func testSpeedAndStars() {
        var fast = TypingRun(text: String(repeating: "a", count: 50))
        for i in 0..<50 { _ = fast.type("a", at: t0.addingTimeInterval(Double(i) * 0.4)) }
        // 50 characters in 19.6 seconds is about 30.6 words a minute, with no mistakes.
        XCTAssertEqual(fast.wordsPerMinute(), 30.6, accuracy: 0.1)
        XCTAssertEqual(fast.stars(), 3)

        var slow = TypingRun(text: String(repeating: "a", count: 20))
        for i in 0..<20 { _ = slow.type("a", at: t0.addingTimeInterval(Double(i) * 3)) }
        XCTAssertEqual(slow.stars(), 1, "Under 12 words a minute")
        XCTAssertEqual(TypingRun(text: "a").wordsPerMinute(at: t0), 0, "Nothing typed yet")
        XCTAssertEqual(TypingRun(text: "a").accuracy, 100)
    }

    // MARK: Keyboard

    func testKeysForCharacters() {
        XCTAssertEqual(TypingKeys.key(for: "a")?.key, "a")
        XCTAssertEqual(TypingKeys.key(for: "a")?.shift, false)
        XCTAssertEqual(TypingKeys.key(for: "J")?.key, "j")
        XCTAssertEqual(TypingKeys.key(for: "J")?.shift, true)
        XCTAssertEqual(TypingKeys.key(for: " ")?.key, " ")
        XCTAssertEqual(TypingKeys.key(for: "?")?.key, "?")
        XCTAssertNil(TypingKeys.key(for: "7"))
        XCTAssertEqual(TypingKeys.character(for: "q", shift: true), "Q")
        XCTAssertEqual(TypingKeys.character(for: ",", shift: true), ",")
        XCTAssertNil(TypingKeys.character(for: TypingKeys.shift, shift: false))
        XCTAssertEqual(TypingKeys.rows.joined().filter { $0.count == 1 && $0.first!.isLetter }.count, 26)
        for key in TypingKeys.typingKeys where key.first!.isLetter {
            XCTAssertNotNil(TypingKeys.finger(for: key), key)
        }
    }

    func testRealKeyboardSkipsArrowKeys() {
        XCTAssertTrue(TypingView.typeable("a"))
        XCTAssertTrue(TypingView.typeable(" "))
        XCTAssertTrue(TypingView.typeable("’"))
        XCTAssertFalse(TypingView.typeable("\u{F700}"), "Up arrow")
        XCTAssertFalse(TypingView.typeable("\t"))
    }

    func testStyledTextColorsLetters() {
        var run = TypingRun(text: "ab c")
        _ = run.type("a", at: t0)
        _ = run.type("x", at: t0)
        let text = TypingView.styled(run, fontSize: 20)
        XCTAssertEqual(String(text.characters), "ab c")
    }

    // MARK: Asking

    private func typingAsk(_ text: String) -> String? {
        if case .typing(let ask)? = IntentRouter.parse(text) { return ask }
        return nil
    }

    func testTypingAsksRoute() {
        let cases: [(String, String)] = [
            ("typing practice", "open"),
            ("Teach me to type", "open"),
            ("typing test", "open"),
            ("practice typing", "open"),
            ("typing lessons", "open"),
            ("How fast can I type?", "open"),
            ("can you teach me how to type", "open"),
            ("I want to learn to type", "open"),
            ("open typing practice", "open"),
            ("start a typing test", "open"),
            ("give me a typing lesson", "open"),
            ("typing test please", "open"),
            ("test my typing speed", "open"),
            ("practice the home row", "homeRow"),
            ("practice the top row keys", "topRow"),
            ("practice the bottom row", "bottomRow"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(typingAsk(text), want, text)
        }
    }

    func testOtherAsksAreNotTyping() {
        for text in ["what is typing", "type hello", "how fast can I run", "practice piano", "keyboard shortcuts",
                     "I like typing games", "what is a keyboard", "how do I type faster"] {
            XCTAssertNil(typingAsk(text), text)
        }
    }

    // MARK: The screen's model

    private func bests() -> TypingBests {
        let b = TypingBests(key: "test.typing.best.\(UUID().uuidString)")
        addTeardownBlock { b.clearAll() }
        return b
    }

    func testModelTapsWithShiftAndFinishes() {
        let model = TypingModel(lesson: .homeRow, bests: bests(), seed: 1)
        let text = String(model.run.target)
        XCTAssertEqual(model.nextKey?.key, String(text.first!))
        for c in text {
            if c.isUppercase { model.tap(TypingKeys.shift) }
            model.tap(c == " " ? TypingKeys.space : String(c).lowercased())
        }
        XCTAssertNotNil(model.result)
        XCTAssertEqual(model.result?.accuracy, 100)
        XCTAssertTrue(model.misses.isEmpty)
        XCTAssertNil(model.nextKey, "Nothing left to type")
        model.fresh(seed: 2)
        XCTAssertNil(model.result)
        XCTAssertEqual(model.run.position, 0)
    }

    func testShiftTurnsOffAfterOneLetter() {
        let model = TypingModel(lesson: .homeRow, bests: bests(), seed: 1)
        model.tap(TypingKeys.shift)
        XCTAssertTrue(model.shift)
        model.tap("z")
        XCTAssertFalse(model.shift)
        XCTAssertEqual(model.run.typed.first, "Z")
        XCTAssertEqual(model.shakes, 1)
        XCTAssertEqual(model.misses.values.reduce(0, +), 1)
        model.tap(TypingKeys.delete)
        XCTAssertEqual(model.run.position, 0)
    }

    func testBestSpeedIsKept() {
        let b = bests()
        XCTAssertEqual(b.best(.words), 0)
        XCTAssertTrue(b.record(20, for: .words))
        XCTAssertFalse(b.record(15, for: .words), "Slower isn't a new best")
        XCTAssertTrue(b.record(25, for: .words))
        XCTAssertEqual(b.best(.words), 25)
        XCTAssertEqual(b.best(.homeRow), 0, "Each lesson has its own best")
    }

    func testTipsAndHeadlines() {
        let three = TypingResult(wpm: 30, accuracy: 99, stars: 3, newBest: true, firstTime: false, best: 30)
        XCTAssertEqual(TypingView.headline(three), "Amazing typing!")
        XCTAssertNil(TypingView.tip(three, misses: [:]))
        XCTAssertEqual(TypingView.tip(three, misses: ["k": 3, "a": 1]),
                       "You missed \"K\" 3 times. Turn on the flame to see all your missed keys.")
        let sloppy = TypingResult(wpm: 20, accuracy: 85, stars: 1, newBest: false, firstTime: true, best: 20)
        XCTAssertEqual(TypingView.headline(sloppy), "Nice try! Slow down a little.")
        XCTAssertTrue(TypingView.tip(sloppy, misses: [:])!.contains("97%"))
    }

    func testChangelogHasTyping() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 60)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Typing") } == true)
    }
}
