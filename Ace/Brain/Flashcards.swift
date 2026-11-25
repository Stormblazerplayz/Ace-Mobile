import Foundation

// MARK: Cards and decks

/// One flashcard: a word or question on the front, the answer on the back, and when to see it next.
struct Flashcard: Codable, Identifiable, Equatable {
    var id: UUID
    var front: String
    var back: String
    /// A small extra line under the answer (how to say it, a fun fact).
    var note: String?
    var added: Date
    /// When the card is ready to review next. New cards are ready right away.
    var due: Date
    /// Days until the next review after a right answer. 0 means new, or being learned again after a miss.
    var interval: Double
    /// How easy the card is for you. It starts at 2.5 and never drops below 1.3.
    var ease: Double
    /// Right answers in a row.
    var streak: Int
    /// Times you forgot it after you'd learned it.
    var lapses: Int
    /// Times you've answered it.
    var reviews: Int
    var lastReviewed: Date?

    init(front: String, back: String, note: String? = nil, now: Date = Date()) {
        id = UUID()
        self.front = front
        self.back = back
        self.note = note
        added = now
        due = now
        interval = 0
        ease = SpacedRepetition.startEase
        streak = 0
        lapses = 0
        reviews = 0
        lastReviewed = nil
    }

    var isNew: Bool { reviews == 0 }

    func isDue(at date: Date) -> Bool { due <= date }

    /// Known well: it waits three weeks or more between reviews.
    var isMastered: Bool { interval >= 21 }
}

/// A named pile of flashcards ("Spanish", "Space", "Science test").
struct FlashDeck: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var cards: [Flashcard]
    var created: Date
    /// Where the cards came from: "phrasebook:es", "trivia:Space", or nil for your own.
    var source: String?
    /// The voice language for "Say it" on the answer side (language decks), like "es-ES".
    var speech: String?

    init(name: String, cards: [Flashcard] = [], source: String? = nil, speech: String? = nil, now: Date = Date()) {
        id = UUID()
        self.name = name
        self.cards = cards
        created = now
        self.source = source
        self.speech = speech
    }

    func dueCards(at date: Date) -> [Flashcard] { cards.filter { $0.isDue(at: date) } }
    func dueCount(at date: Date) -> Int { cards.reduce(0) { $0 + ($1.isDue(at: date) ? 1 : 0) } }
    var newCount: Int { cards.reduce(0) { $0 + ($1.isNew ? 1 : 0) } }
    var masteredCount: Int { cards.reduce(0) { $0 + ($1.isMastered ? 1 : 0) } }
    /// When the next card is ready (it can be in the past when cards are waiting).
    var nextDue: Date? { cards.map(\.due).min() }
}

// MARK: Spaced repetition

/// How well you knew a card.
enum FlashGrade: Int, Codable, CaseIterable, Identifiable {
    case again, hard, good, easy

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var isRight: Bool { self != .again }
}

/// Ace's spaced repetition (like Anki's SM-2): cards you know come back later and later,
/// and cards you miss come back in a minute.
enum SpacedRepetition {
    static let startEase = 2.5
    static let minEase = 1.3
    static let maxEase = 3.5
    /// Ten years, the longest a card ever waits.
    static let maxInterval = 3650.0
    /// A missed card comes back this soon (so it shows again in the same session).
    static let againDelay: TimeInterval = 60
    static let day: TimeInterval = 86_400

    /// Days until the next review if you answer `grade` now (0 for Again).
    static func nextInterval(_ card: Flashcard, _ grade: FlashGrade) -> Double {
        let i = card.interval
        let hard: Double, good: Double, easy: Double
        if i <= 0 {
            // New, or being learned again after a miss.
            hard = 0.5
            good = 1
            easy = 4
        } else {
            hard = whole(max(i * 1.2, i + 1))
            good = max(whole(i * card.ease), hard + 1)
            easy = max(whole(good * 1.3), good + 1)
        }
        switch grade {
        case .again: return 0
        case .hard: return min(maxInterval, hard)
        case .good: return min(maxInterval, good)
        case .easy: return min(maxInterval, easy)
        }
    }

    /// Whole days once it's a day or more, so reviews land on days and not odd hours.
    static func whole(_ days: Double) -> Double {
        days < 1 ? days : days.rounded()
    }

    /// The card after you answer it.
    static func review(_ card: Flashcard, grade: FlashGrade, at now: Date) -> Flashcard {
        var c = card
        c.reviews += 1
        c.lastReviewed = now
        switch grade {
        case .again:
            if card.interval > 0 { c.lapses += 1 }
            c.streak = 0
            c.interval = 0
            c.ease = max(minEase, card.ease - 0.2)
            c.due = now.addingTimeInterval(againDelay)
            return c
        case .hard:
            c.ease = max(minEase, card.ease - 0.15)
        case .good:
            break
        case .easy:
            c.ease = min(maxEase, card.ease + 0.15)
        }
        let days = nextInterval(card, grade)
        c.streak += 1
        c.interval = days
        c.due = now.addingTimeInterval(days * day)
        return c
    }

    /// What each answer button says under its name ("1 min", "12 hr", "3 days").
    static func label(_ grade: FlashGrade, for card: Flashcard) -> String {
        grade == .again ? "1 min" : label(days: nextInterval(card, grade))
    }

    static func label(days: Double) -> String {
        if days < 1 {
            let hours = max(1, Int((days * 24).rounded()))
            return "\(hours) hr"
        }
        if days < 30 {
            let d = Int(days.rounded())
            return d == 1 ? "1 day" : "\(d) days"
        }
        if days < 365 {
            let m = max(1, Int((days / 30).rounded()))
            return m == 1 ? "1 mo" : "\(m) mo"
        }
        let years = days / 365
        return years < 10 ? String(format: "%.1f yr", years) : String(format: "%.0f yr", years)
    }
}

// MARK: A study session

/// One card in a study session, and the deck it lives in.
struct StudyItem: Hashable {
    var deck: UUID
    var card: UUID
}

/// The cards to go through in one sitting. Missed cards go back in a few cards later,
/// so you see them again before you finish.
struct StudyQueue: Equatable {
    private(set) var order: [StudyItem]
    /// How many different cards the session started with.
    let total: Int
    /// Answers given (a missed card that comes back counts twice).
    private(set) var answered = 0
    private(set) var right = 0
    private(set) var missed: Set<StudyItem> = []

    /// New cards per session, so a big new deck doesn't land all at once.
    static let newPerSession = 20
    /// Cards in a practice session (when nothing is due).
    static let practiceSize = 20
    /// How many cards later a missed card comes back.
    static let againGap = 3

    init(_ items: [StudyItem]) {
        order = items
        total = items.count
    }

    var current: StudyItem? { order.first }
    var isDone: Bool { order.isEmpty }
    var left: Int { order.count }

    /// 0...1, how far through the session you are.
    var progress: Double {
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - Double(order.count) / Double(total)))
    }

    mutating func answer(_ grade: FlashGrade) {
        guard !order.isEmpty else { return }
        let item = order.removeFirst()
        answered += 1
        if grade.isRight {
            right += 1
        } else {
            missed.insert(item)
            order.insert(item, at: min(order.count, Self.againGap))
        }
    }

    /// The cards that are due: ones you've seen before first (most overdue first), then new ones (oldest first).
    static func due(in decks: [FlashDeck], at now: Date, newLimit: Int = newPerSession) -> StudyQueue {
        var seen: [(StudyItem, Date)] = []
        var fresh: [(StudyItem, Date)] = []
        for deck in decks {
            for card in deck.cards where card.isDue(at: now) {
                let item = StudyItem(deck: deck.id, card: card.id)
                if card.isNew { fresh.append((item, card.added)) } else { seen.append((item, card.due)) }
            }
        }
        let a = seen.sorted { $0.1 < $1.1 }.map { $0.0 }
        let b = fresh.sorted { $0.1 < $1.1 }.prefix(max(0, newLimit)).map { $0.0 }
        return StudyQueue(a + b)
    }

    /// Practice when nothing is due: the cards that are due soonest. Answers don't change when cards come back.
    static func practice(in decks: [FlashDeck], size: Int = practiceSize) -> StudyQueue {
        var all: [(StudyItem, Date)] = []
        for deck in decks {
            for card in deck.cards { all.append((StudyItem(deck: deck.id, card: card.id), card.due)) }
        }
        return StudyQueue(all.sorted { $0.1 < $1.1 }.prefix(max(0, size)).map { $0.0 })
    }
}

// MARK: Reminders

/// When to remind you that cards are ready: once, at your reminder time, on the first day cards are due.
enum FlashcardReminder {
    static let notificationID = "flashcards-due"
    /// 5:00 PM, after school.
    static let defaultMinutes = 17 * 60

    /// The reminder time, or nil when there are no cards. `minutes` is the time of day (minutes after midnight).
    static func fireDate(for decks: [FlashDeck], now: Date, minutes: Int, calendar: Calendar = .current) -> Date? {
        guard let first = decks.compactMap(\.nextDue).min() else { return nil }
        let earliest = max(first, now.addingTimeInterval(5 * 60))
        let m = min(max(minutes, 0), 24 * 60 - 1)
        let day = calendar.startOfDay(for: earliest)
        guard var at = calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: day) else { return nil }
        if at < earliest, let next = calendar.date(byAdding: .day, value: 1, to: at) { at = next }
        return at
    }

    /// How many cards will be ready at `date`.
    static func count(in decks: [FlashDeck], at date: Date) -> Int {
        decks.reduce(0) { $0 + $1.dueCount(at: date) }
    }

    static func body(count: Int) -> String {
        count == 1 ? "1 flashcard is ready to review. Say \"study my flashcards\" to start."
            : "\(count) flashcards are ready to review. Say \"study my flashcards\" to start."
    }
}

// MARK: Ready-made decks

/// Decks Ace can make from its own data: languages from the phrasebook, topics from trivia.
enum FlashcardSources {
    enum Source: Equatable {
        case language(String)   // phrasebook language code, like "es"
        case trivia(String)     // trivia category, like "Space"
    }

    /// Cards in a ready-made deck.
    static let deckSize = 40

    /// Words people add that aren't the topic ("spanish words" -> "spanish").
    private static let topicFiller = #"\b(?:the|some|my|words?|phrases?|vocab|vocabulary|language|basics?|trivia|facts?|questions?|quiz|stuff|things)\b"#

    /// Words that can sit next to a language and still mean the phrasebook ("spanish greetings").
    private static let languageExtras: Set<String> = ["greetings", "greeting", "common", "useful", "everyday", "easy",
                                                      "beginner", "beginners", "for", "travel", "phrasebook", "learn",
                                                      "learning", "practice", "simple", "first", "starter", "deck"]

    static func clean(_ topic: String) -> String {
        let t = TextKit.normalize(topic).replacingOccurrences(of: topicFiller, with: " ", options: .regularExpression)
        return t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    /// The ready-made deck a topic names, or nil.
    static func source(for topic: String) -> Source? {
        let t = clean(topic)
        guard !t.isEmpty else { return nil }
        // "my science test" or "chapter 4 vocab" is your own deck, not Ace's trivia.
        if Rx.matches(#"\b(?:tests?|exams?|midterms?|finals?|quiz(?:zes)?|homework|class|unit|chapter|lesson|project|worksheet|week|grade|period)\b"#,
                      TextKit.normalize(topic)) { return nil }
        if let code = Phrasebook.languageCode(t) { return .language(code) }
        if let cat = Trivia.category(in: t) { return .trivia(cat) }
        // "spanish greetings": a language plus words about the phrasebook itself
        // (but not "french revolution", which is history, not French).
        let words = t.split(separator: " ").map(String.init)
        for word in words {
            guard let code = Phrasebook.languageCode(word) else { continue }
            if words.allSatisfy({ $0 == word || languageExtras.contains($0) }) { return .language(code) }
        }
        return nil
    }

    /// The `source` tag a deck keeps, so Ace knows not to make the same one twice.
    static func tag(_ s: Source) -> String {
        switch s {
        case .language(let code): return "phrasebook:" + code
        case .trivia(let cat): return "trivia:" + cat
        }
    }

    static func name(_ s: Source) -> String {
        switch s {
        case .language(let code): return Phrasebook.languageName(code)
        case .trivia(let cat): return cat
        }
    }

    static func deck(_ s: Source, now: Date = Date()) -> FlashDeck? {
        switch s {
        case .language(let code): return language(code, now: now)
        case .trivia(let cat): return trivia(cat, now: now)
        }
    }

    /// English on the front, the other language on the back (and how to say it, for other alphabets).
    static func language(_ code: String, size: Int = deckSize, now: Date = Date()) -> FlashDeck? {
        let entries = Phrasebook.entries.filter { e in
            guard let t = e.t[code] else { return false }
            return !t.isEmpty && !e.en.contains("...") && !e.en.contains("…")
        }
        guard !entries.isEmpty else { return nil }
        let cards = entries.prefix(size).compactMap { e -> Flashcard? in
            guard let back = e.t[code] else { return nil }
            var say: String?
            if let p = e.say?[code], !p.isEmpty { say = "Say it: " + p }
            return Flashcard(front: tidy(e.en), back: back, note: say, now: now)
        }
        return FlashDeck(name: Phrasebook.languageName(code), cards: cards, source: tag(.language(code)),
                         speech: Phrasebook.speechCodes[code], now: now)
    }

    /// A trivia question on the front, the answer on the back, and the fun fact under it.
    static func trivia(_ category: String, size: Int = deckSize, now: Date = Date()) -> FlashDeck? {
        let pool = Trivia.all.filter { $0.category == category }
        guard !pool.isEmpty else { return nil }
        let cards = pool.shuffled().prefix(size).compactMap { q -> Flashcard? in
            guard q.choices.indices.contains(q.answer) else { return nil }
            return Flashcard(front: q.q, back: q.choices[q.answer], note: q.fact.isEmpty ? nil : q.fact, now: now)
        }
        guard !cards.isEmpty else { return nil }
        return FlashDeck(name: category, cards: cards, source: tag(.trivia(category)), now: now)
    }

    /// "i'm fine" -> "I'm fine".
    static func tidy(_ s: String) -> String {
        let fixed = s.replacingOccurrences(of: #"(?<![\p{L}])i(?=$|[\s'’,.!?])"#, with: "I", options: .regularExpression)
        return TextKit.capitalizeFirst(fixed.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: Reading what you say

/// What someone wants to do with flashcards.
enum FlashcardAsk: Equatable {
    /// "show my flashcards": open the decks.
    case open
    /// "study my flashcards", "study my spanish flashcards".
    case study(deck: String?)
    /// "how many flashcards are due".
    case due
    /// "make a deck called science test".
    case newDeck(String)
    /// "make spanish flashcards" (a ready-made deck), or "" for "make flashcards" with no topic.
    case make(String)
    /// "add a flashcard to spanish: hola = hello".
    case add(front: String, back: String, deck: String?)
    /// "add a flashcard" with nothing to add yet.
    case help
}

enum FlashcardText {
    static let fc = #"(?:flash ?cards?|flash-cards?)"#
    static let fcs = #"(?:flash ?cards|flash-cards|flash ?card decks?)"#

    /// The words as typed (case kept, so "Paris" stays "Paris"), with curly quotes made straight and
    /// "hey Ace," and "please" taken off the front.
    static func prepare(_ raw: String) -> String {
        var s = raw.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"").replacingOccurrences(of: "”", with: "\"")
        s = s.replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lead = #"^(?:(?:hey|hi|ok|okay|yo)\s+)?(?:ace\b\s*[,!.:]?\s*)?(?:(?:please|can you|could you|would you|will you|can we|can i|let's|lets|let us|i want to|i wanna|i need to|i'd like to|help me|ok|okay|now)\s+)*"#
        if let r = s.range(of: lead, options: [.regularExpression, .caseInsensitive]) {
            s.removeSubrange(r)
        }
        while let last = s.last, "?!.".contains(last) { s.removeLast() }
        s = s.replacingOccurrences(of: #"\s+please$"#, with: "", options: [.regularExpression, .caseInsensitive])
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Reads a flashcard ask, or nil when it isn't about flashcards.
    static func parse(_ raw: String) -> FlashcardAsk? {
        let s = prepare(raw)
        guard !s.isEmpty else { return nil }
        let low = s.lowercased()
        // Quick check so most sentences skip all of this.
        guard Rx.matches(#"\b(?:flash ?cards?|flash-cards?|cards?|decks?)\b"#, low) else { return nil }

        // How many are due ("how many flashcards are due", "do i have any cards to review")
        if Rx.matches(#"^(?:how many|do i have|have i got|are there|any|what|which|is|are|when|is there|got any)\b"#, low),
           Rx.matches(#"\b(?:flash ?cards?|flash-cards?|cards)\b"#, low),
           !Rx.matches(#"\b(?:report|credit|debit|gift|birthday|greeting|sd|micro ?sd|graphics|video|sound|memory|sim|library|trading|pokemon|playing|business|id) cards?\b"#, low),
           Rx.matches(#"\bdue\b"#, low)
            || (Rx.matches(#"\b(?:to review|ready|waiting|left to (?:review|study))\b"#, low) && Rx.matches(#"\b(?:my|i|any|are there)\b"#, low)) {
            return .due
        }

        // Opening the decks ("show my flashcards", "flashcards", "edit my spanish deck")
        if Rx.matches(#"^(?:my |the )?"# + fcs + #"$"#, low)
            || Rx.matches(#"^(?:show|open|see|list|view|manage|check|look at|go to|take me to)(?: me)?(?: my| the| all| all my| all of my)? "# + fcs + #"(?: decks?)?$"#, low)
            || Rx.matches(#"^(?:show|open|see|list|view|manage)(?: me)?(?: my| all my| all of my) (?:flash ?card )?decks$"#, low)
            || Rx.matches(#"^(?:delete|remove|erase|rename|edit|change|fix)(?: my| the| a| this| that| one of my)?(?: [\p{L}\p{N}' ]+?)? (?:"# + fc + #"|"# + fc + #" deck)$"#, low)
            || Rx.matches(#"^(?:delete|remove|erase|rename|edit|fix)(?: my) [\p{L}\p{N}' ]+? deck$"#, low) {
            return .open
        }

        // A new deck by name ("make a deck called science test", "new flashcard deck named spanish")
        if let g = Rx.groups(#"^(?:make|create|start|add|set up|build|new)(?: me)?(?: a| an| another)?(?: new)?(?: "# + fc + #"| study)? deck(?: of "# + fcs + #")? (?:called|named|titled) (.+)$"#, s) {
            let name = deckName(g[0]) ?? ""
            return name.isEmpty ? .make("") : .newDeck(name)
        }
        if let g = Rx.groups(#"^(?:make|create|start|add|set up|build|new)(?: me)?(?: a| an| another)?(?: new)? "# + fc + #" deck(?: (?:for|about|on|of|with) (.+))?$"#, s) {
            return topicAsk(g[0], sure: true)
        }

        // Study time
        if Rx.matches(#"^"# + fc + #" time$|^time for (?:my |some )?"# + fc + #"$|^time to study (?:my )?"# + fc + #"$"#, low) {
            return .study(deck: nil)
        }
        let studyVerbs = #"(?:study|review|practi[cs]e|go over|go through|do|start|run|quiz me on|test me on|drill|revise|learn)"#
        if let g = Rx.groups(#"^"# + studyVerbs + #"(?: some| the| all| all of)?(?: my)?(?: (.+?))? "# + fcs + #"(?: deck)?(?: now| today| again| for a bit)*$"#, s) {
            return .study(deck: deckName(g[0]))
        }
        if let g = Rx.groups(#"^(?:study|review|practi[cs]e|go over|go through|do|quiz me on|test me on|drill|revise)(?: some| the| all| all of)? my(?: (.+?))? (?:cards|deck)(?: now| today| again| for a bit)*$"#, s) {
            return .study(deck: deckName(g[0]))
        }
        if let g = Rx.groups(#"^(?:study|practi[cs]e|quiz me on|test me on|drill)(?: my| the)? (.+?) deck(?: now| today| again)*$"#, s) {
            return .study(deck: deckName(g[0]))
        }

        // Ready-made decks ("make spanish flashcards", "make me flashcards about space")
        if let g = Rx.groups(#"^(?:make|create|build|give me|get|set up|generate|i need|i want)(?: me| us)?(?: a| some| new| the| a set of| a deck of| a pile of)*(?: new)? "# + fcs + #"(?: (?:for|about|on|of|with|in|to learn|to study|so i can learn) (.+))?$"#, s) {
            return topicAsk(g[0], sure: true)
        }
        if let g = Rx.groups(#"^(?:make|create|build|give me|get|set up|generate|i need|i want)(?: me| us)?(?: a| some| new| the| a set of)*(?: new)? (.+?) "# + fcs + #"$"#, s) {
            return topicAsk(g[0], sure: true)
        }
        if let g = Rx.groups(#"^(?:make|create|build|give me|get|set up)(?: me)?(?: a| an| new)*(?: new)? (.+?) deck$"#, s) {
            // "make a steam deck" isn't about flashcards, so only languages and trivia topics count here.
            return topicAsk(g[0], sure: false)
        }

        // Adding a card ("add a flashcard: hola = hello", "add hola = hello to my spanish deck")
        if let add = addCard(s) { return add }
        return nil
    }

    /// A topic for a ready-made or new deck. `sure` is false when the words alone don't say flashcards.
    private static func topicAsk(_ raw: String, sure: Bool) -> FlashcardAsk? {
        let topic = raw.trimmingCharacters(in: .whitespaces)
        if topic.isEmpty { return sure ? .make("") : nil }
        if let g = Rx.groups(#"^(?:called|named|titled) (.+)$"#, topic) {
            let name = deckName(g[0]) ?? ""
            return name.isEmpty ? .make("") : .newDeck(name)
        }
        if FlashcardSources.source(for: topic) != nil { return .make(topic) }
        guard sure else { return nil }
        let name = deckName(topic) ?? ""
        return name.isEmpty ? .make("") : .newDeck(name)
    }

    /// A deck name as said ("my spanish", "the science test") -> "Spanish", "Science test". Nil for none.
    static func deckName(_ raw: String?) -> String? {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        s = s.replacingOccurrences(of: #"^(?:(?:my|the|a|an|all|all of|some|of|own)\s+)+"#, with: "", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: #"\s+(?:"# + fc + #"|deck|cards)$"#, with: "", options: [.regularExpression, .caseInsensitive])
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
        guard !s.isEmpty, !["my", "the", "all", "new", "some", "your", "these", "those", "own", "my own", "a new"].contains(s.lowercased()) else { return nil }
        guard s.count <= 40 else { return nil }
        return TextKit.capitalizeFirst(s)
    }

    /// "add a flashcard: front = back", "add a card to spanish: hola = hello", "add hola = hello to my spanish deck".
    private static func addCard(_ s: String) -> FlashcardAsk? {
        // The opening words, and whether they say "flashcard" (a plain "make a card" could be a birthday card).
        let opener = #"^(?:(?:add|make|create|write|put|new|save)(?: me)?(?: a| an| another| one more| this| the| new| one)*(?: new)? ("# + fc + #"|card)|("# + fc + #")|add)\b\s*(.*)$"#
        guard let g = Rx.groups(opener, s) else { return nil }
        let saysFlashcard = (!g[0].isEmpty && g[0].lowercased() != "card") || !g[1].isEmpty
        var rest = g[2].trimmingCharacters(in: .whitespaces)
        var deck: String?

        // "to my spanish deck: ..." at the front
        if let d = Rx.groups(#"^(?:to|in|into|for|on) (?:my |the )?(.+?) (?:deck|"# + fc + #"|set)\s*[:,\-–—]?\s+(.*)$"#, rest) {
            deck = deckName(d[0])
            rest = d[1]
        } else if let d = Rx.groups(#"^(?:to|in|into|for|on) (?:my |the )?([^:=]+?)\s*:\s*(.+)$"#, rest), saysFlashcard,
                  pair(d[1]) != nil {
            // "add a flashcard to spanish: hola = hello" (but "add a flashcard for loop: a loop that repeats" is a card)
            deck = deckName(d[0])
            rest = d[1]
        } else if let d = Rx.groups(#"^(.+?)\s+(?:to|in|into) (?:my |the )?(.+?) (?:deck|"# + fc + #")$"#, rest) {
            // "... to my spanish deck" at the end
            rest = d[0]
            deck = deckName(d[1])
        }

        rest = rest.replacingOccurrences(of: #"^[:,\-–—]\s*"#, with: "", options: .regularExpression)
        rest = rest.replacingOccurrences(of: #"^(?:that says|saying)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
        rest = rest.trimmingCharacters(in: .whitespaces)

        if let pair = pair(rest) {
            // A plain "add x = y" or "make a card: ..." only counts when it names a deck.
            guard saysFlashcard || deck != nil else { return nil }
            return .add(front: pair.front, back: pair.back, deck: deck)
        }
        // "add a flashcard" with nothing after it: say how. A bare "add ..." or "make a card ..." isn't ours.
        if saysFlashcard && (rest.isEmpty || deck != nil) { return .help }
        return nil
    }

    /// Splits one card into its front and back ("hola = hello", "photosynthesis - how plants make food").
    static func pair(_ raw: String) -> (front: String, back: String)? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if let g = Rx.groups(#"^front\s*[:=]?\s*(.+?)[,;]?\s+back\s*[:=]?\s*(.+)$"#, s) {
            return make(g[0], g[1])
        }
        if let g = Rx.groups(#"^(?:question|q)\s*[:=]\s*(.+?)[,;]?\s+(?:answer|a)\s*[:=]\s*(.+)$"#, s) {
            return make(g[0], g[1])
        }
        let separators = ["\t", " = ", "=", " -> ", "->", " → ", "→", " means ", " – ", " — ", " - ", ": ", " | ", "|", "; "]
        for sep in separators {
            if let r = s.range(of: sep, options: .caseInsensitive) {
                if let p = make(String(s[..<r.lowerBound]), String(s[r.upperBound...])) { return p }
            }
        }
        // Last try: one comma ("hola, hello").
        let commas = s.components(separatedBy: ",")
        if commas.count == 2 { return make(commas[0], commas[1]) }
        return nil
    }

    private static func make(_ a: String, _ b: String) -> (front: String, back: String)? {
        let trim = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'"))
        let front = a.trimmingCharacters(in: trim)
        let back = b.trimmingCharacters(in: trim)
        guard !front.isEmpty, !back.isEmpty, front.count <= 300, back.count <= 600 else { return nil }
        guard front.rangeOfCharacter(from: .alphanumerics) != nil, back.rangeOfCharacter(from: .alphanumerics) != nil else { return nil }
        return (TextKit.capitalizeFirst(front), TextKit.capitalizeFirst(back))
    }

    /// Lots of cards pasted at once, one per line ("hola = hello", "gato - cat"). Lines that aren't cards are skipped.
    static func pairs(fromLines text: String) -> [(front: String, back: String)] {
        text.components(separatedBy: .newlines).compactMap { line in
            let t = line.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"^(?:[-•*]|\d+[.)])\s+"#, with: "", options: .regularExpression)
            return t.isEmpty ? nil : pair(t)
        }
    }
}
