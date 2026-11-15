// @title Countdown Timer App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show CountdownTimerAppView() in ContentView's body.
// @keywords swiftui countdown timer, swiftui timer publish, swiftui progress ring, swiftui onreceive
// @about A countdown timer with a ring that empties as time runs out, using Timer.publish to tick every second.

import Combine
import SwiftUI

struct CountdownTimerAppView: View {
    @State private var totalSeconds = 60
    @State private var remaining = 60
    @State private var running = false
    @State private var finished = false

    let presets = [10, 30, 60, 300, 600]
    // A timer that sends a "tick" every second
    let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var progress: CGFloat {
        totalSeconds == 0 ? 0 : CGFloat(remaining) / CGFloat(totalSeconds)
    }

    var timeText: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    func label(for seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m"
    }

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: progress)  // only draw part of the circle
                    .stroke(finished ? Color.red : Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))  // start at the top
                    .animation(.linear(duration: 1), value: remaining)
                Text(finished ? "Done!" : timeText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 260, height: 260)

            Picker("Time", selection: $totalSeconds) {
                ForEach(presets, id: \.self) { seconds in
                    Text(label(for: seconds)).tag(seconds)
                }
            }
            .pickerStyle(.segmented)
            .disabled(running)
            .onChange(of: totalSeconds) {
                remaining = totalSeconds
                finished = false
            }

            HStack(spacing: 20) {
                Button(running ? "Pause" : "Start") {
                    if remaining == 0 { remaining = totalSeconds }
                    finished = false
                    running.toggle()
                }
                .buttonStyle(.borderedProminent)
                Button("Reset") {
                    running = false
                    finished = false
                    remaining = totalSeconds
                }
                .buttonStyle(.bordered)
            }
            .font(.title2)
        }
        .padding()
        // This runs every time the ticker ticks
        .onReceive(ticker) { _ in
            guard running else { return }
            if remaining > 0 { remaining -= 1 }
            if remaining == 0 {
                running = false
                finished = true
            }
        }
        .sensoryFeedback(.success, trigger: finished)
    }
}
