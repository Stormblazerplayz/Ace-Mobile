import Foundation
import NaturalLanguage

/// One question with all the ways to ask it and all the ways to answer it.
/// Same "ace-qa/1" format as Ace V4 on the PC, so banks can be merged by sync.
struct QAEntry: Codable, Equatable, Identifiable {
    var id: String
    var tag: String
    var q: [String]
    var a: [String]
    /// builtin, learned, taught (the user told Ace), or pc (came from Nimbus).
    var source: String?
    /// ISO 8601 time of the last change, used when merging banks.
    var updated: String?
    var url: String?
}

struct QAFile: Codable {
    var format: String
    var version: Int?
    var source: String?
    var count: Int?
    var entries: [QAEntry]
}

/// The question bank: thousands of answers, matched by words (rare words count more)
/// and then re-ranked with Apple's on-device sentence embedding (a neural network).
@MainActor
final class QABank {
    struct Match {
        var entry: QAEntry
        var wording: String
        var score: Double
        var lexical: Double
        var semantic: Double?
    }

    private(set) var entries: [QAEntry] = []
    private var indexByID: [String: Int] = [:]

    // One row per question wording.
    private var wordingEntry: [Int] = []
    private var wordingText: [String] = []
    private var wordingKeys: [Set<String>] = []
    private var wordingAll: [Set<String>] = []
    private var postings: [String: [Int]] = [:]
    private var docFreq: [String: Int] = [:]
    private var exact: [String: Int] = [:]
    private var embeddingCache: [Int: [Double]] = [:]
    /// How many question wordings use each plain word (for typo fixes and finding the subject of a question).
    private var wordCount: [String: Int] = [:]
    /// Known words grouped by length, so typo fixing only looks at words of about the right size.
    private var wordsByLength: [Int: [String]] = [:]

    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)
    static let learnedFile = "learned_qa.json"

    var builtinCount = 0
    var learnedCount: Int { entries.filter { $0.source == "learned" || $0.source == "taught" || $0.source == "pc" }.count }
    var hasNeuralMatching: Bool { embedding != nil }
    /// Answers in the big knowledge pack (0 until it has loaded, a moment after launch).
    var knowledgeCount: Int { KnowledgePack.ready?.count ?? 0 }
    /// A core answer wins over a pack answer unless the pack one fits clearly better (by this much),
    /// so the hand-made answers stay first for the questions they were made for.
    static let packMargin = 0.03
    private var packEmbeddingCache: [Int: [Double]] = [:]

    /// Loads the knowledge pack now instead of in the background (for tests, so timing doesn't matter).
    func loadKnowledgeNow() { KnowledgePack.loadNow() }

    init() {
        if let url = Bundle.main.url(forResource: "qa_bank", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(QAFile.self, from: data) {
            for var e in file.entries {
                e.source = e.source ?? "builtin"
                add(e)
            }
            builtinCount = file.entries.count
        }
        // In the app it loads in the background. Under tests it loads first, so results don't depend on timing.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            KnowledgePack.loadNow()
        } else {
            KnowledgePack.startLoading()
        }
        if let learned = Persistence.load(QAFile.self, from: Self.learnedFile) {
            for e in learned.entries { upsert(e, save: false) }
        }
    }

    // MARK: Index

    private func add(_ e: QAEntry) {
        let idx = entries.count
        entries.append(e)
        indexByID[e.id] = idx
        indexWordings(of: idx)
    }

    private func indexWordings(of idx: Int) {
        for q in entries[idx].q {
            let w = wordingText.count
            let norm = TextKit.normalize(q)
            let keys = Set(TextKit.keywords(norm))
            let all = Set(TextKit.words(norm).map(TextKit.stem))
            wordingEntry.append(idx)
            wordingText.append(norm)
            wordingKeys.append(keys)
            wordingAll.append(all)
            exact[norm] = w
            for word in norm.split(separator: " ") {
                let plain = String(word)
                if wordCount[plain] == nil, plain.allSatisfy({ $0.isLetter }) {
                    wordsByLength[plain.count, default: []].append(plain)
                }
                wordCount[plain, default: 0] += 1
            }
            for k in all {
                postings[k, default: []].append(w)
                docFreq[k, default: 0] += 1
            }
        }
    }

    /// How much a word tells about the question: rare words a lot, everyday words little.
    private func weight(_ token: String) -> Double {
        let w = idf(token)
        return TextKit.commonWords.contains(token) ? min(w, 2) : w
    }

    private func idf(_ token: String) -> Double {
        let n = Double(max(1, wordingText.count))
        let df = Double(docFreq[token] ?? 0)
        return log((n + 1) / (df + 1)) + 1
    }

    // MARK: Words

    /// How many hand-made question wordings use this word (0 means the core bank has never seen it).
    /// Used to find the subject of a question, so it leaves the knowledge pack out on purpose.
    func wordFrequency(_ word: String) -> Int { wordCount[word] ?? 0 }

    /// How many wordings use this word, counting the knowledge pack too (for typo fixes).
    func spellingFrequency(_ word: String) -> Int {
        (wordCount[word] ?? 0) + (KnowledgePack.ready?.wordCount[word] ?? 0)
    }

    /// Known words within 2 letters of this word's length (core bank and knowledge pack).
    func vocabulary(near word: String) -> [String] {
        let n = word.count
        let lengths = max(1, n - 2)...(n + 2)
        let core = lengths.flatMap { wordsByLength[$0] ?? [] }
        guard let pack = KnowledgePack.ready else { return core }
        var seen = Set(core)
        var out = core
        for l in lengths {
            for w in pack.wordsByLength[l] ?? [] where seen.insert(w).inserted { out.append(w) }
        }
        return out
    }

    // MARK: Matching

    /// Finds the best answers for a question. Scores are 0...1.
    /// Looks in the hand-made bank and in the big knowledge pack, and keeps the hand-made answer first
    /// unless a pack answer fits clearly better.
    func search(_ query: String, limit: Int = 5) -> [Match] {
        let norm = TextKit.normalize(query)
        guard !norm.isEmpty else { return [] }
        if let w = exact[norm] {
            let e = entries[wordingEntry[w]]
            return [Match(entry: e, wording: wordingText[w], score: 1, lexical: 1, semantic: nil)]
        }
        let pack = KnowledgePack.ready
        if let pack, let w = pack.exact[norm] {
            let i = Int(w)
            return [Match(entry: pack.entry(ofWording: i), wording: pack.wordingText[i], score: 1, lexical: 1, semantic: nil)]
        }
        let qKeys = Set(TextKit.keywords(norm))
        let qAll = Set(TextKit.words(norm).map(TextKit.stem))
        let core = searchCore(norm, qKeys: qKeys, qAll: qAll, limit: limit)
        guard let pack else { return core }
        let fromPack = searchPack(pack, norm, qKeys: qKeys, qAll: qAll, limit: limit)
        guard !fromPack.isEmpty else { return core }
        let ranked = core.map { ($0, $0.score + Self.packMargin) } + fromPack.map { ($0, $0.score) }
        return ranked.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
    }

    /// The knowledge pack's best answers, scored the same way as the hand-made bank.
    private func searchPack(_ pack: KnowledgePack, _ norm: String, qKeys: Set<String>, qAll: Set<String>, limit: Int) -> [Match] {
        let top = pack.lexical(qKeys: qKeys, qAll: qAll, limit: 20)
        guard !top.isEmpty else { return [] }
        let qVec = vector(for: norm)
        var bestPerEntry: [Int32: Match] = [:]
        for (w, lex) in top {
            var sem: Double?
            if let qVec, let wVec = cachedPackVector(pack, w) { sem = cosine(qVec, wVec) }
            let score: Double
            if let sem {
                score = min(1, lex * 0.62 + max(0, sem) * 0.38 + (lex > 0.85 && sem > 0.85 ? 0.05 : 0))
            } else {
                score = lex
            }
            let e = pack.wordingEntry[w]
            if (bestPerEntry[e]?.score ?? -1) < score {
                bestPerEntry[e] = Match(entry: pack.entry(ofWording: w), wording: pack.wordingText[w], score: score, lexical: lex, semantic: sem)
            }
        }
        return bestPerEntry.values.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    private func cachedPackVector(_ pack: KnowledgePack, _ w: Int) -> [Double]? {
        if let v = packEmbeddingCache[w] { return v }
        guard let v = embedding?.vector(for: pack.wordingText[w]) else { return nil }
        if packEmbeddingCache.count > 6000 { packEmbeddingCache.removeAll(keepingCapacity: true) }
        packEmbeddingCache[w] = v
        return v
    }

    /// The hand-made bank's best answers.
    private func searchCore(_ norm: String, qKeys: Set<String>, qAll: Set<String>, limit: Int) -> [Match] {
        let lookup = qKeys.isEmpty ? qAll : qKeys

        // 1. Gather candidates that share a word (rarest words first so common ones don't flood it).
        var candidates = Set<Int>()
        for token in lookup.sorted(by: { idf($0) > idf($1) }) {
            guard let list = postings[token] else { continue }
            if list.count > 1500 && candidates.count > 50 { continue }
            candidates.formUnion(list.prefix(3000))
            if candidates.count > 4000 { break }
        }
        guard !candidates.isEmpty else { return semanticOnly(norm, limit: limit) }

        // 2. Word score: weighted overlap where rare words (like "france") matter most.
        var scored: [(Int, Double)] = []
        scored.reserveCapacity(candidates.count)
        for w in candidates {
            let keys = wordingKeys[w]
            var lex: Double
            if !qKeys.isEmpty && !keys.isEmpty {
                // How much of the bank's question you said, and how much of yours it covers.
                // Everyday words ("one", "located") count for little, so they don't sink a good match.
                let inter = qKeys.intersection(keys).reduce(0.0) { $0 + weight($1) }
                let wordingWeight = keys.reduce(0.0) { $0 + weight($1) }
                let questionWeight = qKeys.reduce(0.0) { $0 + weight($1) }
                let coversWording = wordingWeight > 0 ? inter / wordingWeight : 0
                let coversQuestion = questionWeight > 0 ? inter / questionWeight : 0
                lex = coversWording * 0.5 + coversQuestion * 0.35 + jaccard(qAll, wordingAll[w]) * 0.15
                // Penalize when an important word of the question is missing ("france" vs "germany").
                let missing = qKeys.subtracting(keys).filter { weight($0) > 5.5 }
                if !missing.isEmpty { lex *= pow(0.72, Double(missing.count)) }
            } else {
                lex = jaccard(qAll, wordingAll[w])
            }
            if lex > 0.08 { scored.append((w, lex)) }
        }
        scored.sort { $0.1 > $1.1 }
        let top = Array(scored.prefix(25))

        // 3. Neural re-rank of the best few.
        var results: [Match] = []
        let qVec = vector(for: norm)
        for (w, lex) in top {
            var sem: Double?
            if let qVec, let wVec = cachedVector(w) {
                sem = cosine(qVec, wVec)
            }
            let score: Double
            if let sem {
                score = min(1, lex * 0.62 + max(0, sem) * 0.38 + (lex > 0.85 && sem > 0.85 ? 0.05 : 0))
            } else {
                score = lex
            }
            results.append(Match(entry: entries[wordingEntry[w]], wording: wordingText[w], score: score, lexical: lex, semantic: sem))
        }
        // Keep the best wording per entry.
        var bestPerEntry: [String: Match] = [:]
        for m in results where (bestPerEntry[m.entry.id]?.score ?? -1) < m.score {
            bestPerEntry[m.entry.id] = m
        }
        return bestPerEntry.values.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    /// When no words match at all, compare meanings only (a few hundred short wordings).
    private func semanticOnly(_ norm: String, limit: Int) -> [Match] {
        guard let qVec = vector(for: norm) else { return [] }
        var out: [Match] = []
        let chatTags = ["ace", "feelings", "fun", "school", "safety"]
        let short = wordingText.indices.filter { w in
            let tag = entries[wordingEntry[w]].tag
            return wordingText[w].split(separator: " ").count <= 6 && chatTags.contains(where: { tag.hasPrefix($0) })
        }
        for w in short {
            guard let v = cachedVector(w) else { continue }
            let sem = cosine(qVec, v)
            if sem > 0.6 {
                out.append(Match(entry: entries[wordingEntry[w]], wording: wordingText[w], score: sem * 0.8, lexical: 0, semantic: sem))
            }
        }
        return out.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    private func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let u = a.union(b).count
        return u == 0 ? 0 : Double(a.intersection(b).count) / Double(u)
    }

    func vector(for text: String) -> [Double]? {
        embedding?.vector(for: text)
    }

    private func cachedVector(_ w: Int) -> [Double]? {
        if let v = embeddingCache[w] { return v }
        guard let v = embedding?.vector(for: wordingText[w]) else { return nil }
        if embeddingCache.count > 6000 { embeddingCache.removeAll(keepingCapacity: true) }
        embeddingCache[w] = v
        return v
    }

    func cosine(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot = 0.0, na = 0.0, nb = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let d = (na.squareRoot() * nb.squareRoot())
        return d == 0 ? 0 : dot / d
    }

    func entry(id: String) -> QAEntry? {
        if let i = indexByID[id] { return entries[i] }
        return KnowledgePack.ready?.entry(id: id)
    }

    // MARK: Learning

    /// Adds or replaces an entry and saves learned entries to disk.
    func upsert(_ e: QAEntry, save: Bool = true) {
        if let idx = indexByID[e.id] {
            entries[idx] = e
            rebuildIndex()
        } else {
            add(e)
        }
        if save { saveLearned() }
    }

    /// Saves a new answer Ace found or was taught. Returns the entry.
    @discardableResult
    func learn(question: String, answer: String, source: String, tag: String = "learned", url: String? = nil) -> QAEntry {
        let norm = TextKit.normalize(question)
        let stamp = ISO8601DateFormatter().string(from: Date())
        if let w = exact[norm] {
            var e = entries[wordingEntry[w]]
            if e.source == "builtin" {
                // Don't overwrite built-in answers; make a taught copy that wins.
                e = QAEntry(id: "taught." + e.id, tag: e.tag, q: [norm], a: [answer], source: source, updated: stamp, url: url)
            } else {
                e.a = [answer]
                e.source = source
                e.updated = stamp
                e.url = url
            }
            upsert(e)
            return e
        }
        let id = "\(source).\(abs(norm.hashValue % 1_000_000))-\(Int(Date().timeIntervalSince1970))"
        let e = QAEntry(id: id, tag: tag, q: [norm], a: [answer], source: source, updated: stamp, url: url)
        upsert(e)
        return e
    }

    /// Adds another way of asking an existing answer (so Ace gets better at matching).
    func addWording(_ question: String, to id: String) {
        guard let idx = indexByID[id], entries[idx].source != "builtin" else { return }
        let norm = TextKit.normalize(question)
        guard !entries[idx].q.contains(norm) else { return }
        entries[idx].q.append(norm)
        rebuildIndex()
        saveLearned()
    }

    func forget(id: String) {
        guard let idx = indexByID[id], entries[idx].source != "builtin" else { return }
        entries.remove(at: idx)
        rebuildIndex()
        saveLearned()
    }

    func learnedEntries() -> [QAEntry] {
        entries.filter { $0.source != "builtin" }
    }

    /// Merges a bank from Nimbus on the PC. Newer "updated" wins.
    func merge(_ incoming: [QAEntry]) -> Int {
        var changed = 0
        for var e in incoming {
            if e.source == nil || e.source == "builtin" { e.source = "pc" }
            if let idx = indexByID[e.id] {
                let mine = entries[idx]
                if mine.source == "builtin" { continue }
                if (e.updated ?? "") > (mine.updated ?? "") {
                    entries[idx] = e
                    changed += 1
                }
            } else {
                entries.append(e)
                indexByID[e.id] = entries.count - 1
                changed += 1
            }
        }
        if changed > 0 {
            rebuildIndex()
            saveLearned()
        }
        return changed
    }

    private func rebuildIndex() {
        wordingEntry = []
        wordingText = []
        wordingKeys = []
        wordingAll = []
        postings = [:]
        docFreq = [:]
        exact = [:]
        embeddingCache = [:]
        indexByID = [:]
        for i in entries.indices {
            indexByID[entries[i].id] = i
            indexWordings(of: i)
        }
    }

    private func saveLearned() {
        let learned = learnedEntries()
        Persistence.save(QAFile(format: "ace-qa/1", version: 1, source: "ipad", count: learned.count, entries: learned), to: Self.learnedFile)
    }
}
