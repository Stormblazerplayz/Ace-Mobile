import XCTest
@testable import Ace

/// Home commands ("start the vacuum", "turn off the kitchen lights"...) must all be understood,
/// and everyday questions must never be mistaken for one.
final class HomeCommandsTests: XCTestCase {
    private func home(_ text: String) -> HomeCommand? {
        if case .home(let cmd) = IntentRouter.parse(text) { return cmd }
        return nil
    }

    func testHomeCommands() {
        let cases: [(String, String, String?)] = [
            ("start the vacuum", "home.vacuumStart", nil),
            ("Start the MOVA", "home.vacuumStart", nil),
            ("can you start the robot vacuum please", "home.vacuumStart", nil),
            ("vacuum the house", "home.vacuumStart", nil),
            ("start cleaning", "home.vacuumStart", nil),
            ("pause the vacuum", "home.vacuumPause", nil),
            ("stop the vacuum", "home.vacuumPause", nil),
            ("dock the vacuum", "home.vacuumDock", nil),
            ("send the vacuum home", "home.vacuumDock", nil),
            ("send the robot back to the dock", "home.vacuumDock", nil),
            ("clean the kitchen", "home.vacuumRoom", nil),
            ("vacuum the living room", "home.vacuumRoom", nil),
            ("have the vacuum clean the bedroom", "home.vacuumRoom", nil),
            ("is the vacuum running", "home.vacuumStatus", nil),
            ("turn on the lights", "home.on", "lights"),
            ("turn off the kitchen lights", "home.off", "kitchen lights"),
            ("Turn the bedroom lamp off", "home.off", "bedroom lamp"),
            ("lights off", "home.off", "lights"),
            ("switch on the fan", "home.on", "fan"),
            ("lights on in the kitchen", "home.on", "kitchen lights"),
            ("set the living room lights to 40%", "home.level", "living room lights"),
            ("dim the lights", "home.level", "lights"),
            ("set the thermostat to 70", "home.temp", "thermostat"),
            ("make it 72 degrees", "home.temp", "thermostat"),
            ("what's the temperature inside", "home.status", "thermostat"),
            ("is the fan on", "home.status", "fan"),
            ("did I leave the lights on", "home.status", "lights"),
            ("what devices do I have", "home.list", nil),
            ("what can you control", "home.list", nil),
            ("run the goodnight scene", "home.scene", nil),
            ("movie mode", "home.scene", nil),
            ("unlock the front door", "home.safety", nil),
            ("open the garage", "home.safety", nil),
        ]
        var misses: [String] = []
        for (text, name, target) in cases {
            guard let cmd = home(text) else { misses.append("\"\(text)\" -> not a home command"); continue }
            if cmd.name != name { misses.append("\"\(text)\" -> \(cmd.name), wanted \(name)"); continue }
            if let target, cmd.target != target { misses.append("\"\(text)\" -> target \"\(cmd.target)\", wanted \"\(target)\"") }
        }
        print("HOME COMMANDS: \(cases.count - misses.count)/\(cases.count)")
        for m in misses { print("HOME MISS \(m)") }
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testNotHomeCommands() {
        let questions = [
            "clean my room", "turn on hands free mode", "turn off sounds", "what is a robot vacuum",
            "how do robot vacuums work", "build a robot that can clean", "who invented the light bulb",
            "what is the speed of light", "turn off my pc", "what's the weather", "how hot is it outside",
            "set a timer for 5 minutes", "remind me to clean my room", "is it on", "good night",
        ]
        for q in questions {
            XCTAssertNil(home(q), "\"\(q)\" shouldn't be a home command")
        }
    }

    func testTemperatureAndBrightnessValues() {
        if case .temp(let v, let unit)? = home("set the heat to 21 degrees c")?.action {
            XCTAssertEqual(v, 21)
            XCTAssertEqual(unit, "c")
        } else {
            XCTFail("set the heat to 21 degrees c")
        }
        if case .level(let l)? = home("set the living room lights to 40%")?.action {
            XCTAssertEqual(l, 40)
        } else {
            XCTFail("set the living room lights to 40%")
        }
        XCTAssertEqual(HomeService.distance("kitchn", "kitchen"), 1)
        XCTAssertEqual(HomeService.singular("lights"), "light")
    }
}
