import Foundation

enum Speaker: String, Codable {
    case user, ace, system
}

/// One line in the chat.
struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var speaker: Speaker
    var text: String
    var date = Date()
    /// The steps Ace thought through, shown under "How I got this".
    var thoughts: [String] = []
    var cards: [AceCard] = []
    /// A picture the user sent, saved in Application Support/Images.
    var imageFile: String?
    /// Where the answer came from: bank, web, rules, memory, model, learned.
    var source: String?

    init(speaker: Speaker, text: String, thoughts: [String] = [], cards: [AceCard] = [], imageFile: String? = nil, source: String? = nil) {
        self.speaker = speaker
        self.text = text
        self.thoughts = thoughts
        self.cards = cards
        self.imageFile = imageFile
        self.source = source
    }
}
