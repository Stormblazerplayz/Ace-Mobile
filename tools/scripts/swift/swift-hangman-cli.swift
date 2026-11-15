// @title Hangman (Terminal)
// @category Games
// @kind Swift program
// @where On a Mac, save as Hangman.swift and run in Terminal: swiftc -parse-as-library Hangman.swift -o hangman && ./hangman
// @keywords swift hangman terminal, swift word guessing, swift set of characters, swift console game
// @about Guess the secret word one letter at a time in the Terminal before you run out of lives.

import Foundation

@main
struct HangmanProgram {
    static let words = ["swift", "rocket", "planet", "dragon", "castle", "laptop", "jungle", "thunder"]

    static func main() {
        let secret = words.randomElement()!
        var guessed: Set<Character> = []
        var lives = 6

        while lives > 0 {
            let shown = secret.map { guessed.contains($0) ? String($0) : "_" }.joined(separator: " ")
            print("\nWord: \(shown)")
            print("Lives: \(String(repeating: "<3 ", count: lives))")
            if !shown.contains("_") {
                print("You saved the day! The word was \(secret).")
                return
            }
            print("Guess a letter: ", terminator: "")
            guard let line = readLine()?.lowercased() else { return }
            guard line.count == 1, let letter = line.first, letter.isLetter else {
                print("Please type one letter.")
                continue
            }
            if guessed.contains(letter) {
                print("You already tried \(letter).")
            } else {
                guessed.insert(letter)
                if !secret.contains(letter) {
                    lives -= 1
                    print("Nope, no \(letter).")
                }
            }
        }
        print("\nOut of lives! The word was \(secret).")
    }
}
