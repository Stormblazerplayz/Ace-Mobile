import Foundation

/// Ace's built-in code library: Roblox Lua scripts (kill bricks, moving parts, doors, shops...),
/// C++ (Arduino, console games, basics, Unreal Engine), Python (console games, turtle drawing, tools,
/// Raspberry Pi) and Swift (SwiftUI views and apps). It all works with no internet.
/// The scripts live in tools/scripts and are bundled as scripts.json by tools/build_scripts.py.
enum ScriptLibrary {
    struct Script: Decodable, Identifiable, Equatable {
        let id: String
        let title: String
        let language: String   // "Lua", "C++", "Python" or "Swift"
        let category: String
        let kind: String       // "Script", "LocalScript", "Arduino sketch", "Unreal C++ class"...
        let `where`: String
        let keywords: [String]
        let about: String
        let code: String

        var card: CodeCard {
            CodeCard(id: id, title: title, language: language, kind: kind, where: `where`, about: about, code: code)
        }
    }

    private struct File: Decodable { let scripts: [Script] }

    static let all: [Script] = {
        guard let url = Bundle.main.url(forResource: "scripts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.scripts
    }()

    static let languages = ["Lua", "C++", "Python", "Swift"]

    /// Categories for a language, in the library's order.
    static func categories(_ language: String) -> [String] {
        var out: [String] = []
        for s in all where s.language == language && !out.contains(s.category) { out.append(s.category) }
        return out
    }

    static func script(id: String) -> Script? { all.first { $0.id == id } }

    // MARK: Words

    /// Words that say nothing about which script you want.
    static let filler: Set<String> = Set("""
    a an the for in of to i my that this it is and on with can you please how do does what some one which when so be \
    will would like just into from your me give show write make makes making need want get send script scripts code \
    coding program programs sketch sketches example examples lua luau roblox c++ cpp arduino unreal ue5 ue4 engine \
    python py swift swiftui xcode \
    studio simple basic easy good cool little small quick new about using use are there any have has where put
    """.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init))

    private static let cppWords: Set<String> = ["c++", "cpp", "arduino", "unreal", "ue5", "ue4"]
    private static let luaWords: Set<String> = ["lua", "luau", "roblox"]
    private static let pythonWords: Set<String> = ["python", "py"]
    private static let swiftWords: Set<String> = ["swift", "swiftui", "xcode"]

    /// The language a word names ("roblox" -> Lua, "py" -> Python, "swiftui" -> Swift, anything else -> C++).
    static func language(of word: String) -> String {
        if luaWords.contains(word) { return "Lua" }
        if pythonWords.contains(word) { return "Python" }
        if swiftWords.contains(word) { return "Swift" }
        return "C++"
    }

    /// A light word stem so "spinning", "spins" and "spin" match: drops s, ing and a final e.
    static func stem(_ word: String) -> String {
        var w = word
        if w.count > 3, w.hasSuffix("s"), !w.hasSuffix("ss") { w.removeLast() }
        if w.count > 5, w.hasSuffix("ing") {
            w.removeLast(3)
            let chars = Array(w)
            if chars.count > 2, chars[chars.count - 1] == chars[chars.count - 2], !"aeiouls".contains(chars[chars.count - 1]) {
                w.removeLast()
            }
        }
        if w.count > 3, w.hasSuffix("e") { w.removeLast() }
        return w
    }

    /// Splits normalized text into stemmed words (filler words are kept, but not stemmed).
    static func tokens(_ normalized: String) -> [String] {
        var out: [String] = []
        for piece in normalized.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "/" }) {
            var w = String(piece).trimmingCharacters(in: CharacterSet(charactersIn: ".'"))
            if w.hasSuffix("'s"), w.count > 2 { w.removeLast(2) }
            if w.isEmpty { continue }
            if filler.contains(w) { out.append(w); continue }
            let s = stem(w)
            if !s.isEmpty { out.append(s) }
        }
        return out
    }

    private static func significant(_ words: [String]) -> [String] { words.filter { !filler.contains($0) } }

    /// The language and category the words ask for ("c++" -> C++, "arduino" -> C++ and Arduino).
    static func hints(_ words: [String]) -> (language: String?, category: String?) {
        let set = Set(words)
        var language: String?
        if !set.isDisjoint(with: cppWords) || (set.contains("c") && set.contains("plu")) { language = "C++" }
        else if !set.isDisjoint(with: pythonWords) || set.contains("raspberry") { language = "Python" }
        else if !set.isDisjoint(with: swiftWords) { language = "Swift" }
        else if !set.isDisjoint(with: luaWords) { language = "Lua" }
        var category: String?
        if set.contains("arduino") { category = "Arduino" }
        else if set.contains("raspberry") { category = "Raspberry Pi" }
        else if set.contains("turtle") { category = "Drawing" }
        else if !set.isDisjoint(with: ["unreal", "ue5", "ue4"]) { category = "Unreal Engine" }
        return (language, category)
    }

    /// Each script's words (from its title and keywords), its keywords as word lists, and its title's words.
    private static let index: [(words: Set<String>, phrases: [String], title: Set<String>)] = all.map { s in
        let title = Set(significant(tokens(TextKit.normalize(s.title))))
        var words = title
        var phrases: [String] = []
        for k in s.keywords {
            let t = tokens(TextKit.normalize(k))
            words.formUnion(significant(t))
            phrases.append(t.joined(separator: " "))
        }
        return (words, phrases, title)
    }

    /// How many scripts use each word. Rare words count for more.
    private static let wordCounts: [String: Int] = {
        var counts: [String: Int] = [:]
        for entry in index { for w in entry.words { counts[w, default: 0] += 1 } }
        return counts
    }()

    private static func weight(_ word: String) -> Double {
        guard let n = wordCounts[word], n > 0 else { return 0 }
        return log(Double(all.count + 1) / Double(n))
    }

    struct Match: Equatable {
        let script: Script
        let score: Double
        /// True when one of the script's keywords is in the question word for word.
        let phrase: Bool
    }

    /// The best script for a question ("give me a kill brick script", "C++ servo code"), or nil.
    static func find(_ text: String) -> Match? {
        let words = tokens(TextKit.normalize(text))
        let (language, category) = hints(words)
        let wanted = Set(significant(words))
        guard !wanted.isEmpty else { return nil }
        let joined = " " + words.joined(separator: " ") + " "
        var best: Match?
        for (i, s) in all.enumerated() {
            if let language, s.language != language { continue }
            let entry = index[i]
            var score = wanted.reduce(0.0) { $0 + (entry.words.contains($1) ? weight($1) : 0) }
            if score == 0 { continue }
            let phrase = entry.phrases.contains { !$0.isEmpty && joined.contains(" " + $0 + " ") }
            if phrase { score += 2 }
            if let category, s.category == category { score += 3 }
            if language == nil, s.language == "Lua" { score += 0.05 }   // Roblox first when you don't say
            // A word in the title counts a bit more ("servo code" -> Servo Sweep, not a lock that also uses a servo),
            // and among equals the simplest script (fewest words) wins.
            score += 0.3 * Double(wanted.intersection(entry.title).count)
            score -= 0.001 * Double(entry.words.count)
            if best == nil || score > best!.score { best = Match(script: s, score: score, phrase: phrase) }
        }
        guard let b = best, b.score >= 1.5 else { return nil }
        return b
    }

    // MARK: Is this a code question?

    private static let codeWord = #"(?<![a-z])(scripts?|code|coding|program|programs|sketch|sketches|lua|luau|c\+\+|cpp|arduino|unreal|ue5|ue4|roblox|python|py|swift|swiftui)(?![a-z+])"#
    private static let askWord = #"\b(give|show|write|make|need|want|get|send|got|have you got|can you|could you|how do i|how to|code for|script for|script that|script to|scripts? for|i need)\b"#

    /// True when the text asks for one of Ace's scripts. Questions like "what is lua" stay with the answer bank.
    static func wantsScript(_ text: String) -> Bool {
        let t = TextKit.normalize(text)
        guard Rx.matches(codeWord, t) else { return false }
        let asks = Rx.matches(askWord, t)
        if Rx.matches(#"^(what|who|why|when|where) (is|are|was|were|does|do)\b"#, t), !asks { return false }
        guard let m = find(t) else { return false }
        let words = tokens(t)
        let short = Set(significant(words)).count <= 2
        return hints(words).language != nil || asks || m.phrase || short
    }

    /// "what scripts do you have", "show me your roblox scripts", "list c++ code". Returns the language, or "" for all.
    static func listAsk(_ text: String) -> String? {
        let t = TextKit.normalize(text)
        let lang = #"(?:(lua|luau|roblox|c\+\+|cpp|arduino|unreal|python|py|swift|swiftui)\s+)?"#
        let things = #"(?:scripts|code|programs|sketches|code examples)"#
        let patterns = [
            #"^(?:what|which)\s+(?:kinds? of\s+)?"# + lang + things + #"\s+(?:do you have|do you know|can you (?:give me|write|make)|are there|have you got)$"#,
            #"^(?:list|show me|show)\s+(?:all\s+)?(?:of\s+)?(?:the\s+|your\s+)?"# + lang + things + #"$"#,
            #"^(?:do you have|have you got|got)\s+(?:any\s+)?"# + lang + things + #"$"#,
            #"^(?:open\s+)?(?:the\s+|your\s+)?"# + lang + #"(?:script|code)\s+(?:library|list)$"#,
        ]
        for p in patterns {
            if let g = Rx.groups(p, t) {
                let word = g.first ?? ""
                if word.isEmpty { return "" }
                return language(of: word)
            }
        }
        return nil
    }

    /// "give me a script", "can you write me a roblox script": a script, but not which one. Returns the language, or "" for any.
    static func needsOne(_ text: String) -> String? {
        let t = TextKit.normalize(text)
        let p = #"^(?:please\s+)?(?:give me|write me|make me|send me|show me|i want|i need|can you (?:give me|write|make|send)(?: me)?|could you (?:give me|write|make)(?: me)?)\s+(?:a|an|some|one)\s+(?:(lua|luau|roblox|c\+\+|cpp|arduino|unreal|python|py|swift|swiftui)\s+)?(?:script|code|program|sketch)s?(?:\s+please)?$"#
        guard let g = Rx.groups(p, t) else { return nil }
        let word = g.first ?? ""
        if word.isEmpty { return "" }
        return language(of: word)
    }

    /// The name Ace says out loud: "Kill Volume (Kill Brick)" -> "kill volume", "Classes and Objects: a Pet" -> "classes and objects".
    static func spokenName(_ title: String) -> String {
        var name = title
        if let i = name.firstIndex(of: "("), i > name.startIndex { name = String(name[..<i]) }
        if let r = name.range(of: ": "), r.lowerBound > name.startIndex { name = String(name[..<r.lowerBound]) }
        name = name.trimmingCharacters(in: .whitespaces).lowercased()
        return name.replacingOccurrences(of: "neopixel", with: "NeoPixel").replacingOccurrences(of: "npc", with: "NPC")
            .replacingOccurrences(of: "dc motor", with: "DC motor").replacingOccurrences(of: "l298n", with: "L298N")
            .replacingOccurrences(of: #"\bled\b"#, with: "LED", options: .regularExpression)
    }

    /// A few script names for a language, to suggest.
    static func examples(_ language: String?, count: Int = 4) -> [String] {
        let pool = all.filter { language == nil || $0.language == language }
        var out: [String] = []
        var cats: Set<String> = []
        for s in pool where !cats.contains(s.category) && out.count < count {
            cats.insert(s.category)
            out.append(s.title.lowercased())
        }
        return out
    }
}
