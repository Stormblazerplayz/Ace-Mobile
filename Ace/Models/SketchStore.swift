import CoreGraphics
import Foundation

/// The paper a sketch is drawn on. Each one has its own color and pattern.
enum SketchPaper: String, Codable, CaseIterable, Identifiable {
    case midnight, paper, grid, dots, blueprint

    var id: String { rawValue }

    /// How the paper is marked: nothing, ruled lines, squares or dots.
    enum Pattern: String {
        case plain, lines, grid, dots
    }

    var label: String {
        switch self {
        case .midnight: return "Midnight"
        case .paper: return "Paper"
        case .grid: return "Grid"
        case .dots: return "Dots"
        case .blueprint: return "Blueprint"
        }
    }

    /// The paper's color.
    var hex: UInt32 {
        switch self {
        case .midnight: return 0x15122A
        case .paper: return 0xFBF7EE
        case .grid: return 0xFFFFFF
        case .dots: return 0xF4F1FF
        case .blueprint: return 0x123A6B
        }
    }

    /// The color of the paper's lines or dots.
    var lineHex: UInt32 {
        switch self {
        case .midnight: return 0x2A2550
        case .paper: return 0xE6DCC6
        case .grid: return 0xD7E3F4
        case .dots: return 0xC4BCEB
        case .blueprint: return 0x2E5C94
        }
    }

    var pattern: Pattern {
        switch self {
        case .midnight: return .plain
        case .paper: return .lines
        case .grid, .blueprint: return .grid
        case .dots: return .dots
        }
    }

    /// How far apart the lines or dots are, in points.
    var spacing: CGFloat { 32 }

    var isDark: Bool { self == .midnight || self == .blueprint }

    /// A good first ink on this paper: white on dark paper, near-black on light paper.
    var startInk: UInt32 { isDark ? 0xFFFFFF : 0x1B1830 }
}

/// One drawing in the sketchbook. The strokes themselves live in their own file.
struct Sketch: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var paper: SketchPaper
    /// The challenge it was drawn for, if it came from one.
    var prompt: String?
    /// How many strokes it has, for the card and the stats.
    var strokes: Int
    var created: Date
    var updated: Date
}

/// A timer for a drawing challenge.
enum SketchChallenge: Int, CaseIterable, Identifiable {
    case off = 0
    case oneMinute = 60
    case threeMinutes = 180
    case fiveMinutes = 300

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .off: return "No timer"
        case .oneMinute: return "1 min"
        case .threeMinutes: return "3 min"
        case .fiveMinutes: return "5 min"
        }
    }

    var seconds: Int { rawValue }
}

/// Things to draw when you can't think of anything. There's a new one each day.
enum SketchPrompts {
    static let all: [String] = [
        "A robot walking its dog",
        "Your dream treehouse",
        "A dragon who is scared of the dark",
        "A city on the back of a giant turtle",
        "The fastest car ever made",
        "A spaceship shaped like a fish",
        "Your favorite food with a face",
        "A castle in the clouds",
        "A monster under the bed who is actually friendly",
        "An alien visiting a grocery store",
        "A volcano island",
        "A cat wearing armor",
        "The inside of a submarine",
        "A tiny house inside a teacup",
        "A superhero with a silly power",
        "A tree that grows candy",
        "Your room in the year 3000",
        "A penguin on a skateboard",
        "A secret hideout",
        "A giant mech suit",
        "A pirate ship sailing through space",
        "A snowman on vacation at the beach",
        "A sneaker you'd design",
        "An underwater city",
        "A wizard's messy desk",
        "A dinosaur at a birthday party",
        "A floating island with waterfalls",
        "The coolest bike ever",
        "A rocket launch",
        "A haunted lighthouse",
        "A fox reading a book",
        "A bridge between two mountains",
        "A train that rides on rainbows",
        "Your own video game character",
        "An owl astronaut",
        "A jungle with glowing plants",
        "A sandwich that's way too tall",
        "A desert with two suns",
        "A knight riding a giant snail",
        "A robot chef cooking pancakes",
        "A shark in a hat",
        "A crystal cave",
        "A hot air balloon festival",
        "A tiny dragon on your shoulder",
        "A skyscraper made of books",
        "A storm over the ocean",
        "A frog king on a lily pad throne",
        "The view from your window, but on another planet",
        "A drone delivering a pizza",
        "A mushroom village",
        "A giant octopus hugging a boat",
        "A race between a cheetah and a jet",
        "A garden on the moon",
        "A bear in a cozy cabin",
        "A futuristic phone",
        "An old map of a made-up island",
        "A whale flying through the sky",
        "A robot that's learning to paint",
        "A campfire under the stars",
        "A city made of ice"
    ]

    /// Today's challenge. It's the same all day and changes at midnight.
    static func daily(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let count = all.count
        return all[((day % count) + count) % count]
    }

    /// A different challenge from `current`.
    static func random(excluding current: String? = nil) -> String {
        let pool = all.filter { $0 != current }
        return pool.randomElement() ?? all[0]
    }
}

/// What's saved in sketches.json: the list of sketches and the days you drew on.
private struct SketchIndex: Codable {
    var sketches: [Sketch]
    var drawDays: [String]
}

/// The sketchbook: your drawings, newest first. Each drawing's strokes and its little picture
/// are saved as files in the Sketches folder, and the list is saved in sketches.json.
/// Everything stays on the iPad.
@MainActor
final class SketchStore: ObservableObject {
    static let shared = SketchStore()

    /// The longest a sketch's name can be.
    static let maxTitle = 40

    /// Every sketch, the one changed most recently first.
    @Published private(set) var sketches: [Sketch] = []
    /// The days (like "2026-11-25") you drew something.
    @Published private(set) var drawDays: Set<String> = []

    private let indexFile: String?
    private let folder: URL?
    let calendar: Calendar
    private var drawings: [UUID: Data] = [:]
    private var thumbnails: [UUID: Data] = [:]

    /// `indexFile` and `folder` nil keep everything in memory (for tests).
    init(indexFile: String? = "sketches.json", folder: URL? = Persistence.subfolder("Sketches"), calendar: Calendar? = nil) {
        self.indexFile = indexFile
        self.folder = folder
        if let calendar {
            self.calendar = calendar
        } else {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = .current
            self.calendar = cal
        }
        if let indexFile, let saved = Persistence.load(SketchIndex.self, from: indexFile) {
            sketches = saved.sketches.sorted { $0.updated > $1.updated }
            drawDays = Set(saved.drawDays)
        }
    }

    // MARK: Reading

    func sketch(_ id: UUID) -> Sketch? {
        sketches.first { $0.id == id }
    }

    /// The saved strokes of a sketch (PencilKit's drawing data), or nil before anything is drawn.
    func drawingData(_ id: UUID) -> Data? {
        if let data = drawings[id] { return data }
        guard let data = read("\(id.uuidString).drawing") else { return nil }
        drawings[id] = data
        return data
    }

    /// The little picture shown on the sketch's card, or nil for an empty sketch.
    func thumbnailData(_ id: UUID) -> Data? {
        if let data = thumbnails[id] { return data }
        guard let data = read("\(id.uuidString).png") else { return nil }
        thumbnails[id] = data
        return data
    }

    /// The next free "Sketch N" name.
    func nextTitle() -> String {
        var top = 0
        for s in sketches where s.title.hasPrefix("Sketch ") {
            if let n = Int(s.title.dropFirst("Sketch ".count)) { top = max(top, n) }
        }
        return "Sketch \(top + 1)"
    }

    /// Strokes across every sketch.
    var totalStrokes: Int {
        sketches.reduce(0) { $0 + $1.strokes }
    }

    /// Days in a row you've drawn, counting back from today (or yesterday, if you haven't drawn yet today).
    func streak(now: Date = Date()) -> Int {
        var day = calendar.startOfDay(for: now)
        if !drawDays.contains(dayKey(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while drawDays.contains(dayKey(day)) {
            count += 1
            guard let before = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = before
        }
        return count
    }

    // MARK: Writing

    /// Starts a new sketch. One drawn for a challenge is named after it.
    @discardableResult
    func create(paper: SketchPaper, prompt: String? = nil, now: Date = Date()) -> Sketch {
        let clean = prompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let sketch = Sketch(id: UUID(),
                            title: clean.isEmpty ? nextTitle() : Self.clip(clean),
                            paper: paper,
                            prompt: clean.isEmpty ? nil : clean,
                            strokes: 0,
                            created: now,
                            updated: now)
        sketches.insert(sketch, at: 0)
        persistIndex()
        return sketch
    }

    /// Saves a sketch's strokes and its card picture.
    func saveDrawing(_ id: UUID, data: Data, strokes: Int, thumbnail: Data?, now: Date = Date()) {
        guard let i = index(id) else { return }
        sketches[i].strokes = max(0, strokes)
        sketches[i].updated = now
        drawings[id] = data
        thumbnails[id] = thumbnail
        write(data, to: "\(id.uuidString).drawing")
        if let thumbnail {
            write(thumbnail, to: "\(id.uuidString).png")
        } else {
            remove("\(id.uuidString).png")
        }
        if strokes > 0 { drawDays.insert(dayKey(now)) }
        sortSketches()
        persistIndex()
    }

    /// Gives a sketch a new name. Blank names are ignored and long ones are cut.
    func rename(_ id: UUID, to title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, let i = index(id) else { return }
        sketches[i].title = Self.clip(clean)
        persistIndex()
    }

    func setPaper(_ id: UUID, to paper: SketchPaper, now: Date = Date()) {
        guard let i = index(id), sketches[i].paper != paper else { return }
        sketches[i].paper = paper
        sketches[i].updated = now
        sortSketches()
        persistIndex()
    }

    /// Makes a copy of a sketch, strokes and all.
    @discardableResult
    func duplicate(_ id: UUID, now: Date = Date()) -> Sketch? {
        guard let original = sketch(id) else { return nil }
        var copy = original
        copy.id = UUID()
        copy.title = Self.clip(original.title + " copy")
        copy.created = now
        copy.updated = now
        sketches.insert(copy, at: 0)
        if let data = drawingData(id) {
            drawings[copy.id] = data
            write(data, to: "\(copy.id.uuidString).drawing")
        }
        if let thumb = thumbnailData(id) {
            thumbnails[copy.id] = thumb
            write(thumb, to: "\(copy.id.uuidString).png")
        }
        persistIndex()
        return copy
    }

    func delete(_ id: UUID) {
        sketches.removeAll { $0.id == id }
        drawings[id] = nil
        thumbnails[id] = nil
        remove("\(id.uuidString).drawing")
        remove("\(id.uuidString).png")
        persistIndex()
    }

    // MARK: Helpers

    static func clip(_ text: String) -> String {
        String(text.prefix(maxTitle)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func index(_ id: UUID) -> Int? {
        sketches.firstIndex { $0.id == id }
    }

    private func sortSketches() {
        sketches.sort { $0.updated > $1.updated }
    }

    private func persistIndex() {
        guard let indexFile else { return }
        Persistence.save(SketchIndex(sketches: sketches, drawDays: drawDays.sorted()), to: indexFile)
    }

    private func read(_ name: String) -> Data? {
        guard let folder else { return nil }
        return try? Data(contentsOf: folder.appendingPathComponent(name))
    }

    private func write(_ data: Data, to name: String) {
        guard let folder else { return }
        try? data.write(to: folder.appendingPathComponent(name), options: [.atomic])
    }

    private func remove(_ name: String) {
        guard let folder else { return }
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }
}
