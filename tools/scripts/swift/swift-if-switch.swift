// @title If, Else and Switch
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Decisions.swift and run in Terminal: swiftc -parse-as-library Decisions.swift -o decisions && ./decisions
// @keywords swift if else, swift switch, swift conditions, swift ranges in switch, swift ternary
// @about Shows how Swift makes decisions with if, else if, else and the powerful switch statement.

import Foundation

@main
struct DecisionsProgram {
    static func letterGrade(for score: Int) -> String {
        if score >= 90 {
            return "A"
        } else if score >= 80 {
            return "B"
        } else if score >= 70 {
            return "C"
        } else {
            return "Keep practicing"
        }
    }

    static func describe(_ number: Int) -> String {
        // switch must cover every possible case, so we end with default
        switch number {
        case 0:
            return "zero"
        case 1...9:
            return "a single digit"
        case 10, 20, 30:
            return "a round number"
        case let n where n < 0:
            return "negative"
        default:
            return "a big number"
        }
    }

    static func main() {
        for score in [95, 83, 71, 40] {
            print("\(score) -> \(letterGrade(for: score))")
        }

        for number in [0, 7, 20, -5, 1234] {
            print("\(number) is \(describe(number))")
        }

        // switch works with text too
        let weather = "rainy"
        switch weather {
        case "sunny":
            print("Wear sunglasses!")
        case "rainy", "stormy":
            print("Take an umbrella!")
        default:
            print("Have a nice day!")
        }

        // The ternary operator is a tiny if: condition ? valueIfTrue : valueIfFalse
        let age = 12
        print(age >= 13 ? "Teenager" : "Not a teen yet")

        // && means AND, || means OR, ! means NOT
        let hasTicket = true
        let isTall = false
        if hasTicket && !isTall {
            print("You can ride the small coaster.")
        }
    }
}
