import Foundation
import SwiftUI

/// The colors a list can be.
enum ListTint: String, Codable, CaseIterable, Identifiable {
    case blue, purple, green, orange, pink, red

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .red: return "Red"
        }
    }

    var hexes: (UInt32, UInt32) {
        switch self {
        case .blue: return (0x6FD0FF, 0x3D6BFF)
        case .purple: return (0xC2A8FF, 0x7046FF)
        case .green: return (0x8CF0A8, 0x16A06A)
        case .orange: return (0xFFD27A, 0xFF7A2E)
        case .pink: return (0xFFAEDB, 0xFF4F9A)
        case .red: return (0xFF9B8A, 0xE0303E)
        }
    }

    var light: Color { Color(hex: hexes.0) }
    var dark: Color { Color(hex: hexes.1) }
    var gradient: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct ChecklistItem: Codable, Identifiable, Equatable {
    var id: UUID
    var text: String
    var done: Bool
}

/// A list of things to tick off, like a packing list or a morning routine.
struct Checklist: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var symbol: String
    var tint: ListTint
    var items: [ChecklistItem]
    var created: Date
    var updated: Date

    var doneCount: Int { items.filter(\.done).count }
    var isComplete: Bool { !items.isEmpty && doneCount == items.count }
    /// How much is ticked, from 0 to 1.
    var progress: Double { items.isEmpty ? 0 : Double(doneCount) / Double(items.count) }
}

/// A ready-made list to start from.
struct ChecklistTemplate: Identifiable, Equatable {
    let title: String
    let symbol: String
    let tint: ListTint
    let items: [String]
    var id: String { title }

    static let all: [ChecklistTemplate] = [
        ChecklistTemplate(title: "School bag", symbol: "backpack.fill", tint: .blue,
                          items: ["Homework", "Pencil case", "Books for today", "Water bottle", "Lunch", "iPad and charger"]),
        ChecklistTemplate(title: "Sleepover", symbol: "moon.stars.fill", tint: .purple,
                          items: ["Pajamas", "Toothbrush", "Toothpaste", "Clothes for tomorrow", "Pillow", "Phone charger", "Snacks"]),
        ChecklistTemplate(title: "Beach day", symbol: "sun.max.fill", tint: .orange,
                          items: ["Sunscreen", "Swimsuit", "Towel", "Sunglasses", "Hat", "Water", "Snacks", "Flip-flops"]),
        ChecklistTemplate(title: "Camping trip", symbol: "tent.fill", tint: .green,
                          items: ["Tent", "Sleeping bag", "Flashlight", "Bug spray", "Warm jacket", "Water bottle", "First aid kit", "Snacks"]),
        ChecklistTemplate(title: "Morning routine", symbol: "sunrise.fill", tint: .pink,
                          items: ["Make bed", "Brush teeth", "Get dressed", "Eat breakfast", "Pack bag"]),
        ChecklistTemplate(title: "Clean my room", symbol: "sparkles", tint: .red,
                          items: ["Pick up clothes", "Make bed", "Clear the desk", "Put toys and games away", "Take out trash", "Vacuum"])
    ]
}

/// Your lists. Everything stays on the iPad, in checklists.json.
@MainActor
final class ChecklistStore: ObservableObject {
    static let shared = ChecklistStore()

    nonisolated static let maxTitle = 40
    nonisolated static let maxItem = 80
    nonisolated static let maxItems = 200

    nonisolated static let symbols = [
        "checklist", "backpack.fill", "moon.stars.fill", "sun.max.fill", "tent.fill", "sunrise.fill",
        "sparkles", "cart.fill", "gift.fill", "airplane", "book.fill", "gamecontroller.fill",
        "fork.knife", "house.fill", "star.fill", "heart.fill", "graduationcap.fill", "pawprint.fill"
    ]

    @Published private(set) var lists: [Checklist] = []

    private let fileName: String?

    /// `fileName` nil keeps everything in memory (for tests).
    init(fileName: String? = "checklists.json") {
        self.fileName = fileName
        if let fileName, let saved = Persistence.load([Checklist].self, from: fileName) {
            lists = saved
        }
    }

    func list(_ id: UUID) -> Checklist? {
        lists.first { $0.id == id }
    }

    /// Lists with the most recently changed first.
    var sorted: [Checklist] {
        lists.sorted { $0.updated > $1.updated }
    }

    // MARK: Lists

    /// Makes a new list. A blank name becomes "List N".
    @discardableResult
    func create(title: String, symbol: String, tint: ListTint, items: [String] = [], now: Date = Date()) -> Checklist {
        let clean = Self.clip(title, Self.maxTitle)
        let list = Checklist(id: UUID(), title: clean.isEmpty ? nextTitle() : clean,
                             symbol: Self.symbols.contains(symbol) ? symbol : Self.symbols[0], tint: tint,
                             items: Self.cleanItems(items).map { ChecklistItem(id: UUID(), text: $0, done: false) },
                             created: now, updated: now)
        lists.append(list)
        persist()
        return list
    }

    @discardableResult
    func create(from template: ChecklistTemplate, now: Date = Date()) -> Checklist {
        create(title: template.title, symbol: template.symbol, tint: template.tint, items: template.items, now: now)
    }

    /// "List 1", "List 2" and so on, one more than the biggest number used so far.
    func nextTitle() -> String {
        let used = lists.compactMap { list -> Int? in
            guard list.title.hasPrefix("List ") else { return nil }
            return Int(list.title.dropFirst(5))
        }
        return "List \((used.max() ?? 0) + 1)"
    }

    /// Changes the name, icon and color. A blank name keeps the old one.
    func edit(_ id: UUID, title: String, symbol: String, tint: ListTint, now: Date = Date()) {
        change(id, now: now) { list in
            let clean = Self.clip(title, Self.maxTitle)
            if !clean.isEmpty { list.title = clean }
            if Self.symbols.contains(symbol) { list.symbol = symbol }
            list.tint = tint
        }
    }

    func delete(_ id: UUID) {
        lists.removeAll { $0.id == id }
        persist()
    }

    /// A copy with nothing ticked.
    @discardableResult
    func duplicate(_ id: UUID, now: Date = Date()) -> Checklist? {
        guard let list = list(id) else { return nil }
        let title = Self.clip(list.title + " copy", Self.maxTitle)
        return create(title: title, symbol: list.symbol, tint: list.tint, items: list.items.map(\.text), now: now)
    }

    // MARK: Items

    /// Adds items. Each line of the text becomes its own item, so you can paste a whole list.
    /// Returns how many were added.
    @discardableResult
    func add(_ text: String, to id: UUID, now: Date = Date()) -> Int {
        let lines = Self.cleanItems(text.components(separatedBy: .newlines))
        guard let list = list(id), !lines.isEmpty else { return 0 }
        let room = max(0, Self.maxItems - list.items.count)
        let adding = Array(lines.prefix(room))
        guard !adding.isEmpty else { return 0 }
        change(id, now: now) { list in
            // New things go above the ticked ones, so the to-do part stays together.
            let at = list.items.firstIndex(where: \.done) ?? list.items.count
            list.items.insert(contentsOf: adding.map { ChecklistItem(id: UUID(), text: $0, done: false) }, at: at)
        }
        return adding.count
    }

    /// Ticks or unticks an item. A ticked item sinks to the bottom; an unticked one rises above the ticked ones.
    func toggle(_ itemID: UUID, in id: UUID, now: Date = Date()) {
        change(id, now: now) { list in
            guard let i = list.items.firstIndex(where: { $0.id == itemID }) else { return }
            var item = list.items.remove(at: i)
            item.done.toggle()
            if item.done {
                list.items.append(item)
            } else {
                let at = list.items.firstIndex(where: \.done) ?? list.items.count
                list.items.insert(item, at: at)
            }
        }
    }

    /// Changes an item's words. Blank words delete it.
    func rename(_ itemID: UUID, in id: UUID, to text: String, now: Date = Date()) {
        let clean = Self.clip(text, Self.maxItem)
        change(id, now: now) { list in
            guard let i = list.items.firstIndex(where: { $0.id == itemID }) else { return }
            if clean.isEmpty {
                list.items.remove(at: i)
            } else {
                list.items[i].text = clean
            }
        }
    }

    func remove(_ itemID: UUID, from id: UUID, now: Date = Date()) {
        change(id, now: now) { list in list.items.removeAll { $0.id == itemID } }
    }

    func move(in id: UUID, from source: IndexSet, to destination: Int, now: Date = Date()) {
        change(id, now: now) { list in list.items.move(fromOffsets: source, toOffset: destination) }
    }

    /// Unticks everything, so a packing list is ready for next time.
    func reset(_ id: UUID, now: Date = Date()) {
        change(id, now: now) { list in
            for i in list.items.indices { list.items[i].done = false }
        }
    }

    /// Deletes every ticked item.
    func clearDone(_ id: UUID, now: Date = Date()) {
        change(id, now: now) { list in list.items.removeAll(where: \.done) }
    }

    // MARK: Helpers

    nonisolated static func clip(_ text: String, _ limit: Int) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trims each line, drops bullets like "-" or "•" at the start, and skips blank lines.
    nonisolated static func cleanItems(_ lines: [String]) -> [String] {
        lines.compactMap { line in
            var text = line.trimmingCharacters(in: .whitespaces)
            for bullet in ["- ", "• ", "* ", "[ ] ", "[x] "] where text.lowercased().hasPrefix(bullet) {
                text = String(text.dropFirst(bullet.count))
            }
            let clean = clip(text, maxItem)
            return clean.isEmpty ? nil : clean
        }
    }

    private func change(_ id: UUID, now: Date, _ body: (inout Checklist) -> Void) {
        guard let i = lists.firstIndex(where: { $0.id == id }) else { return }
        var list = lists[i]
        body(&list)
        guard list != lists[i] else { return }
        list.updated = now
        lists[i] = list
        persist()
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(lists, to: fileName)
    }
}
