// @title Dates and Times
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Dates.swift and run in Terminal: swiftc -parse-as-library Dates.swift -o dates && ./dates
// @keywords swift date, swift calendar, swift date formatting, swift days between dates, swift dateformatter
// @about Gets today's date, formats it in different styles and counts the days until an upcoming date.

import Foundation

@main
struct DatesProgram {
    static func main() {
        let now = Date()
        let calendar = Calendar.current

        // Built-in formatting styles
        print("Full: \(now.formatted(date: .complete, time: .shortened))")
        print("Short: \(now.formatted(date: .numeric, time: .omitted))")
        print("Just the weekday: \(now.formatted(.dateTime.weekday(.wide)))")

        // Your own format with DateFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d 'at' h:mm a"
        print("Custom: \(formatter.string(from: now))")

        // Pieces of the date
        let parts = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        print("Year \(parts.year ?? 0), month \(parts.month ?? 0), day \(parts.day ?? 0), hour \(parts.hour ?? 0)")

        // Date math: add days
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) {
            print("One week from now: \(nextWeek.formatted(date: .abbreviated, time: .omitted))")
        }

        // Days until next New Year's Day
        let nextYear = (parts.year ?? 2026) + 1
        if let newYear = calendar.date(from: DateComponents(year: nextYear, month: 1, day: 1)) {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: newYear).day ?? 0
            print("Days until New Year \(nextYear): \(days)")
        }

        // Measure how long something takes
        let start = Date()
        var total = 0
        for n in 1...1_000_000 { total &+= n }
        print("Added a million numbers (\(total)) in \(String(format: "%.4f", Date().timeIntervalSince(start))) seconds")
    }
}
