import Foundation

/// How Ace Graphs opens: empty, or with a formula already drawing.
enum GraphStart: Equatable {
    case blank
    case plot(String)

    /// From the brain's ask ("open" or "plot:x^2 + 1").
    init?(ask: String) {
        if ask == "open" {
            self = .blank
        } else if ask.hasPrefix("plot:"), GraphParse.parse(String(ask.dropFirst(5))) != nil {
            self = .plot(String(ask.dropFirst(5)))
        } else {
            return nil
        }
    }
}

extension Brain {
    /// Opens the graph, and says what the formula's graph looks like.
    func graphReply(_ ask: String, host: BrainHost) -> BrainReply {
        let source = "Ace Graphs"
        guard let start = GraphStart(ask: ask) else {
            return BrainReply(text: "Say \"graph y = x squared\" and I'll draw it.", source: source, kind: "graph")
        }
        guard host.showGraph(start) else {
            return BrainReply(text: "I can't open the graph during a call, because the call screen is on top. Hang up, then ask me again.",
                              source: source, mood: .idle, kind: "graph")
        }
        switch start {
        case .blank:
            return BrainReply(text: "Here's the graph paper! Type a formula like 2x + 1 or x^2, or tap an example, and I'll draw it.",
                              source: source, mood: .happy, kind: "graph")
        case .plot(let text):
            let expr = GraphParse.parse(text)!
            let label = "y = " + GraphParse.pretty(text)
            return BrainReply(text: "Here's \(label)! " + GraphFacts.describe(expr) + " Switch to Trace to slide along it.",
                              source: source, mood: .happy, kind: "graph")
        }
    }
}
