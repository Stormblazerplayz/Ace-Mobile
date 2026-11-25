import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// A formula with x in it, like "x^2 - 3" or "2sin(x)", that Ace can draw.
indirect enum GraphExpr: Equatable {
    case number(Double)
    case x
    case add(GraphExpr, GraphExpr)
    case sub(GraphExpr, GraphExpr)
    case mul(GraphExpr, GraphExpr)
    case div(GraphExpr, GraphExpr)
    case pow(GraphExpr, GraphExpr)
    case neg(GraphExpr)
    case fn(String, GraphExpr)

    /// The formula's value at x. NaN where it has none, like the square root of -1.
    func value(_ x: Double) -> Double {
        switch self {
        case .number(let n): return n
        case .x: return x
        case .add(let a, let b): return a.value(x) + b.value(x)
        case .sub(let a, let b): return a.value(x) - b.value(x)
        case .mul(let a, let b): return a.value(x) * b.value(x)
        case .div(let a, let b):
            let d = b.value(x)
            return d == 0 ? .nan : a.value(x) / d
        case .pow(let a, let b):
            let base = a.value(x), power = b.value(x)
            // A negative number to a whole power is fine: (-2)^3 is -8.
            if base < 0, power != power.rounded() { return .nan }
            return Foundation.pow(base, power)
        case .neg(let a): return -a.value(x)
        case .fn(let name, let a):
            let v = a.value(x)
            switch name {
            case "sin": return sin(v)
            case "cos": return cos(v)
            case "tan": return tan(v)
            case "sqrt": return v < 0 ? .nan : v.squareRoot()
            case "cbrt": return cbrt(v)
            case "abs": return abs(v)
            case "ln": return v <= 0 ? .nan : log(v)
            case "log": return v <= 0 ? .nan : log10(v)
            case "exp": return exp(v)
            case "floor": return floor(v)
            case "round": return v.rounded()
            default: return .nan
            }
        }
    }

    /// True if x is somewhere in the formula (so it makes a curve, not a flat line).
    var usesX: Bool {
        switch self {
        case .number: return false
        case .x: return true
        case .add(let a, let b), .sub(let a, let b), .mul(let a, let b), .div(let a, let b), .pow(let a, let b):
            return a.usesX || b.usesX
        case .neg(let a), .fn(_, let a): return a.usesX
        }
    }
}

/// Reads formulas typed with symbols or said in words: "y = x^2 + 1", "x squared minus 3",
/// "2sin(x)", "√x", "|x|", "f(x) = 3x − 2".
enum GraphParse {
    static let functions: Set<String> = ["sin", "cos", "tan", "sqrt", "cbrt", "abs", "ln", "log", "exp", "floor", "round"]

    /// The formula as Ace reads it, with "y =" taken off and words turned into symbols.
    static func clean(_ text: String) -> String {
        var s = " " + text.lowercased() + " "
        let symbols: [(String, String)] = [
            ("²", "^2"), ("³", "^3"), ("×", "*"), ("·", "*"), ("÷", "/"), ("−", "-"), ("–", "-"), ("π", "pi"), ("√", "sqrt "),
        ]
        for (a, b) in symbols { s = s.replacingOccurrences(of: a, with: b) }
        let words: [(String, String)] = [
            (" equals ", " = "), (" is equal to ", " = "), (" to the power of ", " ^ "), (" to the ", " ^ "), (" squared", " ^ 2"),
            (" cubed", " ^ 3"), (" times ", " * "), (" multiplied by ", " * "), (" divided by ", " / "), (" over ", " / "),
            (" plus ", " + "), (" minus ", " - "), (" negative ", " - "), (" the square root of ", " sqrt "),
            (" square root of ", " sqrt "), (" the cube root of ", " cbrt "), (" cube root of ", " cbrt "),
            (" absolute value of ", " abs "), (" sine of ", " sin "), (" cosine of ", " cos "), (" tangent of ", " tan "),
            (" sine ", " sin "), (" cosine ", " cos "), (" tangent ", " tan "), (" half of ", " 0.5 * "),
            (" f of x ", " f(x) "), (" point ", "."),
        ]
        // Twice, so words next to each other ("x squared plus 2 times x") all get swapped.
        for _ in 0..<2 {
            for (a, b) in words { s = s.replacingOccurrences(of: a, with: b) }
        }
        s = MathEval.numberWordsToDigits(s)
        s = s.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "?!.,"))
        // "y = ...", "f(x) = ...", "y equals ..."
        if let g = Rx.groups(#"^(?:y|f\s*\(\s*x\s*\)|g\s*\(\s*x\s*\))\s*=\s*(.+)$"#, s) { s = g[0] }
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: " ^ ", with: "^")
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// The formula written nicely for the screen: "x^2 + 1" becomes "x² + 1", "sqrt x" becomes "√x".
    static func pretty(_ text: String) -> String {
        var s = clean(text)
        s = s.replacingOccurrences(of: #"\^2(?![0-9.])"#, with: "²", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\^3(?![0-9.])"#, with: "³", options: .regularExpression)
        let swaps: [(String, String)] = [("*", "·"), ("sqrt ", "√"), ("sqrt", "√"), ("pi", "π"), ("-", "−")]
        for (a, b) in swaps { s = s.replacingOccurrences(of: a, with: b) }
        return s
    }

    /// The formula, or nil if it isn't one Ace can draw.
    static func parse(_ text: String) -> GraphExpr? {
        guard let tokens = tokenize(clean(text)), !tokens.isEmpty else { return nil }
        var reader = Reader(tokens: tokens)
        guard let e = reader.expression(), reader.atEnd else { return nil }
        return e
    }

    // MARK: Reading

    enum Token: Equatable {
        case number(Double)
        case name(String)
        case op(Character)
        case open, close, bar
    }

    static func tokenize(_ s: String) -> [Token]? {
        var out: [Token] = []
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == " " { i += 1; continue }
            if c.isNumber || (c == "." && i + 1 < chars.count && chars[i + 1].isNumber) {
                var j = i
                while j < chars.count, chars[j].isNumber || chars[j] == "." { j += 1 }
                guard let n = Double(String(chars[i..<j])) else { return nil }
                out.append(.number(n))
                i = j
                continue
            }
            if c.isLetter {
                var j = i
                while j < chars.count, chars[j].isLetter { j += 1 }
                let word = String(chars[i..<j])
                guard let parts = split(word) else { return nil }
                out.append(contentsOf: parts.map { .name($0) })
                i = j
                continue
            }
            switch c {
            case "+", "-", "*", "/", "^": out.append(.op(c))
            case "(", "[": out.append(.open)
            case ")", "]": out.append(.close)
            case "|": out.append(.bar)
            default: return nil
            }
            i += 1
        }
        return out
    }

    /// Splits letters into names Ace knows: "xsinx" is x, sin, x and "pix" is pi, x.
    private static func split(_ word: String) -> [String]? {
        var rest = Substring(word)
        var out: [String] = []
        let known = functions.sorted { $0.count > $1.count } + ["pi", "x", "e"]
        while !rest.isEmpty {
            guard let hit = known.first(where: { rest.hasPrefix($0) }) else { return nil }
            out.append(hit)
            rest = rest.dropFirst(hit.count)
        }
        return out
    }

    struct Reader {
        let tokens: [Token]
        var i = 0
        var depth = 0

        init(tokens: [Token]) { self.tokens = tokens }

        var atEnd: Bool { i >= tokens.count }
        private var next: Token? { i < tokens.count ? tokens[i] : nil }

        mutating func expression() -> GraphExpr? {
            depth += 1
            defer { depth -= 1 }
            guard depth < 60, var left = term() else { return nil }
            while let t = next, case .op(let o) = t, o == "+" || o == "-" {
                i += 1
                guard let right = term() else { return nil }
                left = o == "+" ? .add(left, right) : .sub(left, right)
            }
            return left
        }

        /// Things multiplied together, with or without a "*": "2x", "3(x + 1)", "x sin x".
        mutating func term() -> GraphExpr? {
            guard var left = unary() else { return nil }
            while let t = next {
                if case .op(let o) = t, o == "*" || o == "/" {
                    i += 1
                    guard let right = unary() else { return nil }
                    left = o == "*" ? .mul(left, right) : .div(left, right)
                } else if startsFactor(t) {
                    guard let right = power() else { return nil }
                    left = .mul(left, right)
                } else {
                    break
                }
            }
            return left
        }

        private func startsFactor(_ t: Token) -> Bool {
            switch t {
            case .number, .name, .open: return true
            default: return false
            }
        }

        mutating func unary() -> GraphExpr? {
            if let t = next, case .op(let o) = t, o == "-" || o == "+" {
                i += 1
                guard let inner = unary() else { return nil }
                return o == "-" ? .neg(inner) : inner
            }
            return power()
        }

        mutating func power() -> GraphExpr? {
            guard let base = atom() else { return nil }
            if let t = next, case .op("^") = t {
                i += 1
                guard let exponent = unary() else { return nil }
                return .pow(base, exponent)
            }
            return base
        }

        mutating func atom() -> GraphExpr? {
            guard let t = next else { return nil }
            i += 1
            switch t {
            case .number(let n): return .number(n)
            case .name("x"): return .x
            case .name("pi"): return .number(.pi)
            case .name("e"): return .number(M_E)
            case .name(let f) where GraphParse.functions.contains(f):
                // "sin(x)" or "sin x" or "sin 2x" (everything multiplied up to the next + or -).
                if let n = next, n == .open { return atom().map { .fn(f, $0) } }
                guard var arg = power() else { return nil }
                while let n = next, isLoose(n) {
                    guard let more = power() else { return nil }
                    arg = .mul(arg, more)
                }
                return .fn(f, arg)
            case .open:
                guard let inner = expression(), next == .close else { return nil }
                i += 1
                return inner
            case .bar:
                guard let inner = expression(), next == .bar else { return nil }
                i += 1
                return .fn("abs", inner)
            default:
                return nil
            }
        }

        /// A number or x right after a function's first part, as in "sin 2x".
        private func isLoose(_ t: Token) -> Bool {
            switch t {
            case .name("x"), .name("pi"): return true
            default: return false
            }
        }
    }
}

/// What Ace can say about a graph: where it crosses the axes, and the slope of a straight line.
enum GraphFacts {
    /// Where the graph crosses the x axis between `low` and `high`, left to right.
    static func roots(_ f: GraphExpr, from low: Double = -10, to high: Double = 10, steps: Int = 4_000) -> [Double] {
        var found: [Double] = []
        let dx = (high - low) / Double(steps)
        var x0 = low, y0 = f.value(low)
        func add(_ r: Double) {
            let snapped = abs(r - r.rounded()) < 1e-7 ? r.rounded() : r
            if let last = found.last, abs(last - snapped) < dx * 2 { return }
            found.append(snapped == 0 ? 0 : snapped)
        }
        if y0 == 0 { add(x0) }
        for k in 1...steps {
            let x1 = low + Double(k) * dx
            let y1 = f.value(x1)
            if y1 == 0 {
                add(x1)
            } else if y0.isFinite, y1.isFinite, y0 != 0, (y0 < 0) != (y1 < 0) {
                var a = x0, b = x1, fa = y0
                for _ in 0..<60 {
                    let m = (a + b) / 2, fm = f.value(m)
                    if !fm.isFinite { break }
                    if (fm < 0) == (fa < 0) { a = m; fa = fm } else { b = m }
                }
                let r = (a + b) / 2
                // A jump across zero (like 1/x at 0) isn't a crossing.
                let size = max(1, abs(y0), abs(y1))
                if abs(f.value(r)) < 1e-6 * size { add(r) }
            }
            x0 = x1
            y0 = y1
        }
        return found
    }

    /// Where it crosses the y axis, if it does.
    static func yIntercept(_ f: GraphExpr) -> Double? {
        let v = f.value(0)
        return v.isFinite ? v : nil
    }

    /// Slope and y-intercept if the graph is a straight line.
    static func line(_ f: GraphExpr) -> (slope: Double, intercept: Double)? {
        let xs: [Double] = [-7.3, -2.1, 0, 1.7, 4.9, 9.2]
        let ys = xs.map(f.value)
        guard ys.allSatisfy(\.isFinite) else { return nil }
        let slope = (ys[5] - ys[0]) / (xs[5] - xs[0])
        let intercept = ys[2]
        for (x, y) in zip(xs, ys) where abs(intercept + slope * x - y) > 1e-9 * max(1, abs(y)) {
            return nil
        }
        return (clean(slope), clean(intercept))
    }

    /// The lowest or highest point of a U-shaped graph (a parabola), if it's one.
    static func turningPoint(_ f: GraphExpr) -> (x: Double, y: Double, lowest: Bool)? {
        // A parabola has the same second difference everywhere.
        let h = 0.5
        let xs: [Double] = [-6, -1.3, 0.4, 3.1, 7]
        let seconds = xs.map { f.value($0 + h) - 2 * f.value($0) + f.value($0 - h) }
        guard seconds.allSatisfy(\.isFinite), let s = seconds.first, abs(s) > 1e-9,
              seconds.allSatisfy({ abs($0 - s) < 1e-7 * max(1, abs(s)) }) else { return nil }
        let a = s / (2 * h * h)
        let b = (f.value(1) - f.value(-1)) / 2
        let x = -b / (2 * a)
        return (clean(x), clean(f.value(x)), a > 0)
    }

    private static func clean(_ v: Double) -> Double {
        let r = (v * 1_000_000).rounded() / 1_000_000
        return r == 0 ? 0 : r
    }

    /// A number the way Ace says it: "3", "-1.5", "2.24".
    static func say(_ v: Double) -> String {
        if v == v.rounded(), abs(v) < 1e12 { return String(Int(v)) }
        let s = String(format: "%.2f", v)
        return s.hasSuffix("0") ? String(s.dropLast()) : s
    }

    /// One or two sentences about the graph for the chat.
    static func describe(_ f: GraphExpr) -> String {
        var parts: [String] = []
        if let l = line(f) {
            if l.slope == 0 {
                parts.append("It's a flat line at y = \(say(l.intercept)).")
            } else {
                let way = l.slope > 0 ? "goes up" : "goes down"
                parts.append("It's a straight line that \(way) \(say(abs(l.slope))) for every 1 step right, and crosses the y axis at \(say(l.intercept)).")
            }
        } else if let t = turningPoint(f) {
            parts.append("It's a U-shaped curve (a parabola) with its \(t.lowest ? "lowest" : "highest") point at (\(say(t.x)), \(say(t.y))).")
        } else if let y = yIntercept(f) {
            parts.append("It crosses the y axis at \(say(y)).")
        }
        let r = roots(f)
        if line(f)?.slope == 0 {
            // A flat line has no crossings to list (or crosses everywhere at y = 0).
        } else if r.isEmpty {
            parts.append("It doesn't cross the x axis between -10 and 10.")
        } else if r.count <= 4 {
            let list = r.map(say).joined(separator: ", ")
            parts.append("It crosses the x axis at x = \(list).")
        } else {
            parts.append("It crosses the x axis \(r.count) times between -10 and 10.")
        }
        return parts.joined(separator: " ")
    }
}

/// Which part of the x-y plane the graph screen shows, and how to turn plane points into screen points.
struct GraphViewport: Equatable {
    /// The plane point in the middle of the screen.
    var centerX: Double = 0
    var centerY: Double = 0
    /// How many plane units one screen point covers.
    var unitsPerPoint: Double = 0.04

    static let minUnits = 0.0005
    static let maxUnits = 50.0

    func screen(_ x: Double, _ y: Double, size: CGSize) -> CGPoint {
        CGPoint(x: Double(size.width) / 2 + (x - centerX) / unitsPerPoint,
                y: Double(size.height) / 2 - (y - centerY) / unitsPerPoint)
    }

    func plane(_ p: CGPoint, size: CGSize) -> (x: Double, y: Double) {
        (centerX + (Double(p.x) - Double(size.width) / 2) * unitsPerPoint,
         centerY - (Double(p.y) - Double(size.height) / 2) * unitsPerPoint)
    }

    /// Slides the view by a finger drag (in screen points).
    mutating func pan(by drag: CGSize) {
        centerX -= Double(drag.width) * unitsPerPoint
        centerY += Double(drag.height) * unitsPerPoint
    }

    /// Zooms in (factor above 1) or out, keeping the plane point under `anchor` still.
    mutating func zoom(by factor: Double, around anchor: CGPoint, size: CGSize) {
        guard factor > 0, factor.isFinite else { return }
        let before = plane(anchor, size: size)
        unitsPerPoint = min(Self.maxUnits, max(Self.minUnits, unitsPerPoint / factor))
        let after = plane(anchor, size: size)
        centerX += before.x - after.x
        centerY += before.y - after.y
    }

    /// The gap between grid lines: 1, 2 or 5 times a power of ten, about `target` points apart.
    func gridStep(target: Double = 70) -> Double {
        let raw = target * unitsPerPoint
        let power = Foundation.pow(10, floor(log10(raw)))
        for m in [1.0, 2, 5, 10] where m * power >= raw { return m * power }
        return 10 * power
    }

    /// Sized so x runs from -10 to 10 across the screen.
    static func fitting(width: CGFloat) -> GraphViewport {
        GraphViewport(centerX: 0, centerY: 0, unitsPerPoint: 22 / max(100, Double(width)))
    }
}

/// Understands graph asks: "graph y = x^2", "plot sin x", "draw the graph of 2x + 1",
/// "open the graphing calculator". Returns "open" or "plot:<formula>".
enum GraphAsk {
    private static let polite = #"^(?:(?:please|ok|okay|hey ace|ace|can you|could you|can i|let us|lets|let's|i want to|want to|i would like to|help me)\s+)*"#

    static func parse(_ raw: String) -> String? {
        var s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "?!.")).trimmingCharacters(in: .whitespaces)
        s = s.replacingOccurrences(of: "’", with: "'")
        // "graph of y equals sin x" is a name for a graph (asking what it looks like), not an ask to draw one.
        let named = Rx.matches(#"^(?:the |a )?(?:graph|plot) (?:of|for)\b"#, s)
        // "graph y = x^2", "plot sin x", "draw the graph of 2x+1", "sketch the line y = 3x - 2"
        if !named, let g = Rx.groups(polite + #"(?:graph|plot|draw|sketch|show me)\s+(?:me\s+)?(?:(?:the|a)\s+)?(?:graph|plot|line|curve|parabola)?\s*(?:of|for)?\s*(.+?)(?:\s+(?:please|for me|on a graph|on the graph|on graph paper))?$"#, s),
           let expr = GraphParse.parse(g[0]), expr.usesX {
            return "plot:" + GraphParse.clean(g[0])
        }
        // Just the formula: "y = 2x + 3", "f(x) = x^2 - 4"
        if Rx.matches(#"^(?:y|f\s*\(\s*x\s*\))\s*(?:=|equals)\s*\S"#, s), let expr = GraphParse.parse(s), expr.usesX {
            return "plot:" + GraphParse.clean(s)
        }
        // "open the graphing calculator", "graph paper", "graphs"
        if Rx.matches(polite + #"(?:open|show|start|launch|bring up|pull up|use)?\s*(?:me\s+)?(?:(?:the|a|my)\s+)?(?:graphing calculator|graph calculator|graphing app|graph paper|ace graphs|graphs|graph|grapher)$"#, s)
            || Rx.matches(polite + #"(?:graph|plot|draw)\s+(?:something|a function|a graph|an equation|some functions|functions|equations)$"#, s) {
            return "open"
        }
        return nil
    }
}
