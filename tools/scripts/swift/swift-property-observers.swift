// @title Computed Properties and Observers
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Properties.swift and run in Terminal: swiftc -parse-as-library Properties.swift -o properties && ./properties
// @keywords swift computed property, swift didset, swift willset, swift lazy property, swift private set
// @about Shows properties that calculate themselves, react when they change (didSet) and only load when needed (lazy).

import Foundation

struct ThermostatModel {
    // didSet runs right after the value changes
    var celsius: Double = 20 {
        didSet {
            if celsius > 30 {
                print("  Warning: it's getting hot! (\(celsius) C)")
            }
            if celsius < oldValue {
                print("  Cooling down from \(oldValue) to \(celsius)")
            }
        }
    }

    // A computed property with a getter AND a setter
    var fahrenheit: Double {
        get { celsius * 9 / 5 + 32 }
        set { celsius = (newValue - 32) * 5 / 9 }
    }
}

final class LevelData {
    // private(set): anyone can read it, but only this class can change it
    private(set) var loadCount = 0

    // lazy: not made until someone uses it the first time
    lazy var bigMap: [String] = {
        self.loadCount += 1
        print("  (Loading the big map now...)")
        return (1...5).map { "Room \($0)" }
    }()
}

@main
struct PropertiesProgram {
    static func main() {
        var thermostat = ThermostatModel()
        print("Start: \(thermostat.celsius) C = \(thermostat.fahrenheit) F")
        thermostat.celsius = 32
        thermostat.fahrenheit = 50  // setting F updates C too
        print("Now: \(thermostat.celsius) C")

        let level = LevelData()
        print("Level made. Map loaded \(level.loadCount) times.")
        print("Rooms: \(level.bigMap)")
        print("Rooms again: \(level.bigMap.count)")
        print("Map loaded \(level.loadCount) time(s), only when first needed.")
    }
}
