import Foundation

/// A number kept exactly as a fraction, so 1/3 + 1/6 is 1/2 and not 0.49999.
struct Rational: Equatable, Hashable {
    let n: Int
    let d: Int

    init?(_ n: Int, _ d: Int = 1) {
        guard d != 0 else { return nil }
        let g = Rational.gcd(abs(n), abs(d))
        let sign = d < 0 ? -1 : 1
        self.n = sign * n / max(g, 1)
        self.d = abs(d) / max(g, 1)
    }

    static let zero = Rational(0)!
    static let one = Rational(1)!

    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? max(a, 1) : gcd(b, a % b) }
    static func lcm(_ a: Int, _ b: Int) -> Int? {
        let (p, o) = (a / gcd(a, b)).multipliedReportingOverflow(by: b)
        return o ? nil : p
    }

    /// "2.5" -> 5/2. Nil for numbers too long to keep exactly.
    init?(decimal s: String) {
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = Int(parts[0].isEmpty ? "0" : String(parts[0])) else { return nil }
        if parts.count == 1 { self.init(whole); return }
        let frac = String(parts[1])
        guard frac.count <= 9, frac.allSatisfy(\.isNumber) else { return nil }
        if frac.isEmpty { self.init(whole); return }
        var scale = 1
        for _ in 0..<frac.count { scale *= 10 }
        let (w, o) = whole.multipliedReportingOverflow(by: scale)
        guard !o, let f = Int(frac) else { return nil }
        self.init(w + f, scale)
    }

    var isInteger: Bool { d == 1 }

    static func + (a: Rational, b: Rational) -> Rational? {
        let (x, o1) = a.n.multipliedReportingOverflow(by: b.d)
        let (y, o2) = b.n.multipliedReportingOverflow(by: a.d)
        let (top, o3) = x.addingReportingOverflow(y)
        let (bottom, o4) = a.d.multipliedReportingOverflow(by: b.d)
        guard !(o1 || o2 || o3 || o4) else { return nil }
        return Rational(top, bottom)
    }

    static prefix func - (a: Rational) -> Rational { Rational(-a.n, a.d)! }

    static func - (a: Rational, b: Rational) -> Rational? { a + (-b) }

    static func * (a: Rational, b: Rational) -> Rational? {
        let (top, o1) = a.n.multipliedReportingOverflow(by: b.n)
        let (bottom, o2) = a.d.multipliedReportingOverflow(by: b.d)
        guard !(o1 || o2) else { return nil }
        return Rational(top, bottom)
    }

    static func / (a: Rational, b: Rational) -> Rational? {
        guard b.n != 0, let flip = Rational(b.d, b.n) else { return nil }
        return a * flip
    }

    /// Whole-number powers only (2^3, (1/2)^2), and not huge ones.
    func power(_ e: Rational) -> Rational? {
        guard e.isInteger, abs(e.n) <= 12 else { return nil }
        var out = Rational.one
        for _ in 0..<abs(e.n) { guard let next = out * self else { return nil }; out = next }
        if e.n < 0 { return Rational.one / out }
        return out
    }

    /// "3", "-1/2"
    var fractionText: String { d == 1 ? "\(n)" : "\(n)/\(d)" }

    /// "3", "2.5", "about 0.333"
    var decimalText: String {
        if d == 1 { return "\(n)" }
        var x = d
        var twos = 0
        var fives = 0
        while x % 2 == 0 { x /= 2; twos += 1 }
        while x % 5 == 0 { x /= 5; fives += 1 }
        let v = Double(n) / Double(d)
        let places = max(twos, fives)
        if x == 1 && places <= 6 { return Rational.trim(String(format: "%.\(places)f", v)) }
        return "about " + Rational.trim(String(format: "%.3f", v))
    }

    /// "2.500" -> "2.5", "3.000" -> "3"
    static func trim(_ s: String) -> String {
        guard s.contains(".") else { return s }
        var t = s
        while t.hasSuffix("0") { t.removeLast() }
        if t.hasSuffix(".") { t.removeLast() }
        return t
    }
}

/// Ace's homework helper: arithmetic, fractions, percents and equations like 2x + 3 = 11, solved step by step.
enum Homework {
    struct Solution: Equatable {
        /// The problem, written neatly ("2x + 3 = 11").
        var problem: String
        var steps: [String]
        /// "x = 4", "33", "5/6"
        var answer: String
    }

    // MARK: Reading the problem

    /// The kinds of problem Ace can do, for "I can do ...".
    static let kinds = ["sums with + - × and ÷", "fractions", "percents", "equations like 2x + 3 = 11"]
    static let examples = ["2x + 3 = 11", "3/4 + 1/8", "12 + 7 × 3", "15% of 80"]

    /// "solve 2x+3=11 step by step" -> "2x+3=11". Nil when there's no math problem in it.
    static func problem(in text: String) -> String? {
        var t = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let leads = [
            #"^(?:please\s+)?(?:can you |could you |will you )?(?:please\s+)?(?:help me (?:with|solve|work out|do)|solve|work out|calculate|figure out|simplify|evaluate|explain|find)\s+"#,
            #"^(?:please\s+)?(?:can you |could you |will you )?(?:please\s+)?(?:show|give|tell)(?: me)?(?: the| all the)? (?:steps|working|work|solution|answer)(?: for| to| of| on)?\s+"#,
            #"^how (?:do|would|can|should) (?:i|you|we) (?:solve|work out|do|figure out|calculate|get)\s+"#,
            #"^what (?:is|are|does)\s+"#, #"^whats\s+"#, #"^what's\s+"#,
        ]
        for p in leads { t = t.replacingOccurrences(of: p, with: "", options: .regularExpression) }
        // "for x: 2x + 3 = 11", "this equation: ...", "my homework: ..."
        t = t.replacingOccurrences(of: #"^(?:(?:my|this|the)\s+)?(?:math\s+|maths\s+)?(?:homework|problem|question|equation|sum)\s*[:,]?\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"^for [a-z]\s*[:,]?\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"^[:,]\s*"#, with: "", options: .regularExpression)
        let tails = [#"\s*(?:step by step|with steps|with the steps|show (?:the |your |all )?(?:steps|working|work)|please|for me)\s*[?.!]*$"#,
                     #"\s*(?:,\s*)?(?:solve|find|what is) (?:for )?[a-z]\s*[?.!]*$"#, #"[?.!\s]+$"#]
        for _ in 0..<2 { for p in tails { t = t.replacingOccurrences(of: p, with: "", options: .regularExpression) } }
        t = t.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, t.count <= 80 else { return nil }
        return solve(t) != nil ? t : nil
    }

    /// What to do with a message: "" for "help me with my homework", the problem for one to solve step by step,
    /// or nil when it isn't homework (plain sums like "what is 5 + 3" stay quick answers).
    static func intent(_ raw: String) -> String? {
        let t = TextKit.normalize(raw)
        if Rx.matches(#"^(?:(?:can|could|will) you |please )*(?:help(?: me)?(?: out)? (?:with|on|do) (?:my |some |this )?(?:math |maths )?homework|homework help|(?:i need|i want) help (?:with|on) (?:my )?(?:math |maths )?homework|do (?:my )?(?:math |maths )?homework|(?:math|maths) homework|homework helper)(?: please)?$"#, t) {
            return ""
        }
        guard raw.rangeOfCharacter(from: .decimalDigits) != nil else { return nil }
        let lower = raw.lowercased()
        guard let p = problem(in: raw) else {
            // "solve x^2 = 4": a math problem Ace can't do step by step yet, so it says what it can do.
            if Rx.matches(#"^(?:please\s+)?(?:can you\s+|could you\s+)?(?:solve|simplify)\s+\S"#, lower), Rx.matches(#"[=+*/^×÷]"#, lower) {
                return lower.trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
        if Rx.matches(#"\b(?:solve|step by step|steps|working|show (?:me )?(?:the |your )?work|homework|how (?:do|would|can|should) (?:i|you|we) (?:solve|work out|do|figure out|calculate|get))\b"#, lower) {
            return p
        }
        // An equation with a letter in it ("2x + 3 = 11").
        if Rx.matches(#"=\s*[-(0-9a-z.]"#, p), let s = solve(p), s.answer.contains(" = ") || s.answer == "any number" || s.answer == "no answer" {
            return p
        }
        // Fractions ("3/4 + 1/8"), which a quick answer would turn into a long decimal.
        if Rx.matches(#"\d\s*/\s*\d+\s*[-+*×÷]|[-+*×÷]\s*\d+\s*/\s*\d"#, p) { return p }
        return nil
    }

    /// Lines from a photo that look like math problems ("1) 12 + 7 × 3 =", "2x - 5 = 9").
    /// With `needEquals`, only lines with an "=" count, so a date or a page number in a photo isn't taken for a sum.
    static func problems(inText text: String, needEquals: Bool = false) -> [String] {
        var out: [String] = []
        for raw in text.split(whereSeparator: \.isNewline) {
            var line = String(raw).trimmingCharacters(in: .whitespaces)
            // Drop numbering like "1)", "2.", "a)", "Q3:".
            line = line.replacingOccurrences(of: #"^(?:q\s*\d+\s*[:.)]|\(?[0-9]{1,2}[.)]|\(?[a-h][.)])\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            guard line.contains(where: \.isNumber), !needEquals || line.contains("="), solve(line) != nil, !out.contains(line) else { continue }
            out.append(line)
            if out.count == 5 { break }
        }
        return out
    }

    // MARK: Solving

    static func solve(_ raw: String) -> Solution? {
        let text = tidy(raw)
        if let p = percent(text) { return p }
        let sides = text.split(separator: "=", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        if sides.count == 2, !sides[0].isEmpty, sides[1].isEmpty || sides[1] == "?" {
            return arithmetic(sides[0])   // "12 + 7 × 3 =" means work it out
        }
        if sides.count == 2 { return equation(sides[0], sides[1]) }
        if sides.count == 1 { return arithmetic(sides[0]) }
        return nil
    }

    /// Words and symbols to plain math: "×" and "times" -> "*", "÷" -> "/", "squared" -> "^2".
    static func tidy(_ raw: String) -> String {
        var t = " " + raw.lowercased() + " "
        let words: [(String, String)] = [
            (" multiplied by ", " * "), (" times ", " * "), (" divided by ", " : "), (" over ", " / "),
            (" plus ", " + "), (" minus ", " - "), (" take away ", " - "), (" squared ", "^2 "), (" cubed ", "^3 "),
            (" equals ", " = "), (" is equal to ", " = "),
        ]
        for (a, b) in words { t = t.replacingOccurrences(of: a, with: b) }
        let symbols: [(String, String)] = [
            ("×", "*"), ("·", "*"), ("∗", "*"), ("÷", ":"), ("−", "-"), ("–", "-"), ("—", "-"),
            ("²", "^2"), ("³", "^3"), ("［", "("), ("］", ")"), ("[", "("), ("]", ")"), ("{", "("), ("}", ")"), (",", ""),
        ]
        for (a, b) in symbols { t = t.replacingOccurrences(of: a, with: b) }
        // "3 x 4" is times, "3x" is a letter.
        t = t.replacingOccurrences(of: #"(\d|\))\s+x\s+(\d|\()"#, with: "$1 * $2", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespaces)
    }

    // MARK: Percents

    private static func percent(_ t: String) -> Solution? {
        guard let g = Rx.groups(#"^(\d+(?:\.\d+)?)\s*(?:%|percent) of (\d+(?:\.\d+)?)$"#, t),
              let p = Rational(decimal: g[0]), let whole = Rational(decimal: g[1]),
              let hundred = Rational(100), let part = p / hundred, let answer = part * whole else { return nil }
        let steps = [
            "\(show(p, decimal: true))% means \(show(p, decimal: true)) out of 100, so it's \(show(p, decimal: true)) ÷ 100 = \(show(part, decimal: true)).",
            "Now times it by \(show(whole, decimal: true)): \(show(part, decimal: true)) × \(show(whole, decimal: true)) = \(show(answer, decimal: true)).",
        ]
        return Solution(problem: "\(show(p, decimal: true))% of \(show(whole, decimal: true))", steps: steps, answer: show(answer, decimal: true))
    }

    // MARK: Expressions

    indirect enum Node: Equatable {
        case num(Rational)
        case frac(Rational)          // a fraction written as a/b, like 3/4
        case variable
        case op(Character, Node, Node)
        case neg(Node)

        var isNumber: Bool {
            switch self {
            case .num, .frac: return true
            default: return false
            }
        }

        var value: Rational? {
            switch self {
            case .num(let r), .frac(let r): return r
            default: return nil
            }
        }

        var hasVariable: Bool {
            switch self {
            case .variable: return true
            case .num, .frac: return false
            case .neg(let a): return a.hasVariable
            case .op(_, let a, let b): return a.hasVariable || b.hasVariable
            }
        }

        var operations: Int {
            switch self {
            case .op(_, let a, let b): return 1 + a.operations + b.operations
            case .neg(let a): return a.operations
            default: return 0
            }
        }
    }

    /// The letter used for the unknown ("x"), found while parsing.
    private struct Parser {
        var tokens: [String]
        var i = 0
        var letter: Character?
        var decimals = false

        init?(_ s: String) {
            var out: [String] = []
            var found: Character?
            var dec = false
            let chars = Array(s)
            var k = 0
            while k < chars.count {
                let c = chars[k]
                if c == " " { k += 1; continue }
                if c.isNumber || c == "." {
                    var num = ""
                    while k < chars.count, chars[k].isNumber || chars[k] == "." { num.append(chars[k]); k += 1 }
                    guard num.filter({ $0 == "." }).count <= 1, num != "." else { return nil }
                    if num.contains(".") { dec = true }
                    out.append(num)
                    continue
                }
                if c.isLetter {
                    guard c.isASCII, found == nil || found == c else { return nil }   // one unknown only
                    // A whole word isn't math.
                    if k + 1 < chars.count, chars[k + 1].isLetter { return nil }
                    found = c
                    out.append("v")
                    k += 1
                    continue
                }
                guard "+-*/:^()".contains(c) else { return nil }
                out.append(String(c))
                k += 1
            }
            guard !out.isEmpty else { return nil }
            tokens = out
            letter = found
            decimals = dec
        }

        var peek: String? { i < tokens.count ? tokens[i] : nil }
        mutating func next() -> String? { defer { i += 1 }; return peek }

        mutating func expression() -> Node? {
            guard var left = term() else { return nil }
            while let t = peek, t == "+" || t == "-" {
                i += 1
                guard let right = term() else { return nil }
                left = .op(Character(t), left, right)
            }
            return left
        }

        mutating func term() -> Node? {
            guard var left = unary() else { return nil }
            while true {
                if let t = peek, t == "*" || t == "/" || t == ":" {
                    i += 1
                    guard let right = unary() else { return nil }
                    left = .op(t == ":" ? "/" : Character(t), left, right)
                } else if let t = peek, t == "(" || t == "v" || (t.first?.isNumber ?? false) {
                    // Times without a sign: 2x, 3(x + 1), (2)(3)
                    guard let right = power() else { return nil }
                    left = .op("*", left, right)
                } else {
                    return left
                }
            }
        }

        mutating func unary() -> Node? {
            if peek == "-" {
                i += 1
                guard let inner = unary() else { return nil }
                if case .num(let r) = inner { return .num(-r) }
                if case .op("/", .num(let a), .num(let b)) = inner { return .op("/", .num(-a), .num(b)) }   // -3/4
                return .neg(inner)
            }
            if peek == "+" { i += 1; return unary() }
            return power()
        }

        mutating func power() -> Node? {
            guard let base = atom() else { return nil }
            if peek == "^" {
                i += 1
                guard let exp = unary() else { return nil }
                return .op("^", base, exp)
            }
            return base
        }

        mutating func atom() -> Node? {
            guard let t = next() else { return nil }
            if t == "(" {
                guard let inner = expression(), next() == ")" else { return nil }
                return inner
            }
            if t == "v" { return .variable }
            if let r = Rational(decimal: t) {
                // A slash between whole numbers is one fraction, so 2/3 × 3/4 means (2/3) × (3/4).
                // (÷ and "divided by" are plain dividing.)
                if r.isInteger, !t.contains("."), peek == "/", i + 1 < tokens.count,
                   let b = Rational(decimal: tokens[i + 1]), b.isInteger, !tokens[i + 1].contains("."),
                   i + 2 >= tokens.count || tokens[i + 2] != "^" {
                    i += 2
                    return .op("/", .num(r), .num(b))
                }
                return .num(r)
            }
            return nil
        }
    }

    private static func parse(_ s: String) -> (node: Node, letter: Character?, decimals: Bool)? {
        guard var p = Parser(s), let node = p.expression(), p.i == p.tokens.count else { return nil }
        return (node, p.letter, p.decimals)
    }

    /// Turns a/b with whole numbers into fractions when there's more to the problem (3/4 + 1/8).
    private static func markFractions(_ n: Node) -> Node {
        switch n {
        case .op("/", .num(let a), .num(let b)) where a.isInteger && b.isInteger && b.n > 1 && a.n % b.n != 0 && Rational.gcd(abs(a.n), b.n) == 1:
            if let r = Rational(a.n, b.n) { return .frac(r) }
            return n
        case .op(let o, let a, let b): return .op(o, markFractions(a), markFractions(b))
        case .neg(let a): return .neg(markFractions(a))
        default: return n
        }
    }

    private static func precedence(_ o: Character) -> Int {
        switch o {
        case "^": return 3
        case "*", "/": return 2
        default: return 1
        }
    }

    private static func symbol(_ o: Character) -> String {
        switch o {
        case "*": return "×"
        case "/": return "÷"
        case "-": return "-"
        default: return String(o)
        }
    }

    /// How a number is shown: as a fraction (3/4), or as a decimal (2.5) when the problem used decimals.
    static func show(_ r: Rational, decimal: Bool) -> String { decimal ? r.decimalText : r.fractionText }

    /// Writes the tree back out with only the brackets it needs.
    private static func write(_ n: Node, letter: Character, decimal: Bool, parent: Int = 0, right: Bool = false) -> String {
        switch n {
        case .num(let r):
            let s = show(r, decimal: decimal)
            return r.n < 0 && (right || parent >= 3) ? "(\(s))" : s
        case .frac(let r):
            let s = r.fractionText
            return (r.n < 0 && right) || parent >= 3 ? "(\(s))" : s
        case .variable:
            return String(letter)
        case .neg(let a):
            return "-" + write(a, letter: letter, decimal: decimal, parent: 3)
        case .op(let o, let a, let b):
            let p = precedence(o)
            // 2x, 3(x + 1)
            if o == "*", a.isNumber, let k = a.value, b.hasVariable, !b.isNumber {
                let inner = write(b, letter: letter, decimal: decimal, parent: 2, right: true)
                let lead: String
                if k == .one { lead = "" } else if k == -Rational.one { lead = "-" }
                else if k.isInteger || decimal { lead = show(k, decimal: decimal) } else { lead = "(\(k.fractionText))" }
                let s = lead + inner
                return parent > p || (k.n < 0 && parent > 0) ? "(\(s))" : s
            }
            let l = write(a, letter: letter, decimal: decimal, parent: p)
            let r = write(b, letter: letter, decimal: decimal, parent: p, right: true)
            let s = o == "^" ? "\(l)^\(r)" : "\(l) \(symbol(o)) \(r)"
            let needs = parent > p || (right && parent == p && (o == "-" || o == "+" || o == "/" || parent == 2))
            return needs ? "(\(s))" : s
        }
    }

    // MARK: Arithmetic, one step at a time

    private static func arithmetic(_ s: String) -> Solution? {
        guard let parsed = parse(s), !parsed.node.hasVariable, parsed.node.operations >= 1 else { return nil }
        var node = parsed.node.operations > 1 ? markFractions(parsed.node) : parsed.node
        let decimal = parsed.decimals
        let letter: Character = "x"
        let problem = write(node, letter: letter, decimal: decimal)
        var steps: [String] = []
        // A single division of whole numbers gives a decimal, like 7 ÷ 2 = 3.5.
        var useDecimal = decimal
        var guardCount = 0
        while !node.isNumber {
            guardCount += 1
            guard guardCount < 40, let done = reduceOnce(node, letter: letter, decimal: &useDecimal) else { return nil }
            node = done.0
            if node.isNumber {
                steps.append(done.1)
            } else {
                steps.append(done.1 + " Now it's " + write(node, letter: letter, decimal: useDecimal) + ".")
            }
        }
        guard let v = node.value else { return nil }
        return Solution(problem: problem, steps: steps, answer: show(v, decimal: useDecimal))
    }

    /// Does the next operation by the order of operations (brackets, powers, times and divide, then plus and minus, left to right).
    private static func reduceOnce(_ node: Node, letter: Character, decimal: inout Bool) -> (Node, String)? {
        // Find the operation to do: the highest precedence one whose two sides are numbers, leftmost first.
        var best: (path: [Bool], prec: Int)?
        func scan(_ n: Node, _ path: [Bool]) {
            switch n {
            case .op(let o, let a, let b):
                if a.isNumber && b.isNumber {
                    let p = precedence(o)
                    if best == nil || p > best!.prec { best = (path, p) }
                } else {
                    scan(a, path + [false])
                    scan(b, path + [true])
                }
            case .neg(let a):
                if a.isNumber {
                    if best == nil || 4 > best!.prec { best = (path, 4) }
                } else {
                    scan(a, path + [false])
                }
            default: break
            }
        }
        scan(node, [])
        guard let target = best else { return nil }
        var step = ""
        func apply(_ n: Node) -> Node? {
            if case .neg(let a) = n, let v = a.value {
                step = "Make it negative: \(show(-v, decimal: decimal))."
                return .num(-v)
            }
            guard case .op(let o, let a, let b) = n, let x = a.value, let y = b.value else { return nil }
            var fractions = false
            if case .frac = a { fractions = true }
            if case .frac = b { fractions = true }
            let result: Rational?
            switch o {
            case "+": result = x + y
            case "-": result = x - y
            case "*": result = x * y
            case "/": result = x / y
            case "^": result = x.power(y)
            default: result = nil
            }
            guard let r = result else { return nil }
            if o == "/", !fractions, !r.isInteger { decimal = true }
            let A = write(a, letter: letter, decimal: decimal, parent: precedence(o))
            let B = write(b, letter: letter, decimal: decimal, parent: precedence(o), right: true)
            if fractions, !decimal, (o == "+" || o == "-"), x.d != y.d, let common = Rational.lcm(x.d, y.d) {
                let xa = "\(x.n * (common / x.d))/\(common)", yb = "\(y.n * (common / y.d))/\(common)"
                let raw = (o == "+" ? x.n * (common / x.d) + y.n * (common / y.d) : x.n * (common / x.d) - y.n * (common / y.d))
                var s = "Make the bottoms match: \(x.fractionText) = \(xa) and \(y.fractionText) = \(yb). Then \(xa) \(symbol(o)) \(yb) = \(raw)/\(common)."
                if Rational(raw, common) != nil, "\(raw)/\(common)" != r.fractionText { s += " That simplifies to \(r.fractionText)." }
                step = s
            } else if fractions, !decimal, o == "*" {
                let top = x.n * y.n, bottom = x.d * y.d
                step = "Times the tops and the bottoms: \(A) × \(B) = \(top)/\(bottom)."
                if "\(top)/\(bottom)" != r.fractionText { step += " That simplifies to \(r.fractionText)." }
            } else if fractions, !decimal, o == "/", y.n != 0 {
                let flipped = Rational(y.d, y.n)!
                step = "Flip the second one and times: \(A) × \(flipped.fractionText) = \(r.fractionText)."
            } else if o == "^" {
                step = "Do the power first: \(write(a, letter: letter, decimal: decimal, parent: 3))^\(B) = \(show(r, decimal: decimal))."
            } else {
                let what: String
                switch o {
                case "*": what = "Times"
                case "/": what = "Divide"
                case "+": what = "Add"
                default: what = "Take away"
                }
                step = "\(what): \(A) \(symbol(o)) \(B) = \(show(r, decimal: decimal))."
            }
            if fractions && !r.isInteger { return Node.frac(r) }
            return Node.num(r)
        }
        func rebuild(_ n: Node, _ path: [Bool]) -> Node? {
            if path.isEmpty { return apply(n) }
            switch n {
            case .op(let o, let a, let b):
                if path[0] { guard let nb = rebuild(b, Array(path.dropFirst())) else { return nil }; return .op(o, a, nb) }
                guard let na = rebuild(a, Array(path.dropFirst())) else { return nil }
                return .op(o, na, b)
            case .neg(let a):
                guard let na = rebuild(a, Array(path.dropFirst())) else { return nil }
                return .neg(na)
            default: return nil
            }
        }
        guard let out = rebuild(node, target.path) else { return nil }
        return (out, step)
    }

    // MARK: Equations

    /// a·x + b
    struct Linear: Equatable {
        var a: Rational
        var b: Rational
    }

    private static func linear(_ n: Node) -> Linear? {
        switch n {
        case .num(let r), .frac(let r): return Linear(a: .zero, b: r)
        case .variable: return Linear(a: .one, b: .zero)
        case .neg(let x):
            guard let l = linear(x) else { return nil }
            return Linear(a: -l.a, b: -l.b)
        case .op(let o, let x, let y):
            guard let l = linear(x), let r = linear(y) else { return nil }
            switch o {
            case "+":
                guard let a = l.a + r.a, let b = l.b + r.b else { return nil }
                return Linear(a: a, b: b)
            case "-":
                guard let a = l.a - r.a, let b = l.b - r.b else { return nil }
                return Linear(a: a, b: b)
            case "*":
                if l.a == .zero, let a = l.b * r.a, let b = l.b * r.b { return Linear(a: a, b: b) }
                if r.a == .zero, let a = r.b * l.a, let b = r.b * l.b { return Linear(a: a, b: b) }
                return nil   // x times x isn't a straight-line equation
            case "/":
                guard r.a == .zero, r.b != .zero, let a = l.a / r.b, let b = l.b / r.b else { return nil }
                return Linear(a: a, b: b)
            case "^":
                guard l.a == .zero, r.a == .zero, let v = l.b.power(r.b) else { return nil }
                return Linear(a: .zero, b: v)
            default: return nil
            }
        }
    }

    private static func write(_ l: Linear, letter: Character, decimal: Bool) -> String {
        var parts: [String] = []
        if l.a != .zero {
            let k: String
            if l.a == .one { k = "" } else if l.a == -Rational.one { k = "-" }
            else if l.a.isInteger || decimal { k = show(l.a, decimal: decimal) } else { k = "(\(l.a.fractionText))" }
            parts.append(k + String(letter))
        }
        if l.b != .zero || parts.isEmpty {
            let v = show(l.b.n < 0 && !parts.isEmpty ? -l.b : l.b, decimal: decimal)
            parts.append(parts.isEmpty ? v : (l.b.n < 0 ? "- " : "+ ") + v)
        }
        return parts.joined(separator: " ")
    }

    private static func equation(_ left: String, _ right: String) -> Solution? {
        guard let pl = parse(left), let pr = parse(right) else { return nil }
        guard pl.letter == nil || pr.letter == nil || pl.letter == pr.letter else { return nil }
        guard let letter = pl.letter ?? pr.letter else { return nil }   // "3 + 4 = 7" isn't an equation to solve
        let decimal = pl.decimals || pr.decimals
        let leftNode = markFractions(pl.node), rightNode = markFractions(pr.node)
        guard var l = linear(leftNode), var r = linear(rightNode) else { return nil }
        let problem = write(leftNode, letter: letter, decimal: decimal) + " = " + write(rightNode, letter: letter, decimal: decimal)
        let x = String(letter)
        var steps: [String] = []
        func now() -> String { write(l, letter: letter, decimal: decimal) + " = " + write(r, letter: letter, decimal: decimal) }
        if now() != problem { steps.append("Tidy up each side: \(now()).") }
        // Letters to the left.
        if r.a != .zero {
            let move = r.a
            guard let na = l.a - move else { return nil }
            l.a = na
            r.a = .zero
            let term = write(Linear(a: move.n < 0 ? -move : move, b: .zero), letter: letter, decimal: decimal)
            steps.append((move.n > 0 ? "Take away \(term) from both sides" : "Add \(term) to both sides") + ": \(now()).")
        }
        if l.a == .zero {
            let same = l.b == r.b
            steps.append(same ? "Both sides are always the same, so any number works for \(x)." : "The sides can never be equal, so no number works for \(x).")
            return Solution(problem: problem, steps: steps, answer: same ? "any number" : "no answer")
        }
        // Numbers to the right.
        if l.b != .zero {
            let move = l.b
            guard let nb = r.b - move else { return nil }
            r.b = nb
            l.b = .zero
            let amount = show(move.n < 0 ? -move : move, decimal: decimal)
            steps.append((move.n > 0 ? "Take away \(amount) from both sides" : "Add \(amount) to both sides") + ": \(now()).")
        }
        // Get the letter on its own.
        if l.a != .one {
            let k = l.a
            guard let v = r.b / k else { return nil }
            if k == -Rational.one {
                steps.append("Times both sides by -1: \(x) = \(show(v, decimal: decimal)).")
            } else if k.n == 1, k.d > 1 {
                steps.append("Times both sides by \(k.d): \(x) = \(show(v, decimal: decimal)).")
            } else {
                steps.append("Divide both sides by \(show(k, decimal: decimal)): \(x) = \(show(v, decimal: decimal)).")
            }
            r.b = v
            l.a = .one
        }
        let answer = r.b
        // Check by putting the answer back in.
        if let lv = evaluate(leftNode, x: answer), let rv = evaluate(rightNode, x: answer), lv == rv {
            steps.append("Check: with \(x) = \(show(answer, decimal: decimal)), both sides come to \(show(lv, decimal: decimal)).")
        }
        return Solution(problem: problem, steps: steps, answer: "\(x) = \(show(answer, decimal: decimal))")
    }

    private static func evaluate(_ n: Node, x: Rational) -> Rational? {
        switch n {
        case .num(let r), .frac(let r): return r
        case .variable: return x
        case .neg(let a): return evaluate(a, x: x).map { -$0 }
        case .op(let o, let a, let b):
            guard let p = evaluate(a, x: x), let q = evaluate(b, x: x) else { return nil }
            switch o {
            case "+": return p + q
            case "-": return p - q
            case "*": return p * q
            case "/": return p / q
            case "^": return p.power(q)
            default: return nil
            }
        }
    }
}

/// A worked problem: the steps, then the answer.
struct StepsCard: Codable, Equatable {
    var problem: String
    var steps: [String]
    var answer: String
}
