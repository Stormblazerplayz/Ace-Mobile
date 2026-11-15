import Foundation

/// Ace's offline translator: about 300 everyday words and phrases in 12 languages (phrasebook.json).
enum Phrasebook {
    struct Language: Decodable, Equatable {
        let code: String
        let name: String
    }

    struct Entry: Decodable, Equatable {
        let en: String
        let also: [String]?
        let t: [String: String]
        let say: [String: String]?
    }

    private struct File: Decodable {
        let languages: [Language]
        let entries: [Entry]
    }

    private static let file: File? = {
        guard let url = Bundle.main.url(forResource: "phrasebook", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(File.self, from: data)
    }()

    static var languages: [Language] { file?.languages ?? [] }
    static var entries: [Entry] { file?.entries ?? [] }

    /// Other names people use for a language.
    static let languageWords: [String: String] = [
        "spanish": "es", "espanol": "es", "español": "es", "mexican": "es",
        "french": "fr", "francais": "fr", "français": "fr",
        "german": "de", "deutsch": "de",
        "italian": "it", "italiano": "it",
        "portuguese": "pt", "brazilian": "pt", "brazilian portuguese": "pt",
        "japanese": "ja",
        "chinese": "zh", "mandarin": "zh", "mandarin chinese": "zh",
        "korean": "ko",
        "hindi": "hi",
        "arabic": "ar",
        "russian": "ru",
        "dutch": "nl",
    ]

    /// The voice language for "Say it".
    static let speechCodes: [String: String] = [
        "es": "es-ES", "fr": "fr-FR", "de": "de-DE", "it": "it-IT", "pt": "pt-BR", "ja": "ja-JP",
        "zh": "zh-CN", "ko": "ko-KR", "hi": "hi-IN", "ar": "ar-SA", "ru": "ru-RU", "nl": "nl-NL",
    ]

    static func languageCode(_ name: String) -> String? {
        languageWords[TextKit.normalize(name).trimmingCharacters(in: .whitespaces)]
    }

    static func languageName(_ code: String) -> String {
        languages.first { $0.code == code }?.name ?? code
    }

    private static let languagePattern: String = {
        let names = languageWords.keys.sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }
        return "(" + names.joined(separator: "|") + ")"
    }()

    /// "how do you say thank you in spanish" -> ("thank you", "es"). Nil when it isn't a translation ask.
    static func parse(_ text: String) -> (phrase: String, code: String)? {
        let t = TextKit.normalize(text).trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        let L = languagePattern
        let patterns: [(String, Int, Int)] = [   // pattern, phrase group, language group
            (#"^(?:how (?:do|would|can|should) (?:you|i|we) say|how to say|how does one say)\s+(.+?)\s+(?:in|into)\s+"# + L + #"$"#, 0, 1),
            (#"^(?:can you |could you |please )?(?:translate|say)\s+(.+?)\s+(?:in|into|to)\s+"# + L + #"(?: please)?$"#, 0, 1),
            (#"^(?:can you |could you |please )?translate\s+(?:this |that )?(?:to|into)\s+"# + L + #"\s*:?\s+(.+)$"#, 1, 0),
            (#"^what (?:is|are)\s+(.+?)\s+in\s+"# + L + #"$"#, 0, 1),
            (#"^what (?:is|are) the\s+"# + L + #"\s+(?:word|words|phrase) for\s+(.+)$"#, 1, 0),
            (#"^"# + L + #"\s+(?:for|word for)\s+(.+)$"#, 1, 0),
        ]
        for (p, pi, li) in patterns {
            guard let g = Rx.groups(p, t), g.count > max(pi, li) else { continue }
            var phrase = g[pi].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            for prefix in ["the word ", "the phrase ", "the words ", "word ", "phrase "] where phrase.hasPrefix(prefix) {
                phrase = String(phrase.dropFirst(prefix.count))
            }
            guard !phrase.isEmpty, let code = languageWords[g[li]] else { continue }
            return (phrase, code)
        }
        // Just the words and the language ("thank you in spanish", "how are you in french"), only for phrases Ace knows.
        if let g = Rx.groups(#"^(.+?)\s+in\s+"# + L + #"(?: please)?$"#, t), g.count > 1, let code = languageWords[g[1]], find(g[0]) != nil {
            return (g[0], code)
        }
        return nil
    }

    private static func clean(_ s: String) -> String {
        TextKit.normalize(s).trimmingCharacters(in: CharacterSet(charactersIn: ".!? ")).replacingOccurrences(of: "...", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    /// The entry for an English word or phrase ("thanks", "good morning", "the number 5").
    private static let numberWords: [String: String] = [
        "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine",
        "10": "ten", "11": "eleven", "12": "twelve", "13": "thirteen", "14": "fourteen", "15": "fifteen", "16": "sixteen",
        "17": "seventeen", "18": "eighteen", "19": "nineteen", "20": "twenty", "30": "thirty", "40": "forty", "50": "fifty",
        "100": "one hundred", "1000": "one thousand", "1,000": "one thousand",
    ]

    static func find(_ phrase: String) -> Entry? {
        var p = clean(phrase)
        if p.hasPrefix("the number ") { p = String(p.dropFirst(11)) }
        if let word = numberWords[p] { p = word }
        guard !p.isEmpty else { return nil }
        func keys(_ e: Entry) -> [String] { ([e.en] + (e.also ?? [])).map(clean) }
        if let e = entries.first(where: { keys($0).contains(p) }) { return e }
        // Without a leading "a", "an", "the", "to" or "my", or a "please" at the end.
        var trimmed = p
        for prefix in ["a ", "an ", "the ", "to ", "my ", "some "] where trimmed.hasPrefix(prefix) { trimmed = String(trimmed.dropFirst(prefix.count)) }
        if trimmed.hasSuffix(" please"), !entries.contains(where: { keys($0).contains(trimmed) }) { trimmed = String(trimmed.dropLast(7)) }
        if let e = entries.first(where: { keys($0).contains(trimmed) }) { return e }
        // A simple plural ("cats" -> "cat").
        if trimmed.count > 3, trimmed.hasSuffix("s"), let e = entries.first(where: { keys($0).contains(String(trimmed.dropLast())) }) { return e }
        return nil
    }

    /// A few phrases Ace knows, to suggest when it doesn't know one.
    static let examples = ["hello", "thank you", "where is the bathroom", "how are you"]

    static func card(_ e: Entry, code: String) -> TranslationCard? {
        guard let text = e.t[code] else { return nil }
        return TranslationCard(english: e.en, language: languageName(code), code: code, text: text, say: e.say?[code])
    }
}

/// A translation, with how to say it and a button to hear it.
struct TranslationCard: Codable, Equatable {
    var english: String
    var language: String
    var code: String
    var text: String
    /// How to say it in English letters (for Japanese, Chinese, Korean, Hindi, Arabic and Russian).
    var say: String?
}

/// One piece of a reply read aloud. A nil language is Ace's own voice.
struct SpokenPart: Equatable {
    var text: String
    var language: String?
}

extension Phrasebook {
    /// Splits a reply so a translation is spoken in its own accent:
    /// "In Spanish, "thank you" is gracias." -> Ace says "In Spanish, "thank you" is", then "gracias" in a Spanish voice.
    /// The "say it like" spelling in brackets is left out, because the real voice says it properly.
    static func spokenParts(_ text: String, cards: [AceCard]) -> [SpokenPart] {
        var parts = [SpokenPart(text: text, language: nil)]
        for case .translation(let card) in cards {
            let words = card.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !words.isEmpty, let language = speechCodes[card.code] ?? (card.code.isEmpty ? nil : card.code) else { continue }
            let shown = card.say.map { "\(card.text) (\($0))" } ?? card.text
            var next: [SpokenPart] = []
            var done = false
            for p in parts {
                guard !done, p.language == nil, let r = spot(shown, in: p.text) ?? spot(card.text, in: p.text) else {
                    next.append(p)
                    continue
                }
                done = true
                let before = String(p.text[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let after = String(p.text[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if hasWords(before) { next.append(SpokenPart(text: before, language: nil)) }
                next.append(SpokenPart(text: words, language: language))
                if hasWords(after) { next.append(SpokenPart(text: after, language: nil)) }
            }
            parts = next
        }
        return parts
    }

    /// Where the translation sits in the reply, skipping a match inside quotes ("pizza" in Italian is pizza).
    private static func spot(_ needle: String, in text: String) -> Range<String.Index>? {
        guard !needle.isEmpty else { return nil }
        var first: Range<String.Index>?
        var from = text.startIndex
        while from < text.endIndex, let r = text.range(of: needle, range: from..<text.endIndex) {
            if first == nil { first = r }
            let before = r.lowerBound > text.startIndex ? text[text.index(before: r.lowerBound)] : " "
            let after = r.upperBound < text.endIndex ? text[r.upperBound] : " "
            if before != "\"" && after != "\"" { return r }
            from = text.index(after: r.lowerBound)
        }
        return first
    }

    private static func hasWords(_ s: String) -> Bool { s.unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) } }
}
