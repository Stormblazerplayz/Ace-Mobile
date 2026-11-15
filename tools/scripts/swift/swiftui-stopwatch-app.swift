// @title Stopwatch App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show StopwatchAppView() in ContentView's body.
// @keywords swiftui stopwatch, swiftui lap timer, swiftui elapsed time, swiftui monospaced digits
// @about A stopwatch with start, stop, lap and reset buttons and a list of lap times.

import SwiftUI

struct StopwatchAppView: View {
    @State private var startDate: Date? = nil   // when we last pressed Start
    @State private var savedTime: TimeInterval = 0  // time from earlier runs
    @State private var laps: [TimeInterval] = []

    var isRunning: Bool { startDate != nil }

    // Total time so far = earlier runs + this run
    func elapsed(at now: Date) -> TimeInterval {
        guard let startDate else { return savedTime }
        return savedTime + now.timeIntervalSince(startDate)
    }

    // Turns 83.456 seconds into "01:23.45"
    func format(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let hundredths = Int(time * 100) % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }

    var body: some View {
        VStack(spacing: 30) {
            // Redraw the time 100 times a second
            TimelineView(.periodic(from: .now, by: 0.01)) { context in
                Text(format(elapsed(at: context.date)))
                    .font(.system(size: 70, weight: .medium, design: .monospaced))
            }
            .padding(.top, 40)

            HStack(spacing: 40) {
                Button(isRunning ? "Lap" : "Reset") {
                    if isRunning {
                        laps.append(elapsed(at: .now))
                    } else {
                        savedTime = 0
                        laps.removeAll()
                    }
                }
                .frame(width: 100, height: 100)
                .background(Circle().fill(Color.gray.opacity(0.3)))

                Button(isRunning ? "Stop" : "Start") {
                    if isRunning {
                        savedTime = elapsed(at: .now)
                        startDate = nil
                    } else {
                        startDate = .now
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 100, height: 100)
                .background(Circle().fill(isRunning ? Color.red : Color.green))
            }
            .font(.title2.bold())

            List {
                ForEach(Array(laps.indices.reversed()), id: \.self) { index in
                    HStack {
                        Text("Lap \(index + 1)")
                        Spacer()
                        Text(format(laps[index])).monospacedDigit()
                    }
                }
            }
        }
    }
}
