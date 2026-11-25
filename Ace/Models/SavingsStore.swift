import Foundation
import SwiftUI

/// A color a savings jar can be.
enum SavingsColor: String, Codable, CaseIterable, Identifiable {
    case gold, mint, sky, grape, rose, flame

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gold: return "Gold"
        case .mint: return "Mint"
        case .sky: return "Sky"
        case .grape: return "Grape"
        case .rose: return "Rose"
        case .flame: return "Flame"
        }
    }

    /// Light and dark ends of the color.
    var hexes: (UInt32, UInt32) {
        switch self {
        case .gold: return (0xFFE38A, 0xF5A623)
        case .mint: return (0x8CF5C2, 0x17B27C)
        case .sky: return (0x8FD8FF, 0x3D7BFF)
        case .grape: return (0xC3B4FF, 0x6B4DFF)
        case .rose: return (0xFFB1CC, 0xFF4F86)
        case .flame: return (0xFFC07A, 0xFF5A3D)
        }
    }

    var light: Color { Color(hex: hexes.0) }
    var dark: Color { Color(hex: hexes.1) }
    var gradient: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .top, endPoint: .bottom)
    }
}

/// Money going into a jar (positive) or taken out (negative), in cents.
struct SavingsEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var cents: Int
    var date: Date
    var note: String
}

/// Something you're saving up for, like a bike or a game.
struct SavingsGoal: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var symbol: String
    var color: SavingsColor
    var targetCents: Int
    var created: Date
    var entries: [SavingsEntry]

    /// What's in the jar now.
    var savedCents: Int { max(0, entries.reduce(0) { $0 + $1.cents }) }
    /// How much is still needed.
    var leftCents: Int { max(0, targetCents - savedCents) }
    var isReached: Bool { targetCents > 0 && savedCents >= targetCents }
    /// 0 to 1.
    var progress: Double {
        guard targetCents > 0 else { return 0 }
        return min(1, Double(savedCents) / Double(targetCents))
    }
}

/// A ready-made goal name and icon. You type how much it costs.
struct SavingsIdea: Identifiable, Equatable {
    let title: String
    let symbol: String
    let color: SavingsColor
    var id: String { title }

    static let all: [SavingsIdea] = [
        SavingsIdea(title: "New bike", symbol: "bicycle", color: .sky),
        SavingsIdea(title: "Video game", symbol: "gamecontroller.fill", color: .grape),
        SavingsIdea(title: "Lego set", symbol: "cube.fill", color: .flame),
        SavingsIdea(title: "Gift for someone", symbol: "gift.fill", color: .rose),
        SavingsIdea(title: "Headphones", symbol: "headphones", color: .mint),
        SavingsIdea(title: "Rainy day", symbol: "umbrella.fill", color: .gold)
    ]
}

/// Turning cents into money text and typed money back into cents.
enum SavingsMoney {
    /// "$12.50" (or the iPad's own currency). Whole amounts drop the cents: "$20".
    static func text(_ cents: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        if cents % 100 == 0 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        let value = NSDecimalNumber(value: cents).dividing(by: 100)
        return formatter.string(from: value) ?? "\(Double(cents) / 100)"
    }

    /// Reads what you typed, like "12", "12.5", "$12.50" or "12,50", as cents. Nil when it isn't
    /// a money amount above zero, has more than two digits after the point, or is too big.
    static func cents(from typed: String) -> Int? {
        var text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        text = String(text.filter { !$0.isWhitespace && !"$£€¥".contains($0) })
        guard !text.isEmpty else { return nil }
        // A single comma with one or two digits after it is a decimal point ("12,50").
        if !text.contains("."), let comma = text.lastIndex(of: ","),
           text.filter({ $0 == "," }).count == 1, (1...2).contains(text.distance(from: comma, to: text.endIndex) - 1) {
            text.replaceSubrange(comma...comma, with: ".")
        }
        // Other commas are thousands separators ("1,250.00").
        text = text.replacingOccurrences(of: ",", with: "")
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, parts.allSatisfy({ $0.allSatisfy(\.isNumber) && $0.allSatisfy(\.isASCII) }) else { return nil }
        let whole = parts[0]
        let fraction = parts.count == 2 ? parts[1] : ""
        guard !(whole.isEmpty && fraction.isEmpty), fraction.count <= 2, whole.count <= 7 else { return nil }
        let dollars = Int(whole) ?? 0
        let paddedFraction = String(fraction) + (fraction.count == 1 ? "0" : "")
        let cents = dollars * 100 + (Int(paddedFraction) ?? 0)
        guard cents > 0, cents <= SavingsStore.maxCents else { return nil }
        return cents
    }
}

/// Savings jars: goals, the money you put in and take out, and how fast you're saving.
/// Everything stays on the iPad, in savings.json.
@MainActor
final class SavingsStore: ObservableObject {
    static let shared = SavingsStore()

    /// The biggest goal or jar: 999,999.99.
    nonisolated static let maxCents = 99_999_999
    nonisolated static let maxTitle = 40
    nonisolated static let maxNote = 60
    /// Buttons for quick deposits: 1, 5, 10 and 20.
    nonisolated static let quickAmounts = [100, 500, 1000, 2000]
    nonisolated static let symbols = [
        "star.fill", "bicycle", "gamecontroller.fill", "cube.fill", "gift.fill", "headphones",
        "umbrella.fill", "airplane", "sportscourt.fill", "book.fill", "pawprint.fill", "music.note",
        "camera.fill", "tshirt.fill", "skateboard", "laptopcomputer", "heart.fill", "crown.fill"
    ]

    @Published private(set) var goals: [SavingsGoal] = []

    private let fileName: String?
    nonisolated let calendar: Calendar

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "savings.json", calendar: Calendar = .current) {
        self.fileName = fileName
        self.calendar = calendar
        if let fileName, let saved = Persistence.load([SavingsGoal].self, from: fileName) {
            goals = saved
        }
    }

    func goal(_ id: UUID) -> SavingsGoal? {
        goals.first { $0.id == id }
    }

    /// Everything in every jar.
    var totalSaved: Int { goals.reduce(0) { $0 + $1.savedCents } }

    /// Goals still being saved for first, then the ones you reached.
    var sorted: [SavingsGoal] {
        goals.filter { !$0.isReached } + goals.filter(\.isReached)
    }

    /// Makes a new goal. Needs a name and a price above zero.
    @discardableResult
    func add(title: String, targetCents: Int, symbol: String, color: SavingsColor, now: Date = Date()) -> SavingsGoal? {
        let name = Self.clip(title, Self.maxTitle)
        guard !name.isEmpty, targetCents > 0 else { return nil }
        let goal = SavingsGoal(id: UUID(), title: name, symbol: Self.symbols.contains(symbol) ? symbol : Self.symbols[0],
                               color: color, targetCents: min(targetCents, Self.maxCents), created: now, entries: [])
        goals.append(goal)
        persist()
        return goal
    }

    /// Changes a goal's name, price, icon and color. A blank name or a zero price is ignored.
    func edit(_ id: UUID, title: String, targetCents: Int, symbol: String, color: SavingsColor) {
        guard let i = goals.firstIndex(where: { $0.id == id }) else { return }
        let name = Self.clip(title, Self.maxTitle)
        if !name.isEmpty { goals[i].title = name }
        if targetCents > 0 { goals[i].targetCents = min(targetCents, Self.maxCents) }
        if Self.symbols.contains(symbol) { goals[i].symbol = symbol }
        goals[i].color = color
        persist()
    }

    func delete(_ id: UUID) {
        goals.removeAll { $0.id == id }
        persist()
    }

    /// Puts money in. Returns how much went in (a jar can't go over 999,999.99).
    @discardableResult
    func deposit(_ id: UUID, cents: Int, note: String = "", now: Date = Date()) -> Int {
        guard cents > 0, let i = goals.firstIndex(where: { $0.id == id }) else { return 0 }
        let room = Self.maxCents - goals[i].savedCents
        let amount = min(cents, room)
        guard amount > 0 else { return 0 }
        goals[i].entries.append(SavingsEntry(id: UUID(), cents: amount, date: now, note: Self.clip(note, Self.maxNote)))
        persist()
        return amount
    }

    /// Takes money out. You can't take out more than is in the jar. Returns how much came out.
    @discardableResult
    func withdraw(_ id: UUID, cents: Int, note: String = "", now: Date = Date()) -> Int {
        guard cents > 0, let i = goals.firstIndex(where: { $0.id == id }) else { return 0 }
        let amount = min(cents, goals[i].savedCents)
        guard amount > 0 else { return 0 }
        goals[i].entries.append(SavingsEntry(id: UUID(), cents: -amount, date: now, note: Self.clip(note, Self.maxNote)))
        persist()
        return amount
    }

    /// Removes one entry, like a deposit typed by mistake.
    func removeEntry(_ goalID: UUID, entry: UUID) {
        guard let i = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[i].entries.removeAll { $0.id == entry }
        persist()
    }

    /// Money saved in each of the last `weeks` weeks (in minus out), oldest week first.
    func weekly(_ id: UUID, weeks: Int, now: Date = Date()) -> [Int] {
        guard weeks > 0, let goal = self.goal(id),
              let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return (0..<weeks).map { i in
            let back = weeks - 1 - i
            guard let start = calendar.date(byAdding: .weekOfYear, value: -back, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return 0 }
            return goal.entries.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.cents }
        }
    }

    /// When you'd reach the goal if you keep saving like the last 4 weeks. Nil when it's reached
    /// or nothing was saved lately.
    func estimate(_ id: UUID, now: Date = Date()) -> Date? {
        guard let goal = self.goal(id), !goal.isReached,
              let from = calendar.date(byAdding: .day, value: -28, to: now) else { return nil }
        let recent = goal.entries.filter { $0.date > from && $0.date <= now }.reduce(0) { $0 + $1.cents }
        guard recent > 0 else { return nil }
        let perDay = Double(recent) / 28
        let days = Int((Double(goal.leftCents) / perDay).rounded(.up))
        guard days <= 3650 else { return nil }
        return calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now))
    }

    nonisolated static func clip(_ text: String, _ limit: Int) -> String {
        let oneLine = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return String(oneLine.prefix(limit))
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(goals, to: fileName)
    }
}
