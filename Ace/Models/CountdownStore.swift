import Foundation
import SwiftUI

/// The colors a countdown's card can be.
enum CountdownTheme: String, Codable, CaseIterable, Identifiable {
    case sunset, ocean, galaxy, forest, candy, fire

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .galaxy: return "Galaxy"
        case .forest: return "Forest"
        case .candy: return "Candy"
        case .fire: return "Fire"
        }
    }

    /// Three hex colors for the card's gradient.
    var hexes: [UInt32] {
        switch self {
        case .sunset: return [0xFFCF3A, 0xFF8A3D, 0xFF5F8F]
        case .ocean: return [0x1BC6FF, 0x5BB6FF, 0x3D5AFE]
        case .galaxy: return [0x8F7CFF, 0x5A3DB8, 0x1B1F5E]
        case .forest: return [0x45D483, 0x1FA67A, 0x0E6B5C]
        case .candy: return [0xFF9CE0, 0xFF5F8F, 0xB86BFF]
        case .fire: return [0xFFB020, 0xFF5A4E, 0xB3123A]
        }
    }

    var colors: [Color] { hexes.map { Color(hex: $0) } }
    var color: Color { Color(hex: hexes[1]) }
    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Something you're counting down to: a birthday, a trip, a holiday, a game coming out.
struct Countdown: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    /// The day (and time, unless it's all day) it happens.
    var date: Date
    /// All-day countdowns count down to the start of the day.
    var allDay: Bool
    /// Birthdays and holidays come back every year.
    var repeatsYearly: Bool
    var symbol: String
    var theme: CountdownTheme
    var created: Date
}

/// How long until a countdown, in days, hours, minutes and seconds.
struct CountdownLeft: Equatable {
    var days: Int
    var hours: Int
    var minutes: Int
    var seconds: Int

    static let zero = CountdownLeft(days: 0, hours: 0, minutes: 0, seconds: 0)

    var isZero: Bool { self == .zero }

    /// A short way to say it, like "12 days", "5 hours" or "40 minutes".
    var short: String {
        if days > 0 { return days == 1 ? "1 day" : "\(days) days" }
        if hours > 0 { return hours == 1 ? "1 hour" : "\(hours) hours" }
        if minutes > 0 { return minutes == 1 ? "1 minute" : "\(minutes) minutes" }
        return seconds == 1 ? "1 second" : "\(seconds) seconds"
    }
}

/// Holidays you can add with one tap. Each one comes back every year.
struct CountdownPreset: Identifiable, Equatable {
    let title: String
    let month: Int
    let day: Int
    let symbol: String
    let theme: CountdownTheme

    var id: String { title }

    static let all: [CountdownPreset] = [
        CountdownPreset(title: "New Year's Day", month: 1, day: 1, symbol: "sparkles", theme: .galaxy),
        CountdownPreset(title: "Valentine's Day", month: 2, day: 14, symbol: "heart.fill", theme: .candy),
        CountdownPreset(title: "April Fools' Day", month: 4, day: 1, symbol: "face.smiling.inverse", theme: .sunset),
        CountdownPreset(title: "Halloween", month: 10, day: 31, symbol: "moon.stars.fill", theme: .fire),
        CountdownPreset(title: "Christmas", month: 12, day: 25, symbol: "gift.fill", theme: .forest),
        CountdownPreset(title: "New Year's Eve", month: 12, day: 31, symbol: "party.popper.fill", theme: .ocean)
    ]
}

/// Your countdowns. Each one knows when it next happens (birthdays and holidays roll on to next
/// year once they've passed) and how long is left. Everything stays on the iPad, in countdowns.json.
@MainActor
final class CountdownStore: ObservableObject {
    static let shared = CountdownStore()

    nonisolated static let maxTitle = 40

    /// Icons you can give a countdown.
    nonisolated static let symbols = [
        "gift.fill", "birthday.cake.fill", "airplane", "star.fill", "graduationcap.fill", "sparkles",
        "party.popper.fill", "tree.fill", "sun.max.fill", "snowflake", "heart.fill", "trophy.fill",
        "ticket.fill", "music.note", "camera.fill", "figure.run", "book.fill", "house.fill",
        "moon.stars.fill", "face.smiling.inverse"
    ]

    @Published private(set) var countdowns: [Countdown] = []

    private let fileName: String?
    nonisolated let calendar: Calendar

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "countdowns.json", calendar: Calendar? = nil) {
        self.fileName = fileName
        if let calendar {
            self.calendar = calendar
        } else {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = .current
            self.calendar = cal
        }
        if let fileName, let saved = Persistence.load([Countdown].self, from: fileName) {
            countdowns = saved
        }
    }

    // MARK: Adding and changing

    /// Adds a countdown. Returns nil for a blank name, or a one-time date that's already over.
    @discardableResult
    func add(title: String, date: Date, allDay: Bool, repeatsYearly: Bool, symbol: String, theme: CountdownTheme,
             now: Date = Date()) -> Countdown? {
        let clean = Self.clip(title)
        guard !clean.isEmpty else { return nil }
        let item = Countdown(id: UUID(), title: clean, date: date, allDay: allDay, repeatsYearly: repeatsYearly,
                             symbol: Self.symbols.contains(symbol) ? symbol : Self.symbols[0], theme: theme, created: now)
        guard repeatsYearly || !isOver(item, now: now) else { return nil }
        countdowns.append(item)
        persist()
        return item
    }

    /// Saves changes to a countdown. A blank name keeps the old one.
    func update(_ item: Countdown) {
        guard let i = countdowns.firstIndex(where: { $0.id == item.id }) else { return }
        var changed = item
        let clean = Self.clip(item.title)
        changed.title = clean.isEmpty ? countdowns[i].title : clean
        if !Self.symbols.contains(changed.symbol) { changed.symbol = countdowns[i].symbol }
        countdowns[i] = changed
        persist()
    }

    func delete(_ id: UUID) {
        countdowns.removeAll { $0.id == id }
        persist()
    }

    /// Adds a holiday that comes back every year, unless it's already there.
    @discardableResult
    func add(_ preset: CountdownPreset, now: Date = Date()) -> Countdown? {
        guard !has(preset) else { return nil }
        let year = calendar.component(.year, from: now)
        guard let date = calendar.date(from: DateComponents(year: year, month: preset.month, day: preset.day)) else { return nil }
        return add(title: preset.title, date: date, allDay: true, repeatsYearly: true, symbol: preset.symbol, theme: preset.theme, now: now)
    }

    /// True when you already count down to that holiday.
    func has(_ preset: CountdownPreset) -> Bool {
        countdowns.contains { c in
            c.repeatsYearly && c.allDay
                && calendar.component(.month, from: c.date) == preset.month
                && calendar.component(.day, from: c.date) == preset.day
        }
    }

    // MARK: Timing

    /// How long a countdown's moment lasts: all of its day, or an hour for one with a time.
    func window(_ item: Countdown) -> TimeInterval {
        item.allDay ? 86_400 : 3_600
    }

    /// The moment it counts down to next. One that repeats every year moves on to next year
    /// once its day (or hour) is over.
    func occurrence(_ item: Countdown, now: Date = Date()) -> Date {
        guard item.repeatsYearly else { return start(of: item.date, allDay: item.allDay) }
        let parts = calendar.dateComponents([.month, .day, .hour, .minute], from: item.date)
        let thisYear = calendar.component(.year, from: now)
        for year in (thisYear - 1)...(thisYear + 2) {
            guard let moment = moment(year: year, parts: parts, allDay: item.allDay) else { continue }
            if moment.addingTimeInterval(window(item)) > now { return moment }
        }
        return start(of: item.date, allDay: item.allDay)
    }

    /// True while it's happening: during its day, or the hour after its time.
    func isHappening(_ item: Countdown, now: Date = Date()) -> Bool {
        let moment = occurrence(item, now: now)
        return now >= moment && now < moment.addingTimeInterval(window(item))
    }

    /// True for a one-time countdown whose day (or hour) is over.
    func isOver(_ item: Countdown, now: Date = Date()) -> Bool {
        guard !item.repeatsYearly else { return false }
        return occurrence(item, now: now).addingTimeInterval(window(item)) <= now
    }

    /// Time left until it happens (zero while it's happening or once it's over).
    func left(_ item: Countdown, now: Date = Date()) -> CountdownLeft {
        let moment = occurrence(item, now: now)
        guard moment > now else { return .zero }
        let parts = calendar.dateComponents([.day, .hour, .minute, .second], from: now, to: moment)
        return CountdownLeft(days: max(0, parts.day ?? 0), hours: max(0, parts.hour ?? 0),
                             minutes: max(0, parts.minute ?? 0), seconds: max(0, parts.second ?? 0))
    }

    /// How far along the wait is, from 0 (just added, or just after last time) to 1 (it's here).
    func progress(_ item: Countdown, now: Date = Date()) -> Double {
        let moment = occurrence(item, now: now)
        var begin = item.created
        if item.repeatsYearly, let lastTime = calendar.date(byAdding: .year, value: -1, to: moment), lastTime > begin {
            begin = lastTime
        }
        let total = moment.timeIntervalSince(begin)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(begin) / total))
    }

    /// Countdowns still to come (and ones happening now), soonest first.
    func upcoming(now: Date = Date()) -> [Countdown] {
        countdowns
            .filter { !isOver($0, now: now) }
            .sorted { occurrence($0, now: now) < occurrence($1, now: now) }
    }

    /// One-time countdowns that are over, most recent first.
    func past(now: Date = Date()) -> [Countdown] {
        countdowns
            .filter { isOver($0, now: now) }
            .sorted { $0.date > $1.date }
    }

    // MARK: Helpers

    nonisolated static func clip(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxTitle))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func start(of date: Date, allDay: Bool) -> Date {
        allDay ? calendar.startOfDay(for: date) : date
    }

    /// The date in a given year. February 29 becomes February 28 in years without it.
    private func moment(year: Int, parts: DateComponents, allDay: Bool) -> Date? {
        guard let month = parts.month, var day = parts.day else { return nil }
        var want = DateComponents(year: year, month: month, day: 1)
        guard let first = calendar.date(from: want),
              let days = calendar.range(of: .day, in: .month, for: first)?.count else { return nil }
        day = min(day, days)
        want.day = day
        if !allDay {
            want.hour = parts.hour
            want.minute = parts.minute
        }
        return calendar.date(from: want)
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(countdowns, to: fileName)
    }
}
