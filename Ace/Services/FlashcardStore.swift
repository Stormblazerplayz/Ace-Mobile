import Foundation
import UserNotifications

/// Keeps your flashcard decks (saved in flashcards.json) and the "cards are ready" reminder.
@MainActor
final class FlashcardStore: ObservableObject {
    static let shared = FlashcardStore()

    /// What's saved on disk.
    struct Saved: Codable {
        var decks: [FlashDeck]
        var lastDeckID: UUID?
    }

    @Published private(set) var decks: [FlashDeck] = []
    /// The deck you last added to or studied, so "add a flashcard" knows where to put it.
    @Published private(set) var lastDeckID: UUID?
    /// True when the iPad has notifications for Ace switched off (so the reminder can't ring).
    @Published private(set) var notificationsBlocked = false

    static let remindersKey = "flashcardReminders"
    static let reminderTimeKey = "flashcardReminderMinutes"

    /// Remind me when cards are ready (on by default).
    @Published var remindersOn: Bool {
        didSet {
            defaults.set(remindersOn, forKey: Self.remindersKey)
            refreshReminder()
        }
    }

    /// The reminder time, in minutes after midnight (5:00 PM by default).
    @Published var reminderMinutes: Int {
        didSet {
            defaults.set(reminderMinutes, forKey: Self.reminderTimeKey)
            refreshReminder()
        }
    }

    let fileName: String
    private let schedulesReminders: Bool
    private let defaults: UserDefaults
    private var reminderTask: Task<Void, Never>?

    /// Tests pass their own file and `schedulesReminders: false`, so they never ask for notifications.
    init(fileName: String = "flashcards.json", schedulesReminders: Bool = true, defaults: UserDefaults = .standard) {
        self.fileName = fileName
        self.schedulesReminders = schedulesReminders
        self.defaults = defaults
        remindersOn = defaults.object(forKey: Self.remindersKey) as? Bool ?? true
        reminderMinutes = defaults.object(forKey: Self.reminderTimeKey) as? Int ?? FlashcardReminder.defaultMinutes
        if let saved = Persistence.load(Saved.self, from: fileName) {
            decks = saved.decks
            lastDeckID = saved.lastDeckID
        }
    }

    // MARK: Looking things up

    func deck(_ id: UUID?) -> FlashDeck? {
        guard let id else { return nil }
        return decks.first { $0.id == id }
    }

    func card(_ item: StudyItem) -> Flashcard? {
        deck(item.deck)?.cards.first { $0.id == item.card }
    }

    /// The deck a spoken name means: an exact match first, then one that starts with it or contains it.
    func deck(named raw: String) -> FlashDeck? {
        let want = Self.key(raw)
        guard !want.isEmpty else { return nil }
        if let d = decks.first(where: { Self.key($0.name) == want }) { return d }
        // "spanish" finds "Spanish words", and "science test deck" finds "Science test".
        if let d = decks.first(where: { Self.key($0.name).hasPrefix(want) }) { return d }
        if let d = decks.first(where: { want.hasPrefix(Self.key($0.name)) }) { return d }
        return decks.first { Self.key($0.name).contains(want) }
    }

    /// The deck a ready-made source made ("phrasebook:es"), if you have it.
    func deck(source tag: String) -> FlashDeck? {
        decks.first { $0.source == tag }
    }

    /// Lowercased, without punctuation or "deck"/"flashcards", for comparing names.
    static func key(_ name: String) -> String {
        let t = name.lowercased()
            .replacingOccurrences(of: #"[^\p{L}\p{N} ]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(?:deck|decks|flash ?cards?|cards?)\b"#, with: " ", options: .regularExpression)
        return t.split(separator: " ").joined(separator: " ")
    }

    var lastDeck: FlashDeck? { deck(lastDeckID) }

    func dueCount(at date: Date = Date()) -> Int {
        decks.reduce(0) { $0 + $1.dueCount(at: date) }
    }

    var cardCount: Int { decks.reduce(0) { $0 + $1.cards.count } }

    /// When the next card is ready (nil when you have no cards).
    var nextDue: Date? { decks.compactMap(\.nextDue).min() }

    // MARK: Changing decks

    /// Adds a deck and returns it. A name you already have gets a number ("Spanish 2").
    @discardableResult
    func addDeck(_ deck: FlashDeck) -> FlashDeck {
        var d = deck
        d.name = uniqueName(d.name)
        decks.append(d)
        lastDeckID = d.id
        save()
        return d
    }

    @discardableResult
    func newDeck(named name: String, now: Date = Date()) -> FlashDeck {
        addDeck(FlashDeck(name: Self.cleanName(name), now: now))
    }

    func renameDeck(_ id: UUID, to name: String) {
        guard let i = index(of: id) else { return }
        let clean = Self.cleanName(name)
        guard !clean.isEmpty, clean != decks[i].name else { return }
        decks[i].name = uniqueName(clean, skipping: id)
        save()
    }

    func deleteDeck(_ id: UUID) {
        decks.removeAll { $0.id == id }
        if lastDeckID == id { lastDeckID = decks.last?.id }
        save()
    }

    /// Puts a deck's cards back to new (as if you'd never studied them).
    func resetProgress(_ id: UUID, now: Date = Date()) {
        guard let i = index(of: id) else { return }
        decks[i].cards = decks[i].cards.map { old in
            var c = Flashcard(front: old.front, back: old.back, note: old.note, now: now)
            c.id = old.id
            c.added = old.added
            return c
        }
        save()
    }

    // MARK: Changing cards

    /// Adds a card. If the deck already has a card with the same front, its answer is updated instead.
    /// Returns the card, and true when it was new.
    @discardableResult
    func addCard(front: String, back: String, note: String? = nil, to deckID: UUID, now: Date = Date()) -> (card: Flashcard, isNew: Bool)? {
        guard let i = index(of: deckID) else { return nil }
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else { return nil }
        lastDeckID = deckID
        if let j = decks[i].cards.firstIndex(where: { Self.key($0.front) == Self.key(f) && !Self.key(f).isEmpty }) {
            decks[i].cards[j].back = b
            if let note { decks[i].cards[j].note = note }
            save()
            return (decks[i].cards[j], false)
        }
        let card = Flashcard(front: f, back: b, note: note, now: now)
        decks[i].cards.append(card)
        save()
        return (card, true)
    }

    /// Adds many cards at once (pasted "word = meaning" lines). Returns how many were new.
    @discardableResult
    func importPairs(_ pairs: [(front: String, back: String)], to deckID: UUID, now: Date = Date()) -> Int {
        var added = 0
        for p in pairs {
            if addCard(front: p.front, back: p.back, to: deckID, now: now)?.isNew == true { added += 1 }
        }
        return added
    }

    func updateCard(_ card: Flashcard, in deckID: UUID) {
        guard let i = index(of: deckID), let j = decks[i].cards.firstIndex(where: { $0.id == card.id }) else { return }
        var c = card
        c.front = c.front.trimmingCharacters(in: .whitespacesAndNewlines)
        c.back = c.back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !c.front.isEmpty, !c.back.isEmpty else { return }
        decks[i].cards[j] = c
        save()
    }

    func deleteCard(_ cardID: UUID, from deckID: UUID) {
        guard let i = index(of: deckID) else { return }
        decks[i].cards.removeAll { $0.id == cardID }
        save()
    }

    // MARK: Studying

    /// Records an answer. Practice answers (when nothing was due) don't move the card's next review.
    func grade(_ item: StudyItem, _ grade: FlashGrade, at now: Date = Date(), practice: Bool = false) {
        lastDeckID = item.deck
        guard !practice,
              let i = index(of: item.deck),
              let j = decks[i].cards.firstIndex(where: { $0.id == item.card }) else { return }
        decks[i].cards[j] = SpacedRepetition.review(decks[i].cards[j], grade: grade, at: now)
        save(reminder: false)
    }

    /// The cards to study: one deck, or every deck when `deckID` is nil.
    func queue(deckID: UUID?, practice: Bool, at now: Date = Date()) -> StudyQueue {
        let pool = deckID.flatMap { id in deck(id).map { [$0] } } ?? decks
        return practice ? StudyQueue.practice(in: pool) : StudyQueue.due(in: pool, at: now)
    }

    // MARK: Saving

    func save(reminder: Bool = true) {
        Persistence.save(Saved(decks: decks, lastDeckID: lastDeckID), to: fileName)
        if reminder { refreshReminder() }
    }

    /// Wipes everything (tests use this on their own file).
    func removeAll() {
        decks = []
        lastDeckID = nil
        save()
    }

    // MARK: The reminder

    /// Sets the one "flashcards are ready" notification for the next day cards are due,
    /// or takes it away when the reminder is off or there are no cards.
    func refreshReminder(now: Date = Date()) {
        guard schedulesReminders else { return }
        reminderTask?.cancel()
        let id = FlashcardReminder.notificationID
        guard remindersOn, let fire = FlashcardReminder.fireDate(for: decks, now: now, minutes: reminderMinutes) else {
            Notifier.cancel(id)
            return
        }
        let count = max(1, FlashcardReminder.count(in: decks, at: fire))
        let body = FlashcardReminder.body(count: count)
        reminderTask = Task { @MainActor [weak self] in
            Notifier.cancel(id)
            let ok = await Notifier.schedule(id: id, title: "Flashcards", body: body, at: fire, category: "flashcards")
            guard !Task.isCancelled else { return }
            self?.notificationsBlocked = !ok
        }
    }

    /// Checks whether notifications are allowed without asking (for the note in the Flashcards screen).
    func checkNotifications() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationsBlocked = status == .denied
    }

    // MARK: Helpers

    private func index(of id: UUID) -> Int? {
        decks.firstIndex { $0.id == id }
    }

    /// Trims a deck name, keeps it short and starts it with a capital letter.
    static func cleanName(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let short = String(t.prefix(40)).trimmingCharacters(in: .whitespaces)
        return short.isEmpty ? "My deck" : TextKit.capitalizeFirst(short)
    }

    private func uniqueName(_ name: String, skipping: UUID? = nil) -> String {
        let taken = Set(decks.filter { $0.id != skipping }.map { $0.name.lowercased() })
        guard taken.contains(name.lowercased()) else { return name }
        var n = 2
        while taken.contains("\(name) \(n)".lowercased()) { n += 1 }
        return "\(name) \(n)"
    }
}
