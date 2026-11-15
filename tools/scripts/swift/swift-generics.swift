// @title Generics
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Generics.swift and run in Terminal: swiftc -parse-as-library Generics.swift -o generics && ./generics
// @keywords swift generics, swift generic function, swift generic struct, swift type parameter
// @about Writes functions and types that work with any type, like a Box that can hold anything.

import Foundation

// <T> means "some type, we'll find out which one when it's used"
func swapPair<T>(_ pair: (T, T)) -> (T, T) {
    (pair.1, pair.0)
}

// T: Comparable means T must be something that can be compared with < and >
func largest<T: Comparable>(in items: [T]) -> T? {
    guard var best = items.first else { return nil }
    for item in items where item > best {
        best = item
    }
    return best
}

// A generic struct: a box that can hold any kind of item
struct LootBox<Item> {
    private(set) var items: [Item] = []

    mutating func add(_ item: Item) {
        items.append(item)
    }

    func randomItem() -> Item? {
        items.randomElement()
    }
}

@main
struct GenericsProgram {
    static func main() {
        print(swapPair((1, 2)))
        print(swapPair(("left", "right")))

        print("Largest number: \(largest(in: [3, 9, 2]) ?? 0)")
        print("Largest word: \(largest(in: ["apple", "pear", "zebra"]) ?? "")")
        print("Largest decimal: \(largest(in: [1.5, 0.2, 7.25]) ?? 0)")

        var weapons = LootBox<String>()
        weapons.add("Sword")
        weapons.add("Bow")
        weapons.add("Laser")
        print("You opened the box and got: \(weapons.randomItem() ?? "nothing")")

        var coins = LootBox<Int>()
        coins.add(10)
        coins.add(50)
        print("Coin box holds \(coins.items.count) items worth \(coins.items.reduce(0, +))")
    }
}
