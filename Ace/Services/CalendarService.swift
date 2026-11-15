import EventKit
import Foundation
import UIKit

/// The Nimbus calendar and reminders, through Apple's EventKit.
/// Ace makes a calendar called "Nimbus" before it adds anything, and only changes
/// events after the user taps Yes on a confirm card.
@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    let store = EKEventStore()
    static let calendarName = "Nimbus"

    @Published private(set) var eventAccess = false
    @Published private(set) var reminderAccess = false

    struct ReminderInfo: Identifiable {
        var id: String
        var title: String
        var due: Date?
    }

    enum CalendarError: LocalizedError {
        case noAccess, noCalendar, notFound
        var errorDescription: String? {
            switch self {
            case .noAccess: return "I don't have permission to use your calendar. You can turn it on in Settings > Privacy > Calendars."
            case .noCalendar: return "I couldn't make the Nimbus calendar."
            case .notFound: return "I couldn't find that event anymore."
            }
        }
    }

    private init() {
        refreshStatus()
    }

    func refreshStatus() {
        eventAccess = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        reminderAccess = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }

    @discardableResult
    func requestEventAccess() async -> Bool {
        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            eventAccess = true
            return true
        }
        let ok = (try? await store.requestFullAccessToEvents()) ?? false
        eventAccess = ok
        if ok { _ = nimbusCalendar() }
        return ok
    }

    @discardableResult
    func requestReminderAccess() async -> Bool {
        if EKEventStore.authorizationStatus(for: .reminder) == .fullAccess {
            reminderAccess = true
            return true
        }
        let ok = (try? await store.requestFullAccessToReminders()) ?? false
        reminderAccess = ok
        return ok
    }

    // MARK: Nimbus calendar

    /// Finds the Nimbus calendar, or makes it if it isn't there yet.
    func nimbusCalendar() -> EKCalendar? {
        guard eventAccess else { return nil }
        if let id = UserDefaults.standard.string(forKey: "nimbusCalendarID"),
           let cal = store.calendar(withIdentifier: id), cal.allowsContentModifications {
            return cal
        }
        if let cal = store.calendars(for: .event).first(where: { $0.title == Self.calendarName && $0.allowsContentModifications }) {
            UserDefaults.standard.set(cal.calendarIdentifier, forKey: "nimbusCalendarID")
            return cal
        }
        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title = Self.calendarName
        cal.cgColor = UIColor(red: 0.36, green: 0.71, blue: 1.0, alpha: 1).cgColor
        for source in candidateSources(for: .event) {
            cal.source = source
            do {
                try store.saveCalendar(cal, commit: true)
                UserDefaults.standard.set(cal.calendarIdentifier, forKey: "nimbusCalendarID")
                return cal
            } catch {
                continue
            }
        }
        return nil
    }

    private func candidateSources(for type: EKEntityType) -> [EKSource] {
        var out: [EKSource] = []
        if type == .event, let s = store.defaultCalendarForNewEvents?.source { out.append(s) }
        if type == .reminder, let s = store.defaultCalendarForNewReminders()?.source { out.append(s) }
        out += store.sources.filter { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") }
        out += store.sources.filter { $0.sourceType == .local }
        out += store.sources.filter { $0.sourceType == .calDAV || $0.sourceType == .exchange }
        var seen = Set<String>()
        return out.filter { seen.insert($0.sourceIdentifier).inserted }
    }

    // MARK: Events

    func events(from start: Date, to end: Date, nimbusOnly: Bool) -> [EventItem] {
        guard eventAccess else { return [] }
        var calendars: [EKCalendar]?
        if nimbusOnly {
            guard let cal = nimbusCalendar() else { return [] }
            calendars = [cal]
        }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map(Self.item)
    }

    static func item(_ e: EKEvent) -> EventItem {
        EventItem(
            id: e.eventIdentifier ?? UUID().uuidString,
            title: e.title ?? "Untitled",
            start: e.startDate,
            end: e.endDate,
            allDay: e.isAllDay,
            calendar: e.calendar?.title ?? ""
        )
    }

    /// Events whose title matches the words, closest in time first.
    func find(_ text: String, near date: Date?) -> [EventItem] {
        guard eventAccess else { return [] }
        let center = date ?? Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: center) ?? center
        let end = Calendar.current.date(byAdding: .day, value: 120, to: center) ?? center
        let words = text.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 }
        let all = events(from: start, to: end, nimbusOnly: false)
        let scored = all.compactMap { e -> (EventItem, Int)? in
            let t = e.title.lowercased()
            let hits = words.filter { t.contains($0) }.count
            if hits == 0 && !words.isEmpty { return nil }
            return (e, hits)
        }
        return scored
            .sorted { a, b in
                if a.1 != b.1 { return a.1 > b.1 }
                return abs(a.0.start.timeIntervalSince(center)) < abs(b.0.start.timeIntervalSince(center))
            }
            .map { $0.0 }
    }

    func apply(_ draft: EventDraft) throws -> String {
        guard eventAccess else { throw CalendarError.noAccess }
        switch draft.action {
        case .add:
            guard let cal = nimbusCalendar() else { throw CalendarError.noCalendar }
            let e = EKEvent(eventStore: store)
            e.calendar = cal
            fill(e, from: draft)
            try store.save(e, span: .thisEvent, commit: true)
            return "Added \"\(draft.title)\" to your Nimbus calendar."
        case .edit:
            guard let id = draft.eventID, let e = store.event(withIdentifier: id) else { throw CalendarError.notFound }
            fill(e, from: draft)
            try store.save(e, span: .thisEvent, commit: true)
            return "Updated \"\(draft.title)\"."
        case .delete:
            guard let id = draft.eventID, let e = store.event(withIdentifier: id) else { throw CalendarError.notFound }
            try store.remove(e, span: .thisEvent, commit: true)
            return "Deleted \"\(draft.title)\"."
        }
    }

    private func fill(_ e: EKEvent, from d: EventDraft) {
        e.title = d.title
        e.startDate = d.start
        e.endDate = max(d.end, d.start.addingTimeInterval(d.allDay ? 0 : 60))
        e.isAllDay = d.allDay
        if let n = d.notes { e.notes = n }
        if !d.allDay, e.alarms?.isEmpty ?? true {
            e.addAlarm(EKAlarm(relativeOffset: -10 * 60))
        }
    }

    /// Adds or updates an event that came from Nimbus on the PC. Returns the local id.
    func upsertSynced(id: String?, title: String, start: Date, end: Date, allDay: Bool) -> String? {
        guard eventAccess, let cal = nimbusCalendar() else { return nil }
        let e = id.flatMap { store.event(withIdentifier: $0) } ?? EKEvent(eventStore: store)
        if e.calendar == nil { e.calendar = cal }
        e.title = title
        e.startDate = start
        e.endDate = end
        e.isAllDay = allDay
        do {
            try store.save(e, span: .thisEvent, commit: true)
            return e.eventIdentifier
        } catch {
            return nil
        }
    }

    func removeSynced(id: String) {
        guard eventAccess, let e = store.event(withIdentifier: id) else { return }
        try? store.remove(e, span: .thisEvent, commit: true)
    }

    // MARK: Reminders

    private func nimbusReminderList() -> EKCalendar? {
        guard reminderAccess else { return nil }
        if let cal = store.calendars(for: .reminder).first(where: { $0.title == Self.calendarName && $0.allowsContentModifications }) {
            return cal
        }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = Self.calendarName
        cal.cgColor = UIColor(red: 0.36, green: 0.71, blue: 1.0, alpha: 1).cgColor
        for source in candidateSources(for: .reminder) {
            cal.source = source
            if (try? store.saveCalendar(cal, commit: true)) != nil { return cal }
        }
        return store.defaultCalendarForNewReminders()
    }

    /// Adds a reminder to the Reminders app's Nimbus list, with an alert at `due`.
    func addReminder(_ title: String, due: Date?) -> Bool {
        guard let list = nimbusReminderList() else { return false }
        let r = EKReminder(eventStore: store)
        r.calendar = list
        r.title = title
        if let due {
            r.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
            r.addAlarm(EKAlarm(absoluteDate: due))
        }
        return (try? store.save(r, commit: true)) != nil
    }

    // MARK: Shopping list

    /// The "Shopping" list in Reminders (made the first time it's needed).
    private func shoppingList() -> EKCalendar? {
        guard reminderAccess else { return nil }
        let lists = store.calendars(for: .reminder).filter { $0.allowsContentModifications }
        if let list = lists.first(where: { $0.title.lowercased() == ShoppingList.name.lowercased() })
            ?? lists.first(where: { ["groceries", "grocery", "grocery list", "shopping list"].contains($0.title.lowercased()) }) {
            return list
        }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = ShoppingList.name
        cal.cgColor = UIColor(red: 0.35, green: 0.8, blue: 0.45, alpha: 1).cgColor
        for source in candidateSources(for: .reminder) {
            cal.source = source
            if (try? store.saveCalendar(cal, commit: true)) != nil { return cal }
        }
        return nil
    }

    /// What's still to buy on the Shopping list. Nil when Reminders can't be used.
    func shoppingItems() async -> [String]? {
        guard let list = shoppingList() else { return nil }
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [list])
        return await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { reminders in
                let titles = (reminders ?? []).compactMap { $0.title }.filter { !$0.isEmpty }
                cont.resume(returning: titles)
            }
        }
    }

    /// Adds things to the Shopping list, skipping ones already on it.
    func addToShopping(_ items: [String]) async -> (added: [String], skipped: [String])? {
        guard let list = shoppingList(), let have = await shoppingItems() else { return nil }
        let split = ShoppingList.split(items, existing: have)
        var added: [String] = []
        for item in split.new {
            let r = EKReminder(eventStore: store)
            r.calendar = list
            r.title = item
            if (try? store.save(r, commit: false)) != nil { added.append(item) }
        }
        if !added.isEmpty, (try? store.commit()) == nil { return nil }
        return (added, split.skipped)
    }

    /// Reminders that aren't done and are due before `date` (or have no date).
    func openReminders(dueBefore date: Date) async -> [ReminderInfo] {
        guard reminderAccess else { return [] }
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: date, calendars: nil)
        return await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { reminders in
                let list = (reminders ?? []).map { r in
                    ReminderInfo(id: r.calendarItemIdentifier, title: r.title ?? "Reminder", due: r.dueDateComponents.flatMap { Calendar.current.date(from: $0) })
                }
                cont.resume(returning: list)
            }
        }
    }
}
