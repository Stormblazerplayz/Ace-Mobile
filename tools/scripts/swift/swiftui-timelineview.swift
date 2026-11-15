// @title TimelineView Clock
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TimelineClockView() in ContentView's body.
// @keywords swiftui timelineview, swiftui live clock, swiftui redraw every second, swiftui animation schedule
// @about A digital clock and a spinning dot that redraw themselves on a schedule using TimelineView.

import SwiftUI

struct TimelineClockView: View {
    var body: some View {
        VStack(spacing: 40) {
            // .periodic redraws once every second
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack {
                    Text(context.date, format: .dateTime.hour().minute().second())
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                    Text(context.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .foregroundStyle(.secondary)
                }
            }

            // .animation redraws as fast as the screen can, for smooth motion
            TimelineView(.animation) { timeline in
                let seconds = timeline.date.timeIntervalSinceReferenceDate
                let angle = seconds.truncatingRemainder(dividingBy: 3) / 3 * 2 * Double.pi

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 24, height: 24)
                        .offset(x: CGFloat(80 * cos(angle)), y: CGFloat(80 * sin(angle)))
                }
            }
            Text("The dot goes around once every 3 seconds")
                .font(.caption)
        }
        .padding()
    }
}
