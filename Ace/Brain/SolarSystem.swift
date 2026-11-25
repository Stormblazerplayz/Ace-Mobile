import Foundation

/// The Sun and the eight planets, with real numbers (NASA's planet fact sheets) and where each
/// planet is on any date (from its average orbit, so it's right to within a few degrees).
struct Planet: Identifiable, Equatable {
    let id: String
    let name: String
    let kind: String
    /// Across the middle, in kilometers.
    let diameterKm: Double
    /// Average distance from the Sun in AU (1 AU is Earth's distance, about 149.6 million km). 0 for the Sun.
    let au: Double
    /// One trip around the Sun, in Earth days.
    let yearDays: Double
    /// Sunrise to sunrise, in hours.
    let dayHours: Double
    /// Known moons in 2025 (more keep being found around the giant planets).
    let moons: Int
    /// Average temperature in °C (the Sun's is its surface).
    let tempC: Int
    /// How hard it pulls you down, in m/s² (Earth is 9.8).
    let gravity: Double
    /// Where it was on 1 January 2000 (degrees around the Sun) and how far it goes every 100 years.
    let longitude2000: Double
    let degreesPerCentury: Double
    /// Colors from the lit side to the dark side, as hex.
    let colors: [UInt32]
    let rings: Bool
    let banded: Bool
    let fact: String

    var isSun: Bool { au == 0 }
    /// How many Earths wide it is.
    var earthsWide: Double { diameterKm / 12_756 }
    var yearInEarthYears: Double { yearDays / 365.25 }
}

enum SolarSystem {
    static let kmPerAU = 149_597_870.7
    /// Light takes about 499 seconds to cross 1 AU.
    static let lightSecondsPerAU = 499.005

    static let sun = Planet(
        id: "sun", name: "The Sun", kind: "Star", diameterKm: 1_392_700, au: 0, yearDays: 0, dayHours: 609.1,
        moons: 0, tempC: 5_500, gravity: 274, longitude2000: 0, degreesPerCentury: 0,
        colors: [0xFFF6C8, 0xFFC93C, 0xFF7A1A], rings: false, banded: false,
        fact: "The Sun holds 99.8% of everything in the solar system. Its light takes about 8 minutes to reach Earth.")

    static let planets: [Planet] = [
        Planet(id: "mercury", name: "Mercury", kind: "Rocky planet", diameterKm: 4_879, au: 0.387, yearDays: 88.0, dayHours: 4_222.6,
               moons: 0, tempC: 167, gravity: 3.7, longitude2000: 252.250_323_5, degreesPerCentury: 149_472.674_111_75,
               colors: [0xC9C2BA, 0x8E8780, 0x4A4642], rings: false, banded: false,
               fact: "A year on Mercury is only 88 days, but one day, from sunrise to sunrise, lasts 176 Earth days."),
        Planet(id: "venus", name: "Venus", kind: "Rocky planet", diameterKm: 12_104, au: 0.723, yearDays: 224.7, dayHours: 2_802.0,
               moons: 0, tempC: 464, gravity: 8.9, longitude2000: 181.979_099_5, degreesPerCentury: 58_517.815_387_29,
               colors: [0xFFF1C9, 0xE8C27A, 0x9C6B2E], rings: false, banded: false,
               fact: "Venus spins backwards, so the Sun rises in the west there. Its thick air traps heat, making it the hottest planet."),
        Planet(id: "earth", name: "Earth", kind: "Rocky planet", diameterKm: 12_756, au: 1.0, yearDays: 365.2, dayHours: 24.0,
               moons: 1, tempC: 15, gravity: 9.8, longitude2000: 100.464_571_66, degreesPerCentury: 35_999.372_449_81,
               colors: [0x9FD8FF, 0x2F7FE0, 0x0C2E6B], rings: false, banded: false,
               fact: "Earth is the only planet we know of with life, and the only one with oceans of liquid water on top."),
        Planet(id: "mars", name: "Mars", kind: "Rocky planet", diameterKm: 6_792, au: 1.524, yearDays: 687.0, dayHours: 24.7,
               moons: 2, tempC: -65, gravity: 3.7, longitude2000: -4.553_432_05, degreesPerCentury: 19_140.302_684_99,
               colors: [0xFFB58A, 0xD8542B, 0x6E2210], rings: false, banded: false,
               fact: "Mars has Olympus Mons, the biggest volcano in the solar system, about 2.5 times as tall as Mount Everest."),
        Planet(id: "jupiter", name: "Jupiter", kind: "Gas giant", diameterKm: 142_984, au: 5.203, yearDays: 4_331, dayHours: 9.9,
               moons: 95, tempC: -110, gravity: 23.1, longitude2000: 34.396_440_51, degreesPerCentury: 3_034.746_127_75,
               colors: [0xF5DDB8, 0xC99B6B, 0x6B4529], rings: false, banded: true,
               fact: "All the other planets could fit inside Jupiter. Its Great Red Spot is a storm wider than Earth."),
        Planet(id: "saturn", name: "Saturn", kind: "Gas giant", diameterKm: 120_536, au: 9.537, yearDays: 10_747, dayHours: 10.7,
               moons: 274, tempC: -140, gravity: 9.0, longitude2000: 49.954_244_23, degreesPerCentury: 1_222.493_622_01,
               colors: [0xFFF0C4, 0xE3C27F, 0x8A6A35], rings: true, banded: true,
               fact: "Saturn is so light for its size that it would float in a big enough bathtub. Its rings are mostly chunks of ice."),
        Planet(id: "uranus", name: "Uranus", kind: "Ice giant", diameterKm: 51_118, au: 19.19, yearDays: 30_589, dayHours: 17.2,
               moons: 29, tempC: -195, gravity: 8.7, longitude2000: 313.238_104_51, degreesPerCentury: 428.482_027_85,
               colors: [0xD9FBFF, 0x7FD6E0, 0x2E7F8C], rings: true, banded: false,
               fact: "Uranus is tipped over on its side, so it rolls around the Sun like a ball."),
        Planet(id: "neptune", name: "Neptune", kind: "Ice giant", diameterKm: 49_528, au: 30.07, yearDays: 59_800, dayHours: 16.1,
               moons: 16, tempC: -200, gravity: 11.0, longitude2000: -55.120_029_69, degreesPerCentury: 218.459_453_25,
               colors: [0x9FC2FF, 0x3A63E0, 0x14246E], rings: false, banded: true,
               fact: "Neptune has the fastest winds in the solar system, over 2,000 km/h. It was found with math before anyone saw it."),
    ]

    static var everything: [Planet] { [sun] + planets }

    static func planet(_ id: String) -> Planet? {
        everything.first { $0.id == id }
    }

    /// The planet a sentence names ("show me saturn" finds Saturn, "the sun" finds the Sun).
    static func find(in text: String) -> Planet? {
        let words = " " + text.lowercased() + " "
        for p in everything {
            let names = p.isSun ? ["the sun", "sun"] : [p.id]
            if names.contains(where: { words.contains(" " + $0 + " ") }) { return p }
        }
        return nil
    }

    // MARK: Where things are

    /// Centuries since noon on 1 January 2000.
    static func centuries(_ date: Date) -> Double {
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        return (julianDay - 2_451_545) / 36_525
    }

    /// The planet's angle around the Sun on a date, 0 to 360 degrees (seen from above the North Pole).
    static func longitude(_ p: Planet, at date: Date) -> Double {
        let raw = p.longitude2000 + p.degreesPerCentury * centuries(date)
        let d = raw.truncatingRemainder(dividingBy: 360)
        return d < 0 ? d + 360 : d
    }

    /// Where the planet is, in AU, with the Sun in the middle.
    static func position(_ p: Planet, at date: Date) -> (x: Double, y: Double) {
        guard !p.isSun else { return (0, 0) }
        let a = longitude(p, at: date) * .pi / 180
        return (p.au * cos(a), p.au * sin(a))
    }

    /// How far it is from Earth on a date, in AU.
    static func distanceFromEarth(_ p: Planet, at date: Date) -> Double {
        let e = position(planets[2], at: date)
        let q = position(p, at: date)
        return ((q.x - e.x) * (q.x - e.x) + (q.y - e.y) * (q.y - e.y)).squareRoot()
    }

    /// Where the Moon is around Earth on a date, 0 to 360 degrees (its average path, right to within
    /// several degrees, which is plenty for a dot next to Earth).
    static func moonLongitude(at date: Date) -> Double {
        let days = centuries(date) * 36_525
        let d = (218.316 + 13.176_396 * days).truncatingRemainder(dividingBy: 360)
        return d < 0 ? d + 360 : d
    }

    static func lightMinutes(_ au: Double) -> Double { au * lightSecondsPerAU / 60 }

    /// "about 228 million km", "about 1.2 billion km".
    static func kilometers(_ au: Double) -> String {
        let km = au * kmPerAU
        if km >= 1_000_000_000 {
            return "about " + String(format: "%.1f", km / 1_000_000_000) + " billion km"
        }
        return "about \(Int((km / 1_000_000).rounded())) million km"
    }

    /// "8 minutes", "1 hour and 14 minutes".
    static func lightTime(_ au: Double) -> String {
        let minutes = Int(lightMinutes(au).rounded())
        guard minutes >= 60 else { return minutes == 1 ? "1 minute" : "\(minutes) minutes" }
        let h = minutes / 60, m = minutes % 60
        let hours = h == 1 ? "1 hour" : "\(h) hours"
        if m == 0 { return hours }
        return hours + " and " + (m == 1 ? "1 minute" : "\(m) minutes")
    }

    /// What something weighing `kg` on Earth would weigh there.
    static func weight(_ kg: Double, on p: Planet) -> Double {
        kg * p.gravity / 9.8
    }

    /// "88 days", "1.9 years", "165 years".
    static func yearText(_ p: Planet) -> String {
        if p.yearDays < 730 { return "\(Int(p.yearDays.rounded())) days" }
        let y = p.yearInEarthYears
        return y < 20 ? String(format: "%.1f years", y) : "\(Int(y.rounded())) years"
    }

    /// "24 hours", "176 days".
    static func dayText(_ p: Planet) -> String {
        if p.dayHours < 48 { return String(format: p.dayHours.rounded() == p.dayHours ? "%.0f hours" : "%.1f hours", p.dayHours) }
        return "\(Int((p.dayHours / 24).rounded())) days"
    }

    /// What Ace says when you ask where a planet is right now.
    static func whereNow(_ p: Planet, at date: Date = Date()) -> String {
        if p.id == "earth" { return "You're standing on it! Earth is about 150 million km from the Sun." }
        if p.isSun {
            return "The Sun is about 150 million km away. Its light takes about 8 minutes to get here."
        }
        let au = distanceFromEarth(p, at: date)
        return "Right now \(p.name) is \(kilometers(au)) from Earth (about \(String(format: "%.1f", au)) times the Earth to Sun distance). "
            + "Its light takes \(lightTime(au)) to reach us. Planets move, so this changes every day."
    }
}

/// Understands space asks: "show me the solar system", "show me saturn", "how far is mars right now".
/// Returns "open", "planet:<id>" or "where:<id>".
enum SpaceAsk {
    private static let polite = #"^(?:(?:please|ok|okay|alright|hey ace|ace|yo|can we|could we|can you|could you|can i|let us|lets|i want to|want to|i would like to|time to)\s+)*"#
    private static let end = #"(?:\s+(?:please|now|for me|with me|together|again))*$"#
    private static let names = #"(mercury|venus|earth|mars|jupiter|saturn|uranus|neptune|the sun|sun)"#
    private static let place = #"(?:the )?(?:solar system|planets|space explorer|ace space|outer space|space)"#

    static func parse(_ t: String) -> String? {
        // "how far is mars right now", "where is jupiter now"
        if let g = Rx.groups(#"^(?:where is|where s|where are)\s+(?:the planet\s+)?"# + names + #"\s+(?:right now|now|today|at the moment|in space right now)$"#, t)
            ?? Rx.groups(#"^how far (?:away )?is\s+(?:the planet\s+)?"# + names + #"(?:\s+(?:from|away from) (?:earth|us|here))?\s+(?:right now|now|today|at the moment)$"#, t),
           let p = SolarSystem.find(in: g[0]) {
            return "where:" + p.id
        }
        // "show me saturn", "take me to mars", "zoom in on jupiter"
        if let g = Rx.groups(polite + #"(?:show me|take me to|fly to|fly me to|zoom in on|zoom to|visit|go to|explore)\s+(?:the planet\s+)?"# + names
                                + #"(?:\s+(?:in space|in the solar system|on the solar system map|planet))?"# + end, t),
           let p = SolarSystem.find(in: g[0]) {
            return "planet:" + p.id
        }
        // "show me the solar system", "open space explorer", "explore space"
        if Rx.matches(polite + #"(?:show me|show|open|explore|launch|start|go to|take me to|bring up|pull up|fly through|see)\s+"# + place + #"(?: map| explorer| view)?"# + end, t)
            || Rx.matches(#"^(?:the )?(?:solar system|space explorer|ace space)(?: map| explorer)?$"#, t)
            || Rx.matches(#"^where are (?:all )?the planets(?: right now| now| today)?$"#, t) {
            return "open"
        }
        return nil
    }
}

/// Where things go on the solar system map. Real distances would put Neptune 78 times farther out
/// than Mercury, so the map squeezes them (on a log scale) while keeping their order and angles real.
enum SpaceMap {
    private static let stretch = 3.0

    /// How far out a planet's orbit is drawn, from `inner` (Mercury) to `outer` (Neptune).
    static func radius(_ au: Double, inner: Double, outer: Double) -> Double {
        guard au > 0 else { return 0 }
        let first = log(1 + 0.387 * stretch), last = log(1 + 30.07 * stretch)
        let t = (log(1 + au * stretch) - first) / (last - first)
        return inner + (outer - inner) * t
    }

    /// Where the planet sits on the map on a date, with the Sun at `center`. Up on screen is
    /// counterclockwise, the way the planets go round when seen from above the North Pole.
    static func point(_ p: Planet, at date: Date, center: (x: Double, y: Double), inner: Double, outer: Double) -> (x: Double, y: Double) {
        guard !p.isSun else { return center }
        let r = radius(p.au, inner: inner, outer: outer)
        let a = SolarSystem.longitude(p, at: date) * .pi / 180
        return (center.x + r * cos(a), center.y - r * sin(a))
    }

    /// How big a planet's dot is: bigger planets are bigger, but small ones stay easy to tap.
    static func dotRadius(_ p: Planet, scale: Double = 1) -> Double {
        if p.isSun { return 30 * scale }
        return (4.5 + 2.1 * (p.diameterKm / 1_000).squareRoot()) * scale
    }

    /// The planet nearest a tap, if the tap is close enough to it.
    static func planet(near tap: (x: Double, y: Double), at date: Date, center: (x: Double, y: Double),
                       inner: Double, outer: Double, scale: Double = 1) -> Planet? {
        var best: (Planet, Double)?
        for p in SolarSystem.everything {
            let q = point(p, at: date, center: center, inner: inner, outer: outer)
            let d = ((q.x - tap.x) * (q.x - tap.x) + (q.y - tap.y) * (q.y - tap.y)).squareRoot()
            let reach = max(26, dotRadius(p, scale: scale) + 14)
            if d <= reach, d < (best?.1 ?? .infinity) { best = (p, d) }
        }
        return best?.0
    }
}
