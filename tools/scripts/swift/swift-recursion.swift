// @title Recursion
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Recursion.swift and run in Terminal: swiftc -parse-as-library Recursion.swift -o recursion && ./recursion
// @keywords swift recursion, swift factorial, swift recursive function, swift towers of hanoi
// @about Shows functions that call themselves: factorial, Fibonacci, countdown and the Towers of Hanoi.

import Foundation

@main
struct RecursionProgram {
    // Every recursive function needs a base case (when to stop)
    static func factorial(_ n: Int) -> Int {
        n <= 1 ? 1 : n * factorial(n - 1)
    }

    static func countdown(_ n: Int) {
        if n == 0 {
            print("Blast off!")
            return
        }
        print(n)
        countdown(n - 1)
    }

    static func sumOfDigits(_ n: Int) -> Int {
        n < 10 ? n : n % 10 + sumOfDigits(n / 10)
    }

    // Remember answers we already worked out so Fibonacci stays fast
    static func fibonacci(_ n: Int, memo: inout [Int: Int]) -> Int {
        if n < 2 { return n }
        if let known = memo[n] { return known }
        let answer = fibonacci(n - 1, memo: &memo) + fibonacci(n - 2, memo: &memo)
        memo[n] = answer
        return answer
    }

    static func hanoi(_ disks: Int, from: String, to: String, using spare: String, moves: inout Int) {
        guard disks > 0 else { return }
        hanoi(disks - 1, from: from, to: spare, using: to, moves: &moves)
        moves += 1
        print("Move disk \(disks) from \(from) to \(to)")
        hanoi(disks - 1, from: spare, to: to, using: from, moves: &moves)
    }

    static func main() {
        for n in 1...6 {
            print("\(n)! = \(factorial(n))")
        }
        countdown(3)
        print("Sum of digits of 98765: \(sumOfDigits(98765))")

        var memo: [Int: Int] = [:]
        print("Fibonacci 50: \(fibonacci(50, memo: &memo))")

        var moves = 0
        hanoi(3, from: "A", to: "C", using: "B", moves: &moves)
        print("Solved in \(moves) moves")
    }
}
