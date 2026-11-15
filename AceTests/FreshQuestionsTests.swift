import XCTest
@testable import Ace

/// 50 fresh questions nobody tuned Ace on (tools/fresh_cases.py). This prints an honest score
/// ("FRESH SCORE") and never fails the build on a low score, so the number stays a real check.
@MainActor
final class FreshQuestionsTests: XCTestCase {
    func testFreshQuestions() throws {
        let bundle = Bundle(for: FreshQuestionsTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "fresh_cases", withExtension: "json"), "fresh_cases.json is missing")
        let file = try JSONDecoder().decode(SmartnessTests.CaseFile.self, from: Data(contentsOf: url))
        XCTAssertEqual(file.cases.count, 50)
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        var score = 0
        var misses: [String] = []
        for c in file.cases {
            brain.resetConversation()
            for earlier in c.context ?? [] { brain.noteTurn(earlier) }
            let got = brain.understand(c.prompt)
            if SmartnessTests.passes(got, c.expect) {
                score += 1
            } else {
                misses.append("#\(c.n) [\(c.category)] \"\(c.prompt)\" -> \(SmartnessTests.describe(got))")
                // What the answer bank saw, to show why it missed (print only, the score is the same).
                for m in brain.bank.search(c.prompt, limit: 4) {
                    let sem = m.semantic.map { String(format: "%.2f", $0) } ?? "-"
                    print(String(format: "FRESH NEAR #%d %.3f lex %.3f sem %@ %@ (%@)", c.n, m.score, m.lexical, sem, m.entry.id, m.entry.source ?? "builtin"))
                }
            }
        }
        print("FRESH SCORE: \(score)/\(file.cases.count)")
        for m in misses { print("FRESH MISS \(m)") }
    }
}
