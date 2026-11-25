import Foundation

/// How Ace Piano opens: free play, the song list, a lesson, or Ace playing a song for you.
enum PianoStart: Equatable {
    case free
    case songs
    case learn(String)
    case listen(String)

    /// From the brain's ask ("open", "lessons", "learn:twinkle", "listen:twinkle").
    init?(ask: String) {
        let parts = ask.split(separator: ":", maxSplits: 1).map(String.init)
        switch parts.first {
        case "open": self = .free
        case "lessons": self = .songs
        case "learn" where parts.count == 2 && PianoSongs.song(parts[1]) != nil: self = .learn(parts[1])
        case "listen" where parts.count == 2 && PianoSongs.song(parts[1]) != nil: self = .listen(parts[1])
        default: return nil
        }
    }
}

extension Brain {
    /// Answers a piano ask, and opens Ace Piano when it should.
    func pianoReply(_ ask: String, host: BrainHost, progress: PianoProgress = .shared) -> BrainReply {
        let source = "Ace Piano"
        if ask == "list" {
            var text = "I can play and teach you \(PianoSongs.all.count) songs on the piano: \(PianoSongs.spokenList)."
            if progress.totalStars > 0 {
                let stars = progress.totalStars
                text += " You've earned \(stars) star\(stars == 1 ? "" : "s") so far."
            }
            text += " Say \"teach me Ode to Joy\" to start one."
            return BrainReply(text: text, source: source, mood: .happy, kind: "piano")
        }
        guard let start = PianoStart(ask: ask) else { return BrainReply(text: "Say \"play piano\" to open the piano.", source: source, kind: "piano") }
        guard host.showPiano(start) else {
            return BrainReply(text: "I can't open the piano during a call, because the call screen is on top. Hang up, then ask me again.",
                              source: source, mood: .idle, kind: "piano")
        }
        switch start {
        case .free:
            return BrainReply(text: "Here's the piano! Play anything you like, or tap Songs and I'll teach you one.",
                              source: source, mood: .happy, kind: "piano")
        case .songs:
            return BrainReply(text: "Pick a song and I'll teach it one note at a time. Hot Cross Buns is a great first one.",
                              source: source, mood: .happy, kind: "piano")
        case .learn(let id):
            let song = PianoSongs.song(id)!
            var text = "Let's learn \(song.title)! Press the glowing key, and the song waits for you."
            let best = progress.best(id)
            if best > 0 { text += " Your best is \(best) star\(best == 1 ? "" : "s")." }
            return BrainReply(text: text, source: source, mood: .happy, kind: "piano")
        case .listen(let id):
            let song = PianoSongs.song(id)!
            return BrainReply(text: "Here's \(song.title)! Watch the notes fall, then say \"teach me \(song.title)\" to learn it.",
                              source: source, mood: .happy, kind: "piano")
        }
    }
}
