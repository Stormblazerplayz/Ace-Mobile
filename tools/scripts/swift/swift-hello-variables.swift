// @title Hello, Variables and Constants
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Hello.swift and run in Terminal: swiftc -parse-as-library Hello.swift -o hello && ./hello
// @keywords swift hello world, swift var let, swift variables, swift constants, swift types
// @about Your first Swift program: prints text and shows the difference between var (can change) and let (can't).

import Foundation

@main
struct HelloVariablesProgram {
    // main() is where the program starts
    static func main() {
        print("Hello, world!")

        // let makes a constant: it can never change
        let name = "Storm"
        let birthYear = 2014

        // var makes a variable: it can change later
        var score = 0
        score += 10
        score = score * 2

        // Swift figures out the type, but you can also write it yourself
        let height: Double = 1.52
        let likesCoding: Bool = true
        let favoriteLetter: Character = "S"

        print("Name: \(name)")  // \( ) puts a value inside text
        print("Born in \(birthYear), score is \(score)")
        print("Height: \(height) m, likes coding: \(likesCoding), favorite letter: \(favoriteLetter)")

        // Math works like you'd expect
        let apples = 7
        let friends = 2
        print("\(apples) / \(friends) = \(apples / friends) (whole numbers drop the decimal)")
        print("Remainder: \(apples % friends)")
        print("As decimals: \(Double(apples) / Double(friends))")

        // Converting between types
        let text = "42"
        if let number = Int(text) {
            print("The text \"\(text)\" became the number \(number), and doubled it is \(number * 2)")
        }
    }
}
