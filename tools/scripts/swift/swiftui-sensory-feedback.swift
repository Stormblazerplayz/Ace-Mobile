// @title Haptic Feedback
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show HapticsDemoView() in ContentView's body. Feel it on an iPhone (most iPads don't vibrate).
// @keywords swiftui sensoryfeedback, swiftui haptics, swiftui vibration, swiftui feedback trigger
// @about Makes the device tap or buzz when things happen, using the iOS 17 sensoryFeedback modifier.

import SwiftUI

struct HapticsDemoView: View {
    @State private var taps = 0
    @State private var wins = 0
    @State private var mistakes = 0
    @State private var level = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Text("Feel the buttons!").font(.title.bold())

            Button("Light tap (\(taps))") { taps += 1 }
                .buttonStyle(.bordered)
                // Every time "taps" changes, play a light impact
                .sensoryFeedback(.impact(weight: .light), trigger: taps)

            Button("I won! (\(wins))") { wins += 1 }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .sensoryFeedback(.success, trigger: wins)

            Button("Oops (\(mistakes))") { mistakes += 1 }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .sensoryFeedback(.error, trigger: mistakes)

            VStack {
                Text("Level \(Int(level))")
                Slider(value: $level, in: 1...10, step: 1)
                    // A little click each time the level changes
                    .sensoryFeedback(.selection, trigger: level)
            }
        }
        .padding()
    }
}
