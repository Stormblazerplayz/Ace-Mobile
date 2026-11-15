import Foundation

/// A focus session ("focus for 25 minutes"). It's a timer named "Focus", so it rings when
/// Ace is closed, shows in the timers strip and Live Activity, and fills a ring on the orb.
@MainActor
enum FocusSession {
    static let label = "Focus"

    /// The focus timer that's running, if there is one.
    static var current: KitchenTimers.Running? {
        KitchenTimers.shared.timers.last { $0.label == label && !$0.done }
    }

    /// How much of the session is done, 0...1 (nil when none is running).
    static func progress(at date: Date = Date()) -> Double? {
        current.map { progress(of: $0, at: date) }
    }

    nonisolated static func progress(of t: KitchenTimers.Running, at date: Date) -> Double {
        guard t.total > 0 else { return 1 }
        let left = max(0, t.end.timeIntervalSince(date))
        return min(1, max(0, 1 - left / Double(t.total)))
    }

    /// "start 1500", "stop" or "left" (from the router).
    static func handle(_ what: String) async -> BrainReply {
        if what.hasPrefix("start") {
            let seconds = Int(what.split(separator: " ").last ?? "") ?? 25 * 60
            if let old = current { KitchenTimers.shared.cancel(old.id) }
            let ok = await KitchenTimers.shared.start(label: label, seconds: seconds)
            let minutes = max(1, Int((Double(seconds) / 60).rounded()))
            let note = ok ? "" : " " + Say.line(.timerNoAlerts)
            return BrainReply(text: Say.line(.focusStart, ["minutes": String(minutes)]) + note, mood: .happy)
        }
        guard let t = current else { return BrainReply(text: Say.line(.focusNone), mood: .idle) }
        if what == "stop" {
            KitchenTimers.shared.cancel(t.id)
            return BrainReply(text: Say.line(.focusStopped), mood: .idle)
        }
        let left = max(1, Int(t.end.timeIntervalSinceNow.rounded(.up)))
        return BrainReply(text: Say.line(.focusLeft, ["time": DateParser.sayDuration(TimeInterval(left))]), mood: .idle)
    }
}
