// @title Quiz App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show QuizAppView() in ContentView's body.
// @keywords swiftui quiz app, swiftui multiple choice, swiftui trivia, swiftui score screen
// @about A multiple choice science quiz that colors answers green or red and shows your score at the end.

import SwiftUI

struct QuizQuestion {
    let text: String
    let answers: [String]
    let correctIndex: Int
}

struct QuizAppView: View {
    let questions = [
        QuizQuestion(text: "Which planet is the biggest?", answers: ["Mars", "Jupiter", "Earth", "Venus"], correctIndex: 1),
        QuizQuestion(text: "What gas do plants breathe in?", answers: ["Oxygen", "Helium", "Carbon dioxide", "Nitrogen"], correctIndex: 2),
        QuizQuestion(text: "How many legs does a spider have?", answers: ["6", "8", "10", "12"], correctIndex: 1),
        QuizQuestion(text: "What is H2O?", answers: ["Salt", "Gold", "Air", "Water"], correctIndex: 3),
        QuizQuestion(text: "Which language do iPad apps use?", answers: ["Swift", "Cobra", "Ruby", "Rust"], correctIndex: 0),
    ]

    @State private var current = 0
    @State private var score = 0
    @State private var picked: Int? = nil   // nil means "not answered yet"
    @State private var finished = false

    func color(for index: Int) -> Color {
        guard let picked else { return .blue }
        if index == questions[current].correctIndex { return .green }
        return index == picked ? .red : .gray
    }

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                Text("Quiz finished!").font(.largeTitle.bold())
                Text("You got \(score) out of \(questions.count)").font(.title)
                Text(score == questions.count ? "Perfect score!" : "Nice try, go again!")
                Button("Play again") {
                    current = 0
                    score = 0
                    picked = nil
                    finished = false
                }
                .buttonStyle(.borderedProminent)
            } else {
                ProgressView(value: Double(current), total: Double(questions.count))
                Text("Question \(current + 1) of \(questions.count)").foregroundStyle(.secondary)
                Text(questions[current].text)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                ForEach(questions[current].answers.indices, id: \.self) { index in
                    Button {
                        guard picked == nil else { return }  // only one try
                        picked = index
                        if index == questions[current].correctIndex { score += 1 }
                    } label: {
                        Text(questions[current].answers[index])
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(color(for: index), in: RoundedRectangle(cornerRadius: 14))
                    }
                }

                if picked != nil {
                    Button(current + 1 < questions.count ? "Next question" : "See my score") {
                        picked = nil
                        if current + 1 < questions.count {
                            current += 1
                        } else {
                            finished = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
                Text("Score: \(score)")
            }
        }
        .padding()
        .animation(.default, value: picked)
    }
}
