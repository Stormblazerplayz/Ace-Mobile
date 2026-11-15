import XCTest
@testable import Ace

/// Everyday wordings that the answer bank says another way ("known as" is "called", "turn to ice"
/// is "freeze"). None of these are in the fresh sets, so the fresh scores stay honest.
@MainActor
final class SayItAnotherWayTests: XCTestCase {
    static let cases: [(String, String)] = [
        ("what's a baby frog known as", "animals.baby.what-is-a-baby-frog-called"),
        ("how many years can a dog live", "animals.how-long-do-dogs-live"),
        ("what age is the earth", "space.how-old-is-the-earth"),
        ("what does gravity mean", "space.what-is-gravity"),
        ("water turns to ice at what temperature", "science.what-temperature-does-water-freeze"),
        ("tomato counts as a fruit", "food.is-a-tomato-a-fruit"),
        ("how much water should i drink each day", "body.how-much-water-should-i-drink"),
        // Must not be cut short: "right" here is the word asked about, not "..., right?".
        ("what is the opposite of right", "words.opposite.what-is-the-opposite-of-right"),
    ]

    func testEverydayWordingsFindTheHandMadeAnswer() {
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        for (prompt, id) in Self.cases {
            brain.resetConversation()
            let got = brain.understand(prompt)
            switch got {
            case .bank(let g), .weakBank(let g):
                XCTAssertEqual(g, id, "\"\(prompt)\"")
            default:
                XCTFail("\"\(prompt)\" -> \(got), wanted \(id)")
            }
        }
    }

    func testRulesKeepShortQuestionsWhole() {
        func say(_ s: String) -> String {
            var t = s
            for p in Brain.sayItAnotherWay {
                t = t.replacingOccurrences(of: p.pattern, with: p.with, options: .regularExpression)
            }
            return t
        }
        XCTAssertEqual(say("what is a day"), "what is a day")
        XCTAssertEqual(say("is that right"), "is that right")
        XCTAssertEqual(say("how does rain happen"), "what causes rain")
        XCTAssertEqual(say("pluto still counts as a planet right"), "is a pluto a planet")
        XCTAssertEqual(say("what is a group of tigers known as"), "what is a group of tigers called")
    }
}
