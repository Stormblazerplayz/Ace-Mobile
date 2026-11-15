// @title Binary Search
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as BinarySearch.swift and run in Terminal: swiftc -parse-as-library BinarySearch.swift -o bsearch && ./bsearch
// @keywords swift binary search, swift search sorted array, swift divide and conquer, swift algorithm steps
// @about Finds a number in a sorted list by checking the middle and throwing away half the list each step.

import Foundation

@main
struct BinarySearchProgram {
    static func binarySearch(_ items: [Int], for target: Int) -> (index: Int?, steps: Int) {
        var low = 0
        var high = items.count - 1
        var steps = 0
        while low <= high {
            steps += 1
            let middle = (low + high) / 2
            if items[middle] == target {
                return (middle, steps)
            } else if items[middle] < target {
                low = middle + 1   // it must be in the right half
            } else {
                high = middle - 1  // it must be in the left half
            }
        }
        return (nil, steps)
    }

    static func main() {
        let numbers = Array(stride(from: 0, to: 10_000, by: 7))  // 0, 7, 14, ... sorted!
        print("Searching \(numbers.count) numbers.")
        for target in [7000, 3, 9996, 4242] {
            let result = binarySearch(numbers, for: target)
            if let index = result.index {
                print("Found \(target) at index \(index) in \(result.steps) steps")
            } else {
                print("\(target) is not there (checked in \(result.steps) steps)")
            }
        }
        print("A plain search could need up to \(numbers.count) steps!")
    }
}
