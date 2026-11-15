import Foundation

/// Something to do in the home (Apple Home): lights, plugs, fans, thermostats, the robot vacuum, scenes.
struct HomeCommand: Equatable {
    enum Action: Equatable {
        case on, off
        case level(Int)                       // brightness 0...100
        case color(String)                    // "red", "warm white"...
        case temp(Double, unit: String?)      // "f", "c" or nil (use the app's unit)
        case status
        case list
        case scene(String)
        case vacuumStart
        case vacuumRoom(String)
        case vacuumPause
        case vacuumDock
        case vacuumStatus
        case safety                           // locks, garage doors, alarms: Ace won't touch them
    }

    var action: Action
    /// The words that name the device ("kitchen lights", "fan", "vacuum"). Empty when it doesn't matter.
    var target: String

    /// A short name for tests ("home.on", "home.vacuumStart"...).
    var name: String {
        switch action {
        case .on: return "home.on"
        case .off: return "home.off"
        case .level: return "home.level"
        case .color: return "home.color"
        case .temp: return "home.temp"
        case .status: return "home.status"
        case .list: return "home.list"
        case .scene: return "home.scene"
        case .vacuumStart: return "home.vacuumStart"
        case .vacuumRoom: return "home.vacuumRoom"
        case .vacuumPause: return "home.vacuumPause"
        case .vacuumDock: return "home.vacuumDock"
        case .vacuumStatus: return "home.vacuumStatus"
        case .safety: return "home.safety"
        }
    }
}

/// Reads home commands from normalized text (see TextKit.normalize). Pure rules, no HomeKit,
/// so the smartness tests can run it anywhere.
enum HomeParser {
    /// Names of the devices, rooms and scenes in Apple Home, saved by HomeService so
    /// "turn on the desk thing" works for any name you gave something in the Home app.
    static var knownNames: [String] {
        (UserDefaults.standard.stringArray(forKey: "homeKnownNames") ?? [])
            + (UserDefaults.standard.stringArray(forKey: "lanKnownNames") ?? [])
    }

    static let deviceWords = #"\b(lights?|lamps?|bulbs?|led strips?|light strips?|strip lights?|leds|plugs?|smart plugs?|outlets?|switch(es)?|fans?|ceiling fans?|heaters?|air purifiers?|purifiers?|humidifiers?|dehumidifiers?|thermostats?|ac|air conditioners?|aircon|tv|television|speakers?|kettle|coffee maker|christmas lights|fairy lights|twinkly|govee|blueair|smarthq|dishwasher|washing machine|dryer|oven)\b"#
    static let vac = #"(?:the |my |our )?(?:robot vacuum|vacuum cleaner|robot cleaner|robo ?vac|vacuum|mova|roomba|roborock|cleaning robot|robot)"#
    static let polite = #"^(?:please |can you |could you |would you |hey ace |ace |ok ace |yo ace )*"#
    static let colors = #"(cool white|warm white|warm|red|orange|yellow|gold|amber|green|lime|cyan|teal|blue|purple|violet|pink|magenta|white)"#
    static let rooms = #"(kitchen|living room|lounge|bedroom|my room|master bedroom|bathroom|hallway|hall|dining room|office|basement|family room|den|playroom|laundry room|upstairs|downstairs|entryway|[a-z]+'?s room)"#

    static func parse(_ t: String) -> HomeCommand? {
        // Locks, garage doors and alarms stay in the Home app.
        if Rx.matches(polite + #"(unlock|lock|open|close|disarm|arm)\b.*\b(doors?|front door|back door|garage( door)?|gate|locks?|alarm|security( system)?|deadbolt)$"#, t) {
            return HomeCommand(action: .safety, target: "")
        }

        // Scenes
        // "Focus mode" or "dark mode" are iPad settings, but "the focus scene" is a home scene.
        if let g = Rx.groups(polite + #"(?:run|start|activate|turn on|play|set|do)\s+(?:the\s+|my\s+)?(.+?)\s+(scene|mode)$"#, t),
           g[1] == "scene" || !Rx.matches(#"^(hands ?free|dark|light|low power|airplane|focus|do not disturb|sound|silent|reader|reading|guided access|lost)$"#, g[0]) {
            return HomeCommand(action: .scene(g[0]), target: "")
        }
        if let g = Rx.groups(#"^(movie (?:mode|time|night)|good ?night (?:mode|scene)|good morning (?:mode|scene)|party (?:mode|time)|i am (?:going|heading) to bed|i am leaving|i am home|i am back home)$"#, t) {
            return HomeCommand(action: .scene(g[0]), target: "")
        }

        // Robot vacuum
        if Rx.matches(#"^(?:is|where is|how is|what is) "# + vac + #"(?: doing| up to| status)?(?: (?:running|on|cleaning|done|charging|finished|docked|working|stuck|busy|home))?$"#, t)
            || Rx.matches(#"^"# + vac + #" status$"#, t) {
            return HomeCommand(action: .vacuumStatus, target: "vacuum")
        }
        if Rx.matches(polite + #"(?:dock|recharge|park|charge)\s+"# + vac + "$", t)
            || Rx.matches(polite + #"(?:send|tell|make|have|get)\s+"# + vac + #"\s+(?:to\s+)?(?:go\s+)?(?:back\s+)?(?:home|back|to (?:the |its |his |her )?(?:dock|base|charger|station))"#, t)
            || Rx.matches(#"^"# + vac + #"\s+(?:go home|go back|dock|return|back to)"#, t) {
            return HomeCommand(action: .vacuumDock, target: "vacuum")
        }
        if Rx.matches(polite + #"(?:pause|stop|halt|cancel)\s+"# + vac + #"(?: now| please)?$"#, t)
            || Rx.matches(#"^"# + vac + #"\s+(?:pause|stop)$"#, t) {
            return HomeCommand(action: .vacuumPause, target: "vacuum")
        }
        // "clean my room" is about tidying up, so only "vacuum my room" goes to the vacuum.
        if let g = Rx.groups(polite + #"(clean|vacuum)\s+(?:the\s+|my\s+)?"# + rooms + #"(?:\s+(?:floor|floors))?(?: now| please)?$"#, t),
           !(g[0] == "clean" && (g[1] == "my room" || g[1].hasSuffix("s room"))) {
            return HomeCommand(action: .vacuumRoom(g[1]), target: "vacuum")
        }
        if let g = Rx.groups(polite + #"(?:have |tell |make |get )?"# + vac + #"\s+(?:to\s+)?(?:clean|vacuum)\s+(?:the\s+|my\s+)?"# + rooms, t) {
            return HomeCommand(action: .vacuumRoom(g[0]), target: "vacuum")
        }
        if Rx.matches(polite + #"(?:start|run|begin|turn on|switch on|launch|activate|use)\s+"# + vac + #"(?: now| please| cleaner)?$"#, t)
            || Rx.matches(polite + #"(?:have|tell|make|get)\s+"# + vac + #"\s+(?:to\s+)?(?:start|clean|vacuum|run|go)"#, t)
            || Rx.matches(#"^"# + vac + #"\s+(?:start|go|clean|run)(?: now)?$"#, t)
            || Rx.matches(polite + #"(?:vacuum|clean)\s+(?:the\s+)?(?:house|floors?|whole house|home|everywhere)(?: now| please)?$"#, t)
            || Rx.matches(polite + #"start (?:vacuuming|cleaning)(?: the house| the floors?| now)?$"#, t) {
            return HomeCommand(action: .vacuumStart, target: "vacuum")
        }

        // Thermostat
        if let g = Rx.groups(polite + #"(?:set|change|turn|put)\s+(?:the\s+|my\s+)?(thermostat|heat|heating|heater|ac|air conditioning|air conditioner|aircon|temperature|temp)\s+(?:to|at)\s+(\d{1,3}(?:\.\d)?)\s*(?:degrees?|°)?\s*(f|c|fahrenheit|celsius)?$"#, t),
           let v = Double(g[1]) {
            return HomeCommand(action: .temp(v, unit: g[2].isEmpty ? nil : String(g[2].prefix(1))), target: g[0] == "temperature" || g[0] == "temp" ? "thermostat" : g[0])
        }
        if let g = Rx.groups(polite + #"(?:make it|i want it)\s+(\d{1,3})\s*(?:degrees?|°)\s*(f|c|fahrenheit|celsius)?(?: in here| inside| in the house)?$"#, t), let v = Double(g[0]) {
            return HomeCommand(action: .temp(v, unit: g[1].isEmpty ? nil : String(g[1].prefix(1))), target: "thermostat")
        }
        if Rx.matches(#"^(?:what is |how warm is it |how hot is it |how cold is it )(?:the )?(?:temperature )?(?:inside|in here|in the house|indoors|at home)$"#, t)
            || Rx.matches(#"^(?:what is )?(?:the )?(?:thermostat|indoor temperature|inside temperature)(?: set to| at| on| status)?$"#, t) {
            return HomeCommand(action: .status, target: "thermostat")
        }

        // What's in the home
        if Rx.matches(#"^(?:what|which)\s+(?:smart home\s+|home\s+|smart\s+)?(?:devices|accessories|gadgets|things)\s+(?:do i have|are (?:there|connected|in my (?:home|house)|on)|can you (?:control|see|use))"#, t)
            || Rx.matches(polite + #"(?:list|show)(?: me)?\s+(?:my\s+|all\s+(?:my\s+)?)?(?:smart home\s+|home\s+)?(?:devices|accessories|smart home|home)$"#, t)
            || Rx.matches(#"^(?:smart home|home|apple home) status$|^what can you control(?: in my (?:house|home))?$"#, t) {
            return HomeCommand(action: .list, target: "")
        }

        // Brightness
        if let g = Rx.groups(polite + #"(?:set|dim|turn|put|make|change)\s+(?:the\s+|my\s+|all\s+(?:the\s+)?)?(.+?)\s+(?:to|at)\s+(\d{1,3})\s*(?:%|percent)(?: brightness)?$"#, t),
           isDevice(g[0]), let v = Int(g[1]) {
            return HomeCommand(action: .level(min(100, max(0, v))), target: g[0])
        }
        if let g = Rx.groups(polite + #"(?:set|dim|turn|put|make|change)\s+(?:the\s+|my\s+)?(.+?)\s+brightness\s+(?:to|at)\s+(\d{1,3})\s*(?:%|percent)?$"#, t),
           let v = Int(g[1]) {
            return HomeCommand(action: .level(min(100, max(0, v))), target: g[0])
        }
        if let g = Rx.groups(polite + #"(dim|brighten)\s+(?:the\s+|my\s+|all\s+(?:the\s+)?)?(.+?)(?:\s+(?:a bit|a little|down|up|please))*$"#, t), isDevice(g[1]) {
            return HomeCommand(action: .level(g[0] == "dim" ? 30 : 100), target: g[1])
        }

        // Colors ("turn the lights red", "make the govee lights blue", "set the lamp to warm white")
        if let g = Rx.groups(polite + #"(?:turn|make|set|change|switch|colou?r|paint)\s+(?:the\s+|my\s+|all\s+(?:of\s+)?(?:the\s+|my\s+)?)?(.+?)\s+(?:to\s+|into\s+)?(?:the\s+)?(?:colou?r\s+)?"# + colors + #"(?:\s+colou?r)?(?:\s+(?:please|now|for me))*$"#, t),
           isDevice(g[0]), isLight(g[0]) {
            return HomeCommand(action: .color(g[1]), target: g[0])
        }

        // Is it on? (before "X on", so "is the fan on" is a question)
        if let g = Rx.groups(#"^(?:is|are)\s+(?:the\s+|my\s+|all\s+(?:the\s+)?)?(.+?)\s+(?:on|off|still on|turned on|turned off)$"#, t), isDevice(g[0]) {
            return HomeCommand(action: .status, target: g[0])
        }
        if let g = Rx.groups(#"^(?:did i leave|did you leave)\s+(?:the\s+|my\s+)?(.+?)\s+on$"#, t), isDevice(g[0]) {
            return HomeCommand(action: .status, target: g[0])
        }

        // On and off
        if let g = Rx.groups(polite + #"(?:turn|switch|power|shut)\s+(on|off)\s+(?:the\s+|my\s+|all\s+(?:of\s+)?(?:the\s+|my\s+)?)?(.+?)(?:\s+(?:please|now|for me))*$"#, t), isDevice(g[1]) {
            return HomeCommand(action: g[0] == "on" ? .on : .off, target: g[1])
        }
        if let g = Rx.groups(polite + #"(?:turn|switch|power|shut)\s+(?:the\s+|my\s+|all\s+(?:of\s+)?(?:the\s+|my\s+)?)?(.+?)\s+(on|off)(?:\s+(?:please|now|for me))*$"#, t), isDevice(g[0]) {
            return HomeCommand(action: g[1] == "on" ? .on : .off, target: g[0])
        }
        if let g = Rx.groups(#"^(?:the\s+|my\s+|all\s+(?:the\s+)?)?(.+?)\s+(on|off)(?: please| now)?$"#, t), isDevice(g[0]),
           !Rx.matches(#"^(is|are|was|were|did|do|does|what|how|why|who|when|where|can|could|should|will|would)\b"#, g[0]) {
            return HomeCommand(action: g[1] == "on" ? .on : .off, target: g[0])
        }
        if let g = Rx.groups(#"^(?:lights|lamps)\s+(on|off)\s+(?:in\s+)?(?:the\s+)?(.+)$"#, t) {
            return HomeCommand(action: g[0] == "on" ? .on : .off, target: g[1] + " lights")
        }

        return nil
    }

    /// True unless the words name something that can't change color (a thermostat, a fan...).
    static func isLight(_ words: String) -> Bool {
        !Rx.matches(#"\b(thermostats?|heat|heating|heaters?|ac|air conditioners?|aircon|fans?|ceiling fans?|purifiers?|air purifiers?|humidifiers?|dehumidifiers?|tv|television|speakers?|kettle|coffee maker|plugs?|smart plugs?|outlets?|switch(es)?|blueair)\b"#, words)
    }

    /// True when the words name something in a home (a light, a plug...) or a name from Apple Home.
    static func isDevice(_ words: String) -> Bool {
        let w = words.trimmingCharacters(in: .whitespaces)
        guard !w.isEmpty, w.count <= 40 else { return false }
        if Rx.matches(deviceWords, w) { return true }
        let names = knownNames
        return names.contains { n in
            let n = n.lowercased()
            return n.count >= 3 && (w == n || w.contains(n) || (n.contains(w) && w.count >= 4))
        }
    }
}
