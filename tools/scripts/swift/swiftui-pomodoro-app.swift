// @title Pomodoro Focus Timer
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PomodoroAppView() in ContentView's body.
// @keywords swiftui pomodoro, swiftui focus timer, swiftui study breaks, swiftui work rest cycle
// @about A study timer that switches between 25 minutes of focus and 5 minute breaks, counting finished sessions.

import Combine
import SwiftUI

struct PomodoroAppView: View {
    @State private var isBreak = false
    @State private var secondsLeft = 25 * 60
    @State private var running = false
    @State private var sessions = 0

    let focusLength = 25 * 60
    let breakLength = 5 * 60
    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timeText: String { String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60) }

    var body: some View {
        ZStack {
            // The whole screen changes color for focus or break time
            (isBreak ? Color.green : Color.red)
                .opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(isBreak ? "Break time" : "Focus time")
                    .font(.largeTitle.bold())
                Text(timeText)
                    .font(.system(size: 90, weight: .bold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 20) {
                    Button(running ? "Pause" : "Start") { running.toggle() }
                        .buttonStyle(.borderedProminent)
                    Button("Skip") { switchMode() }
                        .buttonStyle(.bordered)
                    Button("Reset") {
                        running = false
                        isBreak = false
                        secondsLeft = focusLength
                    }
                    .buttonStyle(.bordered)
                }
                .font(.title2)

                // One tomato for each focus session finished
                Text(String(repeating: "* ", count: sessions))
                    .font(.title)
                Text("Sessions finished: \(sessions)")
            }
        }
        .onReceive(clock) { _ in
            guard running else { return }
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                switchMode()
            }
        }
        .sensoryFeedback(.success, trigger: isBreak)
    }

    func switchMode() {
        if !isBreak { sessions += 1 }   // a focus session just ended
        isBreak.toggle()
        secondsLeft = isBreak ? breakLength : focusLength
    }
}
