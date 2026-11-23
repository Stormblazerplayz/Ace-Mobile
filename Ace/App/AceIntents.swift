import AppIntents
import Foundation

/// Hands things you asked Siri, Shortcuts or a widget to Ace once the app is ready.
@MainActor
final class IntentInbox {
    static let shared = IntentInbox()
    private var waiting: [String] = []
    private var handler: ((String) -> Void)?
    private var callWaiting = false
    private var callHandler: (() -> Void)?

    private init() {}

    /// Ace's chat calls this when it's ready, and gets anything that was waiting.
    func connect(_ handler: @escaping (String) -> Void) {
        self.handler = handler
        let queued = waiting
        waiting = []
        for text in queued { handler(text) }
    }

    /// Ace's call screen calls this when it's ready, and starts a call if one was asked for meanwhile.
    func connectCall(_ handler: @escaping () -> Void) {
        callHandler = handler
        if callWaiting {
            callWaiting = false
            handler()
        }
    }

    /// Starts a voice call with Ace (Siri's "Call Ace", or ace://call).
    func postCall() {
        if let callHandler { callHandler() } else { callWaiting = true }
    }

    func post(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if let handler { handler(clean) } else { waiting.append(clean) }
    }
}

/// "Ask Ace": say or type anything and Ace answers in the app.
struct AskAceIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Ace"
    static var description = IntentDescription("Ask Ace anything. Ace opens and answers.")
    static var openAppWhenRun = true

    @Parameter(title: "Question", requestValueDialog: "What do you want to ask Ace?")
    var question: String

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentInbox.shared.post(question)
        return .result()
    }
}

/// "Call Ace": opens Ace's voice call screen so you can talk back and forth.
struct CallAceIntent: AppIntent {
    static var title: LocalizedStringResource = "Call Ace"
    static var description = IntentDescription("Starts a voice call with Ace. Talk, and Ace talks back.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentInbox.shared.postCall()
        return .result()
    }
}

/// "Start the vacuum with Ace".
struct StartVacuumIntent: AppIntent {
    static var title: LocalizedStringResource = "Start the Vacuum"
    static var description = IntentDescription("Tells Ace to start your robot vacuum.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentInbox.shared.post("start the vacuum")
        return .result()
    }
}

/// "Goodnight Ace": runs Ace's goodnight scene (lights off).
struct GoodnightIntent: AppIntent {
    static var title: LocalizedStringResource = "Goodnight"
    static var description = IntentDescription("Runs Ace's goodnight scene.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentInbox.shared.post("run the goodnight scene")
        return .result()
    }
}

/// Ace's built-in scenes, so Shortcuts can show them as a list.
enum AceScene: String, AppEnum, CaseIterable {
    case goodnight, movie, morning, focus, party, welcomeHome

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Scene"
    static var caseDisplayRepresentations: [AceScene: DisplayRepresentation] = [
        .goodnight: "Goodnight", .movie: "Movie", .morning: "Morning",
        .focus: "Focus", .party: "Party", .welcomeHome: "Welcome home",
    ]

    var command: String {
        switch self {
        case .welcomeHome: return "run the welcome home scene"
        default: return "run the \(rawValue) scene"
        }
    }
}

/// "Run a scene with Ace".
struct RunSceneIntent: AppIntent {
    static var title: LocalizedStringResource = "Run a Scene"
    static var description = IntentDescription("Runs one of Ace's scenes, like Movie or Party.")
    static var openAppWhenRun = true

    @Parameter(title: "Scene")
    var scene: AceScene

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentInbox.shared.post(scene.command)
        return .result()
    }
}

/// The phrases Siri knows without any setup.
struct AceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AskAceIntent(), phrases: [
            "Ask \(.applicationName)",
            "Ask \(.applicationName) a question",
            "Talk to \(.applicationName)",
        ], shortTitle: "Ask Ace", systemImageName: "sparkles")
        AppShortcut(intent: CallAceIntent(), phrases: [
            "Call \(.applicationName)",
            "Start a call with \(.applicationName)",
            "Voice call \(.applicationName)",
            "Talk with \(.applicationName) on a call",
        ], shortTitle: "Call Ace", systemImageName: "phone.fill")
        AppShortcut(intent: StartVacuumIntent(), phrases: [
            "Start the vacuum with \(.applicationName)",
            "\(.applicationName) start the vacuum",
            "Vacuum with \(.applicationName)",
        ], shortTitle: "Start the Vacuum", systemImageName: "fan")
        AppShortcut(intent: GoodnightIntent(), phrases: [
            "Goodnight \(.applicationName)",
            "Tell \(.applicationName) goodnight",
            "\(.applicationName) goodnight",
        ], shortTitle: "Goodnight", systemImageName: "moon.stars")
        AppShortcut(intent: RunSceneIntent(), phrases: [
            "Run a scene with \(.applicationName)",
            "Run \(\.$scene) with \(.applicationName)",
            "\(.applicationName) \(\.$scene) scene",
        ], shortTitle: "Run a Scene", systemImageName: "lightbulb.2")
    }
}
