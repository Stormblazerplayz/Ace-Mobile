import XCTest
@testable import Ace

/// Fresh set 2: 50 more questions nobody tuned Ace on (tools/fresh_cases_2.py), written before the
/// matching fixes that the first fresh set led to. Like the knowledge set, it checks the answer's
/// facts, not which entry won. Prints "FRESH2 SCORE" and never fails the build on a low score.
@MainActor
final class FreshQuestions2Tests: XCTestCase {
    func testFreshQuestions2() throws {
        let bundle = Bundle(for: FreshQuestions2Tests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "fresh_cases_2", withExtension: "json"), "fresh_cases_2.json is missing")
        let file = try JSONDecoder().decode(KnowledgeTests.CaseFile.self, from: Data(contentsOf: url))
        XCTAssertEqual(file.cases.count, 50)
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        var score = 0
        var misses: [String] = []
        for c in file.cases {
            brain.resetConversation()
            let got = brain.understand(c.prompt)
            if KnowledgeTests.passes(got, c.expect, brain: brain) {
                score += 1
            } else {
                misses.append("#\(c.n) [\(c.category)] \"\(c.prompt)\" -> \(KnowledgeTests.describe(got, brain: brain))")
            }
        }
        print("FRESH2 SCORE: \(score)/\(file.cases.count)")
        for m in misses { print("FRESH2 MISS \(m)") }
    }
}
