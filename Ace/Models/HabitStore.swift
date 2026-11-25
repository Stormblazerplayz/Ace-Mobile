import Foundation
import SwiftUI

/// A colour a habit can be.
enum HabitColor: String, Codable, CaseIterable, Identifiable {
    case sky, grape, mint, sun, rose, flame

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sky: return "Sky"
        case .grape: return "Grape"
        case .mint: return "Mint"
        case .sun: return "Sun"
        case .rose: return "Rose"
        case .flame: return "Flame"
        }
    }

    /// Light and dark ends of the colour.
    var hexes: (UInt32, UInt32) {
        switch self {
        case .sky: return (0x7FD3FF, 0x3D7BFF)
        case .grape: return (0xB9A8FF, 0x6B4DFF)
        case .mint: return (0x7FF0B5, 0x14A877)
        case .sun: return (0xFFE07A, 0xFFA21F)
        case .rose: return (0xFFA3C4, 0xFF4F86)
        case .flame: return (0xFFB36B, 0xFF4A3D)
        }
    }

    var light: Color { Color(hex: hexes.0) }
    var dark: Color { Color(hex: hexes.1) }
    var gradient: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .top, endPoint: .bottom)
    }
}

/// Something you want to do every day, maybe more than once (like 8 glasses of water).
struct Habit: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var symbol: String
    var color: HabitColor
    /// How many times a day counts as done (1 to 12).
    var goal: Int
    var created: Date
}

/// A ready-made habit you can add with one tap.
struct HabitIdea: Identifiable, Equatable {
    let title: String
    let symbol: String
    let color: HabitColor
    let goal: Int
    var id: String { title }

    static let all: [HabitIdea] = [
        HabitIdea(title: "Drink water", symbol: "drop.fill", color: .sky, goal: 8),
        HabitIdea(title: "Read", symbol: "book.fill", color: .grape, goal: 1),
        HabitIdea(title: "Homework", symbol: "pencil.and.ruler.fill", color: .sun, goal: 1),
        HabitIdea(title: "Brush teeth", symbol: "mouth.fill", color: .mint, goal: 2),
        HabitIdea(title: "Exercise", symbol: "figure.run", color: .flame, goal: 1),
        HabitIdea(title: "Stretch", symbol: "figure.cooldown", color: .rose, goal: 1),
        HabitIdea(title: "Make my bed", symbol: "bed.double.fill", color: .grape, goal: 1),
        HabitIdea(title: "Go outside", symbol: "sun.max.fill", color: .sun, goal: 1)
    ]
}

private struct HabitFile: Codable {
    var habits: [Habit]
    /// Habit id → day ("2026-11-25") → how many times it was done that day.
    var checks: [UUID: [String: Int]]
}

/// Your habits and every tick you've given them. Works out streaks, the week's dots and the
/// day's progress. Everything stays on the iPad, in habits.json.
@MainActor
final class HabitStore: ObservableObject {
    static let shared = HabitStore()

    nonisolated static let maxTitle = 40
    nonisolated static let maxGoal = 12

    nonisolated static let symbols = [
        "drop.fill", "book.fill", "pencil.and.ruler.fill", "mouth.fill", "figure.run", "figure.cooldown",
        "bed.double.fill", "sun.max.fill", "leaf.fill", "brain.head.profile", "pawprint.fill", "fork.knife",
        "moon.zzz.fill", "heart.fill", "star.fill", "dumbbell.fill", "bicycle", "checkmark.seal.fill"
    ]

    @Published private(set) var habits: [Habit] = []
    @Published private(set) var checks: [UUID: [String: Int]] = [:]

    private let fileName: String?
    nonisolated let calendar: Calendar

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "habits.json", calendar: Calendar? = nil) {
        self.fileName = fileName
        if let calendar {
            self.calendar = calendar
        } else {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = .current
            self.calendar = cal
        }
        if let fileName, let saved = Persistence.load(HabitFile.self, from: fileName) {
            habits = saved.habits
            checks = saved.checks
        }
    }

    // MARK: Habits

    /// Adds a habit. Returns nil for a blank name or a name you already have.
    @discardableResult
    func add(title: String, symbol: String, color: HabitColor, goal: Int, now: Date = Date()) -> Habit? {
        let clean = Self.clip(title)
        guard !clean.isEmpty, !has(clean) else { return nil }
        let habit = Habit(id: UUID(), title: clean, symbol: Self.symbols.contains(symbol) ? symbol : Self.symbols[0],
                          color: color, goal: Self.clampGoal(goal), created: now)
        habits.append(habit)
        persist()
        return habit
    }

    @discardableResult
    func add(_ idea: HabitIdea, now: Date = Date()) -> Habit? {
        add(title: idea.title, symbol: idea.symbol, color: idea.color, goal: idea.goal, now: now)
    }

    /// True when a habit already has that name (ignoring capitals).
    func has(_ title: String, except id: UUID? = nil) -> Bool {
        let key = Self.clip(title).lowercased()
        return habits.contains { $0.id != id && $0.title.lowercased() == key }
    }

    /// Saves changes. A blank or taken name keeps the old one.
    func update(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        var changed = habit
        let clean = Self.clip(habit.title)
        changed.title = (clean.isEmpty || has(clean, except: habit.id)) ? habits[i].title : clean
        if !Self.symbols.contains(changed.symbol) { changed.symbol = habits[i].symbol }
        changed.goal = Self.clampGoal(changed.goal)
        habits[i] = changed
        persist()
    }

    func delete(_ id: UUID) {
        habits.removeAll { $0.id == id }
        checks[id] = nil
        persist()
    }

    /// Moves a habit up or down the list.
    func move(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    // MARK: Ticking

    /// How many times it was done on that day.
    func count(_ habit: Habit, on date: Date) -> Int {
        checks[habit.id]?[dayKey(date)] ?? 0
    }

    func isDone(_ habit: Habit, on date: Date) -> Bool {
        count(habit, on: date) >= habit.goal
    }

    /// One more tick for today. Once it's done, a tap starts it over from zero.
    /// Returns true when this tap finished it.
    @discardableResult
    func tap(_ habit: Habit, now: Date = Date()) -> Bool {
        let now0 = count(habit, on: now)
        let next = now0 >= habit.goal ? 0 : now0 + 1
        set(habit, count: next, on: now)
        return next == habit.goal
    }

    /// Takes one tick away from today.
    func undo(_ habit: Habit, now: Date = Date()) {
        set(habit, count: max(0, count(habit, on: now) - 1), on: now)
    }

    private func set(_ habit: Habit, count: Int, on date: Date) {
        var days = checks[habit.id] ?? [:]
        days[dayKey(date)] = count > 0 ? count : nil
        checks[habit.id] = days.isEmpty ? nil : days
        persist()
    }

    // MARK: Streaks and progress

    /// Days in a row it was done, counting today if it's done, or up to yesterday if today isn't done yet.
    func streak(_ habit: Habit, now: Date = Date()) -> Int {
        var day = calendar.startOfDay(for: now)
        if !isDone(habit, on: day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var run = 0
        while isDone(habit, on: day) {
            run += 1
            guard let before = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = before
        }
        return run
    }

    /// The longest run of days it was ever done.
    func bestStreak(_ habit: Habit) -> Int {
        let done = (checks[habit.id] ?? [:]).filter { $0.value >= habit.goal }.keys.compactMap { date(fromKey: $0) }.sorted()
        var best = 0
        var run = 0
        var last: Date?
        for day in done {
            if let last, let next = calendar.date(byAdding: .day, value: 1, to: last), calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            last = day
        }
        return best
    }

    /// The last 7 days, oldest first, ending today: true where it was done.
    func week(_ habit: Habit, now: Date = Date()) -> [Bool] {
        lastDays(7, now: now).map { isDone(habit, on: $0) }
    }

    /// The last `count` days, oldest first, ending today.
    func lastDays(_ count: Int, now: Date = Date()) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<max(0, count)).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    /// How much of the day's habits are done, from 0 to 1. Each habit counts its ticks toward its goal.
    func todayProgress(now: Date = Date()) -> Double {
        guard !habits.isEmpty else { return 0 }
        let total = habits.reduce(0.0) { sum, h in sum + min(1, Double(count(h, on: now)) / Double(h.goal)) }
        return total / Double(habits.count)
    }

    func doneToday(now: Date = Date()) -> Int {
        habits.filter { isDone($0, on: now) }.count
    }

    /// How much of all habits was done on a day, from 0 to 1, for the heat map.
    /// Habits that didn't exist yet that day don't count.
    func dayScore(_ date: Date) -> Double {
        let end = calendar.startOfDay(for: date).addingTimeInterval(86_400)
        let alive = habits.filter { $0.created < end }
        guard !alive.isEmpty else { return 0 }
        let done = alive.filter { isDone($0, on: date) }.count
        return Double(done) / Double(alive.count)
    }

    // MARK: Helpers

    nonisolated static func clip(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxTitle))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func clampGoal(_ goal: Int) -> Int {
        min(maxGoal, max(1, goal))
    }

    func dayKey(_ date: Date) -> String {
        let p = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", p.year ?? 0, p.month ?? 0, p.day ?? 0)
    }

    private func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(HabitFile(habits: habits, checks: checks), to: fileName)
    }
}
