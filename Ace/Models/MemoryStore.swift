import Foundation

/// Facts the user asked Ace to remember ("remember my favorite color is blue").
struct MemoryFact: Codable, Identifiable, Equatable {
    var id = UUID()
    var text: String
    var date = Date()
}

@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var facts: [MemoryFact] = []
    private let file = "memory.json"

    init() {
        facts = Persistence.load([MemoryFact].self, from: file) ?? []
    }

    func add(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        // A new fact about the same thing replaces the old one ("my favorite color is ...").
        if let subject = Self.subject(of: clean) {
            facts.removeAll { Self.subject(of: $0.text) == subject }
        }
        facts.append(MemoryFact(text: clean))
        save()
    }

    func remove(_ fact: MemoryFact) {
        facts.removeAll { $0.id == fact.id }
        save()
    }

    /// Removes facts that mention the words. Returns how many were removed.
    @discardableResult
    func forget(matching words: String) -> Int {
        let w = words.lowercased()
        if ["everything", "all", "it all", "everything you know"].contains(w) {
            let n = facts.count
            facts.removeAll()
            save()
            return n
        }
        let keys = Set(TextKit.keywords(w))
        let before = facts.count
        facts.removeAll { f in
            let fk = Set(TextKit.keywords(f.text))
            return !keys.isEmpty && keys.isSubset(of: fk)
        }
        save()
        return before - facts.count
    }

    /// Finds the facts that best match a question like "what's my favorite color".
    func recall(_ question: String) -> [MemoryFact] {
        let q = Set(TextKit.keywords(question))
        guard !q.isEmpty else { return [] }
        return facts
            .map { f in (f, Set(TextKit.keywords(f.text)).intersection(q).count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    func replaceAll(_ list: [MemoryFact]) {
        facts = list
        save()
    }

    private func save() {
        Persistence.save(facts, to: file)
    }

    /// "my favorite color is blue" -> "favorite color".
    static func subject(of text: String) -> String? {
        let t = TextKit.normalize(text)
        guard let g = Rx.groups(#"^(?:my|i have a|our)\s+(.+?)\s+(?:is|are|was)\s+.+$"#, t) else { return nil }
        return g[0]
    }

    /// Turns "my favorite color is blue" into "your favorite color is blue" for replies.
    static func youForm(_ text: String) -> String {
        var words = text.split(separator: " ").map(String.init)
        for i in words.indices {
            switch words[i].lowercased() {
            case "my": words[i] = "your"
            case "i": words[i] = "you"
            case "i'm", "im": words[i] = "you're"
            case "me": words[i] = "you"
            case "am": words[i] = "are"
            case "mine": words[i] = "yours"
            default: break
            }
        }
        return words.joined(separator: " ")
    }
}
