// @title Functions
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Functions.swift and run in Terminal: swiftc -parse-as-library Functions.swift -o functions && ./functions
// @keywords swift functions, swift func, swift return value, swift argument labels, swift default parameters
// @about Shows how to write your own functions with parameters, labels, default values and return values.

import Foundation

@main
struct FunctionsProgram {
    // A function with no inputs and no output
    static func sayHi() {
        print("Hi there!")
    }

    // A parameter has a name and a type
    static func greet(name: String) {
        print("Hello, \(name)!")
    }

    // -> Int means the function gives back an Int
    static func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }

    // Argument labels make calls read like English: area(width: 3, height: 4)
    static func area(width: Double, height: Double) -> Double {
        width * height  // one-line functions can skip "return"
    }

    // A default value is used when you leave it out
    static func makePizza(size: String = "medium", cheese: Bool = true) -> String {
        "A \(size) pizza \(cheese ? "with" : "without") cheese"
    }

    // A function can return more than one value with a tuple
    static func minMax(of numbers: [Int]) -> (min: Int, max: Int)? {
        guard let first = numbers.first else { return nil }
        var low = first
        var high = first
        for n in numbers {
            low = Swift.min(low, n)
            high = Swift.max(high, n)
        }
        return (low, high)
    }

    static func main() {
        sayHi()
        greet(name: "Storm")
        print("3 + 4 = \(add(3, 4))")
        print("Area: \(area(width: 3, height: 4.5))")
        print(makePizza())
        print(makePizza(size: "large", cheese: false))
        if let result = minMax(of: [8, 3, 12, 5]) {
            print("Lowest \(result.min), highest \(result.max)")
        }
    }
}
