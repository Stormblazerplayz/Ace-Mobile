// @title Structs
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Structs.swift and run in Terminal: swiftc -parse-as-library Structs.swift -o structs && ./structs
// @keywords swift struct, swift mutating func, swift memberwise init, swift value type
// @about Makes a struct for game characters with properties and methods, and shows that structs are copied.

import Foundation

// A struct is a blueprint for a value with properties (data) and methods (actions)
struct GameHero {
    var name: String
    var health: Int = 100
    var level: Int = 1

    // A computed property works out its value every time you ask
    var isAlive: Bool { health > 0 }

    // mutating means this method changes the struct's own properties
    mutating func takeDamage(_ amount: Int) {
        health = max(0, health - amount)
    }

    mutating func levelUp() {
        level += 1
        health = 100
    }

    func describe() -> String {
        "\(name) (level \(level)) has \(health) HP" + (isAlive ? "" : " and is knocked out")
    }
}

@main
struct StructsProgram {
    static func main() {
        // Swift makes an init for you from the properties ("memberwise initializer")
        var hero = GameHero(name: "Storm")
        hero.takeDamage(30)
        print(hero.describe())
        hero.levelUp()
        print(hero.describe())

        // Structs are COPIED when you assign them. Changing the copy doesn't change the original.
        var copy = hero
        copy.name = "Storm's Clone"
        copy.takeDamage(150)
        print(hero.describe())
        print(copy.describe())

        // An array of structs
        let party = [GameHero(name: "Nova", health: 80, level: 3), GameHero(name: "Ace", level: 5)]
        for member in party {
            print(member.describe())
        }
        let total = party.reduce(0) { $0 + $1.level }
        print("Total party level: \(total)")
    }
}
