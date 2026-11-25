import Foundation
import SwiftUI

/// A city you can add to World clocks, with its real time zone.
struct WorldCity: Codable, Identifiable, Equatable, Hashable {
    var name: String
    var country: String
    /// An IANA time zone name, like "Asia/Tokyo".
    var zoneID: String

    var id: String { zoneID + "|" + name }
    var zone: TimeZone? { TimeZone(identifier: zoneID) }

    /// Cities to pick from. Every one uses its real time zone, so daylight saving is handled by iPadOS.
    static let all: [WorldCity] = [
        WorldCity(name: "Honolulu", country: "United States", zoneID: "Pacific/Honolulu"),
        WorldCity(name: "Anchorage", country: "United States", zoneID: "America/Anchorage"),
        WorldCity(name: "Los Angeles", country: "United States", zoneID: "America/Los_Angeles"),
        WorldCity(name: "Phoenix", country: "United States", zoneID: "America/Phoenix"),
        WorldCity(name: "Denver", country: "United States", zoneID: "America/Denver"),
        WorldCity(name: "Chicago", country: "United States", zoneID: "America/Chicago"),
        WorldCity(name: "Mexico City", country: "Mexico", zoneID: "America/Mexico_City"),
        WorldCity(name: "New York", country: "United States", zoneID: "America/New_York"),
        WorldCity(name: "Toronto", country: "Canada", zoneID: "America/Toronto"),
        WorldCity(name: "St. John's", country: "Canada", zoneID: "America/St_Johns"),
        WorldCity(name: "São Paulo", country: "Brazil", zoneID: "America/Sao_Paulo"),
        WorldCity(name: "Buenos Aires", country: "Argentina", zoneID: "America/Argentina/Buenos_Aires"),
        WorldCity(name: "Reykjavik", country: "Iceland", zoneID: "Atlantic/Reykjavik"),
        WorldCity(name: "London", country: "United Kingdom", zoneID: "Europe/London"),
        WorldCity(name: "Dublin", country: "Ireland", zoneID: "Europe/Dublin"),
        WorldCity(name: "Lagos", country: "Nigeria", zoneID: "Africa/Lagos"),
        WorldCity(name: "Paris", country: "France", zoneID: "Europe/Paris"),
        WorldCity(name: "Madrid", country: "Spain", zoneID: "Europe/Madrid"),
        WorldCity(name: "Amsterdam", country: "Netherlands", zoneID: "Europe/Amsterdam"),
        WorldCity(name: "Berlin", country: "Germany", zoneID: "Europe/Berlin"),
        WorldCity(name: "Rome", country: "Italy", zoneID: "Europe/Rome"),
        WorldCity(name: "Stockholm", country: "Sweden", zoneID: "Europe/Stockholm"),
        WorldCity(name: "Athens", country: "Greece", zoneID: "Europe/Athens"),
        WorldCity(name: "Cairo", country: "Egypt", zoneID: "Africa/Cairo"),
        WorldCity(name: "Johannesburg", country: "South Africa", zoneID: "Africa/Johannesburg"),
        WorldCity(name: "Istanbul", country: "Turkey", zoneID: "Europe/Istanbul"),
        WorldCity(name: "Moscow", country: "Russia", zoneID: "Europe/Moscow"),
        WorldCity(name: "Nairobi", country: "Kenya", zoneID: "Africa/Nairobi"),
        WorldCity(name: "Dubai", country: "United Arab Emirates", zoneID: "Asia/Dubai"),
        WorldCity(name: "Karachi", country: "Pakistan", zoneID: "Asia/Karachi"),
        WorldCity(name: "Mumbai", country: "India", zoneID: "Asia/Kolkata"),
        WorldCity(name: "Kathmandu", country: "Nepal", zoneID: "Asia/Kathmandu"),
        WorldCity(name: "Dhaka", country: "Bangladesh", zoneID: "Asia/Dhaka"),
        WorldCity(name: "Bangkok", country: "Thailand", zoneID: "Asia/Bangkok"),
        WorldCity(name: "Jakarta", country: "Indonesia", zoneID: "Asia/Jakarta"),
        WorldCity(name: "Singapore", country: "Singapore", zoneID: "Asia/Singapore"),
        WorldCity(name: "Hong Kong", country: "China", zoneID: "Asia/Hong_Kong"),
        WorldCity(name: "Shanghai", country: "China", zoneID: "Asia/Shanghai"),
        WorldCity(name: "Manila", country: "Philippines", zoneID: "Asia/Manila"),
        WorldCity(name: "Perth", country: "Australia", zoneID: "Australia/Perth"),
        WorldCity(name: "Seoul", country: "South Korea", zoneID: "Asia/Seoul"),
        WorldCity(name: "Tokyo", country: "Japan", zoneID: "Asia/Tokyo"),
        WorldCity(name: "Sydney", country: "Australia", zoneID: "Australia/Sydney"),
        WorldCity(name: "Auckland", country: "New Zealand", zoneID: "Pacific/Auckland")
    ]
}

/// What the sky looks like at a time of day.
enum WorldSky: Equatable {
    case night, dawn, day, dusk

    /// From the hour (0 to 24, with fractions).
    static func at(hour: Double) -> WorldSky {
        switch hour {
        case 5..<7.5: return .dawn
        case 7.5..<17.5: return .day
        case 17.5..<20: return .dusk
        default: return .night
        }
    }

    var label: String {
        switch self {
        case .night: return "Night"
        case .dawn: return "Sunrise"
        case .day: return "Day"
        case .dusk: return "Sunset"
        }
    }

    var symbol: String {
        switch self {
        case .night: return "moon.stars.fill"
        case .dawn: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .dusk: return "sunset.fill"
        }
    }

    /// Top and bottom colors of the sky.
    var hexes: (UInt32, UInt32) {
        switch self {
        case .night: return (0x0B1030, 0x26215A)
        case .dawn: return (0x5B6CD8, 0xFFB38A)
        case .day: return (0x3FA2FF, 0x9EDCFF)
        case .dusk: return (0x3C2A78, 0xFF7A59)
        }
    }
}

/// Time math for World clocks.
enum WorldTime {
    /// The hour (0 to 24, with minutes as a fraction) somewhere.
    static func hour(at date: Date, in zone: TimeZone) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let parts = cal.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60 + Double(parts.second ?? 0) / 3600
    }

    /// How many seconds `zone` is ahead of `here` right then.
    static func difference(_ zone: TimeZone, from here: TimeZone, at date: Date) -> Int {
        zone.secondsFromGMT(for: date) - here.secondsFromGMT(for: date)
    }

    /// "Same time", "5 hours ahead", "3 hours 30 minutes behind", "1 hour ahead".
    static func differenceText(_ seconds: Int) -> String {
        guard seconds != 0 else { return "Same time" }
        let minutes = abs(seconds) / 60
        let h = minutes / 60
        let m = minutes % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) \(h == 1 ? "hour" : "hours")") }
        if m > 0 { parts.append("\(m) \(m == 1 ? "minute" : "minutes")") }
        return parts.joined(separator: " ") + (seconds > 0 ? " ahead" : " behind")
    }

    /// "Today", "Tomorrow" or "Yesterday" there, compared with the day here.
    static func dayWord(at date: Date, in zone: TimeZone, here: TimeZone) -> String {
        switch dayOffset(at: date, in: zone, here: here) {
        case 1...: return "Tomorrow"
        case ..<0: return "Yesterday"
        default: return "Today"
        }
    }

    /// How many calendar days ahead (+1) or behind (-1) it is there.
    static func dayOffset(at date: Date, in zone: TimeZone, here: TimeZone) -> Int {
        func dayNumber(_ tz: TimeZone) -> Int {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            let c = cal.dateComponents([.year, .month, .day], from: date)
            // A plain day count, so month and year edges work.
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = TimeZone(identifier: "UTC")!
            let d = utc.date(from: DateComponents(year: c.year, month: c.month, day: c.day)) ?? date
            return Int(d.timeIntervalSince1970 / 86_400)
        }
        return dayNumber(zone) - dayNumber(here)
    }

    /// Whether it's a good time to call someone there (8 AM to 9 PM).
    static func isAwakeHours(_ hour: Double) -> Bool {
        hour >= 8 && hour < 21
    }
}

/// The cities you added. Saved on the iPad in world-clocks.json.
@MainActor
final class WorldClockStore: ObservableObject {
    static let shared = WorldClockStore()

    nonisolated static let maxCities = 24

    @Published private(set) var cities: [WorldCity] = []

    private let fileName: String?

    /// `fileName` nil keeps everything in memory (for tests). The first time, it starts with London and Tokyo.
    init(fileName: String? = "world-clocks.json") {
        self.fileName = fileName
        if let fileName, let saved = Persistence.load([WorldCity].self, from: fileName) {
            cities = saved.filter { $0.zone != nil }
        } else {
            cities = WorldCity.all.filter { $0.name == "London" || $0.name == "Tokyo" }
        }
    }

    func has(_ city: WorldCity) -> Bool {
        cities.contains { $0.id == city.id }
    }

    /// Adds a city. Returns false when it's already there, its time zone is unknown, or the list is full.
    @discardableResult
    func add(_ city: WorldCity) -> Bool {
        guard !has(city), city.zone != nil, cities.count < Self.maxCities else { return false }
        cities.append(city)
        persist()
        return true
    }

    func remove(_ city: WorldCity) {
        cities.removeAll { $0.id == city.id }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        cities.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Cities whose name or country matches what you typed, ignoring capitals and accents.
    nonisolated static func search(_ text: String) -> [WorldCity] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return WorldCity.all }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return WorldCity.all.filter {
            $0.name.range(of: query, options: options) != nil || $0.country.range(of: query, options: options) != nil
        }
    }

    private func persist() {
        guard let fileName else { return }
        Persistence.save(cities, to: fileName)
    }
}
