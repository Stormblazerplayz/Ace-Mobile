// @title Loops
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Loops.swift and run in Terminal: swiftc -parse-as-library Loops.swift -o loops && ./loops
// @keywords swift for in loop, swift while loop, swift repeat while, swift stride, swift ranges
// @about Shows Swift's for-in, while and repeat-while loops, plus stride for counting by steps.

import Foundation

@main
struct LoopsProgram {
    static func main() {
        // 1...5 includes 5. 1..<5 stops before 5.
        for number in 1...5 {
            print("Counting: \(number)")
        }

        // Loop over a list
        let snacks = ["chips", "apples", "popcorn"]
        for snack in snacks {
            print("I like \(snack)")
        }

        // enumerated() gives the position too
        for (index, snack) in snacks.enumerated() {
            print("\(index + 1). \(snack)")
        }

        // stride counts by steps: from 10 down to 0 by 2s
        for n in stride(from: 10, through: 0, by: -2) {
            print("Even countdown: \(n)")
        }

        // while: keeps going as long as the condition is true
        var lives = 3
        while lives > 0 {
            print("Lives left: \(lives)")
            lives -= 1
        }

        // repeat-while: always runs at least once
        var roll = 0
        var tries = 0
        repeat {
            roll = Int.random(in: 1...6)
            tries += 1
        } while roll != 6
        print("Rolled a 6 after \(tries) tries")

        // continue skips to the next round, break stops the loop
        for n in 1...20 {
            if n % 2 == 0 { continue }
            if n > 9 { break }
            print("Odd: \(n)")
        }

        // Add up 1 to 100 with a loop
        var total = 0
        for n in 1...100 {
            total += n
        }
        print("1 + 2 + ... + 100 = \(total)")
    }
}
