// @title Codable and JSON
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as JSONDemo.swift and run in Terminal: swiftc -parse-as-library JSONDemo.swift -o jsondemo && ./jsondemo
// @keywords swift codable, swift json decoder, swift json encoder, swift parse json, swift coding keys
// @about Turns JSON text into Swift structs with Codable, changes them, and turns them back into JSON.

import Foundation

struct SavedPlayer: Codable {
    var name: String
    var level: Int
    var items: [String]
    var favoriteColor: String

    // CodingKeys lets the Swift name be different from the JSON name
    enum CodingKeys: String, CodingKey {
        case name, level, items
        case favoriteColor = "favorite_color"
    }
}

@main
struct CodableJSONProgram {
    static func main() {
        let json = """
        [
          {"name": "Storm", "level": 12, "items": ["sword", "map"], "favorite_color": "blue"},
          {"name": "Nova", "level": 9, "items": [], "favorite_color": "purple"}
        ]
        """

        do {
            // Decode: JSON text -> Swift values
            let data = Data(json.utf8)
            var players = try JSONDecoder().decode([SavedPlayer].self, from: data)
            for player in players {
                print("\(player.name) is level \(player.level) and carries \(player.items.count) items")
            }

            // Change something
            players[1].items.append("shield")
            players[1].level += 1

            // Encode: Swift values -> JSON text
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let output = try encoder.encode(players)
            print(String(decoding: output, as: UTF8.self))
        } catch {
            print("The JSON didn't match: \(error)")
        }
    }
}
