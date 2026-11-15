import ActivityKit
import Foundation

/// Cooking timers from recipe steps ("Cookies baking", "Cooling"). Several can run at once.
/// Each one is also a notification with a sound, so it rings even when Ace is closed,
/// and a Live Activity where the device allows it.
@MainActor
final class KitchenTimers: ObservableObject {
    static let shared = KitchenTimers()

    struct Running: Identifiable, Codable, Equatable {
        var id = UUID()
        var label: String
        var end: Date
        var total: Int
        var done = false
        var activityID: String?

        var notificationID: String { "kitchen-\(id.uuidString)" }
    }

    @Published private(set) var timers: [Running] = []

    private let storeKey = "kitchenTimers"
    private var waits: [UUID: Task<Void, Never>] = [:]

    private init() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let saved = try? JSONDecoder().decode([Running].self, from: data) {
            timers = saved.filter { !$0.done || $0.end.timeIntervalSinceNow > -600 }
        }
        refresh()
    }

    /// Starts a timer. False when notifications are off (it still runs inside Ace).
    @discardableResult
    func start(label: String, seconds: Int) async -> Bool {
        var t = Running(label: label, end: Date().addingTimeInterval(TimeInterval(seconds)), total: seconds)
        let ok = await Notifier.schedule(id: t.notificationID, title: "\(label) timer is done", body: "Time's up! \(Self.clock(seconds)) went by.",
                                         at: t.end, category: "kitchen")
        t.activityID = startActivity(t)
        timers.append(t)
        save()
        wait(for: t)
        return ok
    }

    func cancel(_ id: UUID) {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return }
        let t = timers.remove(at: i)
        Notifier.cancel(t.notificationID)
        waits[id]?.cancel()
        waits[id] = nil
        endActivity(t, done: false)
        save()
    }

    /// Adds a minute to a timer (handy when the cookies need a bit longer).
    func addMinute(_ id: UUID) async {
        guard let i = timers.firstIndex(where: { $0.id == id }) else { return }
        var t = timers[i]
        let base = t.done ? Date() : t.end
        t.end = base.addingTimeInterval(60)
        t.total += 60
        t.done = false
        Notifier.cancel(t.notificationID)
        await Notifier.schedule(id: t.notificationID, title: "\(t.label) timer is done", body: "Time's up!", at: t.end, category: "kitchen")
        timers[i] = t
        updateActivity(t)
        save()
        wait(for: t)
    }

    /// Marks finished timers as done (call when Ace comes back to the front).
    func refresh() {
        for t in timers where !t.done {
            if t.end <= Date() { finish(t.id, ring: false) } else if waits[t.id] == nil { wait(for: t) }
        }
    }

    private func wait(for t: Running) {
        waits[t.id]?.cancel()
        waits[t.id] = Task { [weak self] in
            let left = t.end.timeIntervalSinceNow
            if left > 0 { try? await Task.sleep(nanoseconds: UInt64(left * 1_000_000_000)) }
            guard !Task.isCancelled else { return }
            self?.finish(t.id, ring: true)
        }
    }

    private func finish(_ id: UUID, ring: Bool) {
        guard let i = timers.firstIndex(where: { $0.id == id }), !timers[i].done else { return }
        timers[i].done = true
        waits[id] = nil
        endActivity(timers[i], done: true)
        save()
        if ring {
            // The notification plays its sound too. This makes sure you hear it inside Ace.
            SoundFX.shared.play(.alert, gain: 0.9)
            Haptics.shared.play(.alert)
        }
        // Clear a finished timer after 10 minutes.
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000_000)
            guard let self, let j = self.timers.firstIndex(where: { $0.id == id }), self.timers[j].done else { return }
            self.timers.remove(at: j)
            self.save()
        }
    }

    func dismiss(_ id: UUID) {
        timers.removeAll { $0.id == id && $0.done }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(timers) { UserDefaults.standard.set(data, forKey: storeKey) }
    }

    /// "12:00", "1:05:00"
    nonisolated static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    /// "12 min", "1 hr 15 min", "8 hr", "90 sec"
    nonisolated static func words(_ seconds: Int) -> String {
        if seconds < 120 && seconds % 60 != 0 { return "\(seconds) sec" }
        let h = seconds / 3600, m = (seconds % 3600 + 30) / 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }

    // MARK: Live Activities

    private func startActivity(_ t: Running) -> String? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        let attributes = KitchenTimerAttributes(label: t.label, total: t.total)
        let state = KitchenTimerAttributes.ContentState(end: t.end, done: false)
        let content = ActivityContent(state: state, staleDate: t.end.addingTimeInterval(60))
        return try? Activity.request(attributes: attributes, content: content, pushType: nil).id
    }

    private func updateActivity(_ t: Running) {
        guard let id = t.activityID, let a = Activity<KitchenTimerAttributes>.activities.first(where: { $0.id == id }) else { return }
        let state = KitchenTimerAttributes.ContentState(end: t.end, done: false)
        Task { await a.update(ActivityContent(state: state, staleDate: t.end.addingTimeInterval(60))) }
    }

    private func endActivity(_ t: Running, done: Bool) {
        guard let id = t.activityID, let a = Activity<KitchenTimerAttributes>.activities.first(where: { $0.id == id }) else { return }
        let state = KitchenTimerAttributes.ContentState(end: t.end, done: done)
        Task {
            await a.end(ActivityContent(state: state, staleDate: nil),
                        dismissalPolicy: done ? .after(Date().addingTimeInterval(15 * 60)) : .immediate)
        }
    }
}
