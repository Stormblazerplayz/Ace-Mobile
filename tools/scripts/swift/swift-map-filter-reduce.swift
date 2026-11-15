// @title Map, Filter and Reduce
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as MapFilter.swift and run in Terminal: swiftc -parse-as-library MapFilter.swift -o mapfilter && ./mapfilter
// @keywords swift map, swift filter, swift reduce, swift compactmap, swift higher order functions
// @about Transforms, filters and adds up arrays in one line each with map, filter, reduce and friends.

import Foundation

struct ShopItem {
    let name: String
    let price: Double
    let inStock: Bool
}

@main
struct MapFilterReduceProgram {
    static func main() {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        // map: change every item
        let doubled = numbers.map { $0 * 2 }
        print("Doubled: \(doubled)")

        // filter: keep only some items
        let evens = numbers.filter { $0 % 2 == 0 }
        print("Evens: \(evens)")

        // reduce: combine everything into one value
        let sum = numbers.reduce(0) { total, n in total + n }
        print("Sum: \(sum)")

        // compactMap: map, but throw away the nils
        let typed = ["4", "cat", "15", "", "8"]
        let valid = typed.compactMap { Int($0) }
        print("Valid numbers: \(valid)")

        // Chaining them together
        let items = [
            ShopItem(name: "Keychain", price: 4, inStock: true),
            ShopItem(name: "Phone stand", price: 8.5, inStock: false),
            ShopItem(name: "Dragon", price: 15, inStock: true),
            ShopItem(name: "Lamp", price: 22, inStock: true),
        ]
        let available = items.filter { $0.inStock }.map { $0.name }
        print("In stock: \(available.joined(separator: ", "))")
        let stockValue = items.filter(\.inStock).reduce(0) { $0 + $1.price }
        print("Value of stock: $\(stockValue)")

        // A few more helpers
        print("Any over $20? \(items.contains { $0.price > 20 })")
        print("All under $30? \(items.allSatisfy { $0.price < 30 })")
        print("Cheapest: \(items.min { $0.price < $1.price }?.name ?? "none")")
        print("Sorted by price: \(items.sorted { $0.price < $1.price }.map(\.name))")
    }
}
