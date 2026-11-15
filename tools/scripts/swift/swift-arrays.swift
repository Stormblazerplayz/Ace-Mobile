// @title Arrays
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Arrays.swift and run in Terminal: swiftc -parse-as-library Arrays.swift -o arrays && ./arrays
// @keywords swift arrays, swift append, swift array index, swift remove from array, swift sort array
// @about Shows how to make a list (array), add and remove items, sort it and search it.

import Foundation

@main
struct ArraysProgram {
    static func main() {
        var games = ["Minecraft", "Roblox", "Rocket League"]
        print("Start: \(games)")
        print("First: \(games[0]), count: \(games.count)")

        games.append("Fortnite")          // add to the end
        games.insert("Terraria", at: 1)   // add at a position
        print("After adding: \(games)")

        let removed = games.remove(at: 2) // remove by position
        print("Removed \(removed): \(games)")

        games.sort()                      // A to Z (changes the array)
        print("Sorted: \(games)")
        print("Backwards: \(Array(games.reversed()))")

        // Safe lookups: first and last are optionals because the array might be empty
        print("First game: \(games.first ?? "none"), last: \(games.last ?? "none")")
        print("Has Minecraft? \(games.contains("Minecraft"))")
        if let spot = games.firstIndex(of: "Terraria") {
            print("Terraria is at index \(spot)")
        }

        // Arrays of numbers
        let scores = [88, 95, 72, 100, 64]
        let total = scores.reduce(0, +)
        print("Scores: \(scores)")
        print("Highest: \(scores.max() ?? 0), lowest: \(scores.min() ?? 0)")
        print("Average: \(Double(total) / Double(scores.count))")

        // A slice is part of an array
        print("First three: \(Array(scores.prefix(3)))")
        print("Last two: \(Array(scores.suffix(2)))")

        // An empty array needs its type written out
        var empty: [String] = []
        print("Is it empty? \(empty.isEmpty)")
        empty.append("now it has one")
        print(empty)
    }
}
