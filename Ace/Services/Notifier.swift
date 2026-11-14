import Foundation
import UserNotifications

/// Ace's own notifications: timers, reminders and background heads-ups.
/// (iPadOS only lets an app see its own notifications, not other apps'.)
enum Notifier {
    static var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    @discardableResult
    static func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    /// Schedules a notification. Returns false if permission is off.
    @discardableResult
    static func schedule(id: String, title: String, body: String, at date: Date, category: String = "ace") async -> Bool {
        guard await requestPermission() else { return false }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        content.threadIdentifier = category
        let seconds = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    /// Posts a heads-up right away (used by the background check).
    static func postNow(id: String, title: String, body: String) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "check"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        try? await center.add(request)
    }

    static func cancel(_ id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    struct Pending {
        var id: String
        var title: String
        var body: String
        var fireDate: Date?
    }

    static func pending() async -> [Pending] {
        let requests = await center.pendingNotificationRequests()
        return requests.map { r in
            let date = (r.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                ?? (r.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            return Pending(id: r.identifier, title: r.content.title, body: r.content.body, fireDate: date)
        }
    }

    /// Ace's own notifications still sitting in Notification Center.
    static func delivered() async -> [Pending] {
        let list = await center.deliveredNotifications()
        return list.map { n in
            Pending(id: n.request.identifier, title: n.request.content.title, body: n.request.content.body, fireDate: n.date)
        }
    }

    static func clearDelivered() {
        center.removeAllDeliveredNotifications()
    }
}
