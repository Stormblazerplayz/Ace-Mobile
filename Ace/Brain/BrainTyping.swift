import Foundation

extension Brain {
    /// Opens Ace Typing, maybe straight into one lesson ("practice the home row").
    func typingReply(_ ask: String, host: BrainHost) -> BrainReply {
        let source = "Ace Typing"
        let lesson = TypingLesson(rawValue: ask)
        guard host.showTyping(lesson) else {
            return BrainReply(text: "I can't open typing practice during a call, because the call screen is on top. Hang up, then ask me again.",
                              source: source, mood: .idle, kind: "typing")
        }
        if let lesson {
            return BrainReply(text: "Let's practice the \(lesson.title.lowercased())! \(lesson.blurb) Type what you see, and watch the glowing key for what comes next.",
                              source: source, mood: .happy, kind: "typing")
        }
        return BrainReply(text: "Here's Ace Typing! Pick a lesson, type the words you see, and I'll show your speed and accuracy as you go.",
                          source: source, mood: .happy, kind: "typing")
    }
}
