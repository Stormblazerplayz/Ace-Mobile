import XCTest
@testable import Ace

/// Checks the big knowledge pack (Resources/knowledge.acekb) loads, fast enough, and that the words
/// tools/knowledge/textkit.py stored for each question are the same ones TextKit.swift makes now.
/// If this fails after a TextKit change, change tools/knowledge/textkit.py the same way and rebuild.
@MainActor
final class KnowledgePackTests: XCTestCase {
    func testPackLoads() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: KnowledgePack.fileName, withExtension: KnowledgePack.fileExtension),
                                "knowledge.acekb is missing from the app")
        let data = try Data(contentsOf: url)
        let start = Date()
        let pack = try XCTUnwrap(KnowledgePack(packed: data), "knowledge.acekb didn't load")
        let seconds = Date().timeIntervalSince(start)
        print(String(format: "KNOWLEDGE PACK: %d answers, %d wordings, %.1f MB, loaded in %.2f s",
                     pack.count, pack.wordingCount, Double(data.count) / 1_000_000, seconds))
        XCTAssertGreaterThan(pack.count, 1000)
        XCTAssertLessThan(seconds, 20, "The knowledge pack takes too long to load")
        // Every entry has at least one wording and one answer.
        for e in stride(from: 0, to: pack.count, by: max(1, pack.count / 500)) {
            let entry = pack.entry(at: e)
            XCTAssertFalse(entry.q.isEmpty, "\(entry.id) has no wordings")
            XCTAssertFalse(entry.a.isEmpty, "\(entry.id) has no answers")
        }
    }

    func testStoredWordsMatchTextKit() throws {
        let pack = try XCTUnwrap(KnowledgePack.loadNow())
        var wrong: [String] = []
        let step = max(1, pack.wordingCount / 3000)
        for w in stride(from: 0, to: pack.wordingCount, by: step) {
            let text = pack.wordingText[w]
            let keys = Set(pack.keys(ofWording: w).map { pack.tokens[Int($0)] })
            let all = Set(pack.allWords(ofWording: w).map { pack.tokens[Int($0)] })
            let swiftKeys = Set(TextKit.keywords(text))
            let swiftAll = Set(TextKit.words(text).map(TextKit.stem))
            if TextKit.normalize(text) != text || keys != swiftKeys || all != swiftAll {
                wrong.append("\"\(text)\": stored \(keys.sorted()) / \(all.sorted()), TextKit \(swiftKeys.sorted()) / \(swiftAll.sorted())")
            }
        }
        for line in wrong.prefix(20) { print("KNOWLEDGE PACK MISMATCH \(line)") }
        XCTAssertTrue(wrong.isEmpty, "\(wrong.count) stored wordings don't match TextKit. Update tools/knowledge/textkit.py.")
    }

    func testSearchFindsPackAnswers() throws {
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        let pack = try XCTUnwrap(KnowledgePack.ready)
        XCTAssertEqual(brain.bank.knowledgeCount, pack.count)
        // Asked word for word, every sampled pack question finds its own answer.
        for e in stride(from: 0, to: pack.count, by: max(1, pack.count / 200)) {
            let entry = pack.entry(at: e)
            let hit = brain.bank.search(entry.q[0]).first
            XCTAssertEqual(hit?.entry.id, entry.id, "\"\(entry.q[0])\" didn't find \(entry.id)")
            XCTAssertNotNil(brain.bank.entry(id: entry.id))
        }
    }

    func testSearchStaysFast() throws {
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        let questions = ["whats the capital of peru", "how do i make a part spin in roblox", "why is my pc so laggy",
                         "how do volcanoes form", "what is a for loop in python", "who was the first president"]
        _ = brain.bank.search(questions[0])
        let start = Date()
        for q in questions { _ = brain.understand(q) }
        let each = Date().timeIntervalSince(start) / Double(questions.count)
        print(String(format: "KNOWLEDGE SEARCH: %.0f ms per question", each * 1000))
        XCTAssertLessThan(each, 1.5, "Answering got too slow with the knowledge pack")
    }
}
