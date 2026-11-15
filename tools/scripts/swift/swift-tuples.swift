// @title Tuples
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Tuples.swift and run in Terminal: swiftc -parse-as-library Tuples.swift -o tuples && ./tuples
// @keywords swift tuples, swift named tuple, swift return multiple values, swift destructuring
// @about Groups a few values together with tuples and uses them to return more than one value from a function.

import Foundation

@main
struct TuplesProgram {
    static func divide(_ a: Int, by b: Int) -> (quotient: Int, remainder: Int) {
        (a / b, a % b)
    }

    static func stats(_ numbers: [Double]) -> (total: Double, average: Double, count: Int) {
        let total = numbers.reduce(0, +)
        return (total, numbers.isEmpty ? 0 : total / Double(numbers.count), numbers.count)
    }

    static func main() {
        // A tuple groups values together in ( )
        let point = (x: 3, y: 7)
        print("x is \(point.x), y is \(point.y)")

        // Pull the values out ("destructuring")
        let (x, y) = point
        print("Distance from the middle: \((Double(x * x + y * y)).squareRoot())")

        let result = divide(17, by: 5)
        print("17 / 5 = \(result.quotient) remainder \(result.remainder)")

        let summary = stats([4, 8, 15, 16, 23, 42])
        print("Total \(summary.total), average \(summary.average), count \(summary.count)")

        // Swap two variables in one line
        var first = "left"
        var second = "right"
        (first, second) = (second, first)
        print("first = \(first), second = \(second)")

        // Tuples in a switch
        let move = (dx: 0, dy: -1)
        switch move {
        case (0, 0): print("Standing still")
        case (0, _): print("Moving up or down")
        case (_, 0): print("Moving left or right")
        default: print("Moving diagonally")
        }
    }
}
