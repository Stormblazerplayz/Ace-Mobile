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

    /// Forgets everything.
    func removeAll() {
        facts.removeAll()
        save()
    }

    /// Facts that contain the words, newest first (for the Memory page's search box).
    func search(_ words: String) -> [MemoryFact] {
        let w = words.trimmingCharacters(in: .whitespaces).lowercased()
        let list = facts.reversed()
        guard !w.isEmpty else { return Array(list) }
        return list.filter { $0.text.lowercased().contains(w) }
    }

    /// Names you gave things: "my vacuum is called Mova" gives ["mova": "vacuum"].
    var aliases: [String: String] { Self.aliases(in: facts.map(\.text)) }

    /// Finds "my X is called Y", "my X's name is Y" and "Y is my X" in a list of facts.
    nonisolated static func aliases(in texts: [String]) -> [String: String] {
        var out: [String: String] = [:]
        for text in texts {
            let t = TextKit.normalize(text)
            var pair: (alias: String, thing: String)?
            if let g = Rx.groups(#"^(?:my|our) ([a-z][a-z ]*?) (?:is|are) (?:called|named) ([a-z0-9][a-z0-9 '\-]*)$"#, t) {
                pair = (g[1], g[0])
            } else if let g = Rx.groups(#"^(?:my|our) ([a-z][a-z ]*?)'s name is ([a-z0-9][a-z0-9 '\-]*)$"#, t) {
                pair = (g[1], g[0])
            } else if let g = Rx.groups(#"^([a-z0-9][a-z0-9 '\-]*?) is (?:my|our) ([a-z][a-z ]*?)(?:'s name)?$"#, t) {
                pair = (g[0], g[1])
            }
            guard let p = pair else { continue }
            let alias = p.alias.trimmingCharacters(in: .whitespaces)
            var thing = p.thing.trimmingCharacters(in: .whitespaces)
            for art in ["new ", "robot "] where thing.hasPrefix(art) && thing.count > art.count + 2 { thing = String(thing.dropFirst(art.count)) }
            // Short words and words that aren't names ("it is my birthday") don't count.
            guard alias.count >= 2, alias.split(separator: " ").count <= 3, !notNames.contains(alias),
                  thing.split(separator: " ").count <= 3, !notNames.contains(thing), alias != thing,
                  !Rx.matches(#"\b(favorite|favourite|fav|best|least|worst|lucky|first|last|least favorite)\b"#, thing) else { continue }
            out[alias] = thing
        }
        return out
    }

    nonisolated private static let notNames: Set<String> = [
        "it", "this", "that", "he", "she", "they", "there", "here", "what", "who", "today", "tomorrow", "tonight",
        "favorite", "best", "the best", "name", "birthday", "fault", "turn", "job", "life", "dream", "goal", "plan",
        "home", "house", "friend", "best friend", "the", "a", "an", "one", "mine", "ours",
    ]

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
