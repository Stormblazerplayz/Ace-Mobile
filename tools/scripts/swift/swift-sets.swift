// @title Sets
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Sets.swift and run in Terminal: swiftc -parse-as-library Sets.swift -o sets && ./sets
// @keywords swift sets, swift set union intersection, swift remove duplicates, swift contains fast
// @about Shows sets, collections with no duplicates, and how to compare two sets.

import Foundation

@main
struct SetsProgram {
    static func main() {
        // A set never holds the same value twice
        var colors: Set<String> = ["red", "blue", "red", "green"]
        print("Colors: \(colors.sorted())")  // sorted() turns it into an ordered array

        colors.insert("yellow")
        colors.remove("red")
        print("After changes: \(colors.sorted())")
        print("Has blue? \(colors.contains("blue"))")

        // Remove duplicates from an array
        let rolls = [3, 6, 3, 1, 6, 6, 2]
        let unique = Set(rolls)
        print("Different numbers rolled: \(unique.sorted())")

        // Comparing sets
        let myGames: Set = ["Minecraft", "Roblox", "Terraria"]
        let friendGames: Set = ["Roblox", "Fortnite", "Minecraft"]
        print("We both play: \(myGames.intersection(friendGames).sorted())")
        print("All games: \(myGames.union(friendGames).sorted())")
        print("Only I play: \(myGames.subtracting(friendGames).sorted())")
        print("Only one of us plays: \(myGames.symmetricDifference(friendGames).sorted())")

        // Letters used in a word
        let word = "lightning"
        let letters = Set(word)
        print("\"\(word)\" uses \(letters.count) different letters")
    }
}
