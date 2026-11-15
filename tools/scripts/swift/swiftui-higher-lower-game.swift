// @title Higher or Lower Card Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show HigherLowerGameView() in ContentView's body.
// @keywords swiftui higher or lower, swiftui card guessing, swiftui streak game, swiftui playing card view
// @about Guess if the next card will be higher or lower and see how long a streak you can build.

import SwiftUI

struct HigherLowerGameView: View {
    let cardNames = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    let suits = ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill"]

    @State private var card = Int.random(in: 1...13)
    @State private var suit = 0
    @State private var streak = 0
    @State private var best = 0
    @State private var message = "Will the next card be higher or lower?"

    var body: some View {
        VStack(spacing: 30) {
            Text("Streak: \(streak)   Best: \(best)").font(.title2.bold())

            // A simple playing card
            VStack {
                Text(cardNames[card]).font(.system(size: 80, weight: .bold))
                Image(systemName: suits[suit]).font(.system(size: 50))
            }
            .foregroundStyle(suit < 2 ? Color.red : Color.black)
            .frame(width: 200, height: 280)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 2))
            .shadow(radius: 6)
            .id(card * 10 + suit)   // a new id makes the transition play
            .transition(.scale.combined(with: .opacity))

            Text(message).multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button("Higher") { guess(higher: true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                Button("Lower") { guess(higher: false) }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
            .font(.title2)
        }
        .padding()
    }

    func guess(higher: Bool) {
        let next = Int.random(in: 1...13)
        let correct = higher ? next > card : next < card
        if next == card {
            message = "Same card! That one doesn't count."
        } else if correct {
            streak += 1
            best = max(best, streak)
            message = "Yes! It was \(cardNames[next])."
        } else {
            message = "Nope, it was \(cardNames[next]). Streak lost!"
            streak = 0
        }
        withAnimation(.spring(duration: 0.4)) {
            card = next
            suit = Int.random(in: 0..<4)
        }
    }
}
