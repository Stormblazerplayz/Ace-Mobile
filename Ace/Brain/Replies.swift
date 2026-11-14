import Foundation

/// Every canned reply Ace says, by name. Each has 20 wordings in Resources/replies.json
/// (built by tools/build_replies.py), so Ace rarely says the same thing twice in a row.
enum ReplyKey: String, CaseIterable {
    case alarm
    case batteryCharging
    case batteryFull
    case batteryLow
    case batteryOK
    case batteryUnknown
    case calendarAddAsk
    case calendarFree
    case calendarList
    case calendarWhen
    case clarify
    case correctionAsk
    case correctionSaved
    case date
    case daysUntil
    case daysUntilToday
    case deleteAsk
    case deleteNotFound
    case dontKnow
    case empty
    case eventFound
    case eventMoveWhen
    case eventNotFound
    case followUpLost
    case forgotNothing
    case forgotSome
    case fromRoman
    case goodbye
    case greeting
    case guess
    case lowPowerOn
    case math
    case memoryUsage
    case modelMissing
    case nextUp
    case noNameYet
    case noPhoto
    case nothingComingUp
    case offline
    case onlineCellular
    case onlineWiFi
    case openSite
    case pcAppDone
    case pcAppNotPaired
    case pcAppOnIPad
    case pcNotPaired
    case pcRestarting
    case pcShuttingDown
    case pcStatusOff
    case randomNumber
    case recallHeader
    case recallMissing
    case recallNothing
    case recipeFound
    case recipeNotFound
    case remembered
    case reminderSaved
    case reminderSet
    case reminderWhen
    case repeatNothing
    case romanRange
    case searchTab
    case setName
    case soundsOff
    case soundsOn
    case spell
    case storage
    case storageLow
    case storageUnknown
    case summon
    case taught
    case taughtAnswer
    case tellMoreFail
    case tellMoreWhat
    case thanks
    case time
    case timerNoAlerts
    case timerSet
    case toRoman
    case weatherAskCity
    case weatherFail
    case weatherNow
    case weatherToday
    case yourName
}

/// Picks one of several wordings, never one it used recently for the same thing.
@MainActor
final class VariantPicker {
    static let shared = VariantPicker()
    private var recent: [String: [Int]] = [:]

    /// Remembers up to half the choices (at most 8), so with 20 wordings the last 8 are skipped.
    func pick(_ key: String, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let memory = min(8, count / 2)
        let used = recent[key] ?? []
        let fresh = (0..<count).filter { !used.contains($0) }
        let choice = fresh.randomElement() ?? Int.random(in: 0..<count)
        var updated = used + [choice]
        if updated.count > memory { updated.removeFirst(updated.count - memory) }
        recent[key] = updated
        return choice
    }

    func reset() { recent = [:] }
}

/// Fills in a reply: Say.line(.timerSet, ["label": "Timer", "duration": "5 minutes"]).
@MainActor
enum Say {
    struct File: Decodable {
        struct Reply: Decodable {
            let required: [String]
            let say: [String]
        }
        let replies: [String: Reply]
    }

    static let table: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "replies", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [:] }
        return file.replies.mapValues(\.say)
    }()

    /// All the wordings for a reply (for tests).
    static func wordings(_ key: ReplyKey) -> [String] { table[key.rawValue] ?? [] }

    static func line(_ key: ReplyKey, _ slots: [String: String] = [:]) -> String {
        let options = table[key.rawValue] ?? []
        guard !options.isEmpty else { return fill(fallback[key] ?? "Okay.", slots) }
        let i = VariantPicker.shared.pick("reply." + key.rawValue, count: options.count)
        return fill(options[i], slots)
    }

    static func fill(_ template: String, _ slots: [String: String]) -> String {
        var s = template
        for (k, v) in slots { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
        // Any slot nobody filled (only optional ones) disappears.
        s = s.replacingOccurrences(of: #"\{[A-Za-z]+\}"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "  ", with: " ")
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// Used only if replies.json is missing from the app.
    private static let fallback: [ReplyKey: String] = [
        .empty: "I'm here. What's up?", .summon: "Yeah? What do you need?", .dontKnow: "I don't know that one yet.",
    ]
}
