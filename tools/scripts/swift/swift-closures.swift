// @title Closures
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Closures.swift and run in Terminal: swiftc -parse-as-library Closures.swift -o closures && ./closures
// @keywords swift closures, swift trailing closure, swift $0 shorthand, swift functions as values
// @about Explains closures: little blocks of code you can store in variables and pass to other functions.

import Foundation

@main
struct ClosuresProgram {
    // This function takes another function as an input
    static func repeatAction(times: Int, action: (Int) -> Void) {
        for i in 1...times {
            action(i)
        }
    }

    // A function that makes and returns a closure
    static func makeCounter() -> () -> Int {
        var count = 0
        return {
            count += 1  // the closure "captures" count and remembers it
            return count
        }
    }

    static func main() {
        // A closure stored in a constant
        let shout = { (word: String) -> String in
            word.uppercased() + "!"
        }
        print(shout("hello"))

        // Trailing closure: when the last input is a closure, it can go after the ()
        repeatAction(times: 3) { number in
            print("Jump number \(number)")
        }

        // Closures are everywhere in Swift, like sorting
        let names = ["Nova", "Ace", "Storm", "Doodle"]
        let byLength = names.sorted { first, second in first.count < second.count }
        print("Sorted by length: \(byLength)")

        // $0 and $1 are shortcuts for the first and second inputs
        print("Sorted Z to A: \(names.sorted { $0 > $1 })")

        let counter = makeCounter()
        _ = counter()
        _ = counter()
        print("Counter says: \(counter())")

        // A dictionary of closures works like a mini calculator
        let operations: [String: (Double, Double) -> Double] = [
            "+": { $0 + $1 },
            "-": { $0 - $1 },
            "x": { $0 * $1 },
        ]
        for symbol in ["+", "-", "x"] {
            if let operation = operations[symbol] {
                print("6 \(symbol) 3 = \(operation(6, 3))")
            }
        }
    }
}
