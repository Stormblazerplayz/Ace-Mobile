import Foundation

/// How the solar system opens: the whole map, or with one planet's card already showing.
enum SpaceStart: Equatable {
    case overview
    case planet(String)

    /// From the brain's ask ("open" or "planet:mars"). "where:mars" is answered in the chat instead.
    init?(ask: String) {
        let parts = ask.split(separator: ":", maxSplits: 1).map(String.init)
        switch parts.first {
        case "open": self = .overview
        case "planet" where parts.count == 2 && SolarSystem.planet(parts[1]) != nil: self = .planet(parts[1])
        default: return nil
        }
    }
}

extension Brain {
    /// Answers a space ask: says where a planet is right now, or opens the solar system.
    func spaceReply(_ ask: String, host: BrainHost, now: Date = Date()) -> BrainReply {
        let source = "Ace Space"
        if ask.hasPrefix("where:"), let p = SolarSystem.planet(String(ask.dropFirst(6))) {
            let text = SolarSystem.whereNow(p, at: now) + " Say \"show me \(p.isSun ? "the Sun" : p.name)\" to see it on the map."
            return BrainReply(text: text, source: source, mood: .happy, kind: "space")
        }
        guard let start = SpaceStart(ask: ask) else {
            return BrainReply(text: "Say \"show me the solar system\" to open the map of the planets.", source: source, kind: "space")
        }
        guard host.showSpace(start) else {
            return BrainReply(text: "I can't open the solar system during a call, because the call screen is on top. Hang up, then ask me again.",
                              source: source, mood: .idle, kind: "space")
        }
        switch start {
        case .overview:
            return BrainReply(text: "Here's the solar system, with every planet where it really is today! Speed up time to watch them go round, or tap one to learn about it.",
                              source: source, mood: .happy, kind: "space")
        case .planet(let id):
            let p = SolarSystem.planet(id)!
            let name = p.isSun ? "the Sun" : p.name
            return BrainReply(text: "Here's \(name)! \(p.fact)", source: source, mood: .happy, kind: "space")
        }
    }
}
