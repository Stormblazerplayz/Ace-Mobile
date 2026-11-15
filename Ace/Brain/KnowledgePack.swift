import Foundation

/// Ace's big built-in knowledge (tens of thousands of answers), kept apart from the hand-made answer bank.
///
/// It's made by tools/knowledge/build_knowledge.py into Resources/knowledge.acekb: compressed text where
/// every question is already split into stemmed words and stored as numbers, so loading it means reading
/// numbers, not running TextKit's regexes over every question. It loads on a background thread when Ace
/// starts, and searches use it as soon as it's ready. Once loaded it never changes, so any thread can read it.
final class KnowledgePack: @unchecked Sendable {
    // Words (stemmed), one id each.
    let tokens: [String]
    let tokenID: [String: Int32]
    /// How much each word tells about a question (rare words a lot), the same formula as QABank.
    let tokenWeight: [Double]

    // Entries.
    let entryIDs: [String]
    let entryTags: [String]
    let entryAnswers: [String]
    /// Where each entry's wordings start (one extra at the end).
    let entryFirstWording: [Int32]
    let entryIndex: [String: Int32]

    // Wordings (one row per way to ask), with their word ids packed one after another.
    let wordingEntry: [Int32]
    let wordingText: [String]
    let keyStart: [Int32]
    let keyIDs: [Int32]
    let allStart: [Int32]
    let allIDs: [Int32]
    let exact: [String: Int32]

    // Which wordings use each word id.
    let postingStart: [Int32]
    let postingIDs: [Int32]

    /// How many wordings use each plain word (for typo fixes).
    let wordCount: [String: Int]
    let wordsByLength: [Int: [String]]

    var count: Int { entryIDs.count }
    var wordingCount: Int { wordingText.count }

    // MARK: Loading

    static let fileName = "knowledge"
    static let fileExtension = "acekb"

    /// Loaded once, the first time anything asks (Swift makes this safe across threads).
    static let shared: KnowledgePack? = {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
              let data = try? Data(contentsOf: url) else { return nil }
        return KnowledgePack(packed: data)
    }()

    private static let lock = NSLock()
    private static var isReady = false
    private static var started = false

    /// The pack if it has finished loading, without waiting for it.
    static var ready: KnowledgePack? {
        lock.lock()
        let done = isReady
        lock.unlock()
        return done ? shared : nil
    }

    /// Starts loading in the background so Ace opens with no wait.
    static func startLoading() {
        lock.lock()
        let already = started
        started = true
        lock.unlock()
        guard !already else { return }
        DispatchQueue.global(qos: .utility).async { markReady() }
    }

    /// Loads it now (waits if it's loading). Used by tests so results don't depend on timing.
    @discardableResult
    static func loadNow() -> KnowledgePack? {
        markReady()
        return shared
    }

    private static func markReady() {
        _ = shared
        lock.lock()
        isReady = true
        started = true
        lock.unlock()
    }

    init?(packed: Data) {
        guard let raw = try? (packed as NSData).decompressed(using: .zlib) as Data else { return nil }
        let bytes = [UInt8](raw)
        var pos = 0

        func line() -> ArraySlice<UInt8>? {
            guard pos < bytes.count else { return nil }
            var end = pos
            while end < bytes.count && bytes[end] != 10 { end += 1 }
            let slice = bytes[pos..<end]
            pos = end + 1
            return slice
        }
        func text(_ s: ArraySlice<UInt8>) -> String { String(decoding: s, as: UTF8.self) }
        func fields(_ s: ArraySlice<UInt8>, _ sep: UInt8 = 9) -> [ArraySlice<UInt8>] {
            s.split(separator: sep, omittingEmptySubsequences: false)
        }
        func number(_ s: ArraySlice<UInt8>) -> Int {
            var n = 0
            for b in s where b >= 48 && b <= 57 { n = n * 10 + Int(b - 48) }
            return n
        }
        func numbers(_ s: ArraySlice<UInt8>, into out: inout [Int32]) {
            var n: Int32 = 0
            var inNumber = false
            for b in s {
                if b >= 48 && b <= 57 {
                    n = n * 10 + Int32(b - 48)
                    inNumber = true
                } else if inNumber {
                    out.append(n)
                    n = 0
                    inNumber = false
                }
            }
            if inNumber { out.append(n) }
        }

        guard let head = line(), text(head) == "ace-kb/1", let countsLine = line() else { return nil }
        let counts = fields(countsLine, 32).dropFirst().map(number)
        guard counts.count == 4 else { return nil }
        let (nEntries, nWordings, nTokens, nWords) = (counts[0], counts[1], counts[2], counts[3])

        var tokens: [String] = []
        tokens.reserveCapacity(nTokens)
        var tokenID: [String: Int32] = [:]
        tokenID.reserveCapacity(nTokens)
        for i in 0..<nTokens {
            guard let l = line() else { return nil }
            let t = text(l)
            tokens.append(t)
            tokenID[t] = Int32(i)
        }

        var entryIDs: [String] = [], entryTags: [String] = [], entryAnswers: [String] = []
        entryIDs.reserveCapacity(nEntries)
        entryTags.reserveCapacity(nEntries)
        entryAnswers.reserveCapacity(nEntries)
        var entryIndex: [String: Int32] = [:]
        entryIndex.reserveCapacity(nEntries)
        for i in 0..<nEntries {
            guard let l = line() else { return nil }
            let f = fields(l)
            guard f.count == 3 else { return nil }
            let id = text(f[0])
            entryIDs.append(id)
            entryTags.append(text(f[1]))
            entryAnswers.append(text(f[2]))
            entryIndex[id] = Int32(i)
        }

        var wordingEntry: [Int32] = [], wordingText: [String] = []
        var keyStart: [Int32] = [0], keyIDs: [Int32] = [], allStart: [Int32] = [0], allIDs: [Int32] = []
        var exact: [String: Int32] = [:]
        var entryFirstWording = [Int32](repeating: -1, count: nEntries + 1)
        var docFreq = [Int32](repeating: 0, count: nTokens)
        wordingEntry.reserveCapacity(nWordings)
        wordingText.reserveCapacity(nWordings)
        keyStart.reserveCapacity(nWordings + 1)
        allStart.reserveCapacity(nWordings + 1)
        exact.reserveCapacity(nWordings)
        for w in 0..<nWordings {
            guard let l = line() else { return nil }
            let f = fields(l)
            guard f.count == 4 else { return nil }
            let e = number(f[0])
            guard e < nEntries else { return nil }
            if entryFirstWording[e] < 0 { entryFirstWording[e] = Int32(w) }
            wordingEntry.append(Int32(e))
            let t = text(f[1])
            wordingText.append(t)
            if exact[t] == nil { exact[t] = Int32(w) }
            numbers(f[2], into: &keyIDs)
            keyStart.append(Int32(keyIDs.count))
            let before = allIDs.count
            numbers(f[3], into: &allIDs)
            allStart.append(Int32(allIDs.count))
            for k in allIDs[before...] {
                guard Int(k) < nTokens else { return nil }
                docFreq[Int(k)] += 1
            }
        }
        // Wordings are written in entry order, so each entry's wordings run until the next entry's start.
        entryFirstWording[nEntries] = Int32(nWordings)
        for e in stride(from: nEntries - 1, through: 0, by: -1) where entryFirstWording[e] < 0 {
            entryFirstWording[e] = entryFirstWording[e + 1]
        }

        var wordCount: [String: Int] = [:]
        wordCount.reserveCapacity(nWords)
        var wordsByLength: [Int: [String]] = [:]
        for _ in 0..<nWords {
            guard let l = line() else { return nil }
            let f = fields(l)
            guard f.count == 2 else { return nil }
            let word = text(f[0])
            wordCount[word] = number(f[1])
            if word.allSatisfy({ $0.isLetter }) { wordsByLength[word.count, default: []].append(word) }
        }

        // Which wordings use each word.
        var postingStart = [Int32](repeating: 0, count: nTokens + 1)
        for t in 0..<nTokens { postingStart[t + 1] = postingStart[t] + docFreq[t] }
        var fill = Array(postingStart.dropLast())
        var postingIDs = [Int32](repeating: 0, count: allIDs.count)
        for w in 0..<nWordings {
            for k in allIDs[Int(allStart[w])..<Int(allStart[w + 1])] {
                postingIDs[Int(fill[Int(k)])] = Int32(w)
                fill[Int(k)] += 1
            }
        }

        let n = Double(max(1, nWordings))
        let common = TextKit.commonWords
        var tokenWeight: [Double] = []
        tokenWeight.reserveCapacity(nTokens)
        for t in 0..<nTokens {
            let idf = log((n + 1) / (Double(docFreq[t]) + 1)) + 1
            tokenWeight.append(common.contains(tokens[t]) ? min(idf, 2) : idf)
        }

        self.tokens = tokens
        self.tokenID = tokenID
        self.tokenWeight = tokenWeight
        self.entryIDs = entryIDs
        self.entryTags = entryTags
        self.entryAnswers = entryAnswers
        self.entryFirstWording = entryFirstWording
        self.entryIndex = entryIndex
        self.wordingEntry = wordingEntry
        self.wordingText = wordingText
        self.keyStart = keyStart
        self.keyIDs = keyIDs
        self.allStart = allStart
        self.allIDs = allIDs
        self.exact = exact
        self.postingStart = postingStart
        self.postingIDs = postingIDs
        self.wordCount = wordCount
        self.wordsByLength = wordsByLength
    }

    // MARK: Reading

    func keys(ofWording w: Int) -> ArraySlice<Int32> { keyIDs[Int(keyStart[w])..<Int(keyStart[w + 1])] }
    func allWords(ofWording w: Int) -> ArraySlice<Int32> { allIDs[Int(allStart[w])..<Int(allStart[w + 1])] }
    func postings(_ token: Int32) -> ArraySlice<Int32> {
        postingIDs[Int(postingStart[Int(token)])..<Int(postingStart[Int(token) + 1])]
    }

    func entry(at e: Int) -> QAEntry {
        let q = (Int(entryFirstWording[e])..<Int(entryFirstWording[e + 1])).map { wordingText[$0] }
        let answers = entryAnswers[e].split(separator: "\u{1F}", omittingEmptySubsequences: true).map(String.init)
        return QAEntry(id: entryIDs[e], tag: entryTags[e], q: q, a: answers, source: "pack", updated: nil, url: nil)
    }

    func entry(id: String) -> QAEntry? {
        entryIndex[id].map { entry(at: Int($0)) }
    }

    func entry(ofWording w: Int) -> QAEntry { entry(at: Int(wordingEntry[w])) }

    /// How much a word tells, for words the pack has never seen too (they count as very rare).
    func weight(_ token: String) -> Double {
        if let id = tokenID[token] { return tokenWeight[Int(id)] }
        let idf = log(Double(max(1, wordingCount)) + 1) + 1
        return TextKit.commonWords.contains(token) ? min(idf, 2) : idf
    }

    // MARK: Matching

    /// Word matching, scored exactly like QABank's: the best wordings and their scores (0...1).
    func lexical(qKeys: Set<String>, qAll: Set<String>, limit: Int = 25) -> [(wording: Int, lex: Double)] {
        let lookup = qKeys.isEmpty ? qAll : qKeys
        let known = lookup.compactMap { tokenID[$0] }
        guard !known.isEmpty else { return [] }

        // 1. Candidates that share a word, rarest words first.
        var candidates = Set<Int32>()
        for token in known.sorted(by: { postingStart[Int($0) + 1] - postingStart[Int($0)] < postingStart[Int($1) + 1] - postingStart[Int($1)] }) {
            let list = postings(token)
            if list.count > 1500 && candidates.count > 50 { continue }
            candidates.formUnion(list.prefix(3000))
            if candidates.count > 4000 { break }
        }
        guard !candidates.isEmpty else { return [] }

        // 2. Weighted overlap.
        let qKeyIDs = Set(qKeys.compactMap { tokenID[$0] })
        let questionWeight = qKeys.reduce(0.0) { $0 + weight($1) }
        let bigKeys = qKeys.filter { weight($0) > 5.5 }.map { tokenID[$0] }
        let qAllIDs = Set(qAll.compactMap { tokenID[$0] })

        var scored: [(Int, Double)] = []
        scored.reserveCapacity(candidates.count)
        for w32 in candidates {
            let w = Int(w32)
            let keys = keys(ofWording: w)
            let all = allWords(ofWording: w)
            var allInter = 0
            for a in all where qAllIDs.contains(a) { allInter += 1 }
            let union = qAll.count + all.count - allInter
            let jac = union == 0 ? 0 : Double(allInter) / Double(union)
            var lex: Double
            if !qKeys.isEmpty && !keys.isEmpty {
                var inter = 0.0, wordingWeight = 0.0
                for k in keys {
                    let wt = tokenWeight[Int(k)]
                    wordingWeight += wt
                    if qKeyIDs.contains(k) { inter += wt }
                }
                let coversWording = wordingWeight > 0 ? inter / wordingWeight : 0
                let coversQuestion = questionWeight > 0 ? inter / questionWeight : 0
                lex = coversWording * 0.5 + coversQuestion * 0.35 + jac * 0.15
                var missing = 0
                for id in bigKeys {
                    if let id { if !keys.contains(id) { missing += 1 } } else { missing += 1 }
                }
                if missing > 0 { lex *= pow(0.72, Double(missing)) }
            } else {
                lex = jac
            }
            if lex > 0.08 { scored.append((w, lex)) }
        }
        scored.sort { $0.1 > $1.1 }
        return scored.prefix(limit).map { (wording: $0.0, lex: $0.1) }
    }
}
