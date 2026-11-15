// @title Optionals
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Optionals.swift and run in Terminal: swiftc -parse-as-library Optionals.swift -o optionals && ./optionals
// @keywords swift optionals, swift if let, swift nil, swift optional unwrapping, swift nil coalescing
// @about Explains optionals, Swift's way of saying a value might be missing, and the safe ways to unwrap them.

import Foundation

@main
struct OptionalsProgram {
    static func main() {
        // A ? means "this might hold a value, or it might be nil (nothing)"
        var nickname: String? = nil
        print("Nickname is \(nickname ?? "not set")")  // ?? gives a backup value

        nickname = "Lightning"

        // if let: only runs when there IS a value, and gives you the unwrapped value
        if let nick = nickname {
            print("Your nickname is \(nick)")
        }

        // Turning text into a number gives an optional, because the text might not be a number
        let inputs = ["12", "hello", "7"]
        for input in inputs {
            if let number = Int(input) {
                print("\(input) -> \(number * 2) when doubled")
            } else {
                print("\(input) is not a number")
            }
        }

        // Optional chaining with ?. stops safely if something is nil
        let scores: [String: Int] = ["Storm": 95, "Nova": 88]
        let doodleScore = scores["Doodle"]  // looking up a dictionary gives an optional
        print("Doodle's score: \(doodleScore.map { String($0) } ?? "no score")")
        print("Storm's name length: \(scores.keys.first { $0 == "Storm" }?.count ?? 0)")

        // guard let is great at the start of a function
        func greet(_ name: String?) {
            guard let name = name, !name.isEmpty else {
                print("Hello, mystery person!")
                return
            }
            print("Hello, \(name)!")
        }
        greet(nil)
        greet("Ace")

        // ! force-unwraps. It CRASHES if the value is nil, so only use it when you're 100% sure.
        let sure = Int("100")!
        print("Force unwrapped: \(sure)")
    }
}
