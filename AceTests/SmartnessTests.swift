import XCTest
@testable import Ace

/// Ace's smartness test: 200 held-out questions (never in the answer bank),
/// covering new wordings, typos, skills, follow-ups, multi-part questions and
/// things Ace can't know. The cases come from tools/smartness_cases.py.
@MainActor
final class SmartnessTests: XCTestCase {
    struct CaseFile: Decodable {
        let count: Int
        let cases: [TestCase]
    }

    struct TestCase: Decodable {
        let n: Int
        let category: String
        let prompt: String
        let expect: Expect
        let context: [String]?
    }

    struct Expect: Decodable {
        let bank: [String]?
        let skill: String?
        let unknown: Bool?
        let multi: [Expect]?
    }

    /// The lowest score that still passes, so the brain can't quietly get worse.
    static let passMark = 0

    private func loadCases() throws -> CaseFile {
        let bundle = Bundle(for: SmartnessTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "smartness_cases", withExtension: "json"), "smartness_cases.json is missing")
        return try JSONDecoder().decode(CaseFile.self, from: Data(contentsOf: url))
    }

    func testCasesAreHeldOut() throws {
        let file = try loadCases()
        XCTAssertEqual(file.cases.count, 200)
        let brain = Brain()
        for c in file.cases {
            let norm = TextKit.normalize(c.prompt)
            if let hit = brain.bank.search(c.prompt).first, hit.wording == norm, hit.semantic == nil, hit.score >= 1 {
                XCTFail("Case \(c.n) is in the answer bank word for word: \(c.prompt)")
            }
        }
    }

    func testSmartness() throws {
        let file = try loadCases()
        let brain = Brain()
        var score = 0
        var perCategory: [String: (right: Int, total: Int)] = [:]
        var misses: [String] = []
        for c in file.cases {
            brain.resetConversation()
            for earlier in c.context ?? [] { brain.noteTurn(earlier) }
            let got = brain.understand(c.prompt)
            let ok = Self.passes(got, c.expect)
            if ok { score += 1 } else { misses.append("#\(c.n) [\(c.category)] \"\(c.prompt)\" -> \(Self.describe(got))") }
            var row = perCategory[c.category] ?? (0, 0)
            row.total += 1
            if ok { row.right += 1 }
            perCategory[c.category] = row
        }
        print("SMARTNESS SCORE: \(score)/\(file.cases.count)")
        for (category, row) in perCategory.sorted(by: { $0.key < $1.key }) {
            print("SMARTNESS \(category): \(row.right)/\(row.total)")
        }
        for m in misses { print("SMARTNESS MISS \(m)") }
        XCTAssertGreaterThanOrEqual(score, Self.passMark, "Smartness dropped below \(Self.passMark)/200")
    }

    static func passes(_ got: Brain.Understanding, _ e: Expect) -> Bool {
        if let parts = e.multi {
            guard case .multi(let gotParts) = got, gotParts.count == parts.count else { return false }
            return zip(gotParts, parts).allSatisfy { passes($0.0, $0.1) }
        }
        if let ids = e.bank {
            switch got {
            case .bank(let id), .weakBank(let id): return ids.contains(id)
            default: return false
            }
        }
        if let skill = e.skill {
            if case .skill(let kind) = got { return kind == skill }
            return false
        }
        if e.unknown == true {
            switch got {
            case .unknown, .clarify: return true
            default: return false
            }
        }
        return false
    }

    static func describe(_ u: Brain.Understanding) -> String {
        switch u {
        case .skill(let k): return "skill \(k)"
        case .bank(let id): return "bank \(id)"
        case .weakBank(let id): return "guess \(id)"
        case .clarify(let ids): return "asks: \(ids.joined(separator: " or "))"
        case .unknown: return "don't know"
        case .multi(let parts): return "[" + parts.map(describe).joined(separator: " | ") + "]"
        }
    }
}
