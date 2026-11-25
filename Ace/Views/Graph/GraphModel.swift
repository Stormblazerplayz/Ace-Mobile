import SwiftUI

/// What opens Ace Graphs (see `AceCore.graphScreen`).
struct GraphScreen: Identifiable {
    let id = UUID()
    var start: GraphStart
}

/// One formula on the graph, with its color and when it was added (so it can draw itself in).
struct GraphLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let expr: GraphExpr
    let color: UInt32
    let born: Date
    var shown = true
    /// Where it crosses the x axis (worked out once, between -50 and 50).
    let roots: [Double]

    init(text: String, expr: GraphExpr, color: UInt32, born: Date) {
        self.text = text
        self.expr = expr
        self.color = color
        self.born = born
        roots = GraphFacts.roots(expr, from: -50, to: 50, steps: 20_000)
    }

    var label: String { "y = " + GraphParse.pretty(text) }
}

/// Everything on the graph screen: the formulas, which part of the plane is showing, and the trace.
@MainActor
final class GraphModel: ObservableObject {
    static let colors: [UInt32] = [0x5BB6FF, 0xFF5F8F, 0x45D483, 0xFFCF3A]
    static let maxLines = 4
    static let examples = ["x^2", "2x + 1", "sin x", "x^3 - 3x", "|x|", "sqrt x", "1/x", "-x^2 + 4"]

    @Published var lines: [GraphLine] = []
    @Published var viewport = GraphViewport()
    @Published var input = ""
    @Published var problem: String?
    /// The line the trace follows, and where along x it is.
    @Published var picked: UUID?
    @Published var traceX: Double?
    /// The plane size the viewport was fitted to, so Reset can fit it again.
    private var fittedWidth: CGFloat = 0

    var pickedLine: GraphLine? { lines.first { $0.id == picked } ?? lines.first }

    func fit(width: CGFloat) {
        guard width > 0, fittedWidth == 0 else { return }
        fittedWidth = width
        viewport = .fitting(width: width)
    }

    func resetView() {
        viewport = .fitting(width: max(100, fittedWidth))
        traceX = nil
    }

    /// Adds a formula. False (with a note in `problem`) if Ace can't read it or the graph is full.
    @discardableResult
    func add(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let expr = GraphParse.parse(trimmed) else {
            problem = "I can't read \"\(trimmed)\". Try something like 2x + 1, x^2 or sin x."
            return false
        }
        guard expr.usesX || GraphFacts.line(expr) != nil else {
            problem = "Put an x in it so there's something to draw."
            return false
        }
        let clean = GraphParse.clean(trimmed)
        if let same = lines.first(where: { $0.expr == expr }) {
            picked = same.id
            problem = "y = \(GraphParse.pretty(clean)) is already on the graph."
            return false
        }
        guard lines.count < Self.maxLines else {
            problem = "The graph holds \(Self.maxLines) lines. Remove one to add another."
            return false
        }
        let used = Set(lines.map(\.color))
        let color = Self.colors.first { !used.contains($0) } ?? Self.colors[0]
        let line = GraphLine(text: clean, expr: expr, color: color, born: Date())
        lines.append(line)
        picked = line.id
        problem = nil
        input = ""
        return true
    }

    func remove(_ id: UUID) {
        lines.removeAll { $0.id == id }
        if picked == id { picked = lines.last?.id }
        if lines.isEmpty { traceX = nil }
    }

    func toggle(_ id: UUID) {
        guard let i = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[i].shown.toggle()
    }

    func clearAll() {
        lines.removeAll()
        picked = nil
        traceX = nil
        problem = nil
    }

    /// The trace's point on the picked line, if it has one there.
    var tracePoint: (x: Double, y: Double)? {
        guard let x = traceX, let line = pickedLine, line.shown else { return nil }
        let y = line.expr.value(x)
        return y.isFinite ? (x, y) : nil
    }
}
