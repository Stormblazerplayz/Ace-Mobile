// @title Magic 8 Ball App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MagicEightBallView() in ContentView's body.
// @keywords swiftui magic 8 ball, swiftui fortune teller, swiftui random answer, swiftui shake animation
// @about Ask a yes or no question, tap the ball, and it wobbles before showing a random answer.

import SwiftUI

struct MagicEightBallView: View {
    @State private var question = ""
    @State private var answer = "Ask me anything"
    @State private var wobble = false
    @State private var showAnswer = true

    let answers = [
        "Yes, definitely", "It is certain", "Without a doubt", "Most likely",
        "Ask again later", "Cannot predict now", "Better not tell you now",
        "Don't count on it", "My reply is no", "Very doubtful", "Signs point to yes",
    ]

    var body: some View {
        VStack(spacing: 30) {
            TextField("Type a yes or no question", text: $question)
                .textFieldStyle(.roundedBorder)

            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.gray, .black], center: .topLeading, startRadius: 10, endRadius: 250))
                    .frame(width: 280, height: 280)
                    .shadow(radius: 10)
                Circle()
                    .fill(Color.indigo)
                    .frame(width: 140, height: 140)
                Text(answer)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(width: 110)
                    .opacity(showAnswer ? 1 : 0)
            }
            .rotationEffect(.degrees(wobble ? 8 : -8))
            .onTapGesture { shake() }

            Text("Tap the ball").foregroundStyle(.secondary)
        }
        .padding()
    }

    func shake() {
        showAnswer = false
        // Wobble back and forth a few times
        withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
            wobble.toggle()
        }
        // Then, after a short wait, show a new answer
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            answer = question.isEmpty ? "Ask a question first!" : (answers.randomElement() ?? "Maybe")
            withAnimation(.easeIn(duration: 0.6)) { showAnswer = true }
        }
    }
}
