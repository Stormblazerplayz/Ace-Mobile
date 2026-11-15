import Foundation

/// Notes you make by voice ("take a note: bring my PE kit"), kept on the iPad, newest first.
@MainActor
final class NotesStore: ObservableObject {
    static let shared = NotesStore()

    struct Note: Codable, Identifiable, Equatable {
        var id = UUID()
        var text: String
        var date = Date()
    }

    @Published private(set) var notes: [Note] = []
    private let key: String

    init(key: String = "aceNotes") {
        self.key = key
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Note].self, from: data) {
            notes = saved
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) { UserDefaults.standard.set(data, forKey: key) }
    }

    @discardableResult
    func add(_ text: String) -> Note {
        var clean = text.trimmingCharacters(in: CharacterSet(charactersIn: " .\"'"))
        if let first = clean.first { clean = first.uppercased() + clean.dropFirst() }
        let note = Note(text: clean)
        notes.insert(note, at: 0)
        save()
        return note
    }

    /// The best match for "the note about milk": the note with the most of those words, newest first on a tie.
    func find(_ words: String) -> Note? {
        let wanted = Set(TextKit.normalize(words).split(separator: " ").map(String.init))
            .subtracting(["the", "a", "an", "my", "about", "to", "of", "that", "says", "note"])
        guard !wanted.isEmpty else { return nil }
        var best: (note: Note, hits: Int)?
        for n in notes {
            let have = Set(TextKit.normalize(n.text).split(separator: " ").map(String.init))
            let hits = wanted.intersection(have).count
            if hits > 0, hits > (best?.hits ?? 0) { best = (n, hits) }
        }
        return best?.note
    }

    @discardableResult
    func delete(matching words: String) -> Note? {
        guard let n = find(words) else { return nil }
        notes.removeAll { $0.id == n.id }
        save()
        return n
    }

    /// Notes containing every word typed in the search box ("milk eggs"). All notes when it's empty.
    func search(_ text: String) -> [Note] {
        let words = TextKit.normalize(text).split(separator: " ").map(String.init)
        guard !words.isEmpty else { return notes }
        return notes.filter { n in
            let have = TextKit.normalize(n.text)
            return words.allSatisfy { have.contains($0) }
        }
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    /// Deletes every note. Returns how many there were.
    @discardableResult
    func clearAll() -> Int {
        let n = notes.count
        notes = []
        save()
        return n
    }
}

/// Reads asks about notes, the voice speed and the shopping list.
enum HelperParser {
    /// "take a note: buy milk" -> ("add", "buy milk"). Actions: add, list, delete, clear.
    static func note(_ raw: String) -> (action: String, text: String)? {
        let t = TextKit.normalize(raw)
        if Rx.matches(#"^(?:please )?(?:delete|remove|erase|clear|wipe)(?: out)?(?: all)?(?: of)? (?:my |the )?notes(?: please)?$"#, t) {
            return ("clear", "")
        }
        if Rx.matches(#"^(?:(?:what are|show|read|list|tell me|open|check)(?: me)?(?: all)?(?: of)? (?:my |the )?notes|(?:my )?notes|do i have (?:any )?notes|what notes do i have|what did i (?:write down|note down))(?: please)?$"#, t) {
            return ("list", "")
        }
        if let g = Rx.groups(#"^(?:please )?(?:delete|remove|erase|get rid of|cross off|cross out) (?:the |my |that )?note (?:about|that says|saying|for|on|with)\s+(.+)$"#, t) {
            return ("delete", g[0])
        }
        // Keep the words as they were typed (capitals and all) for the note itself.
        let typed = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "’", with: "'")
        let adds = [
            #"^(?:please\s+)?(?:can you\s+|could you\s+)?(?:take|make|write|add|create|save|jot)(?:\s+me)?\s+(?:a|down a|another|a quick|a new)\s+note(?:\s+to self)?(?:\s+(?:that says|saying|that|to say|for me))?\s*[:,\-]?\s+(.+)$"#,
            #"^(?:please\s+)?note(?:\s+to self)?\s*[:,\-]\s*(.+)$"#,
            #"^(?:please\s+)?note to self\s+(.+)$"#,
            #"^(?:please\s+)?(?:can you\s+)?(?:write|jot|put)\s+(?:this\s+|that\s+)?down\s*[:,\-]?\s+(.+)$"#,
            #"^(?:please\s+)?(?:add|put)\s+(.+?)\s+(?:to|in|on)\s+my notes$"#,
        ]
        for p in adds {
            if let g = Rx.groups(p, typed), let text = g.first {
                let clean = text.trimmingCharacters(in: CharacterSet(charactersIn: " .!\"'"))
                if !clean.isEmpty { return ("add", clean) }
            }
        }
        return nil
    }

    /// "talk slower" -> "slower". Also "faster" and "normal".
    static func voiceSpeed(_ raw: String) -> String? {
        let t = TextKit.normalize(raw)
        let polite = #"(?:(?:can you|could you|please|ace|hey ace|ok|okay)\s+)*"#
        if Rx.matches("^" + polite + #"(?:talk|speak|read|say things|go)(?: a)?(?: bit| little| lot)?(?: bit)? (?:slower|more slowly|slowly|less fast)(?: please)?$"#, t)
            || Rx.matches("^" + polite + #"slow (?:down|it down)(?: your voice| when you talk| please)*$"#, t)
            || Rx.matches(#"^you(?: are)? (?:talk|talking|speak|speaking) (?:too|really|so) (?:fast|quick|quickly)$"#, t) {
            return "slower"
        }
        if Rx.matches("^" + polite + #"(?:talk|speak|read|say things|go)(?: a)?(?: bit| little| lot)?(?: bit)? (?:faster|quicker|more quickly|quickly)(?: please)?$"#, t)
            || Rx.matches("^" + polite + #"speed (?:up|it up)(?: your voice| when you talk| please)*$"#, t)
            || Rx.matches(#"^you(?: are)? (?:talk|talking|speak|speaking) (?:too|really|so) (?:slow|slowly)$"#, t) {
            return "faster"
        }
        if Rx.matches("^" + polite + #"(?:(?:talk|speak)(?: at)? (?:your |the )?(?:normal|regular|usual) speed|(?:reset|fix) (?:your |the )?(?:voice|talking|speaking) speed|normal (?:voice|talking) speed|(?:go back to|back to|use|switch back to|change back to) (?:your |the )?(?:normal|regular|usual) (?:speed|voice|voice speed|talking speed))(?: please)?$"#, t) {
            return "normal"
        }
        return nil
    }

    /// "recipe" (the last recipe's ingredients), "read", or "add:milk and eggs".
    static func shopping(_ raw: String) -> String? {
        let t = TextKit.normalize(raw)
        let list = #"(?:my |the |a )?(?:shopping|grocery|groceries|grocery store|food) list"#
        if Rx.matches(#"^(?:please )?(?:can you )?(?:add|put|save|send|copy)(?: all)?(?: of)? (?:the |these |those |its |all the )?(?:ingredients|recipe|stuff i need|things i need|stuff|items)(?: for (?:it|this|that|the recipe|this recipe|that recipe))? (?:to|on|onto|in|into) "# + list + #"(?: please)?$"#, t)
            || Rx.matches(#"^(?:please )?(?:can you )?(?:make|create|build|start) (?:me )?a (?:shopping|grocery) list(?: for (?:it|this|that|this recipe|that recipe|the recipe))?(?: please)?$"#, t) {
            return "recipe"
        }
        if Rx.matches(#"^(?:(?:what is|what are the things|what do i have|what do i need) on "# + list + #"|(?:read|show|tell me|open|check|what is in)(?: me)? "# + list + #"|(?:my )?(?:shopping|grocery) list)(?: please)?$"#, t) {
            return "read"
        }
        if let g = Rx.groups(#"^(?:please )?(?:can you )?(?:add|put)\s+(.+?)\s+(?:to|on|onto|in)\s+"# + list + #"(?: please)?$"#, t) {
            return "add:" + g[0]
        }
        return nil
    }
}

/// Which of the things to buy are new (the list already has the rest).
enum ShoppingList {
    static let name = "Shopping"

    static func key(_ s: String) -> String {
        TextKit.normalize(s).replacingOccurrences(of: #"^(?:some|a|an|the)\s+"#, with: "", options: .regularExpression)
    }

    static func split(_ items: [String], existing: [String]) -> (new: [String], skipped: [String]) {
        var have = Set(existing.map(key))
        var new: [String] = []
        var skipped: [String] = []
        for item in items {
            let clean = item.trimmingCharacters(in: .whitespaces)
            guard !clean.isEmpty else { continue }
            let k = key(clean)
            if have.contains(k) { skipped.append(clean) } else { new.append(clean); have.insert(k) }
        }
        return (new, skipped)
    }
}

extension Say {
    /// "You have 1 notes" -> "You have 1 note".
    static func singular(_ text: String) -> String {
        text.replacingOccurrences(of: #"\b1 (note|ingredient|thing|item)s\b"#, with: "1 $1", options: .regularExpression)
    }
}
