// @title Rock Paper Scissors (Terminal)
// @category Games
// @kind Swift program
// @where On a Mac, save as RPS.swift and run in Terminal: swiftc -parse-as-library RPS.swift -o rps && ./rps
// @keywords swift rock paper scissors terminal, swift enum game, swift caseiterable random, swift best of five
// @about Play rock paper scissors against the computer in the Terminal; first to 3 wins.

import Foundation

enum HandMove: String, CaseIterable {
    case rock, paper, scissors

    func beats(_ other: HandMove) -> Bool {
        switch (self, other) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper): return true
        default: return false
        }
    }
}

@main
struct RockPaperScissorsProgram {
    static func main() {
        var you = 0
        var computer = 0
        print("First to 3 wins! Type rock, paper or scissors (or r, p, s).")

        while you < 3 && computer < 3 {
            print("\nYour move: ", terminator: "")
            guard let text = readLine()?.lowercased(), !text.isEmpty else { return }
            guard let move = HandMove.allCases.first(where: { $0.rawValue.hasPrefix(text) }) else {
                print("That's not a move!")
                continue
            }
            let cpu = HandMove.allCases.randomElement()!
            print("You: \(move.rawValue)   Computer: \(cpu.rawValue)")
            if move == cpu {
                print("Tie!")
            } else if move.beats(cpu) {
                you += 1
                print("You win this round!")
            } else {
                computer += 1
                print("Computer wins this round.")
            }
            print("Score: you \(you) - \(computer) computer")
        }
        print(you == 3 ? "\nYOU WIN THE MATCH!" : "\nThe computer wins. Rematch?")
    }
}
