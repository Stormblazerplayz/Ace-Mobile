// @title DatePicker
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show DatePickerDemoView() in ContentView's body.
// @keywords swiftui datepicker, swiftui pick a date, swiftui graphical calendar, swiftui date range, swiftui time picker
// @about Lets you pick a date and a time, shows a calendar, and counts the days until the chosen date.

import SwiftUI

struct DatePickerDemoView: View {
    @State private var eventDate = Date.now.addingTimeInterval(7 * 24 * 60 * 60)
    @State private var alarm = Date.now

    var daysAway: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: eventDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // in: Date.now... means you can't pick a day in the past
                DatePicker("Event", selection: $eventDate, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)

                Text(daysAway == 0 ? "That's today!" : "\(daysAway) days to go")
                    .font(.title2.bold())

                Text(eventDate.formatted(date: .complete, time: .omitted))
                    .foregroundStyle(.secondary)

                Divider()

                // Just the time
                DatePicker("Alarm", selection: $alarm, displayedComponents: .hourAndMinute)
                Text("Alarm set for \(alarm.formatted(date: .omitted, time: .shortened))")
            }
            .padding()
        }
    }
}
