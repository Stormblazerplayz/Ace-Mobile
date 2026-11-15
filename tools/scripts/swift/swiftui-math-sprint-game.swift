// @title Math Sprint Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MathSprintGameView() in ContentView's body.
// @keywords swiftui math sprint, swiftui arithmetic game, swiftui answer buttons, swiftui 60 second challenge
// @about Answer as many math questions as you can in 60 seconds by tapping the right answer out of four.

import Combine
import SwiftUI

struct MathSprintGameView: View {
    @State private var questionText = ""
    @State private var correctAnswer = 0
    @State private var options: [Int] = []
    @State private var score = 0
    @State private var timeLeft = 60
    @State private var playing = false
    @State private var flashColor = Color.clear

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text("Score: \(score)")
                Spacer()
                Text("Time: \(timeLeft)")
            }
            .font(.title2.bold())
            .monospacedDigit()

            Text(playing ? questionText : "Math Sprint")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity)
                .background(flashColor.opacity(0.3), in: RoundedRectangle(cornerRadius: 20))

            if playing {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            pick(option)
                        } label: {
                            Text("\(option)")
                                .font(.largeTitle.bold())
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Button(timeLeft == 0 ? "Play again" : "Start") { start() }
                    .buttonStyle(.borderedProminent)
                    .font(.title)
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
        timeLeft = 60
        playing = true
        newQuestion()
    }

    func newQuestion() {
        let a = Int.random(in: 2...12)
        let b = Int.random(in: 2...12)
        switch Int.random(in: 0..<3) {
        case 0:
            questionText = "\(a) + \(b)"
            correctAnswer = a + b
        case 1:
            questionText = "\(a + b) - \(b)"
            correctAnswer = a
        default:
            questionText = "\(a) x \(b)"
            correctAnswer = a * b
        }
        // Make three wrong answers that are close to the right one (a Set stops repeats)
        var choices: Set<Int> = [correctAnswer]
        while choices.count < 4 {
            let wrong = correctAnswer + Int.random(in: -10...10)
            if wrong >= 0 { choices.insert(wrong) }
        }
        options = Array(choices).shuffled()
    }

    func pick(_ option: Int) {
        if option == correctAnswer {
            score += 1
            flashColor = .green
        } else {
            score = max(0, score - 1)
            flashColor = .red
        }
        withAnimation(.easeOut(duration: 0.5)) { flashColor = .clear }
        newQuestion()
    }
}
