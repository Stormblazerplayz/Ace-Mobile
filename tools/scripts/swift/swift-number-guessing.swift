// @title Number Guessing Game (Terminal)
// @category Games
// @kind Swift program
// @where On a Mac, save as Guess.swift and run in Terminal: swiftc -parse-as-library Guess.swift -o guess && ./guess (it needs the Terminal because it reads what you type).
// @keywords swift number guessing game, swift readline, swift terminal game, swift higher lower
// @about The computer picks a number from 1 to 100 and you guess it with higher and lower hints.

import Foundation

@main
struct NumberGuessingProgram {
    static func main() {
        let secret = Int.random(in: 1...100)
        var tries = 0
        print("I'm thinking of a number from 1 to 100.")

        while true {
            print("Your guess: ", terminator: "")
            // readLine() reads what you type. It's nil if the input ends.
            guard let line = readLine() else { return }
            guard let guess = Int(line.trimmingCharacters(in: .whitespaces)) else {
                print("Please type a whole number.")
                continue
            }
            tries += 1
            if guess < secret {
                print("Higher!")
            } else if guess > secret {
                print("Lower!")
            } else {
                print("You got it in \(tries) tries!")
                print(tries <= 7 ? "That's expert guessing!" : "Try to beat \(tries) next time.")
                return
            }
        }
    }
}
