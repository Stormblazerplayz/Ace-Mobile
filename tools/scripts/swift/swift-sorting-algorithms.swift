// @title Sorting Algorithms
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Sorting.swift and run in Terminal: swiftc -parse-as-library Sorting.swift -o sorting && ./sorting
// @keywords swift bubble sort, swift insertion sort, swift merge sort, swift sorting algorithm
// @about Writes bubble sort, insertion sort and merge sort by hand and checks them against Swift's sorted().

import Foundation

@main
struct SortingProgram {
    static func bubbleSort(_ input: [Int]) -> [Int] {
        var items = input
        guard items.count > 1 else { return items }
        for end in stride(from: items.count - 1, to: 0, by: -1) {
            for i in 0..<end where items[i] > items[i + 1] {
                items.swapAt(i, i + 1)  // the bigger one bubbles right
            }
        }
        return items
    }

    static func insertionSort(_ input: [Int]) -> [Int] {
        var items = input
        guard items.count > 1 else { return items }
        for i in 1..<items.count {
            let current = items[i]
            var j = i - 1
            while j >= 0 && items[j] > current {  // slide bigger ones to the right
                items[j + 1] = items[j]
                j -= 1
            }
            items[j + 1] = current
        }
        return items
    }

    static func mergeSort(_ items: [Int]) -> [Int] {
        guard items.count > 1 else { return items }
        let middle = items.count / 2
        let left = mergeSort(Array(items[..<middle]))
        let right = mergeSort(Array(items[middle...]))
        var merged: [Int] = []
        var i = 0
        var j = 0
        while i < left.count && j < right.count {
            if left[i] <= right[j] {
                merged.append(left[i])
                i += 1
            } else {
                merged.append(right[j])
                j += 1
            }
        }
        return merged + left[i...] + right[j...]
    }

    static func main() {
        let numbers = (0..<12).map { _ in Int.random(in: 1...99) }
        print("Start:     \(numbers)")
        print("Bubble:    \(bubbleSort(numbers))")
        print("Insertion: \(insertionSort(numbers))")
        print("Merge:     \(mergeSort(numbers))")

        var passed = true
        for _ in 0..<200 {
            let data = (0..<Int.random(in: 0...25)).map { _ in Int.random(in: -50...50) }
            let expected = data.sorted()
            if bubbleSort(data) != expected || insertionSort(data) != expected || mergeSort(data) != expected {
                passed = false
            }
        }
        print(passed ? "All three passed 200 random tests!" : "Something is wrong!")
    }
}
