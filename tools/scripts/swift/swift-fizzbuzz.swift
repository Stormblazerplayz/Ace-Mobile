// @title FizzBuzz
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as FizzBuzz.swift and run in Terminal: swiftc -parse-as-library FizzBuzz.swift -o fizzbuzz && ./fizzbuzz
// @keywords swift fizzbuzz, swift remainder operator, swift isMultiple, swift coding challenge
// @about The classic challenge: print Fizz for multiples of 3, Buzz for 5, FizzBuzz for both.

import Foundation

@main
struct FizzBuzzProgram {
    static func fizzBuzz(_ n: Int) -> String {
        switch (n.isMultiple(of: 3), n.isMultiple(of: 5)) {
        case (true, true): return "FizzBuzz"
        case (true, false): return "Fizz"
        case (false, true): return "Buzz"
        case (false, false): return String(n)
        }
    }

    static func main() {
        for n in 1...30 {
            print(fizzBuzz(n))
        }

        // A version you can grow: just add more rules!
        let rules: [(Int, String)] = [(3, "Fizz"), (5, "Buzz"), (7, "Bazz")]
        let line = (1...21).map { n -> String in
            let word = rules.filter { n.isMultiple(of: $0.0) }.map { $0.1 }.joined()
            return word.isEmpty ? String(n) : word
        }
        print(line.joined(separator: ", "))
    }
}
