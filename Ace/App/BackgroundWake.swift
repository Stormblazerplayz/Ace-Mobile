import BackgroundTasks
import EventKit
import Foundation
import UIKit
import WidgetKit

/// While Ace isn't open, iPadOS lets it wake up now and then (iPadOS picks the exact time,
/// usually not more than every 15 minutes). Ace checks the battery and what's coming up,
/// and only sends a notification if something needs you.
enum BackgroundWake {
    static let id = "com.stormblazerplayz.ace.wake"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: id)
        request.earliestBeginDate = Date().addingTimeInterval(Double.random(in: 15 * 60...30 * 60))
        try? BGTaskScheduler.shared.submit(request)
    }

    static func run() async {
        schedule()
        guard SettingsStore.backgroundAlertsOn else { return }
        var notes: [String] = []

        let (level, state) = await MainActor.run { () -> (Float, UIDevice.BatteryState) in
            UIDevice.current.isBatteryMonitoringEnabled = true
            return (UIDevice.current.batteryLevel, UIDevice.current.batteryState)
        }
        if level >= 0, level <= 0.15, state == .unplugged {
            notes.append("Battery is at \(Int(level * 100))%.")
        }

        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            let store = EKEventStore()
            let now = Date()
            let predicate = store.predicateForEvents(withStart: now, end: now.addingTimeInterval(45 * 60), calendars: nil)
            if let next = store.events(matching: predicate).filter({ !$0.isAllDay && $0.startDate > now }).min(by: { $0.startDate < $1.startDate }) {
                let mins = max(1, Int(next.startDate.timeIntervalSince(now) / 60))
                let key = "bgEvent-" + (next.eventIdentifier ?? next.title ?? "")
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    notes.append("\(next.title ?? "An event") starts in \(mins) minutes.")
                }
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
        guard !notes.isEmpty else { return }
        await Notifier.postNow(id: "check-\(UUID().uuidString)", title: "Ace checked in", body: notes.joined(separator: " "))
    }
}
