import XCTest
@testable import Ace

/// 100 never-seen questions in Storm's style (tools/knowledge_cases.py), written before the big
/// knowledge pack was added. A case passes when Ace picks an answer whose text has the right facts,
/// so it checks the answer itself, not just an id. Prints "KNOWLEDGE SCORE".
@MainActor
final class KnowledgeTests: XCTestCase {
    struct CaseFile: Decodable {
        let count: Int
        let cases: [Case]
    }

    struct Case: Decodable {
        let n: Int
        let category: String
        let prompt: String
        let expect: Expect
    }

    struct Expect: Decodable {
        let has: [[String]]?
        let skill: String?
        let unknown: Bool?
    }

    /// The lowest score that still passes. Raised once the pack is in, so it can't quietly get worse.
    static let passMark = 0

    func testKnowledgeQuestions() throws {
        let bundle = Bundle(for: KnowledgeTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "knowledge_cases", withExtension: "json"), "knowledge_cases.json is missing")
        let file = try JSONDecoder().decode(CaseFile.self, from: Data(contentsOf: url))
        XCTAssertEqual(file.cases.count, 100)
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        var score = 0
        var perCategory: [String: (right: Int, total: Int)] = [:]
        var misses: [String] = []
        for c in file.cases {
            brain.resetConversation()
            let got = brain.understand(c.prompt)
            let ok = Self.passes(got, c.expect, brain: brain)
            if ok { score += 1 } else { misses.append("#\(c.n) [\(c.category)] \"\(c.prompt)\" -> \(Self.describe(got, brain: brain))") }
            var row = perCategory[c.category] ?? (0, 0)
            row.total += 1
            if ok { row.right += 1 }
            perCategory[c.category] = row
        }
        print("KNOWLEDGE SCORE: \(score)/\(file.cases.count)")
        for (category, row) in perCategory.sorted(by: { $0.key < $1.key }) {
            print("KNOWLEDGE \(category): \(row.right)/\(row.total)")
        }
        for m in misses { print("KNOWLEDGE MISS \(m)") }
        XCTAssertGreaterThanOrEqual(score, Self.passMark, "Knowledge score dropped below \(Self.passMark)/100")
    }

    /// Every group in `has` needs one of its strings somewhere in the picked entry's answers.
    static func answerFits(_ id: String, _ groups: [[String]], brain: Brain) -> Bool {
        guard let e = brain.bank.entry(id: id) else { return false }
        let text = e.a.joined(separator: " ").lowercased()
        return groups.allSatisfy { group in group.contains { text.contains($0.lowercased()) } }
    }

    static func passes(_ got: Brain.Understanding, _ e: Expect, brain: Brain) -> Bool {
        if e.unknown == true {
            switch got {
            case .unknown, .clarify: return true
            default: return false
            }
        }
        if let skill = e.skill, case .skill(let kind) = got, kind == skill { return true }
        if let groups = e.has {
            switch got {
            case .bank(let id), .weakBank(let id): return answerFits(id, groups, brain: brain)
            default: return false
            }
        }
        return false
    }

    static func describe(_ u: Brain.Understanding, brain: Brain) -> String {
        switch u {
        case .bank(let id), .weakBank(let id):
            let first = brain.bank.entry(id: id)?.a.first ?? ""
            return "\(SmartnessTests.describe(u)): \(first.prefix(90))"
        default:
            return SmartnessTests.describe(u)
        }
    }
}
