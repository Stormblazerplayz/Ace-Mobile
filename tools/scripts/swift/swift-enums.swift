// @title Enums
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Enums.swift and run in Terminal: swiftc -parse-as-library Enums.swift -o enums && ./enums
// @keywords swift enum, swift associated values, swift raw values, swift caseiterable, swift switch enum
// @about Shows enums: a type with a fixed list of choices, including raw values and associated values.

import Foundation

// A simple enum with raw String values
enum PizzaSize: String, CaseIterable {
    case small, medium, large

    var price: Double {
        switch self {
        case .small: return 8
        case .medium: return 10.5
        case .large: return 13
        }
    }
}

// An enum where each case can carry extra information
enum GameEvent {
    case coinCollected(amount: Int)
    case enemyDefeated(name: String, points: Int)
    case levelComplete
}

@main
struct EnumsProgram {
    static func points(for event: GameEvent) -> Int {
        switch event {
        case .coinCollected(let amount):
            return amount
        case .enemyDefeated(_, let points):
            return points
        case .levelComplete:
            return 500
        }
    }

    static func main() {
        // CaseIterable gives us allCases for free
        for size in PizzaSize.allCases {
            print("\(size.rawValue.capitalized) pizza costs $\(size.price)")
        }

        // Make an enum value from its raw value (it might fail, so it's optional)
        if let size = PizzaSize(rawValue: "large") {
            print("Found size: \(size)")
        }

        let events: [GameEvent] = [
            .coinCollected(amount: 10),
            .enemyDefeated(name: "Slime", points: 50),
            .coinCollected(amount: 25),
            .levelComplete,
        ]
        var score = 0
        for event in events {
            score += points(for: event)
            if case .enemyDefeated(let name, _) = event {
                print("Defeated a \(name)!")
            }
        }
        print("Final score: \(score)")
    }
}
