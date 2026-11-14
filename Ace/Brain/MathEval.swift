import Foundation

/// Works out math said in words or symbols: "what is 12 times 8", "15% of 80",
/// "square root of 144", "(3 + 4) ^ 2".
enum MathEval {
    enum MathError: Error { case bad }

    /// Turns spoken math into symbols. Returns nil if there's no math in it.
    static func expression(from text: String) -> String? {
        var s = " " + text.lowercased() + " "
        let swaps: [(String, String)] = [
            (" multiplied by ", " * "), (" times ", " * "), (" x ", " * "), (" × ", " * "),
            (" divided by ", " / "), (" over ", " / "), (" ÷ ", " / "),
            (" plus ", " + "), (" add ", " + "), (" minus ", " - "), (" take away ", " - "), (" subtract ", " - "),
            (" to the power of ", " ^ "), (" power ", " ^ "), (" squared ", " ^ 2 "), (" cubed ", " ^ 3 "),
            (" square root of ", " sqrt "), (" the square root of ", " sqrt "), (" sqrt of ", " sqrt "),
            (" cube root of ", " cbrt "), (" mod ", " % "), (" modulo ", " % "),
            (" percent of ", " pctof "), ("% of ", " pctof "), (" point ", "."),
        ]
        for (a, b) in swaps { s = s.replacingOccurrences(of: a, with: b) }
        let fillers = ["what is", "what's", "whats", "how much is", "calculate", "compute", "solve", "equals", "equal",
                       "work out", "?", "=", "please", "can you", "tell me", "do", "is"]
        for f in fillers { s = s.replacingOccurrences(of: " \(f) ", with: " ") }
        s = s.replacingOccurrences(of: ",", with: "")
        s = numberWordsToDigits(s)
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Only digits, operators and our keywords may remain.
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/^%() ")
        let check = trimmed.replacingOccurrences(of: "sqrt", with: "").replacingOccurrences(of: "cbrt", with: "")
            .replacingOccurrences(of: "pctof", with: "").replacingOccurrences(of: "pi", with: "")
        guard check.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              trimmed.rangeOfCharacter(from: .decimalDigits) != nil,
              trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: "+-*/^%")) != nil || trimmed.contains("sqrt")
                || trimmed.contains("cbrt") || trimmed.contains("pctof")
        else { return nil }
        return trimmed
    }

    static func evaluate(_ expr: String) throws -> Double {
        var p = Parser(tokens: tokenize(expr))
        let v = try p.parseExpression()
        guard p.atEnd, v.isFinite else { throw MathError.bad }
        return v
    }

    static func format(_ v: Double) -> String {
        if v == v.rounded(), abs(v) < 1e15 {
            return NumberFormatter.localizedString(from: NSNumber(value: Int64(v)), number: .decimal)
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 6
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    private static let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
        "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
        "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
    ]

    /// "twenty five" -> "25", "a hundred" -> "100", "three thousand" -> "3000".
    static func numberWordsToDigits(_ text: String) -> String {
        let words = text.split(separator: " ").map(String.init)
        var out: [String] = []
        var current = 0
        var total = 0
        var inNumber = false
        func flush() {
            if inNumber { out.append(String(total + current)) }
            current = 0
            total = 0
            inNumber = false
        }
        for (i, w) in words.enumerated() {
            if let n = numberWords[w] {
                current += n
                inNumber = true
            } else if w == "hundred" && (inNumber || (i > 0 && words[i - 1] == "a")) {
                if !inNumber, out.last == "a" { out.removeLast(); current = 1; inNumber = true }
                current = max(current, 1) * 100
            } else if (w == "thousand" || w == "million" || w == "billion") && inNumber {
                let m = w == "thousand" ? 1_000 : w == "million" ? 1_000_000 : 1_000_000_000
                total += max(current, 1) * m
                current = 0
            } else if w == "and" && inNumber {
                continue
            } else {
                flush()
                out.append(w)
            }
        }
        flush()
        return out.joined(separator: " ")
    }

    private enum Token: Equatable {
        case num(Double), op(Character), lparen, rparen, fn(String)
    }

    private static func tokenize(_ s: String) -> [Token] {
        var tokens: [Token] = []
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            if c == " " { i = s.index(after: i); continue }
            if c.isNumber || c == "." {
                var j = i
                while j < s.endIndex, s[j].isNumber || s[j] == "." { j = s.index(after: j) }
                tokens.append(.num(Double(s[i..<j]) ?? .nan))
                i = j
                continue
            }
            if c.isLetter {
                var j = i
                while j < s.endIndex, s[j].isLetter { j = s.index(after: j) }
                let word = String(s[i..<j])
                if word == "pi" { tokens.append(.num(Double.pi)) } else { tokens.append(.fn(word)) }
                i = j
                continue
            }
            if c == "(" { tokens.append(.lparen) }
            else if c == ")" { tokens.append(.rparen) }
            else if "+-*/^%".contains(c) { tokens.append(.op(c)) }
            i = s.index(after: i)
        }
        return tokens
    }

    private struct Parser {
        var tokens: [Token]
        var pos = 0
        var atEnd: Bool { pos >= tokens.count }

        mutating func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }
        mutating func next() -> Token? {
            defer { pos += 1 }
            return pos < tokens.count ? tokens[pos] : nil
        }

        // expression := term (('+' | '-') term)*
        mutating func parseExpression() throws -> Double {
            var v = try parseTerm()
            while let t = peek(), case .op(let o) = t, o == "+" || o == "-" {
                pos += 1
                let r = try parseTerm()
                v = o == "+" ? v + r : v - r
            }
            return v
        }

        // term := power (('*' | '/' | '%' | pctof) power)*
        mutating func parseTerm() throws -> Double {
            var v = try parsePower()
            while let t = peek() {
                if case .op(let o) = t, o == "*" || o == "/" || o == "%" {
                    pos += 1
                    let r = try parsePower()
                    if o == "*" { v *= r }
                    else if o == "/" { guard r != 0 else { throw MathError.bad }; v /= r }
                    else {
                        // "%" right after a number with nothing following means percent.
                        v = r == 0 ? v / 100 : v.truncatingRemainder(dividingBy: r)
                    }
                } else if case .fn("pctof") = t {
                    pos += 1
                    let r = try parsePower()
                    v = v / 100 * r
                } else {
                    break
                }
            }
            return v
        }

        // power := unary ('^' power)?
        mutating func parsePower() throws -> Double {
            let base = try parseUnary()
            if let t = peek(), case .op("^") = t {
                pos += 1
                let e = try parsePower()
                return pow(base, e)
            }
            return base
        }

        mutating func parseUnary() throws -> Double {
            if let t = peek(), case .op("-") = t {
                pos += 1
                return -(try parseUnary())
            }
            if let t = peek(), case .op("+") = t {
                pos += 1
                return try parseUnary()
            }
            return try parsePrimary()
        }

        mutating func parsePrimary() throws -> Double {
            guard let t = next() else { throw MathError.bad }
            switch t {
            case .num(let n):
                guard !n.isNaN else { throw MathError.bad }
                // A trailing "%" with no number after it: 50% -> 0.5
                if let p = peek(), case .op("%") = p, pos + 1 >= tokens.count {
                    pos += 1
                    return n / 100
                }
                return n
            case .lparen:
                let v = try parseExpression()
                guard let close = next(), close == .rparen else { throw MathError.bad }
                return v
            case .fn(let name):
                let arg = try parseUnary()
                switch name {
                case "sqrt": guard arg >= 0 else { throw MathError.bad }; return arg.squareRoot()
                case "cbrt": return cbrt(arg)
                default: throw MathError.bad
                }
            default:
                throw MathError.bad
            }
        }
    }
}

/// Unit conversion with Apple's Measurement types (so the numbers are exact).
enum UnitConvert {
    private static let units: [String: Dimension] = {
        var u: [String: Dimension] = [:]
        func add(_ names: [String], _ d: Dimension) { for n in names { u[n] = d } }
        add(["mm", "millimeter", "millimeters", "millimetre", "millimetres"], UnitLength.millimeters)
        add(["cm", "centimeter", "centimeters", "centimetre", "centimetres"], UnitLength.centimeters)
        add(["m", "meter", "meters", "metre", "metres"], UnitLength.meters)
        add(["km", "kilometer", "kilometers", "kilometre", "kilometres"], UnitLength.kilometers)
        add(["in", "inch", "inches"], UnitLength.inches)
        add(["ft", "foot", "feet"], UnitLength.feet)
        add(["yd", "yard", "yards"], UnitLength.yards)
        add(["mi", "mile", "miles"], UnitLength.miles)
        add(["mg", "milligram", "milligrams"], UnitMass.milligrams)
        add(["g", "gram", "grams"], UnitMass.grams)
        add(["kg", "kilo", "kilos", "kilogram", "kilograms"], UnitMass.kilograms)
        add(["oz", "ounce", "ounces"], UnitMass.ounces)
        add(["lb", "lbs", "pound", "pounds"], UnitMass.pounds)
        add(["ml", "milliliter", "milliliters", "millilitre", "millilitres"], UnitVolume.milliliters)
        add(["l", "liter", "liters", "litre", "litres"], UnitVolume.liters)
        add(["tsp", "teaspoon", "teaspoons"], UnitVolume.teaspoons)
        add(["tbsp", "tablespoon", "tablespoons"], UnitVolume.tablespoons)
        add(["cup", "cups"], UnitVolume.cups)
        add(["pint", "pints"], UnitVolume.pints)
        add(["quart", "quarts"], UnitVolume.quarts)
        add(["gallon", "gallons", "gal"], UnitVolume.gallons)
        add(["c", "celsius", "°c", "degrees celsius", "centigrade"], UnitTemperature.celsius)
        add(["f", "fahrenheit", "°f", "degrees fahrenheit"], UnitTemperature.fahrenheit)
        add(["k", "kelvin"], UnitTemperature.kelvin)
        add(["s", "sec", "secs", "second", "seconds"], UnitDuration.seconds)
        add(["min", "mins", "minute", "minutes"], UnitDuration.minutes)
        add(["h", "hr", "hrs", "hour", "hours"], UnitDuration.hours)
        add(["mph", "miles per hour"], UnitSpeed.milesPerHour)
        add(["kph", "km/h", "kmh", "kilometers per hour", "kilometres per hour"], UnitSpeed.kilometersPerHour)
        add(["mps", "m/s", "meters per second"], UnitSpeed.metersPerSecond)
        add(["kb", "kilobyte", "kilobytes"], UnitInformationStorage.kilobytes)
        add(["mb", "megabyte", "megabytes"], UnitInformationStorage.megabytes)
        add(["gb", "gigabyte", "gigabytes"], UnitInformationStorage.gigabytes)
        add(["tb", "terabyte", "terabytes"], UnitInformationStorage.terabytes)
        add(["byte", "bytes"], UnitInformationStorage.bytes)
        return u
    }()

    /// "5 km to miles", "how many cups in 2 liters", "100 f in c".
    static func convert(_ text: String) -> String? {
        let t = TextKit.normalize(text)
        let unitPattern = #"([a-z°/ ]+?)"#
        let patterns = [
            #"(-?\d+(?:\.\d+)?)\s*"# + unitPattern + #"\s+(?:to|in|into|as)\s+"# + unitPattern + #"$"#,
            #"how many\s+"# + unitPattern + #"\s+(?:are\s+)?(?:in|is)\s+(-?\d+(?:\.\d+)?)\s*"# + unitPattern + #"$"#,
        ]
        for (i, p) in patterns.enumerated() {
            guard let m = Rx.groups(p, in: t), m.count == 3 else { continue }
            let value: Double?
            let fromName: String
            let toName: String
            if i == 0 {
                value = Double(m[0]); fromName = clean(m[1]); toName = clean(m[2])
            } else {
                value = Double(m[1]); fromName = clean(m[2]); toName = clean(m[0])
            }
            guard let v = value, let from = units[fromName], let to = units[toName],
                  type(of: from) == type(of: to) else { continue }
            let result = Measurement(value: v, unit: from).converted(to: to)
            let f = MeasurementFormatter()
            f.unitOptions = .providedUnit
            f.unitStyle = .long
            f.numberFormatter.maximumFractionDigits = 3
            let a = f.string(from: Measurement(value: v, unit: from))
            let b = f.string(from: result)
            return "\(a) is \(b)."
        }
        return nil
    }

    private static func clean(_ s: String) -> String {
        var x = s.trimmingCharacters(in: .whitespaces)
        for prefix in ["degrees ", "degree "] where x.hasPrefix(prefix) && units[x] == nil {
            x = String(x.dropFirst(prefix.count))
        }
        if x.hasPrefix("the ") { x = String(x.dropFirst(4)) }
        return x
    }
}

/// Roman numerals both ways.
enum Roman {
    static func toRoman(_ n: Int) -> String? {
        guard (1...3999).contains(n) else { return nil }
        let table: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
                                      (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var n = n
        var out = ""
        for (v, s) in table {
            while n >= v { out += s; n -= v }
        }
        return out
    }

    static func fromRoman(_ s: String) -> Int? {
        let values: [Character: Int] = ["I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000]
        let chars = Array(s.uppercased())
        guard !chars.isEmpty, chars.allSatisfy({ values[$0] != nil }) else { return nil }
        var total = 0
        for i in chars.indices {
            let v = values[chars[i]]!
            if i + 1 < chars.count, let next = values[chars[i + 1]], next > v { total -= v } else { total += v }
        }
        return toRoman(total) == s.uppercased() ? total : nil
    }
}

/// Tiny regex helper: returns the capture groups of the first match.
enum Rx {
    static func groups(_ pattern: String, in text: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let m = re.firstMatch(in: text, range: range) else { return nil }
        var out: [String] = []
        for i in 1..<max(1, m.numberOfRanges) {
            if let r = Range(m.range(at: i), in: text) { out.append(String(text[r])) } else { out.append("") }
        }
        return out
    }

    static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
