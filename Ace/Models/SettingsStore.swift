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
    /// How fast Ace talks: 1 is normal, 0.6 is slowest, 1.5 is fastest.
    @Published var voiceSpeed: Double { didSet { d.set(voiceSpeed, forKey: "voiceSpeed") } }
    @Published var wakeChecks: Bool { didSet { d.set(wakeChecks, forKey: "wakeChecks") } }
    @Published var backgroundAlerts: Bool { didSet { d.set(backgroundAlerts, forKey: "backgroundAlerts") } }
    /// "ace" opens pages in a sheet inside Ace, "safari" opens Safari.
    @Published var openLinksIn: String { didSet { d.set(openLinksIn, forKey: "openLinksIn") } }
    /// "google", "duckduckgo" or "bing".
    @Published var searchEngine: String { didSet { d.set(searchEngine, forKey: "searchEngine") } }
    @Published var webAnswers: Bool { didSet { d.set(webAnswers, forKey: "webAnswers") } }
    @Published var showThinking: Bool { didSet { d.set(showThinking, forKey: "showThinking") } }
    @Published var useAppleModel: Bool { didSet { d.set(useAppleModel, forKey: "useAppleModel") } }
    /// "Fall back to LFM3 Omni when Ace doesn't know" (Normal Ace only).
    @Published var useLocalModel: Bool { didSet { d.set(useLocalModel, forKey: "useLocalModel") } }
    /// Who answers: "ace" (Normal Ace: rules, answer bank, web) or "model" (LFM3 Omni answers questions).
    @Published var brain: String { didSet { d.set(brain, forKey: "brain") } }
    @Published var bedtimeTips: Bool { didSet { d.set(bedtimeTips, forKey: "bedtimeTips") } }
    /// Listen for "Hey Ace" while the app is open.
    @Published var heyAce: Bool { didSet { d.set(heyAce, forKey: "heyAce") } }
    /// "auto", "c" or "f".
    @Published var temperatureUnit: String { didSet { d.set(temperatureUnit, forKey: "temperatureUnit") } }
    @Published var syncEnabled: Bool { didSet { d.set(syncEnabled, forKey: "syncEnabled") } }
    @Published var syncHost: String { didSet { d.set(syncHost, forKey: "syncHost") } }
    @Published var syncPort: Int { didSet { d.set(syncPort, forKey: "syncPort") } }
    @Published var syncPCName: String { didSet { d.set(syncPCName, forKey: "syncPCName") } }
    @Published var lastSync: Date? { didSet { d.set(lastSync, forKey: "lastSync") } }
    @Published var lastGreetingDay: String { didSet { d.set(lastGreetingDay, forKey: "lastGreetingDay") } }
    /// When Ace last said hello as the app opened (it doesn't greet twice within a few minutes).
    @Published var lastGreetingAt: Date? { didSet { d.set(lastGreetingAt, forKey: "lastGreetingAt") } }
    /// Say the hello out loud when the app opens.
    @Published var speakGreeting: Bool { didSet { d.set(speakGreeting, forKey: "speakGreeting") } }
    /// A short quiet sound when the orb changes mood.
    @Published var moodSounds: Bool { didSet { d.set(moodSounds, forKey: "moodSounds") } }
    /// Seasonal outfits on the orb (a Santa hat in December...).
    @Published var orbOutfits: Bool { didSet { d.set(orbOutfits, forKey: "orbOutfits") } }
    /// "normal" or "sassy" (lots of attitude, same right answers).
    @Published var personality: String { didSet { d.set(personality, forKey: "personality") } }
    /// How much sass in Sassy mode: "mild", "spicy" or "extra" (the default).
    @Published var sassLevel: String { didSet { d.set(sassLevel, forKey: "sassLevel") } }
    /// The newest build whose What's new card was shown in the chat.
    @Published var lastWhatsNewBuild: Int { didSet { d.set(lastWhatsNewBuild, forKey: "lastWhatsNewBuild") } }
    /// Springy, bouncy animations all over the app. Off swaps them for a quick, calm fade.
    @Published var bouncyMotion: Bool { didSet { d.set(bouncyMotion, forKey: AceMotion.settingKey) } }

    init() {
        d.register(defaults: [
            "soundsOn": true, "volume": 0.8, "hapticsOn": true, "speakReplies": false,
            "wakeChecks": true, "backgroundAlerts": true, "openLinksIn": "ace", "searchEngine": "google",
            "webAnswers": true, "showThinking": true, "useAppleModel": false, "useLocalModel": true, "brain": "ace",
            "bedtimeTips": true, "temperatureUnit": "auto", "syncEnabled": false, "syncPort": 48620, "voiceSpeed": 1.0,
            "speakGreeting": true, "moodSounds": true, "orbOutfits": true, "personality": "normal", "sassLevel": "extra",
            AceMotion.settingKey: true,
        ])
        userName = d.string(forKey: "userName") ?? ""
        soundsOn = d.bool(forKey: "soundsOn")
        volume = d.double(forKey: "volume")
        hapticsOn = d.bool(forKey: "hapticsOn")
        speakReplies = d.bool(forKey: "speakReplies")
        voiceID = d.string(forKey: "voiceID") ?? ""
        voiceSpeed = min(SettingsStore.fastestVoice, max(SettingsStore.slowestVoice, d.double(forKey: "voiceSpeed")))
        wakeChecks = d.bool(forKey: "wakeChecks")
        backgroundAlerts = d.bool(forKey: "backgroundAlerts")
        openLinksIn = d.string(forKey: "openLinksIn") ?? "ace"
        searchEngine = d.string(forKey: "searchEngine") ?? "google"
        webAnswers = d.bool(forKey: "webAnswers")
        showThinking = d.bool(forKey: "showThinking")
        useAppleModel = d.bool(forKey: "useAppleModel")
        useLocalModel = d.bool(forKey: "useLocalModel")
        brain = d.string(forKey: "brain") == "model" ? "model" : "ace"
        bedtimeTips = d.bool(forKey: "bedtimeTips")
        heyAce = d.bool(forKey: "heyAce")
        temperatureUnit = d.string(forKey: "temperatureUnit") ?? "auto"
        syncEnabled = d.bool(forKey: "syncEnabled")
        syncHost = d.string(forKey: "syncHost") ?? ""
        syncPort = d.integer(forKey: "syncPort")
        syncPCName = d.string(forKey: "syncPCName") ?? ""
        lastSync = d.object(forKey: "lastSync") as? Date
        lastGreetingDay = d.string(forKey: "lastGreetingDay") ?? ""
        lastGreetingAt = d.object(forKey: "lastGreetingAt") as? Date
        speakGreeting = d.bool(forKey: "speakGreeting")
        moodSounds = d.bool(forKey: "moodSounds")
        orbOutfits = d.bool(forKey: "orbOutfits")
        personality = d.string(forKey: "personality") == "sassy" ? "sassy" : "normal"
        sassLevel = SassLevel(setting: d.string(forKey: "sassLevel") ?? "extra").setting
        lastWhatsNewBuild = d.integer(forKey: "lastWhatsNewBuild")
        bouncyMotion = d.bool(forKey: AceMotion.settingKey)
    }

    nonisolated static let slowestVoice = 0.6
    nonisolated static let fastestVoice = 1.5

    /// The speed for background code that can't reach the settings object.
    nonisolated static var voiceSpeedNow: Double {
        let v = UserDefaults.standard.double(forKey: "voiceSpeed")
        return v == 0 ? 1 : min(fastestVoice, max(slowestVoice, v))
    }

    /// True when LFM3 Omni is picked as the brain.
    var modelBrain: Bool { brain == "model" }

    /// True when LFM3 Omni may answer at all (picked as the brain, or as Normal Ace's fallback).
    var lfmAllowed: Bool { modelBrain || useLocalModel }

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
