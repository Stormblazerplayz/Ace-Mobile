import Foundation
import Combine

/// Everything the user can change in Settings. Saved to UserDefaults right away.
@MainActor
final class SettingsStore: ObservableObject {
    private let d = UserDefaults.standard

    @Published var userName: String { didSet { d.set(userName, forKey: "userName") } }
    @Published var soundsOn: Bool { didSet { d.set(soundsOn, forKey: "soundsOn") } }
    @Published var volume: Double { didSet { d.set(volume, forKey: "volume") } }
    @Published var hapticsOn: Bool { didSet { d.set(hapticsOn, forKey: "hapticsOn") } }
    @Published var speakReplies: Bool { didSet { d.set(speakReplies, forKey: "speakReplies") } }
    @Published var voiceID: String { didSet { d.set(voiceID, forKey: "voiceID") } }
    @Published var wakeChecks: Bool { didSet { d.set(wakeChecks, forKey: "wakeChecks") } }
    @Published var backgroundAlerts: Bool { didSet { d.set(backgroundAlerts, forKey: "backgroundAlerts") } }
    /// "ace" opens pages in a sheet inside Ace, "safari" opens Safari.
    @Published var openLinksIn: String { didSet { d.set(openLinksIn, forKey: "openLinksIn") } }
    /// "google", "duckduckgo" or "bing".
    @Published var searchEngine: String { didSet { d.set(searchEngine, forKey: "searchEngine") } }
    @Published var webAnswers: Bool { didSet { d.set(webAnswers, forKey: "webAnswers") } }
    @Published var showThinking: Bool { didSet { d.set(showThinking, forKey: "showThinking") } }
    @Published var useAppleModel: Bool { didSet { d.set(useAppleModel, forKey: "useAppleModel") } }
    @Published var useLocalModel: Bool { didSet { d.set(useLocalModel, forKey: "useLocalModel") } }
    @Published var bedtimeTips: Bool { didSet { d.set(bedtimeTips, forKey: "bedtimeTips") } }
    /// "auto", "c" or "f".
    @Published var temperatureUnit: String { didSet { d.set(temperatureUnit, forKey: "temperatureUnit") } }
    @Published var syncEnabled: Bool { didSet { d.set(syncEnabled, forKey: "syncEnabled") } }
    @Published var syncHost: String { didSet { d.set(syncHost, forKey: "syncHost") } }
    @Published var syncPort: Int { didSet { d.set(syncPort, forKey: "syncPort") } }
    @Published var syncPCName: String { didSet { d.set(syncPCName, forKey: "syncPCName") } }
    @Published var lastSync: Date? { didSet { d.set(lastSync, forKey: "lastSync") } }
    @Published var lastGreetingDay: String { didSet { d.set(lastGreetingDay, forKey: "lastGreetingDay") } }

    init() {
        d.register(defaults: [
            "soundsOn": true, "volume": 0.8, "hapticsOn": true, "speakReplies": false,
            "wakeChecks": true, "backgroundAlerts": true, "openLinksIn": "ace", "searchEngine": "google",
            "webAnswers": true, "showThinking": true, "useAppleModel": false, "useLocalModel": false,
            "bedtimeTips": true, "temperatureUnit": "auto", "syncEnabled": false, "syncPort": 48620,
        ])
        userName = d.string(forKey: "userName") ?? ""
        soundsOn = d.bool(forKey: "soundsOn")
        volume = d.double(forKey: "volume")
        hapticsOn = d.bool(forKey: "hapticsOn")
        speakReplies = d.bool(forKey: "speakReplies")
        voiceID = d.string(forKey: "voiceID") ?? ""
        wakeChecks = d.bool(forKey: "wakeChecks")
        backgroundAlerts = d.bool(forKey: "backgroundAlerts")
        openLinksIn = d.string(forKey: "openLinksIn") ?? "ace"
        searchEngine = d.string(forKey: "searchEngine") ?? "google"
        webAnswers = d.bool(forKey: "webAnswers")
        showThinking = d.bool(forKey: "showThinking")
        useAppleModel = d.bool(forKey: "useAppleModel")
        useLocalModel = d.bool(forKey: "useLocalModel")
        bedtimeTips = d.bool(forKey: "bedtimeTips")
        temperatureUnit = d.string(forKey: "temperatureUnit") ?? "auto"
        syncEnabled = d.bool(forKey: "syncEnabled")
        syncHost = d.string(forKey: "syncHost") ?? ""
        syncPort = d.integer(forKey: "syncPort")
        syncPCName = d.string(forKey: "syncPCName") ?? ""
        lastSync = d.object(forKey: "lastSync") as? Date
        lastGreetingDay = d.string(forKey: "lastGreetingDay") ?? ""
    }

    var useFahrenheit: Bool {
        switch temperatureUnit {
        case "c": return false
        case "f": return true
        default: return Locale.current.measurementSystem == .us
        }
    }

    /// Plain settings that background code (not on the main actor) can read.
    nonisolated static var backgroundAlertsOn: Bool {
        UserDefaults.standard.object(forKey: "backgroundAlerts") as? Bool ?? true
    }
}
