import Foundation

/// The rules behind a voice call with Ace, kept apart from the audio so tests can check them.
enum CallLogic {
    /// Where a call is right now.
    enum Phase: String, Equatable {
        /// No call.
        case off
        /// The microphone and speaker are starting up.
        case connecting
        /// Ace is waiting for you to talk.
        case listening
        /// You're talking (words are coming in).
        case hearing
        /// Ace is working out an answer.
        case thinking
        /// Ace is talking.
        case speaking
        /// The call just ended (the screen shows "Call ended" for a moment).
        case ended

        /// The call is on (the call screen shows).
        var isLive: Bool { self != .off && self != .ended }

        /// What the call screen says under the timer.
        var label: String {
            switch self {
            case .off: return ""
            case .connecting: return "Connecting"
            case .listening: return "Listening"
            case .hearing: return "Hearing you"
            case .thinking: return "Thinking"
            case .speaking: return "Talking"
            case .ended: return "Call ended"
            }
        }
    }

    /// The call timer, like a phone: "0:07", "12:30", "1:02:03".
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    /// How long a call lasted, said in words for the chat ("2 minutes 5 seconds").
    static func lengthInWords(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        func part(_ n: Int, _ word: String) -> String { "\(n) \(word)\(n == 1 ? "" : "s")" }
        var parts: [String] = []
        if h > 0 { parts.append(part(h, "hour")) }
        if m > 0 { parts.append(part(m, "minute")) }
        if s > 0 || parts.isEmpty { parts.append(part(s, "second")) }
        return parts.joined(separator: " ")
    }

    // MARK: Words

    /// Lowercase words without punctuation ("Wait, what?" -> ["wait", "what"]).
    static func words(_ text: String) -> [String] {
        let cleaned = text.lowercased().map { ch -> Character in
            ch.isLetter || ch.isNumber || ch == "'" ? ch : " "
        }
        return String(cleaned).split(separator: " ").map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: "'")) }
            .filter { !$0.isEmpty }
    }

    /// One word that stops Ace right away, even on its own.
    static let stopWords: Set<String> = ["stop", "wait", "hold", "pause", "quiet", "shush", "shh", "nevermind", "enough", "hang"]

    // MARK: Talking over Ace

    /// While Ace talks, the microphone can still hear Ace (the iPad's echo cancelling isn't perfect).
    /// So Ace only stops when it hears words that aren't in what it's saying: two new words,
    /// or one "stop" word ("wait", "stop", "hold on") that Ace didn't just say itself.
    static func shouldInterrupt(heard: String, aceSaying: String) -> Bool {
        let fresh = newWords(heard: heard, aceSaying: aceSaying)
        if fresh.count >= 2 { return true }
        return fresh.contains { stopWords.contains($0) }
    }

    /// The words you said that aren't an echo of Ace.
    static func newWords(heard: String, aceSaying: String) -> [String] {
        let ace = Set(words(aceSaying))
        return words(heard).filter { !ace.contains($0) }
    }

    /// What you said after talking over Ace, without any of Ace's own words the microphone heard
    /// before you started ("the capital is paris wait what about spain" -> "wait what about spain").
    static func userPart(heard: String, aceSaying: String) -> String {
        let ace = Set(words(aceSaying))
        let all = words(heard)
        guard !ace.isEmpty, let first = all.firstIndex(where: { !ace.contains($0) }) else {
            return ace.isEmpty ? heard.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        }
        // Keep the original spelling and capitals: skip the same number of words in the original text.
        let originals = heard.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
        var skipped = 0
        var index = 0
        while index < originals.count, skipped < first {
            skipped += words(String(originals[index])).count
            index += 1
        }
        return originals[index...].joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,.!?"))
    }

    // MARK: Starting a call by voice

    /// "Call Ace" (and the ways speech recognition likes to spell it), said on its own while "Hey Ace" is on.
    static func saysCallAce(_ text: String) -> Bool {
        let w = words(text)
        guard w.count >= 2 else { return false }
        let ace: Set<String> = ["ace", "ase", "a's", "ace's", "aces"]
        for i in 0..<(w.count - 1) where w[i] == "call" || w[i] == "cole" || w[i] == "col" {
            if ace.contains(w[i + 1]) { return true }
        }
        return false
    }

    // MARK: Quiet calls

    enum IdleStep: Equatable { case wait, nudge, hangUp }

    /// After this long with nothing said, Ace asks if you're still there.
    static let nudgeAfter: TimeInterval = 75
    /// And after this much longer, Ace hangs up.
    static let hangUpAfter: TimeInterval = 30

    /// What to do when nobody has said anything for `silentFor` seconds.
    /// `nudged` is true once Ace has asked "still there?" in this quiet spell.
    static func idleStep(silentFor: TimeInterval, nudged: Bool) -> IdleStep {
        if !nudged { return silentFor >= nudgeAfter ? .nudge : .wait }
        return silentFor >= hangUpAfter ? .hangUp : .wait
    }

    // MARK: The orb on the call screen

    /// How the big orb looks: it follows the call (listening, thinking, talking), but a sassy
    /// eye-roll or a happy look from Ace still shows.
    static func orbMood(_ phase: Phase, ace: OrbMood) -> OrbMood {
        if ace.showsEyes, phase != .ended { return ace }
        switch phase {
        case .off, .listening: return .idle
        case .connecting: return .checking
        case .hearing: return .listening
        case .thinking: return .thinking
        case .speaking: return .talking
        case .ended: return .sleeping
        }
    }

    // MARK: Captions

    /// One line of the live captions.
    struct Caption: Identifiable, Equatable {
        enum Who: Equatable { case you, ace }
        var id = UUID()
        var who: Who
        var text: String
        /// Still coming in (your words while you talk).
        var live = false
    }

    /// The captions to show: the last few lines of this call, plus what you're saying now.
    static func captions(_ lines: [Caption], live: String, keep: Int = 6) -> [Caption] {
        var out = Array(lines.suffix(keep))
        let now = live.trimmingCharacters(in: .whitespacesAndNewlines)
        if !now.isEmpty { out.append(Caption(id: liveID, who: .you, text: now, live: true)) }
        return out
    }

    /// A fixed id for the live line, so it doesn't flicker as words come in.
    static let liveID = UUID(uuidString: "00000000-0000-0000-0000-00000000CA11")!

    /// A reply as it's shown in the captions: no bullets or extra blank lines, and long replies cut short.
    static func captionText(_ reply: String, limit: Int = 320) -> String {
        let lines = reply.replacingOccurrences(of: "•", with: "")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let joined = lines.joined(separator: " ")
        guard joined.count > limit else { return joined }
        let cut = joined.prefix(limit)
        if let space = cut.lastIndex(of: " ") { return String(cut[..<space]) + "…" }
        return String(cut) + "…"
    }
}
