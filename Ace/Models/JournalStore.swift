import Foundation
import SwiftUI

/// How a day went, from Awesome down to Rough. Each one has its own weather icon and color.
enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case awesome, good, okay, meh, rough

    var id: String { rawValue }

    var label: String {
        switch self {
        case .awesome: return "Awesome"
        case .good: return "Good"
        case .okay: return "Okay"
        case .meh: return "Meh"
        case .rough: return "Rough"
        }
    }

    /// 5 for Awesome down to 1 for Rough, for averages and the trend chart.
    var score: Int {
        switch self {
        case .awesome: return 5
        case .good: return 4
        case .okay: return 3
        case .meh: return 2
        case .rough: return 1
        }
    }

    var symbol: String {
        switch self {
        case .awesome: return "sun.max.fill"
        case .good: return "cloud.sun.fill"
        case .okay: return "cloud.fill"
        case .meh: return "cloud.drizzle.fill"
        case .rough: return "cloud.bolt.rain.fill"
        }
    }

    /// Two hex colors for the mood's gradient.
    var hexes: [UInt32] {
        switch self {
        case .awesome: return [0xFFCF3A, 0xFF8A3D]
        case .good: return [0x45D483, 0x1BC6FF]
        case .okay: return [0x5BB6FF, 0x8F7CFF]
        case .meh: return [0x9A7CFF, 0x5A5FA8]
        case .rough: return [0xFF5F8F, 0x7A3DB8]
        }
    }

    var color: Color { Color(hex: hexes[0]) }
    var colors: [Color] { hexes.map { Color(hex: $0) } }
    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The mood closest to an average score (4.6 is Awesome, 3.2 is Okay).
    static func nearest(to score: Double) -> JournalMood {
        allCases.min { abs(Double($0.score) - score) < abs(Double($1.score) - score) } ?? .okay
    }
}

/// One day in the journal: how it went, what happened, and what you did.
struct JournalEntry: Codable, Identifiable, Equatable {
    /// The day, like "2026-11-25". There's one entry per day.
    var day: String
    var mood: JournalMood
    var text: String
    var tags: [String]
    /// When it was last saved.
    var updated: Date

    var id: String { day }
}

/// A point on the mood chart: a day and its score (nil when you didn't write that day).
struct MoodPoint: Equatable, Identifiable {
    let date: Date
    let score: Int?
    var id: Date { date }
}

/// The mood journal: one entry a day with a mood, a few words and what you did. It works out
/// your streak, your average mood, a month of colored days and which things go with your best days.
/// Everything stays on the iPad, in journal.json.
@MainActor
final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    /// Things you can tag a day with.
    static let tags = ["School", "Friends", "Family", "Gaming", "Building", "Sports", "Outside", "Music", "Reading", "Rest"]
    static let maxText = 2_000

    /// Every entry, newest day first.
    @Published private(set) var entries: [JournalEntry] = []

    private let fileName: String?
    let calendar: Calendar

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "journal.json", calendar: Calendar? = nil) {
        self.fileName = fileName
        if let calendar {
            self.calendar = calendar
        } else {
            var cal = Calendar(identifier: .gregorian)
            cal.firstWeekday = Calendar.current.firstWeekday
            cal.timeZone = .current
            self.calendar = cal
        }
        if let fileName, let saved = Persistence.load([JournalEntry].self, from: fileName) {
            entries = saved.sorted { $0.day > $1.day }
        }
    }

    // MARK: Days

    func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func entry(on date: Date) -> JournalEntry? {
        let key = dayKey(date)
        return entries.first { $0.day == key }
    }

    // MARK: Writing

    /// Saves how a day went. Writing again on the same day replaces that day's entry.
    /// Returns nil for a day that hasn't happened yet.
    @discardableResult
    func save(mood: JournalMood, text: String, tags: [String], on date: Date, now: Date = Date()) -> JournalEntry? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: now) else { return nil }
        let clean = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxText))
        var picked: [String] = []
        for t in tags where Self.tags.contains(t) && !picked.contains(t) { picked.append(t) }
        let entry = JournalEntry(day: dayKey(date), mood: mood, text: clean, tags: picked, updated: now)
        entries.removeAll { $0.day == entry.day }
        entries.append(entry)
        entries.sort { $0.day > $1.day }
        persist()
        return entry
    }

    func delete(on date: Date) {
        let key = dayKey(date)
        entries.removeAll { $0.day == key }
        persist()
    }

    // MARK: Reading

    /// Days in a row you've written, counting back from today (or yesterday, if today isn't written yet).
    func streak(now: Date = Date()) -> Int {
        let days = Set(entries.map(\.day))
        var day = calendar.startOfDay(for: now)
        if !days.contains(dayKey(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while days.contains(dayKey(day)) {
            count += 1
            guard let before = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = before
        }
        return count
    }

    /// The last `days` days (oldest first, ending today) with each day's mood score.
    func trend(days: Int = 7, now: Date = Date()) -> [MoodPoint] {
        let today = calendar.startOfDay(for: now)
        let byDay = Dictionary(entries.map { ($0.day, $0) }, uniquingKeysWith: { a, _ in a })
        return (0..<max(0, days)).reversed().compactMap { back in
            guard let date = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return MoodPoint(date: date, score: byDay[dayKey(date)]?.mood.score)
        }
    }

    /// Your average mood score over the last `days` days, or nil if you didn't write in them.
    func average(days: Int = 7, now: Date = Date()) -> Double? {
        let scores = trend(days: days, now: now).compactMap(\.score)
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    /// How many days of each mood in the month that holds `date`.
    func moodCounts(inMonthOf date: Date) -> [JournalMood: Int] {
        let prefix = String(dayKey(date).prefix(7))
        var out: [JournalMood: Int] = [:]
        for e in entries where e.day.hasPrefix(prefix) { out[e.mood, default: 0] += 1 }
        return out
    }

    /// The tag that goes with your best days (highest average mood), once it's on at least
    /// `minDays` days and beats your overall average.
    func bestTag(minDays: Int = 2) -> (tag: String, average: Double)? {
        guard !entries.isEmpty else { return nil }
        let overall = Double(entries.reduce(0) { $0 + $1.mood.score }) / Double(entries.count)
        var best: (String, Double)?
        for tag in Self.tags {
            let scores = entries.filter { $0.tags.contains(tag) }.map(\.mood.score)
            guard scores.count >= minDays else { continue }
            let avg = Double(scores.reduce(0, +)) / Double(scores.count)
            guard avg > overall else { continue }
            if best == nil || avg > best!.1 { best = (tag, avg) }
        }
        return best.map { (tag: $0.0, average: $0.1) }
    }

    /// Entries whose words or tags contain `query` (all of them for an empty query).
    func search(_ query: String) -> [JournalEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { e in
            e.text.lowercased().contains(q)
                || e.tags.contains { $0.lowercased().contains(q) }
                || e.mood.label.lowercased() == q
        }
    }

    /// The cells for a month grid: nil for the blank squares before the 1st, then one date per day.
    func monthCells(for date: Date) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let count = calendar.range(of: .day, in: .month, for: date)?.count else { return [] }
        let first = interval.start
        let weekday = calendar.component(.weekday, from: first)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: blanks)
        for i in 0..<count {
            cells.append(calendar.date(byAdding: .day, value: i, to: first))
        }
        return cells
    }

    /// Short weekday names in the grid's order ("S", "M", ...).
    var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    // MARK: Saving

    private func persist() {
        guard let fileName else { return }
        Persistence.save(entries, to: fileName)
    }
}
