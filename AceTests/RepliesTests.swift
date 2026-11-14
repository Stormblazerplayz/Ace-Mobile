import XCTest
@testable import Ace

/// Checks that every reply Ace has comes in 20 different wordings, and that Ace never says model tags.
@MainActor
final class RepliesTests: XCTestCase {

    func testEveryCannedReplyHas20Wordings() {
        for key in ReplyKey.allCases {
            let all = Say.wordings(key)
            XCTAssertEqual(all.count, 20, "\(key.rawValue) should have 20 wordings")
            XCTAssertEqual(Set(all).count, all.count, "\(key.rawValue) has the same wording twice")
        }
    }

    func testEveryBankAnswerHas20Wordings() {
        let bank = QABank()
        let builtIn = bank.entries.filter { $0.source == nil || $0.source == "builtin" }
        XCTAssertGreaterThan(builtIn.count, 2000)
        for e in builtIn {
            XCTAssertEqual(e.a.count, 20, "\(e.id) should have 20 answers")
            XCTAssertEqual(Set(e.a).count, e.a.count, "\(e.id) has the same answer twice")
        }
    }

    func testRepliesDontRepeatRightAway() {
        VariantPicker.shared.reset()
        var last: [String] = []
        for _ in 0..<40 {
            let line = Say.line(.summon)
            XCTAssertFalse(last.suffix(8).contains(line), "Said \"\(line)\" again too soon")
            last.append(line)
        }
    }

    func testSlotsGetFilled() {
        let line = Say.line(.timerSet, ["label": "Timer", "duration": "5 minutes"])
        XCTAssertFalse(line.contains("{"), line)
        XCTAssertTrue(line.contains("5 minutes"), line)
    }

    func testModelTagsAreStripped() {
        XCTAssertEqual(TextKit.stripModelTags("<think></think>Hi there!"), "Hi there!")
        XCTAssertEqual(TextKit.stripModelTags("<think>\nlet me think\n</think>\n\nThe answer is 4."), "The answer is 4.")
        XCTAssertEqual(TextKit.stripModelTags("<think>never closed"), "")
        XCTAssertEqual(TextKit.stripModelTags("Paris<|im_end|>"), "Paris")
        XCTAssertEqual(TextKit.stripModelTags("Answer: 42"), "42")
    }

    func testWebAnswersStayShort() {
        let long = "A playing card is a piece of specially prepared card stock. It is used for card games. "
            + "Cards are often printed with numbers. People have played cards for hundreds of years. Some decks have jokers."
        let short = Brain.brief(long, query: "playing cards")
        XCTAssertLessThanOrEqual(short.count, 280)
        XCTAssertTrue(short.hasPrefix("A playing card"), short)
        XCTAssertFalse(short.contains("jokers"), short)
    }
}
