import Foundation

extension Brain {
    /// Opens Ace Breathe, maybe on one pattern ("do box breathing").
    func breatheReply(_ ask: String, host: BrainHost) -> BrainReply {
        let source = "Ace Breathe"
        let pattern = BreathPattern(rawValue: ask)
        guard host.showBreathe(pattern) else {
            return BreathReplyText.duringCall(source: source)
        }
        if let pattern {
            return BrainReply(text: "Let's do \(pattern.title.lowercased()) breathing together. \(pattern.blurb) Follow the glowing circle.",
                              source: source, mood: .happy, kind: "breathe")
        }
        return BrainReply(text: "Let's breathe together. Pick a pattern, then breathe in as the circle grows and out as it shrinks.",
                          source: source, mood: .happy, kind: "breathe")
    }
}

enum BreathReplyText {
    static func duringCall(source: String) -> BrainReply {
        BrainReply(text: "I can't open breathing during a call, because the call screen is on top. Hang up, then ask me again.",
                   source: source, mood: .idle, kind: "breathe")
    }
}
