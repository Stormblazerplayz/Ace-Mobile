// @title Stacks and Queues
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as StackQueue.swift and run in Terminal: swiftc -parse-as-library StackQueue.swift -o stackqueue && ./stackqueue
// @keywords swift stack, swift queue, swift generic data structure, swift undo history
// @about Builds a generic Stack (last in, first out) and Queue (first in, first out) and uses them.

import Foundation

struct UndoStack<Element> {
    private var items: [Element] = []
    var isEmpty: Bool { items.isEmpty }
    var peek: Element? { items.last }

    mutating func push(_ item: Element) { items.append(item) }
    mutating func pop() -> Element? { items.popLast() }
}

struct WaitingLine<Element> {
    private var items: [Element] = []
    var count: Int { items.count }

    mutating func join(_ item: Element) { items.append(item) }
    mutating func next() -> Element? { items.isEmpty ? nil : items.removeFirst() }
}

@main
struct StackQueueProgram {
    static func isBalanced(_ code: String) -> Bool {
        let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        var stack = UndoStack<Character>()
        for ch in code {
            if "([{".contains(ch) {
                stack.push(ch)
            } else if let opener = pairs[ch] {
                if stack.pop() != opener { return false }
            }
        }
        return stack.isEmpty
    }

    static func main() {
        // Stack: an undo history for a drawing app
        var history = UndoStack<String>()
        for action in ["draw circle", "fill red", "draw star"] {
            history.push(action)
            print("Did: \(action)")
        }
        while let last = history.pop() {
            print("Undo: \(last)")
        }

        // Queue: players waiting for their turn
        var line = WaitingLine<String>()
        ["Storm", "Nova", "Ace"].forEach { line.join($0) }
        while let player = line.next() {
            print("\(player)'s turn. Still waiting: \(line.count)")
        }

        for code in ["(1 + 2) * [3]", "{[}]", "((("] {
            print("\(code) is \(isBalanced(code) ? "balanced" : "NOT balanced")")
        }
    }
}
