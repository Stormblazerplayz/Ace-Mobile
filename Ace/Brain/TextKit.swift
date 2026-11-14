import Foundation
import NaturalLanguage

/// Small text tools the brain uses everywhere.
enum TextKit {
    static let stopwords: Set<String> = [
        "a", "an", "the", "is", "are", "was", "were", "be", "been", "am", "do", "does", "did", "of", "to", "in", "on",
        "at", "for", "and", "or", "but", "it", "its", "this", "that", "these", "those", "i", "me", "my", "you", "your",
        "we", "us", "our", "he", "she", "they", "them", "their", "his", "her", "please", "can", "could", "would",
        "should", "will", "shall", "tell", "say", "know", "about", "what", "whats", "what's", "how", "who", "whos",
        "when", "where", "why", "which", "there", "here", "with", "from", "by", "as", "so", "if", "then", "just",
        "hey", "ace", "okay", "ok", "um", "uh", "like", "really", "some", "any", "much", "many", "have", "has", "had",
        "get", "got", "give", "show", "find", "let", "lets", "let's", "want", "wanna", "need", "into", "up", "out",
    ]

    /// Lowercases, swaps curly quotes, drops punctuation (keeps + - * / . for math) and squashes spaces.
    static func normalize(_ text: String) -> String {
        var s = text.lowercased()
        s = s.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "‘", with: "'")
        s = s.replacingOccurrences(of: "“", with: "\"").replacingOccurrences(of: "”", with: "\"")
        let contractions = ["what's": "what is", "whats": "what is", "who's": "who is", "where's": "where is",
                            "how's": "how is", "it's": "it is", "i'm": "i am", "im": "i am", "you're": "you are",
                            "don't": "do not", "can't": "can not", "cannot": "can not", "won't": "will not",
                            "isn't": "is not", "didn't": "did not", "doesn't": "does not", "let's": "let us",
                            "wanna": "want to", "gonna": "going to", "u": "you", "ur": "your", "pls": "please",
                            "plz": "please", "thx": "thanks"]
        var words = s.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).map(String.init)
        words = words.map { w in
            let trimmed = w.trimmingCharacters(in: CharacterSet(charactersIn: "?!,;:\"()[]{}"))
            return contractions[trimmed] ?? trimmed
        }
        s = words.joined(separator: " ")
        s = s.replacingOccurrences(of: #"[^\p{L}\p{N}\s\+\-\*/\.%'°#&]"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    static func words(_ text: String) -> [String] {
        normalize(text)
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: ".'")) }
            .filter { !$0.isEmpty }
    }

    /// Words that mean the same thing to the answer bank, so "largest" finds "biggest".
    /// Used on both the bank's questions and yours, so it works both ways.
    static let sameMeaning: [String: String] = [
        "largest": "biggest", "hugest": "biggest", "greatest": "biggest",
        "large": "big", "huge": "big", "giant": "big", "enormous": "big", "massive": "big",
        "tiny": "small", "little": "small", "smallest": "small", "tiniest": "small",
        "quickest": "fastest", "speediest": "fastest", "quick": "fast", "speedy": "fast", "rapid": "fast",
        "highest": "tallest", "high": "tall",
        "invented": "invent", "inventor": "invent", "invents": "invent", "created": "invent", "creator": "invent",
        "kids": "child", "kid": "child", "children": "child",
        "mom": "mother", "mum": "mother", "mommy": "mother", "dad": "father", "daddy": "father",
        "film": "movie", "films": "movie", "movies": "movie",
        "colour": "color", "colours": "color", "favourite": "favorite", "fav": "favorite",
        "pc": "computer", "laptop": "computer", "tablet": "ipad",
        "begin": "start", "began": "start", "started": "start", "beginning": "start",
        "finish": "end", "ended": "end", "finished": "end",
        "temp": "temperature", "hottest": "hot", "coldest": "cold",
        "years": "year", "yrs": "year", "km": "kilometer", "kilometres": "kilometer", "kilometers": "kilometer",
        "metres": "meter", "meters": "meter", "metre": "meter", "discovered": "discover", "discoverer": "discover",
        "humans": "human", "people": "human", "person": "human",
    ]

    /// Simple word stem so "planets" matches "planet" and "running" matches "run".
    static func stem(_ w: String) -> String {
        if let same = sameMeaning[w] { return same }
        guard w.count > 3, w.allSatisfy({ $0.isLetter }) else { return w }
        if w.hasSuffix("ies"), w.count > 4 { return String(w.dropLast(3)) + "y" }
        if w.hasSuffix("sses") { return String(w.dropLast(2)) }
        if w.hasSuffix("ing"), w.count > 5 {
            let base = String(w.dropLast(3))
            if let last = base.last, let prev = base.dropLast().last, last == prev, !"lsz".contains(last) {
                return String(base.dropLast())
            }
            return base
        }
        if w.hasSuffix("ed"), w.count > 4 { return String(w.dropLast(2)) }
        if w.hasSuffix("es"), w.count > 4, ["ch", "sh", "x", "ss"].contains(where: { String(w.dropLast(2)).hasSuffix($0) }) {
            return String(w.dropLast(2))
        }
        if w.hasSuffix("s"), !w.hasSuffix("ss"), !w.hasSuffix("us"), !w.hasSuffix("is") { return String(w.dropLast()) }
        return w
    }

    /// The meaningful words of a sentence, stemmed.
    static func keywords(_ text: String) -> [String] {
        words(text).filter { !stopwords.contains($0) }.map(stem)
    }

    /// Takes out a language model's hidden thinking and control tags, like "<think>...</think>" or "<|im_end|>".
    static func stripModelTags(_ text: String) -> String {
        var s = text
        // Whole thinking blocks, then any thinking block that never closed.
        s = s.replacingOccurrences(of: #"(?is)<(think|thinking|reasoning|reflection)>.*?</\1>"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?is)<(think|thinking|reasoning)>.*$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?i)</?(think|thinking|reasoning|reflection|answer|response|output)>"#, with: "", options: .regularExpression)
        // Chat-template tokens like <|im_start|>, <|endoftext|>, <s>, </s>, [INST].
        s = s.replacingOccurrences(of: #"<\|[^|>]{1,40}\|>"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"(?i)</?s>|\[/?INST\]"#, with: "", options: .regularExpression)
        // A leftover "Reworded answer:" or "Answer:" label at the start.
        s = s.replacingOccurrences(of: #"(?i)^\s*(reworded answer|answer|assistant|ace)\s*:\s*"#, with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Letters to change, add, remove or swap to turn one word into another (stops early past `limit`).
    static func editDistance(_ a: String, _ b: String, limit: Int = 2) -> Int {
        let x = Array(a), y = Array(b)
        if abs(x.count - y.count) > limit { return limit + 1 }
        if x.isEmpty { return y.count }
        if y.isEmpty { return x.count }
        var prev2 = [Int](repeating: 0, count: y.count + 1)
        var prev = Array(0...y.count)
        var cur = [Int](repeating: 0, count: y.count + 1)
        for i in 1...x.count {
            cur[0] = i
            var rowMin = cur[0]
            for j in 1...y.count {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                var v = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                if i > 1, j > 1, x[i - 1] == y[j - 2], x[i - 2] == y[j - 1] { v = min(v, prev2[j - 2] + 1) }
                cur[j] = v
                rowMin = min(rowMin, v)
            }
            if rowMin > limit { return limit + 1 }
            prev2 = prev
            prev = cur
        }
        return prev[y.count]
    }

    static func capitalizeFirst(_ s: String) -> String {
        guard let f = s.first else { return s }
        return f.uppercased() + s.dropFirst()
    }
}

/// Picks the most useful sentences from text (extractive summary).
enum Summarizer {
    static func sentences(_ text: String) -> [String] {
        var out: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if s.count > 2 { out.append(s) }
            return true
        }
        return out
    }

    /// The main subject of a question ("who invented the telephone" -> "invented telephone").
    static func topic(of query: String) -> String {
        let fillers: Set<String> = ["search", "look", "lookup", "google", "web", "internet", "online", "tell", "explain",
                                    "define", "meaning", "information", "info", "facts", "fact", "me", "about", "up"]
        let w = TextKit.words(query).filter { !TextKit.stopwords.contains($0) && !fillers.contains($0) }
        return w.isEmpty ? query : w.joined(separator: " ")
    }

    static func overlap(query: String, text: String) -> Double {
        let q = Set(TextKit.keywords(query))
        guard !q.isEmpty else { return 0 }
        let t = Set(TextKit.keywords(text))
        return Double(q.intersection(t).count) / Double(q.count)
    }

    static func summarize(_ text: String, query: String, maxSentences: Int) -> String {
        let all = sentences(text)
        guard all.count > maxSentences else { return all.joined(separator: " ") }
        let q = Set(TextKit.keywords(query))
        let scored = all.enumerated().map { (i, s) -> (Int, Double) in
            let k = Set(TextKit.keywords(s))
            let hits = Double(q.intersection(k).count)
            let position = 1.0 / Double(i + 1)
            let lengthOK = (40...260).contains(s.count) ? 0.3 : 0
            return (i, hits * 1.2 + position * 1.5 + lengthOK)
        }
        let best = scored.sorted { $0.1 > $1.1 }.prefix(maxSentences).map { $0.0 }.sorted()
        return best.map { all[$0] }.joined(separator: " ")
    }

    /// A few short facts from text that aren't already in the summary.
    static func keyFacts(_ text: String, excluding summary: String, count: Int) -> [String] {
        sentences(text)
            .filter { !summary.contains($0) && (25...200).contains($0.count) }
            .prefix(count)
            .map { $0 }
    }
}
