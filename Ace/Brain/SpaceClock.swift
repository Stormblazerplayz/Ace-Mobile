import Foundation

/// The solar system map's own clock. It can stand still, or race ahead so you can watch the planets
/// go round: one second of real time can be a day, a week, a month or a year on the map.
struct SpaceClock: Equatable {
    enum Warp: String, CaseIterable, Identifiable {
        case paused, day, week, month, year

        var id: String { rawValue }

        /// Map days that pass in one real second.
        var daysPerSecond: Double {
            switch self {
            case .paused: return 0
            case .day: return 1
            case .week: return 7
            case .month: return 30.44
            case .year: return 365.25
            }
        }

        var label: String {
            switch self {
            case .paused: return "Paused"
            case .day: return "1 day a second"
            case .week: return "1 week a second"
            case .month: return "1 month a second"
            case .year: return "1 year a second"
            }
        }

        var short: String {
            switch self {
            case .paused: return "Stop"
            case .day: return "Day"
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            }
        }

        var symbol: String {
            switch self {
            case .paused: return "pause.fill"
            case .day: return "play.fill"
            case .week: return "forward.fill"
            case .month: return "forward.end.fill"
            case .year: return "hare.fill"
            }
        }
    }

    /// The map's date when the clock was last set, and the real time it was set at.
    private(set) var anchor: Date
    private(set) var setAt: Date
    private(set) var warp: Warp

    init(date: Date = Date(), warp: Warp = .paused, now: Date = Date()) {
        anchor = date
        setAt = now
        self.warp = warp
    }

    /// The map's date at a real moment.
    func date(at now: Date) -> Date {
        let seconds = max(0, now.timeIntervalSince(setAt))
        return anchor.addingTimeInterval(seconds * warp.daysPerSecond * 86_400)
    }

    var running: Bool { warp != .paused }

    /// Changes the speed without making the planets jump.
    mutating func set(_ newWarp: Warp, now: Date = Date()) {
        anchor = date(at: now)
        setAt = now
        warp = newWarp
    }

    /// Jumps to a date and keeps the same speed.
    mutating func jump(to date: Date, now: Date = Date()) {
        anchor = date
        setAt = now
    }

    /// Moves the map's date by some days (back if negative), keeping the same speed.
    mutating func shift(days: Double, now: Date = Date()) {
        jump(to: date(at: now).addingTimeInterval(days * 86_400), now: now)
    }

    /// True when the map shows today (within a day either way).
    func isToday(at now: Date, today: Date = Date()) -> Bool {
        abs(date(at: now).timeIntervalSince(today)) < 86_400
    }
}
