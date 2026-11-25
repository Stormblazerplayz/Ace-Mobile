import Foundation
import SwiftUI

/// One flashcard: a question on the front, the answer (and a fun fact) on the back.
struct StudyCard: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var deck: String
    var front: String
    var back: String
    var note: String
    /// True for cards you made yourself (they can be deleted), false for Ace's trivia cards.
    var mine: Bool
}

/// How well you know a card: which Leitner box it's in and when it's next due.
struct CardProgress: Codable, Equatable {
    /// 0 is "still learning". Each right answer moves it up a box, up to `Leitner.topBox`.
    var box: Int
    var due: Date
    var seen: Int
    var right: Int
}

/// The Leitner system: every time you know a card it waits longer before coming back,
/// and when you miss it, it goes back to the start.
enum Leitner {
    /// Days a card waits in each box.
    static let intervals: [Double] = [0, 1, 2, 4, 8, 16, 32]
    static var topBox: Int { intervals.count - 1 }
    /// From this box on, a card counts as mastered.
    static let masteredBox = 4

    static func next(after old: CardProgress?, knew: Bool, now: Date) -> CardProgress {
        var p = old ?? CardProgress(box: 0, due: now, seen: 0, right: 0)
        p.seen += 1
        if knew {
            p.right += 1
            p.box = min(topBox, p.box + 1)
        } else {
            p.box = 0
        }
        p.due = now.addingTimeInterval(intervals[p.box] * 86_400)
        return p
    }
}

/// A deck: one per trivia category, plus "My cards" for the ones you make.
struct StudyDeck: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let symbol: String
    /// Two hex colors for the deck's gradient.
    let colors: [UInt32]
    let cards: [StudyCard]

    var gradient: LinearGradient {
        LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var tint: Color { Color(hex: colors.first ?? 0x5BB6FF) }

    static let myDeckName = "My cards"

    /// The symbol and colors for each deck.
    static func style(for name: String) -> (symbol: String, colors: [UInt32]) {
        switch name {
        case "Space": return ("sparkles", [0x5B3DF5, 0x1BC6FF])
        case "Animals": return ("pawprint.fill", [0xFF8A3D, 0xFFCF3A])
        case "Science": return ("atom", [0x00C9A7, 0x3D8BFF])
        case "Earth": return ("globe.americas.fill", [0x2FBF71, 0x1E8FD6])
        case "Human Body": return ("heart.fill", [0xFF5F8F, 0xFF9A5F])
        case "History": return ("building.columns.fill", [0xC08B4E, 0xF5B83D])
        case "Geography": return ("map.fill", [0x18B2A8, 0x8BE15C])
        case "Sports": return ("figure.run", [0xFF5A4E, 0xFFB020])
        case "Technology": return ("cpu.fill", [0x8F7CFF, 0x5BB6FF])
        case "Food": return ("fork.knife", [0xFF7A59, 0xFFD15C])
        case myDeckName: return ("pencil.and.scribble", [0xB45CFF, 0xFF5FB4])
        case "Review": return ("arrow.triangle.2.circlepath", [0x8F7CFF, 0xFF5F8F])
        default: return ("rectangle.on.rectangle.angled", [0x5BB6FF, 0x8F7CFF])
        }
    }
}

/// How a deck is going: how many cards, how many are mastered and how many are waiting for you.
struct DeckStats: Equatable {
    var total: Int
    var mastered: Int
    var learning: Int
    var due: Int
    var fresh: Int

    /// 0 to 1: how much of the deck is mastered.
    var progress: Double { total == 0 ? 0 : Double(mastered) / Double(total) }
}

/// Study mode: flashcards made from Ace's trivia and from cards you write, with spaced
/// repetition so the cards you find hard come back sooner. Everything is saved in study.json.
@MainActor
final class StudyStore: ObservableObject {
    static let shared = StudyStore()

    /// Brand new cards a session hands out at most, so a big deck doesn't bury you.
    static let newPerSession = 10
    /// The most cards in one session.
    static let sessionSize = 20
    static let maxFront = 200
    static let maxBack = 300
    /// Cards a day that fill the ring on the Study screen.
    static let dailyGoal = 20

    @Published private(set) var progress: [String: CardProgress] = [:]
    @Published private(set) var myCards: [StudyCard] = []
    @Published private(set) var streak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var lastStudyDay: String?
    @Published private(set) var totalReviews = 0
    @Published private(set) var todayCount = 0
    @Published private(set) var todayKey: String?

    private let fileName: String?
    private let triviaDecks: [StudyDeck]

    private struct Saved: Codable {
        var progress: [String: CardProgress]
        var myCards: [StudyCard]
        var streak: Int
        var bestStreak: Int
        var lastStudyDay: String?
        var totalReviews: Int
        var todayCount: Int
        var todayKey: String?
    }

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "study.json", trivia: [TriviaQuestion] = Trivia.all) {
        self.fileName = fileName
        let cards = StudyStore.cards(from: trivia)
        var order: [String] = []
        for c in cards where !order.contains(c.deck) { order.append(c.deck) }
        self.triviaDecks = order.map { name in
            let s = StudyDeck.style(for: name)
            return StudyDeck(name: name, symbol: s.symbol, colors: s.colors, cards: cards.filter { $0.deck == name })
        }
        if let fileName, let saved = Persistence.load(Saved.self, from: fileName) {
            progress = saved.progress
            myCards = saved.myCards
            streak = saved.streak
            bestStreak = saved.bestStreak
            lastStudyDay = saved.lastStudyDay
            totalReviews = saved.totalReviews
            todayCount = saved.todayCount
            todayKey = saved.todayKey
        }
    }

    /// Turns trivia questions into cards: the question on the front, the right answer and its fact on the back.
    static func cards(from trivia: [TriviaQuestion]) -> [StudyCard] {
        trivia.compactMap { q in
            guard q.choices.indices.contains(q.answer) else { return nil }
            return StudyCard(id: "t-" + q.id, deck: q.category, front: q.q, back: q.choices[q.answer], note: q.fact, mine: false)
        }
    }

    // MARK: Decks

    /// Every deck: yours first (if you've made any cards), then the trivia decks in their usual order.
    var decks: [StudyDeck] {
        guard !myCards.isEmpty else { return triviaDecks }
        let s = StudyDeck.style(for: StudyDeck.myDeckName)
        return [StudyDeck(name: StudyDeck.myDeckName, symbol: s.symbol, colors: s.colors, cards: myCards)] + triviaDecks
    }

    static let reviewDeckName = "Review"

    /// A deck of every card that's due again, from all the decks, for a quick review.
    func reviewDeck(now: Date = Date()) -> StudyDeck {
        let s = StudyDeck.style(for: Self.reviewDeckName)
        let due = decks.flatMap(\.cards).filter { card in
            guard let p = progress[card.id] else { return false }
            return p.due <= now
        }
        return StudyDeck(name: Self.reviewDeckName, symbol: s.symbol, colors: s.colors, cards: due)
    }

    func deck(named name: String) -> StudyDeck? {
        decks.first { $0.name == name }
    }

    func stats(for deck: StudyDeck, now: Date = Date()) -> DeckStats {
        var s = DeckStats(total: deck.cards.count, mastered: 0, learning: 0, due: 0, fresh: 0)
        for card in deck.cards {
            guard let p = progress[card.id] else {
                s.fresh += 1
                continue
            }
            if p.box >= Leitner.masteredBox { s.mastered += 1 } else { s.learning += 1 }
            if p.due <= now { s.due += 1 }
        }
        return s
    }

    /// Cards waiting for you across every deck (ones you've seen before that are due again).
    func dueCount(now: Date = Date()) -> Int {
        decks.reduce(0) { $0 + stats(for: $1, now: now).due }
    }

    /// Cards mastered across every deck.
    var masteredCount: Int {
        progress.values.filter { $0.box >= Leitner.masteredBox }.count
    }

    // MARK: Sessions

    /// The cards for one session: due cards first (most overdue first), then a few new ones.
    func session(for deck: StudyDeck, now: Date = Date(), shuffle: Bool = true) -> [StudyCard] {
        var due: [(StudyCard, Date)] = []
        var fresh: [StudyCard] = []
        for card in deck.cards {
            if let p = progress[card.id] {
                if p.due <= now { due.append((card, p.due)) }
            } else {
                fresh.append(card)
            }
        }
        due.sort { $0.1 < $1.1 }
        if shuffle { fresh.shuffle() }
        var out = due.prefix(Self.sessionSize).map { $0.0 }
        let room = max(0, Self.sessionSize - out.count)
        out += fresh.prefix(min(room, Self.newPerSession))
        return out
    }

    /// Records whether you knew a card, and moves your streak along.
    func grade(_ card: StudyCard, knew: Bool, now: Date = Date()) {
        progress[card.id] = Leitner.next(after: progress[card.id], knew: knew, now: now)
        totalReviews += 1
        let today = Persistence.dayKey(now)
        if todayKey != today {
            todayKey = today
            todayCount = 0
        }
        todayCount += 1
        markStudied(on: now)
        save()
    }

    /// Days in a row you've studied. Studying today keeps it; skipping a day starts it over.
    func markStudied(on now: Date) {
        let today = Persistence.dayKey(now)
        guard lastStudyDay != today else { return }
        let yesterday = Persistence.dayKey(Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: now) ?? now)
        streak = lastStudyDay == yesterday ? streak + 1 : 1
        bestStreak = max(bestStreak, streak)
        lastStudyDay = today
    }

    /// The streak to show: it drops to 0 once a whole day has gone by without studying.
    func currentStreak(now: Date = Date()) -> Int {
        guard let last = lastStudyDay else { return 0 }
        let today = Persistence.dayKey(now)
        let yesterday = Persistence.dayKey(Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: now) ?? now)
        return last == today || last == yesterday ? streak : 0
    }

    /// Cards you've answered today.
    func reviewsToday(now: Date = Date()) -> Int {
        todayKey == Persistence.dayKey(now) ? todayCount : 0
    }

    /// 0 to 1: how close today is to the daily goal.
    func goalProgress(now: Date = Date()) -> Double {
        min(1, Double(reviewsToday(now: now)) / Double(Self.dailyGoal))
    }

    func studiedToday(now: Date = Date()) -> Bool {
        lastStudyDay == Persistence.dayKey(now)
    }

    // MARK: Your own cards

    enum AddError: Error, Equatable {
        case emptyFront, emptyBack, tooLong, duplicate
    }

    /// Adds a card you wrote to "My cards". Returns the card, or why it couldn't be added.
    @discardableResult
    func addCard(front: String, back: String, note: String = "") -> Result<StudyCard, AddError> {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty else { return .failure(.emptyFront) }
        guard !b.isEmpty else { return .failure(.emptyBack) }
        guard f.count <= Self.maxFront, b.count <= Self.maxBack, n.count <= Self.maxBack else { return .failure(.tooLong) }
        let key = f.lowercased()
        guard !myCards.contains(where: { $0.front.lowercased() == key }) else { return .failure(.duplicate) }
        let card = StudyCard(id: "m-" + UUID().uuidString, deck: StudyDeck.myDeckName, front: f, back: b, note: n, mine: true)
        myCards.append(card)
        save()
        return .success(card)
    }

    func deleteCard(_ card: StudyCard) {
        guard card.mine else { return }
        myCards.removeAll { $0.id == card.id }
        progress[card.id] = nil
        save()
    }

    /// Starts a deck over: every card in it goes back to new.
    func reset(_ deck: StudyDeck) {
        for card in deck.cards { progress[card.id] = nil }
        save()
    }

    // MARK: Saving

    private func save() {
        guard let fileName else { return }
        Persistence.save(Saved(progress: progress, myCards: myCards, streak: streak, bestStreak: bestStreak,
                               lastStudyDay: lastStudyDay, totalReviews: totalReviews,
                               todayCount: todayCount, todayKey: todayKey), to: fileName)
    }
}
