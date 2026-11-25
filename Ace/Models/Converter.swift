import Foundation

/// The kinds of things Ace's converter can measure.
enum MeasureKind: String, CaseIterable, Identifiable, Codable {
    case length, weight, temperature, volume, speed, area, time, data

    var id: String { rawValue }

    var title: String {
        switch self {
        case .length: return "Length"
        case .weight: return "Weight"
        case .temperature: return "Temperature"
        case .volume: return "Volume"
        case .speed: return "Speed"
        case .area: return "Area"
        case .time: return "Time"
        case .data: return "Data"
        }
    }

    var symbol: String {
        switch self {
        case .length: return "ruler.fill"
        case .weight: return "scalemass.fill"
        case .temperature: return "thermometer.medium"
        case .volume: return "drop.fill"
        case .speed: return "gauge.with.dots.needle.67percent"
        case .area: return "square.dashed"
        case .time: return "clock.fill"
        case .data: return "externaldrive.fill"
        }
    }

    /// Two colors for this kind's tile, glow and bars.
    var hexes: (UInt32, UInt32) {
        switch self {
        case .length: return (0x5BB6FF, 0x8F7CFF)
        case .weight: return (0xFFCF3A, 0xFF8A3D)
        case .temperature: return (0xFF5F8F, 0xFFB020)
        case .volume: return (0x3DDCFF, 0x45D483)
        case .speed: return (0xFF5A4E, 0xFF5F8F)
        case .area: return (0x45D483, 0xB6F36A)
        case .time: return (0x8F7CFF, 0xFF5F8F)
        case .data: return (0x5BB6FF, 0x3DDCFF)
        }
    }

    /// The pair of units it starts on.
    var defaultPair: (from: String, to: String) {
        switch self {
        case .length: return ("m", "ft")
        case .weight: return ("kg", "lb")
        case .temperature: return ("c", "f")
        case .volume: return ("cup", "ml")
        case .speed: return ("kmh", "mph")
        case .area: return ("m2", "ft2")
        case .time: return ("h", "min")
        case .data: return ("mb", "gb")
        }
    }
}

/// One unit. `perBase` is how many base units one of these is (metres, kilograms, litres,
/// metres per second, square metres, seconds or bytes). Temperature works differently.
struct MeasureUnit: Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let perBase: Double
}

/// Something real to compare an amount with, like a soda can or a marathon.
struct MeasureReference: Identifiable, Hashable {
    let name: String
    let symbol: String
    /// Its size in the kind's base unit.
    let base: Double
    /// True when the size is only about right (things vary), so the app says "about".
    let rough: Bool
    var id: String { name }
}

/// One line of the "In every unit" list.
struct MeasureRow: Identifiable, Hashable {
    let unit: MeasureUnit
    let value: Double
    var id: String { unit.id }
}

/// How an amount compares with a reference.
struct MeasureComparison: Identifiable, Hashable {
    let reference: MeasureReference
    /// How many of the reference fit in the amount.
    let times: Double
    var id: String { reference.id }
}

/// Exact conversion factors (from the international definitions of the inch, pound, US gallon
/// and so on) and the maths behind Ace's unit converter.
enum Converter {
    /// The longest number you can type.
    static let maxDigits = 15

    static func units(_ kind: MeasureKind) -> [MeasureUnit] {
        switch kind {
        case .length:
            return [
                MeasureUnit(id: "mm", name: "Millimetres", short: "mm", perBase: 0.001),
                MeasureUnit(id: "cm", name: "Centimetres", short: "cm", perBase: 0.01),
                MeasureUnit(id: "m", name: "Metres", short: "m", perBase: 1),
                MeasureUnit(id: "km", name: "Kilometres", short: "km", perBase: 1000),
                MeasureUnit(id: "in", name: "Inches", short: "in", perBase: 0.0254),
                MeasureUnit(id: "ft", name: "Feet", short: "ft", perBase: 0.3048),
                MeasureUnit(id: "yd", name: "Yards", short: "yd", perBase: 0.9144),
                MeasureUnit(id: "mi", name: "Miles", short: "mi", perBase: 1609.344),
                MeasureUnit(id: "nmi", name: "Nautical miles", short: "nmi", perBase: 1852)
            ]
        case .weight:
            return [
                MeasureUnit(id: "mg", name: "Milligrams", short: "mg", perBase: 0.000001),
                MeasureUnit(id: "g", name: "Grams", short: "g", perBase: 0.001),
                MeasureUnit(id: "kg", name: "Kilograms", short: "kg", perBase: 1),
                MeasureUnit(id: "t", name: "Metric tonnes", short: "t", perBase: 1000),
                MeasureUnit(id: "oz", name: "Ounces", short: "oz", perBase: 0.028349523125),
                MeasureUnit(id: "lb", name: "Pounds", short: "lb", perBase: 0.45359237),
                MeasureUnit(id: "st", name: "Stone", short: "st", perBase: 6.35029318),
                MeasureUnit(id: "ton", name: "US tons", short: "US ton", perBase: 907.18474)
            ]
        case .temperature:
            return [
                MeasureUnit(id: "c", name: "Celsius", short: "°C", perBase: 1),
                MeasureUnit(id: "f", name: "Fahrenheit", short: "°F", perBase: 1),
                MeasureUnit(id: "k", name: "Kelvin", short: "K", perBase: 1)
            ]
        case .volume:
            return [
                MeasureUnit(id: "ml", name: "Millilitres", short: "mL", perBase: 0.001),
                MeasureUnit(id: "l", name: "Litres", short: "L", perBase: 1),
                MeasureUnit(id: "m3", name: "Cubic metres", short: "m³", perBase: 1000),
                MeasureUnit(id: "tsp", name: "Teaspoons (US)", short: "tsp", perBase: 0.00492892159375),
                MeasureUnit(id: "tbsp", name: "Tablespoons (US)", short: "tbsp", perBase: 0.01478676478125),
                MeasureUnit(id: "floz", name: "Fluid ounces (US)", short: "fl oz", perBase: 0.0295735295625),
                MeasureUnit(id: "cup", name: "Cups (US)", short: "cup", perBase: 0.2365882365),
                MeasureUnit(id: "pt", name: "Pints (US)", short: "pt", perBase: 0.473176473),
                MeasureUnit(id: "qt", name: "Quarts (US)", short: "qt", perBase: 0.946352946),
                MeasureUnit(id: "gal", name: "Gallons (US)", short: "gal", perBase: 3.785411784)
            ]
        case .speed:
            return [
                MeasureUnit(id: "ms", name: "Metres per second", short: "m/s", perBase: 1),
                MeasureUnit(id: "kmh", name: "Kilometres per hour", short: "km/h", perBase: 1 / 3.6),
                MeasureUnit(id: "mph", name: "Miles per hour", short: "mph", perBase: 0.44704),
                MeasureUnit(id: "kn", name: "Knots", short: "kn", perBase: 1852.0 / 3600.0),
                MeasureUnit(id: "fts", name: "Feet per second", short: "ft/s", perBase: 0.3048)
            ]
        case .area:
            return [
                MeasureUnit(id: "cm2", name: "Square centimetres", short: "cm²", perBase: 0.0001),
                MeasureUnit(id: "m2", name: "Square metres", short: "m²", perBase: 1),
                MeasureUnit(id: "ha", name: "Hectares", short: "ha", perBase: 10_000),
                MeasureUnit(id: "km2", name: "Square kilometres", short: "km²", perBase: 1_000_000),
                MeasureUnit(id: "in2", name: "Square inches", short: "in²", perBase: 0.00064516),
                MeasureUnit(id: "ft2", name: "Square feet", short: "ft²", perBase: 0.09290304),
                MeasureUnit(id: "yd2", name: "Square yards", short: "yd²", perBase: 0.83612736),
                MeasureUnit(id: "ac", name: "Acres", short: "ac", perBase: 4046.8564224),
                MeasureUnit(id: "mi2", name: "Square miles", short: "mi²", perBase: 2_589_988.110336)
            ]
        case .time:
            return [
                MeasureUnit(id: "ms", name: "Milliseconds", short: "ms", perBase: 0.001),
                MeasureUnit(id: "s", name: "Seconds", short: "s", perBase: 1),
                MeasureUnit(id: "min", name: "Minutes", short: "min", perBase: 60),
                MeasureUnit(id: "h", name: "Hours", short: "h", perBase: 3600),
                MeasureUnit(id: "day", name: "Days", short: "days", perBase: 86_400),
                MeasureUnit(id: "wk", name: "Weeks", short: "weeks", perBase: 604_800),
                MeasureUnit(id: "yr", name: "Years (365.25 days)", short: "years", perBase: 31_557_600)
            ]
        case .data:
            return [
                MeasureUnit(id: "bit", name: "Bits", short: "bits", perBase: 0.125),
                MeasureUnit(id: "b", name: "Bytes", short: "B", perBase: 1),
                MeasureUnit(id: "kb", name: "Kilobytes", short: "KB", perBase: 1000),
                MeasureUnit(id: "mb", name: "Megabytes", short: "MB", perBase: 1_000_000),
                MeasureUnit(id: "gb", name: "Gigabytes", short: "GB", perBase: 1_000_000_000),
                MeasureUnit(id: "tb", name: "Terabytes", short: "TB", perBase: 1_000_000_000_000),
                MeasureUnit(id: "kib", name: "Kibibytes", short: "KiB", perBase: 1024),
                MeasureUnit(id: "mib", name: "Mebibytes", short: "MiB", perBase: 1_048_576),
                MeasureUnit(id: "gib", name: "Gibibytes", short: "GiB", perBase: 1_073_741_824)
            ]
        }
    }

    static func unit(_ id: String, in kind: MeasureKind) -> MeasureUnit? {
        units(kind).first { $0.id == id }
    }

    /// The amount in the kind's base unit (Celsius for temperature).
    static func toBase(_ value: Double, from unit: MeasureUnit, kind: MeasureKind) -> Double {
        guard kind == .temperature else { return value * unit.perBase }
        switch unit.id {
        case "f": return (value - 32) * 5 / 9
        case "k": return value - 273.15
        default: return value
        }
    }

    /// An amount in the kind's base unit (Celsius for temperature), turned into `unit`.
    static func fromBase(_ base: Double, to unit: MeasureUnit, kind: MeasureKind) -> Double {
        guard kind == .temperature else { return base / unit.perBase }
        switch unit.id {
        case "f": return base * 9 / 5 + 32
        case "k": return base + 273.15
        default: return base
        }
    }

    static func convert(_ value: Double, from: MeasureUnit, to: MeasureUnit, kind: MeasureKind) -> Double {
        if from.id == to.id { return value }
        return fromBase(toBase(value, from: from, kind: kind), to: to, kind: kind)
    }

    /// Reads what was typed: commas are ignored and a lone "-" or "." counts as nothing yet.
    static func parse(_ text: String) -> Double? {
        let clean = text.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, let value = Double(clean), value.isFinite else { return nil }
        return value
    }

    /// Keeps only what makes a number: digits, one dot and a minus at the front (temperatures only).
    static func cleanTyping(_ text: String, allowNegative: Bool) -> String {
        var out = ""
        var dot = false
        var digits = 0
        for ch in text {
            if ch.isASCII, ch.isNumber {
                guard digits < maxDigits else { continue }
                digits += 1
                out.append(ch)
            } else if ch == "." || ch == ",", !dot {
                // Some keyboards type a comma for the decimal point.
                dot = true
                out.append(".")
            } else if ch == "-" || ch == "−", allowNegative, out.isEmpty {
                out.append("-")
            }
        }
        return out
    }

    /// A short, readable number: up to 7 significant digits with thousands commas, or
    /// scientific notation when it's huge or tiny.
    static func format(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        let size = abs(value)
        if size < 1e-12 { return "0" }
        if size >= 1e15 || size < 1e-6 {
            let text = String(format: "%.4e", value)
            return tidyScientific(text)
        }
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.usesSignificantDigits = true
        f.minimumSignificantDigits = 1
        f.maximumSignificantDigits = 7
        return f
    }()

    /// "1.2000e+20" becomes "1.2 × 10²⁰".
    private static func tidyScientific(_ text: String) -> String {
        let parts = text.split(separator: "e")
        guard parts.count == 2, let power = Int(parts[1]) else { return text }
        var mantissa = String(parts[0])
        if mantissa.contains(".") {
            while mantissa.hasSuffix("0") { mantissa.removeLast() }
            if mantissa.hasSuffix(".") { mantissa.removeLast() }
        }
        return "\(mantissa) × 10\(superscript(power))"
    }

    static func superscript(_ number: Int) -> String {
        let map: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"
        ]
        return String(String(number).compactMap { map[$0] })
    }

    /// Every unit of the kind showing the same amount.
    static func everyUnit(_ value: Double, from: MeasureUnit, kind: MeasureKind) -> [MeasureRow] {
        units(kind).map { MeasureRow(unit: $0, value: convert(value, from: from, to: $0, kind: kind)) }
    }

    // MARK: Comparing with real things

    static func references(_ kind: MeasureKind) -> [MeasureReference] {
        switch kind {
        case .length:
            return [
                MeasureReference(name: "credit card width", symbol: "creditcard.fill", base: 0.0856, rough: false),
                MeasureReference(name: "American football field (100 yards)", symbol: "sportscourt.fill", base: 91.44, rough: false),
                MeasureReference(name: "Mount Everest", symbol: "mountain.2.fill", base: 8849, rough: false),
                MeasureReference(name: "marathon", symbol: "figure.run", base: 42_195, rough: false)
            ]
        case .weight:
            return [
                MeasureReference(name: "US nickel", symbol: "centsign.circle.fill", base: 0.005, rough: false),
                MeasureReference(name: "litre of water", symbol: "drop.fill", base: 1, rough: true),
                MeasureReference(name: "car", symbol: "car.fill", base: 1500, rough: true)
            ]
        case .temperature:
            return []
        case .volume:
            return [
                MeasureReference(name: "teaspoon", symbol: "fork.knife", base: 0.00492892159375, rough: false),
                MeasureReference(name: "soda can (12 fl oz)", symbol: "takeoutbag.and.cup.and.straw.fill", base: 0.3548823547500, rough: false),
                MeasureReference(name: "bathtub", symbol: "bathtub.fill", base: 150, rough: true),
                MeasureReference(name: "Olympic pool", symbol: "figure.pool.swim", base: 2_500_000, rough: true)
            ]
        case .speed:
            return [
                MeasureReference(name: "walking person", symbol: "figure.walk", base: 5 / 3.6, rough: true),
                MeasureReference(name: "car on the highway (65 mph)", symbol: "car.fill", base: 65 * 0.44704, rough: false),
                MeasureReference(name: "speed of sound (sea level, 20°C)", symbol: "speaker.wave.3.fill", base: 343, rough: true)
            ]
        case .area:
            return [
                MeasureReference(name: "sheet of letter paper", symbol: "doc.fill", base: 0.2159 * 0.2794, rough: false),
                MeasureReference(name: "tennis court (doubles)", symbol: "tennisball.fill", base: 23.77 * 10.97, rough: false),
                MeasureReference(name: "soccer field (105 × 68 m)", symbol: "soccerball", base: 105 * 68, rough: false)
            ]
        case .time:
            return [
                MeasureReference(name: "minute", symbol: "timer", base: 60, rough: false),
                MeasureReference(name: "school day (about 7 hours)", symbol: "backpack.fill", base: 7 * 3600, rough: true),
                MeasureReference(name: "year", symbol: "calendar", base: 31_557_600, rough: false)
            ]
        case .data:
            return [
                MeasureReference(name: "text message (140 bytes)", symbol: "message.fill", base: 140, rough: false),
                MeasureReference(name: "song (MP3)", symbol: "music.note", base: 4_000_000, rough: true),
                MeasureReference(name: "HD movie", symbol: "film.fill", base: 4_000_000_000, rough: true)
            ]
        }
    }

    /// How the amount (in the base unit) compares with each reference, smallest reference first.
    static func compare(base: Double, kind: MeasureKind) -> [MeasureComparison] {
        guard base > 0, base.isFinite else { return [] }
        return references(kind)
            .sorted { $0.base < $1.base }
            .map { MeasureComparison(reference: $0, times: base / $0.base) }
    }

    /// The comparison that's easiest to picture: the one closest to "1 of them" (on a log scale),
    /// preferring ones you need at least one of.
    static func headline(_ comparisons: [MeasureComparison]) -> MeasureComparison? {
        let atLeastOne = comparisons.filter { $0.times >= 1 }
        let pool = atLeastOne.isEmpty ? comparisons : atLeastOne
        return pool.min { abs(log10($0.times)) < abs(log10($1.times)) }
    }

    /// "a", "an" or nothing (for names like Mount Everest) to go before a reference's name.
    static func article(_ name: String) -> String {
        if name.hasPrefix("Mount ") { return "" }
        if name.hasPrefix("HD") { return "an" }
        guard let first = name.lowercased().first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }

    /// A sentence like "About 3.2 × bathtub", "Half a marathon" or "12% of Mount Everest".
    static func sentence(_ comparison: MeasureComparison) -> String {
        let times = comparison.times
        let name = comparison.reference.name
        let rough = comparison.reference.rough
        let a = article(name)
        let thing = a.isEmpty ? name : "\(a) \(name)"
        if abs(times - 0.5) < 0.005 {
            return rough ? "About half \(thing)" : "Half \(thing)"
        }
        if abs(times - 1) < 0.005 {
            return rough ? "About one \(name)" : "One \(name)"
        }
        if times < 1 {
            let percent = min(99, max(1, Int((times * 100).rounded())))
            return rough ? "About \(percent)% of \(thing)" : "\(percent)% of \(thing)"
        }
        let count = times >= 100 ? format(times.rounded()) : format((times * 10).rounded() / 10)
        return rough ? "About \(count) × \(name)" : "\(count) × \(name)"
    }

    /// Where a bar should end on a log scale from 0 to 1, for ratios between 1/1000 and 1000.
    static func barFill(_ times: Double) -> Double {
        guard times > 0, times.isFinite else { return 0 }
        let position = (log10(times) + 3) / 6
        return min(1, max(0, position))
    }

    // MARK: Temperature landmarks

    struct Landmark: Identifiable, Hashable {
        let name: String
        let celsius: Double
        var id: String { name }
    }

    static let landmarks: [Landmark] = [
        Landmark(name: "Water freezes", celsius: 0),
        Landmark(name: "Room", celsius: 20),
        Landmark(name: "Body", celsius: 37),
        Landmark(name: "Water boils", celsius: 100)
    ]

    /// The thermometer runs from −40 °C to 120 °C.
    static let thermometerRange: ClosedRange<Double> = -40...120

    /// How full the thermometer is, from 0 to 1.
    static func thermometerFill(celsius: Double) -> Double {
        let low = thermometerRange.lowerBound
        let high = thermometerRange.upperBound
        return min(1, max(0, (celsius - low) / (high - low)))
    }

    /// A word for how hot or cold it feels.
    static func feel(celsius: Double) -> String {
        switch celsius {
        case ..<(-273.15): return "Colder than anything can be"
        case ..<(-20): return "Bitterly cold"
        case ..<0: return "Freezing"
        case ..<10: return "Cold"
        case ..<18: return "Cool"
        case ..<25: return "Comfy"
        case ..<32: return "Warm"
        case ..<45: return "Hot"
        case ..<100: return "Scalding"
        default: return "Boiling hot"
        }
    }

    // MARK: Remembering your pairs

    /// Saves which two units each kind was on, like "length=m>ft;weight=kg>lb".
    static func encodePairs(_ pairs: [MeasureKind: (from: String, to: String)]) -> String {
        MeasureKind.allCases.compactMap { kind in
            guard let pair = pairs[kind] else { return nil }
            return "\(kind.rawValue)=\(pair.from)>\(pair.to)"
        }
        .joined(separator: ";")
    }

    /// Reads saved pairs back, skipping anything that isn't a real unit of that kind.
    static func decodePairs(_ text: String) -> [MeasureKind: (from: String, to: String)] {
        var out: [MeasureKind: (from: String, to: String)] = [:]
        for chunk in text.split(separator: ";") {
            let sides = chunk.split(separator: "=", maxSplits: 1)
            guard sides.count == 2, let kind = MeasureKind(rawValue: String(sides[0])) else { continue }
            let ids = sides[1].split(separator: ">", maxSplits: 1).map(String.init)
            guard ids.count == 2, unit(ids[0], in: kind) != nil, unit(ids[1], in: kind) != nil else { continue }
            out[kind] = (ids[0], ids[1])
        }
        return out
    }
}
