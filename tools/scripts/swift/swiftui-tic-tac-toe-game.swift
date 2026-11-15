// @title Tic Tac Toe Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TicTacToeGameView() in ContentView's body.
// @keywords swiftui tic tac toe, swiftui noughts and crosses, swiftui computer opponent, swiftui board game grid
// @about Play tic tac toe against a friend or a computer that tries to win and blocks your lines.

import SwiftUI

struct TicTacToeGameView: View {
    @State private var board = Array(repeating: "", count: 9)
    @State private var xTurn = true
    @State private var winner: String? = nil
    @State private var vsComputer = true

    // All 8 ways to get three in a row
    let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    var status: String {
        if let winner {
            return winner == "Draw" ? "It's a draw!" : "\(winner) wins!"
        }
        return xTurn ? "X's turn" : "O's turn"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(status).font(.largeTitle.bold())
            Toggle("Play against the computer (O)", isOn: $vsComputer)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(0..<9, id: \.self) { index in
                    Button {
                        play(index)
                    } label: {
                        Text(board[index])
                            .font(.system(size: 60, weight: .heavy))
                            .foregroundStyle(board[index] == "X" ? Color.blue : Color.red)
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Button("New game") {
                board = Array(repeating: "", count: 9)
                xTurn = true
                winner = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func play(_ index: Int) {
        guard board[index].isEmpty, winner == nil else { return }
        board[index] = xTurn ? "X" : "O"
        xTurn.toggle()
        winner = findWinner()
        if vsComputer && !xTurn && winner == nil {
            computerMove()
        }
    }

    func findWinner() -> String? {
        for line in lines {
            let first = board[line[0]]
            if !first.isEmpty && first == board[line[1]] && first == board[line[2]] {
                return first
            }
        }
        return board.contains("") ? nil : "Draw"
    }

    // Find an empty square that would finish a line of two "mark"s
    func finishingSpot(for mark: String) -> Int? {
        for line in lines {
            let count = line.filter { board[$0] == mark }.count
            if count == 2, let empty = line.first(where: { board[$0].isEmpty }) {
                return empty
            }
        }
        return nil
    }

    func computerMove() {
        let empties = board.indices.filter { board[$0].isEmpty }
        // 1. win if we can, 2. block X, 3. take the middle, 4. pick any empty square
        let fallback: Int? = board[4].isEmpty ? 4 : empties.randomElement()
        if let choice = finishingSpot(for: "O") ?? finishingSpot(for: "X") ?? fallback {
            play(choice)
        }
    }
}
