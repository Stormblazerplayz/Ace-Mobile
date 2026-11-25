import Foundation

/// A wheel of choices to spin.
struct DecideWheel: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var options: [String]
}

/// The math behind Pick for me: where a spinning wheel stops and which slice wins, coin flips,
/// dice and splitting people into teams. Everything takes a random number generator, so tests can
/// use a fixed one.
enum DecideMath {
    /// The wheel's slices start at the top (where the pointer is) and go clockwise. Turning the wheel
    /// clockwise by `rotation` degrees puts this slice under the pointer.
    static func winner(rotation: Double, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let slice = 360 / Double(count)
        let atPointer = positive(-rotation)
        return min(count - 1, Int(atPointer / slice))
    }

    /// Picks a winning slice and works out the rotation to stop on it, after a few full turns.
    /// The wheel lands somewhere inside the slice, never right on a line.
    static func spin<G: RandomNumberGenerator>(from rotation: Double, count: Int, turns: Int = 5,
                                               using rng: inout G) -> (rotation: Double, winner: Int) {
        guard count > 0 else { return (rotation, 0) }
        let slice = 360 / Double(count)
        let winner = Int.random(in: 0..<count, using: &rng)
        let inside = Double.random(in: 0.15...0.85, using: &rng)
        let target = (Double(winner) + inside) * slice
        // We need -final ≡ target (mod 360).
        let extra = positive(-target - rotation)
        return (rotation + Double(max(1, turns)) * 360 + extra, winner)
    }

    /// Rolls `count` six-sided dice.
    static func roll<G: RandomNumberGenerator>(_ count: Int, using rng: inout G) -> [Int] {
        (0..<max(0, count)).map { _ in Int.random(in: 1...6, using: &rng) }
    }

    /// Splits names into teams as evenly as possible, in a random order.
    static func teams<G: RandomNumberGenerator>(_ names: [String], into count: Int, using rng: inout G) -> [[String]] {
        let people = cleanNames(names)
        let k = max(1, min(count, max(1, people.count)))
        var shuffled = people
        shuffled.shuffle(using: &rng)
        var result = Array(repeating: [String](), count: k)
        for (i, name) in shuffled.enumerated() { result[i % k].append(name) }
        return result
    }

    /// One name per line, trimmed, no blanks, no repeats (ignoring capitals).
    static func cleanNames(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for line in lines {
            let name = String(line.trimmingCharacters(in: .whitespacesAndNewlines).prefix(DecideStore.maxOption))
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            out.append(name)
        }
        return out
    }

    static func positive(_ angle: Double) -> Double {
        let r = angle.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }
}

/// Saved wheels and the last few results. Everything stays on the iPad, in decide.json.
@MainActor
final class DecideStore: ObservableObject {
    static let shared = DecideStore()

    nonisolated static let maxOption = 30
    nonisolated static let maxOptions = 16
    nonisolated static let maxHistory = 12

    /// Wheels you can start from.
    nonisolated static let starters: [(title: String, options: [String])] = [
        ("What's for dinner?", ["Pizza", "Tacos", "Pasta", "Burgers", "Sushi", "Soup"]),
        ("Yes or no?", ["Yes", "No", "Maybe", "Ask again"]),
        ("What should I do?", ["Read", "Draw", "Go outside", "Build something", "Play a game", "Help at home"]),
        ("Movie night", ["Comedy", "Action", "Animated", "Adventure", "Mystery"])
    ]

    private struct Saved: Codable {
        var wheels: [DecideWheel]
        var history: [String]
    }

    @Published private(set) var wheels: [DecideWheel] = []
    @Published private(set) var history: [String] = []

    private let fileName: String?

    /// `fileName` nil keeps everything in memory (for tests). A first run starts with the starter wheels.
    init(fileName: String? = "decide.json") {
        self.fileName = fileName
        if let fileName, let saved = Persistence.load(Saved.self, from: fileName) {
            wheels = saved.wheels
            history = saved.history
        } else {
            wheels = Self.starters.map { DecideWheel(id: UUID(), title: $0.title, options: $0.options) }
        }
    }

    func wheel(_ id: UUID) -> DecideWheel? {
        wheels.first { $0.id == id }
    }

    /// Makes a new wheel. Returns nil without at least two different options.
    @discardableResult
    func add(title: String, options: [String]) -> DecideWheel? {
        let clean = Self.cleanOptions(options)
        guard clean.count >= 2 else { return nil }
        let name = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        let wheel = DecideWheel(id: UUID(), title: name.isEmpty ? "My wheel" : name, options: clean)
        wheels.append(wheel)
        persist()
        return wheel
    }

    /// Saves new options for a wheel. Needs at least two.
    @discardableResult
    func setOptions(_ id: UUID, _ options: [String]) -> Bool {
        let clean = Self.cleanOptions(options)
        guard clean.count >= 2, let i = wheels.firstIndex(where: { $0.id == id }) else { return false }
        wheels[i].options = clean
        persist()
        return true
    }

    func rename(_ id: UUID, to title: String) {
        let name = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        guard !name.isEmpty, let i = wheels.firstIndex(where: { $0.id == id }) else { return }
        wheels[i].title = name
        persist()
    }

    func delete(_ id: UUID) {
        wheels.removeAll { $0.id == id }
        persist()
    }

    /// Remembers a result, newest first.
    func remember(_ result: String) {
        let clean = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        history.insert(clean, at: 0)
        if history.count > Self.maxHistory { history.removeLast(history.count - Self.maxHistory) }
        persist()
    }

    func clearHistory() {
        history = []
        persist()
    }

    /// Trims options, drops blanks and repeats, and keeps at most 16.
    nonisolated static func cleanOptions(_ options: [String]) -> [String] {
        Array(DecideMath.cleanNames(options).prefix(maxOptions))
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(Saved(wheels: wheels, history: history), to: fileName)
    }
}
