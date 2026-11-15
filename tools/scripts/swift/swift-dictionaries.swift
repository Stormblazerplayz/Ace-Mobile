// @title Dictionaries
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Dictionaries.swift and run in Terminal: swiftc -parse-as-library Dictionaries.swift -o dicts && ./dicts
// @keywords swift dictionary, swift key value, swift dictionary loop, swift update dictionary
// @about Stores a player's stats in a dictionary and shows how to read, change, loop over and count with it.

import Foundation

@main
struct DictionariesProgram {
    static func main() {
        // [key: value]
        var stats: [String: Int] = ["coins": 150, "level": 7, "gems": 3]

        // Looking up a key gives an optional, because the key might not exist
        print("Coins: \(stats["coins"] ?? 0)")
        print("Mana: \(stats["mana", default: 0])")  // default: gives a backup value

        stats["coins", default: 0] += 50   // change a value
        stats["health"] = 100              // add a new key
        stats["gems"] = nil                // setting to nil removes it
        print("After the quest: \(stats)")

        // Dictionaries have no order, so sort the keys to print them neatly
        for key in stats.keys.sorted() {
            print("  \(key): \(stats[key] ?? 0)")
        }

        // Count letters in a word
        var counts: [Character: Int] = [:]
        for letter in "mississippi" {
            counts[letter, default: 0] += 1
        }
        for (letter, count) in counts.sorted(by: { $0.key < $1.key }) {
            print("\(letter): \(String(repeating: "#", count: count))")
        }

        // A dictionary of arrays
        let teams: [String: [String]] = [
            "Lightning": ["Storm", "Nova"],
            "Thunder": ["Doodle", "Ace", "Blaze"],
        ]
        for (team, players) in teams.sorted(by: { $0.key < $1.key }) {
            print("\(team) has \(players.count) players: \(players.joined(separator: ", "))")
        }
    }
}
