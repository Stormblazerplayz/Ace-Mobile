import Foundation

/// Special pieces of UI that can ride along with a chat message.
enum AceCard: Codable, Equatable {
    case recipe(RecipeCard)
    case weather(WeatherCard)
    case web(WebCard)
    case links([LinkItem])
    case eventDraft(EventDraft)
    case events([EventItem])
    case check(CheckReport)
    case files([FileHit])
    case screenshots([ScreenshotHit])
    case image(ImageReport)
    case timer(TimerCard)
    case power(PowerCard)
    case greeting(GreetingCard)
    case code(CodeCard)
    case trivia(TriviaCard)
    case translation(TranslationCard)
    case quickReplies(QuickReplies)
    case steps(StepsCard)
    case whatsNew(WhatsNewCard)
    case ticTacToe(TicTacToeCard)
    case hangman(HangmanCard)
    case numberGuess(NumberGuessCard)
    case rps(RPSCard)
}

/// What changed in this build, shown once after an update (and from Settings).
struct WhatsNewCard: Codable, Equatable {
    var build: Int
    var date: String
    var items: [String]
}

/// Buttons that send a short answer ("Yes", "No"...), used by 20 questions and recipe offers.
struct QuickReplies: Codable, Equatable {
    /// Matches Brain.gameToken while these buttons still mean something.
    var token: String
    var replies: [String]
    /// True for buttons that work any time, like "Chocolate mug cake recipe" (not part of a game).
    /// Optional so chats saved before it still load.
    var anytime: Bool? = nil
}

/// The first hello of the day: the date, what's on today, and a few quick things to ask.
struct GreetingCard: Codable, Equatable {
    var hello: String
    var date: Date
    /// Today's events, soonest first (empty when the calendar is clear or not allowed).
    var events: [EventItem]
    var calendarAllowed: Bool
}

/// A script from Ace's code library, shown with colors, a Copy button and where to put it.
struct CodeCard: Codable, Equatable {
    var id: String
    var title: String
    var language: String   // "Lua", "C++", "Python" or "Swift"
    var kind: String       // "Script", "LocalScript", "Arduino sketch"...
    var `where`: String
    var about: String
    var code: String
}

struct RecipeCard: Codable, Equatable {
    var name: String
    var category: String?
    var area: String?
    var imageURL: URL?
    var ingredients: [String]
    var steps: [String]
    var sourceURL: URL?
    var servings: Int? = nil
    var time: String? = nil
    /// True for recipes from Ace's own recipe book (they work with no internet).
    var builtIn: Bool? = nil
}

struct WeatherCard: Codable, Equatable {
    struct Day: Codable, Equatable {
        var date: Date
        var high: Double
        var low: Double
        var code: Int
        var rainChance: Int?
    }
    var place: String
    var temperature: Double
    var feelsLike: Double?
    var code: Int
    var wind: Double?
    var unit: String   // "°C" or "°F"
    var days: [Day]
}

struct WebSource: Codable, Equatable, Identifiable {
    var id: String { url.absoluteString }
    var title: String
    var url: URL
}

struct WebCard: Codable, Equatable {
    var title: String
    var summary: String
    var bullets: [String]
    var imageURL: URL?
    var sources: [WebSource]
}

struct LinkItem: Codable, Equatable, Identifiable {
    var id: String { url.absoluteString }
    var title: String
    var url: URL
}

enum EventAction: String, Codable {
    case add, edit, delete
}

enum DraftStatus: String, Codable {
    case waiting, done, cancelled, failed
}

/// A calendar change Ace wants to make. Nothing happens until the user taps Yes.
struct EventDraft: Codable, Equatable, Identifiable {
    var id = UUID()
    var action: EventAction
    var title: String
    var start: Date
    var end: Date
    var allDay: Bool = false
    var notes: String?
    /// The EventKit identifier of the event being edited or deleted.
    var eventID: String?
    var status: DraftStatus = .waiting
    var resultText: String?
}

struct EventItem: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var start: Date
    var end: Date
    var allDay: Bool
    var calendar: String
}

enum CheckLevel: String, Codable {
    case ok, info, warn
}

struct CheckItem: Codable, Equatable, Identifiable {
    var id = UUID()
    var icon: String     // SF Symbol name
    var title: String
    var detail: String
    var level: CheckLevel
}

struct CheckReport: Codable, Equatable, Identifiable {
    var id = UUID()
    var date = Date()
    var items: [CheckItem]
    var summary: String

    var needsAttention: Bool { items.contains { $0.level == .warn } }
}

struct FileHit: Codable, Equatable, Identifiable {
    var id: String { path }
    var name: String
    var path: String
    var size: Int64
    var modified: Date?
    var snippet: String?
    /// Which picked folder it came from (its bookmark key).
    var folderKey: String
}

struct ScreenshotHit: Codable, Equatable, Identifiable {
    var id: String { assetID }
    var assetID: String
    var date: Date?
    var snippet: String
}

struct ImageReport: Codable, Equatable {
    var labels: [String]
    var text: String?
    var codes: [String]
    var faces: Int
    var summary: String
}

struct TimerCard: Codable, Equatable, Identifiable {
    var id = UUID()
    var label: String
    var fireDate: Date
    var notificationID: String
}

struct PowerCard: Codable, Equatable {
    var action: String   // shutdown, restart, or another PC command
    var status: DraftStatus
    var detail: String
}
