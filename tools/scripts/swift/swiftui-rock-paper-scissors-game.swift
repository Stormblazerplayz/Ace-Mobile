// @title Rock Paper Scissors Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show RPSGameView() in ContentView's body.
// @keywords swiftui rock paper scissors, swiftui enum caseiterable, swiftui best of five, swiftui versus computer
// @about Play rock paper scissors against the iPad, first to three wins takes the match.

import SwiftUI

enum RPSChoice: String, CaseIterable {
    case rock = "Rock"
    case paper = "Paper"
    case scissors = "Scissors"

    var symbol: String {
        switch self {
        case .rock: return "mountain.2.fill"
        case .paper: return "doc.fill"
        case .scissors: return "scissors"
        }
    }

    // Does this choice beat the other one?
    func beats(_ other: RPSChoice) -> Bool {
        (self == .rock && other == .scissors) ||
        (self == .paper && other == .rock) ||
        (self == .scissors && other == .paper)
    }
}

struct RPSGameView: View {
    @State private var playerPick: RPSChoice? = nil
    @State private var computerPick: RPSChoice? = nil
    @State private var playerWins = 0
    @State private var computerWins = 0
    @State private var roundText = "Pick one!"

    var matchOver: Bool { playerWins == 3 || computerWins == 3 }

    var body: some View {
        VStack(spacing: 28) {
            Text("You \(playerWins)  :  \(computerWins) iPad")
                .font(.largeTitle.bold())
                .monospacedDigit()

            HStack(spacing: 50) {
                ChoiceBadge(title: "You", choice: playerPick)
                ChoiceBadge(title: "iPad", choice: computerPick)
            }

            Text(matchOver ? (playerWins == 3 ? "You win the match!" : "The iPad wins the match!") : roundText)
                .font(.title2)

            HStack(spacing: 16) {
                ForEach(RPSChoice.allCases, id: \.self) { choice in
                    Button {
                        play(choice)
                    } label: {
                        Label(choice.rawValue, systemImage: choice.symbol)
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(matchOver)
                }
            }

            if matchOver {
                Button("New match") {
                    playerWins = 0
                    computerWins = 0
                    playerPick = nil
                    computerPick = nil
                    roundText = "Pick one!"
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    func play(_ choice: RPSChoice) {
        let computer = RPSChoice.allCases.randomElement() ?? .rock
        playerPick = choice
        computerPick = computer
        if choice == computer {
            roundText = "A tie!"
        } else if choice.beats(computer) {
            playerWins += 1
            roundText = "\(choice.rawValue) beats \(computer.rawValue). Point to you!"
        } else {
            computerWins += 1
            roundText = "\(computer.rawValue) beats \(choice.rawValue). Point to the iPad."
        }
    }
}

struct ChoiceBadge: View {
    let title: String
    let choice: RPSChoice?

    var body: some View {
        VStack {
            Image(systemName: choice?.symbol ?? "questionmark")
                .font(.system(size: 64))
                .frame(width: 120, height: 120)
                .background(Color.gray.opacity(0.15), in: Circle())
            Text(title).font(.headline)
        }
    }
}
