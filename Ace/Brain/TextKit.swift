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
        canonical(normalize(text))
            .split(separator: " ")
            .map { word -> String in
                var w = String(word).trimmingCharacters(in: CharacterSet(charactersIn: ".'"))
                // "japan's" -> "japan"
                if w.hasSuffix("'s"), w.count > 3 { w = String(w.dropLast(2)) }
                return w
            }
            .filter { !$0.isEmpty }
    }

    /// Phrases that mean the same thing, said one way ("came up with" -> "invented").
    static let samePhrases: [(pattern: String, with: String)] = [
        (#"\b(came|come|comes|coming) up with\b"#, "invented"),
        (#"\bthought up\b"#, "invented"),
        (#"\b(second world war|world war two|world war ii|ww2|wwii)\b"#, "world war 2"),
        (#"\b(first world war|world war one|world war i|ww1|wwi)\b"#, "world war 1"),
        (#"\b(united states of america|the usa|usa|the us|the u\.s\.?|u\.s\.a\.?)\b"#, "united states"),
        (#"\bus president\b"#, "president of the united states"),
        (#"\b(stand|stands|short) for\b"#, "mean"),
        (#"\b(are|is|am) (you|i|it|we|they) able to\b"#, "can $2"),
        (#"\bable to\b"#, "can"),
        (#"\bis it (ok|okay|alright|fine|safe|smart|a good idea) (to|if i)\b"#, "should i"),
    ]

    static func canonical(_ normalized: String) -> String {
        var s = normalized
        for p in samePhrases {
            s = s.replacingOccurrences(of: p.pattern, with: p.with, options: .regularExpression)
        }
        return s
    }

    /// Everyday words that say little about what a question is about ("one", "located", "actually").
    /// They still count, just much less than words like "france" or "volcano".
    static let commonWords: Set<String> = Set([
        "one", "very", "actually", "located", "famous", "exactly", "really", "even", "ever", "also", "quite", "just",
        "real", "kind", "sort", "thing", "things", "stuff", "go", "goes", "going", "went", "gone", "come", "comes",
        "came", "coming", "with", "up", "equal", "equals", "add", "adds", "added", "make", "makes", "making", "use",
        "uses", "used", "using", "able", "do", "done", "doing", "does", "did", "put", "take", "takes", "took", "get",
        "gets", "getting", "got", "being", "become", "becomes", "became", "seem", "seems", "look", "looks",
        "looking", "like", "likes", "liked", "want", "wanted", "way", "ways", "much", "more", "most", "less",
        "least", "lot", "lots", "bit", "little", "enough", "well", "good", "great", "nice", "cool", "okay", "sure",
        "certain", "certainly", "maybe", "probably", "possibly", "perhaps", "basically", "literally", "totally",
        "completely", "simply", "generally", "usually", "normally", "typically", "often", "sometimes", "always",
        "never", "still", "already", "yet", "again", "ago", "now", "currently", "today", "back",
        "over", "under", "off", "around", "away", "through", "across", "along", "whole", "entire", "every", "each",
        "all", "both", "either", "neither", "other", "another", "same", "different", "such", "own", "type", "kinds",
        "types", "something", "anything", "everything", "nothing", "someone", "anyone", "everyone", "somebody",
        "anybody", "exist", "exists", "existing", "happen", "happens", "happened", "happening", "mean", "means",
        "meant", "called", "call", "calls", "named", "known", "part", "parts", "piece", "amount", "total", "main",
        "specific", "particular", "general", "overall", "usual", "special", "important", "major", "minor", "current",
        "recent", "next", "previous", "whats", "anyway", "anyhow", "though", "although", "because",
        "since", "while", "during", "before", "after", "until", "than", "then", "too", "yes", "no", "not", "dont",
        "doesnt", "isnt", "arent", "wasnt", "werent", "cant", "couldnt", "wont", "wouldnt", "shouldnt", "am", "into",
        "onto", "upon", "within", "without", "between", "among", "toward", "towards", "about", "above", "below",
        "behind", "beside", "besides", "near", "inside", "outside", "throughout", "per", "via", "indeed", "course",
        "pretty", "fairly", "rather", "somewhat", "almost", "nearly", "approximately", "roughly", "please", 
        "ok", "alright", "wondering", "wonder", "curious", "question", "questions",
        "ask", "asking", "asked", "answer", "answers", "tell", "telling", "told", "say", "saying", "said", "know",
        "knowing", "knew", "think", "thinking", "thought", "guess", "guessing", "feel", "feeling", "explain",
        "explaining", 
    ].map(stem))

    /// Small words that are the whole subject when they end a question ("the capital of the us", "what element is he").
    static let subjectAtEnd: Set<String> = ["us", "he", "as", "at", "be", "no", "am"]

    /// Words that mean the same thing to the answer bank, so "largest" finds "biggest".
    /// Used on both the bank's questions and yours, so it works both ways.
    static let sameMeaning: [String: String] = [
        "largest": "biggest", "hugest": "biggest", "greatest": "biggest",
        "large": "big", "huge": "big", "giant": "big", "enormous": "big", "massive": "big",
        "tiny": "small", "little": "small", "smallest": "small", "tiniest": "small",
        "fastest": "fast", "quickest": "fast", "speediest": "fast", "quick": "fast", "speedy": "fast", "rapid": "fast",
        "speed": "fast", "distance": "far", "money": "currency", "cash": "currency",
        "founded": "start", "founder": "start", "sank": "sink", "sunk": "sink",
        "upset": "sad", "unhappy": "sad", "afraid": "scared", "frightened": "scared", "mad": "angry", "furious": "angry",
        "sleepy": "tired", "exhausted": "tired", "starving": "hungry",
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
        "metres": "meter", "meters": "meter", "metre": "meter",
        "kg": "kilogram", "kgs": "kilogram", "kilograms": "kilogram", "lb": "pound", "lbs": "pound", "ft": "foot", "feet": "foot",
        "hr": "hour", "hrs": "hour", "mins": "minute", "secs": "second", "discovered": "discover", "discoverer": "discover",
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
        let all = words(text)
        return all.enumerated()
            .filter { !stopwords.contains($0.element) || ($0.offset == all.count - 1 && subjectAtEnd.contains($0.element)) }
            .map { stem($0.element) }
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
