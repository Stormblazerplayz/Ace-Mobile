import Foundation

/// Learns roughly when you go to sleep and wake up from when you use Ace
/// (last use at night, first use in the morning) and suggests a bedtime.
/// It's a guess from app use, not a sleep tracker.
@MainActor
final class SleepCoach {
    struct Day: Codable {
        var key: String          // yyyy-MM-dd of the "night" (a 1 AM use counts for the day before)
        var firstMinute: Int?    // first use after 4 AM, minutes after midnight
        var lastMinute: Int?     // last use, minutes after midnight (can be over 1440 after midnight)
    }

    private var days: [Day] = []
    private let file = "sleep_log.json"
    /// Kids 6–12 need 9–12 hours and teens 8–10, so Ace aims for 9 and a half.
    let targetSleepHours = 9.5

    init() {
        days = Persistence.load([Day].self, from: file) ?? []
    }

    /// Call whenever the user is actively using Ace.
    func noteActive(_ date: Date = Date()) {
        let cal = Calendar.current
        let minute = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        if minute < 4 * 60 {
            // After midnight: counts as a late night for yesterday.
            let yesterday = cal.date(byAdding: .day, value: -1, to: date) ?? date
            update(Persistence.dayKey(yesterday)) { d in d.lastMinute = max(d.lastMinute ?? 0, minute + 1440) }
        } else {
            update(Persistence.dayKey(date)) { d in
                if d.firstMinute == nil { d.firstMinute = minute }
                d.lastMinute = max(d.lastMinute ?? 0, minute)
            }
        }
    }

    private func update(_ key: String, _ change: (inout Day) -> Void) {
        if let i = days.firstIndex(where: { $0.key == key }) {
            change(&days[i])
        } else {
            var d = Day(key: key)
            change(&d)
            days.append(d)
        }
        if days.count > 30 { days.removeFirst(days.count - 30) }
        Persistence.save(days, to: file)
    }

    struct Advice {
        var text: String
        var bedtime: Date?
    }

    func advice(now: Date = Date()) -> Advice {
        let recent = days.suffix(14)
        let lates = recent.compactMap { $0.lastMinute }.filter { $0 >= 18 * 60 }
        let wakes = recent.compactMap { $0.firstMinute }.filter { $0 >= 4 * 60 && $0 <= 12 * 60 }
        guard lates.count >= 3, wakes.count >= 3 else {
            return Advice(text: "I'm still learning your sleep times from when you use me. Give me a few more days. Most kids your age do best with 9 to 11 hours of sleep.", bedtime: nil)
        }
        let avgLate = Double(lates.reduce(0, +)) / Double(lates.count)
        let avgWake = Double(wakes.reduce(0, +)) / Double(wakes.count)
        var bed = avgWake - targetSleepHours * 60
        if bed < 0 { bed += 1440 }
        let bedMinute = Int(bed.rounded())
        let bedDate = Calendar.current.date(bySettingHour: (bedMinute / 60) % 24, minute: bedMinute % 60, second: 0, of: now)
        let lateText = clock(Int(avgLate.rounded()))
        let wakeText = clock(Int(avgWake.rounded()))
        let bedText = clock(bedMinute)
        let hours = (avgWake + 1440 - avgLate).truncatingRemainder(dividingBy: 1440) / 60
        var text = "You usually finish up around \(lateText) and start around \(wakeText). "
        if hours < 9 {
            text += String(format: "That's about %.1f hours. Try going to bed around %@ to get closer to 9 and a half hours.", hours, bedText)
        } else {
            text += String(format: "That's about %.1f hours, which is great. Keep a bedtime around %@.", hours, bedText)
        }
        return Advice(text: text, bedtime: bedDate)
    }

    /// True once tonight's suggested bedtime is near (within 20 minutes after it).
    func isNearBedtime(now: Date = Date()) -> Bool {
        guard let bed = advice(now: now).bedtime else { return false }
        let diff = now.timeIntervalSince(bed)
        return diff >= -5 * 60 && diff <= 20 * 60
    }

    private func clock(_ minute: Int) -> String {
        let m = ((minute % 1440) + 1440) % 1440
        let date = Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
