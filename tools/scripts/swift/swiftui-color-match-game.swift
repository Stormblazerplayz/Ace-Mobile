// @title Color Word Match Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ColorMatchGameView() in ContentView's body.
// @keywords swiftui color word game, swiftui stroop test, swiftui brain trainer, swiftui quick decision
// @about A brain trick game: does the word's meaning match the color it is painted in? Answer fast for 30 seconds.

import Combine
import SwiftUI

struct ColorMatchGameView: View {
    let names = ["RED", "BLUE", "GREEN", "ORANGE", "PURPLE"]
    let colors: [Color] = [.red, .blue, .green, .orange, .purple]

    @State private var wordIndex = 0
    @State private var inkIndex = 0
    @State private var score = 0
    @State private var wrong = 0
    @State private var timeLeft = 30
    @State private var playing = false

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var isMatch: Bool { wordIndex == inkIndex }

    var body: some View {
        VStack(spacing: 30) {
            Text("Time: \(timeLeft)   Score: \(score)   Wrong: \(wrong)")
                .font(.title3.bold())
                .monospacedDigit()

            Text("Does the WORD match its COLOR?").foregroundStyle(.secondary)

            Text(playing ? names[wordIndex] : "READY?")
                .font(.system(size: 72, weight: .black))
                .foregroundStyle(playing ? colors[inkIndex] : Color.primary)

            if playing {
                HStack(spacing: 20) {
                    Button("Match") { answer(true) }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button("No match") { answer(false) }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray)
                }
                .font(.title2)
            } else {
                Button(timeLeft == 0 ? "Play again" : "Start") { start() }
                    .buttonStyle(.borderedProminent)
                    .font(.title2)
            }
        }
        .padding()
        .onReceive(clock) { _ in
            guard playing else { return }
            timeLeft -= 1
            if timeLeft <= 0 { playing = false }
        }
    }

    func start() {
        score = 0
        wrong = 0
        timeLeft = 30
        playing = true
        newWord()
    }

    func newWord() {
        wordIndex = Int.random(in: 0..<names.count)
        // Half the time make it match, so it's fair
        inkIndex = Bool.random() ? wordIndex : Int.random(in: 0..<colors.count)
    }

    func answer(_ saidMatch: Bool) {
        if saidMatch == isMatch {
            score += 1
        } else {
            wrong += 1
        }
        newWord()
    }
}
