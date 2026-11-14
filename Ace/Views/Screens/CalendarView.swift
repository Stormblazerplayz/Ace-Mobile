import SwiftUI
import WidgetKit

/// The Nimbus calendar screen. Add, change, or delete events. Every change asks first.
struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var calendar = CalendarService.shared
    @State private var events: [EventItem] = []
    @State private var allCalendars = false
    @State private var editing: EventDraft?
    @State private var deleting: EventItem?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Group {
                if !calendar.eventAccess {
                    accessPrompt
                } else {
                    list
                }
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Nimbus calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if calendar.eventAccess {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            let start = Self.nextHour()
                            editing = EventDraft(action: .add, title: "", start: start, end: start.addingTimeInterval(3600))
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add event")
                    }
                }
            }
            .sheet(item: $editing) { draft in
                EventEditor(draft: draft) { saved in
                    save(saved)
                }
            }
            .alert("Delete this event?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting) { e in
                Button("Delete", role: .destructive) {
                    let d = EventDraft(action: .delete, title: e.title, start: e.start, end: e.end, allDay: e.allDay, eventID: e.id)
                    save(d)
                }
                Button("Cancel", role: .cancel) {}
            } message: { e in
                Text("\"\(e.title)\" will be removed from \(e.calendar.isEmpty ? "your calendar" : e.calendar).")
            }
            .onAppear(perform: reload)
            .onChange(of: allCalendars) { _, _ in reload() }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }

    private var accessPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(AceTheme.ace)
            Text("Ace needs your calendar")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AceTheme.fg)
            Text("Ace makes a calendar called Nimbus and only adds or changes events after you say yes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(AceTheme.muted)
                .padding(.horizontal, 30)
            Button("Allow calendar") {
                Task {
                    if await calendar.requestEventAccess() { reload() }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            Section {
                Toggle("Show all my calendars", isOn: $allCalendars)
            }
            if let message {
                Section {
                    Text(message).foregroundStyle(AceTheme.muted)
                }
            }
            if events.isEmpty {
                Section {
                    Text("Nothing in the next 30 days. Tap + or ask Ace to add something.")
                        .foregroundStyle(AceTheme.muted)
                }
            }
            ForEach(groupedDays) { group in
                Section(group.day.formatted(.dateTime.weekday(.wide).month().day())) {
                    ForEach(group.items) { e in
                        Button {
                            editing = EventDraft(action: .edit, title: e.title, start: e.start, end: e.end, allDay: e.allDay, eventID: e.id)
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(e.calendar == CalendarService.calendarName ? AceTheme.ace : AceTheme.accent)
                                    .frame(width: 4, height: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.title).foregroundStyle(AceTheme.fg)
                                    Text(Self.timeText(e)).font(.caption).foregroundStyle(AceTheme.muted)
                                }
                                Spacer()
                                if allCalendars {
                                    Text(e.calendar).font(.caption2).foregroundStyle(AceTheme.muted)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { deleting = e } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable { reload() }
    }

    private struct DayGroup: Identifiable {
        var day: Date
        var items: [EventItem]
        var id: Date { day }
    }

    private var groupedDays: [DayGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: events) { cal.startOfDay(for: $0.start) }
        return groups.keys.sorted().map { DayGroup(day: $0, items: groups[$0] ?? []) }
    }

    private func reload() {
        calendar.refreshStatus()
        guard calendar.eventAccess else { events = []; return }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 30, to: start) ?? now
        events = calendar.events(from: start, to: end, nimbusOnly: !allCalendars)
    }

    private func save(_ draft: EventDraft) {
        do {
            message = try calendar.apply(draft)
            SoundFX.shared.play(.success, gain: 0.6)
            Haptics.shared.play(.success)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            message = error.localizedDescription
            SoundFX.shared.play(.alert, gain: 0.7)
        }
        reload()
    }

    static func timeText(_ e: EventItem) -> String {
        if e.allDay { return "All day" }
        let a: String = e.start.formatted(date: .omitted, time: .shortened)
        let b: String = e.end.formatted(date: .omitted, time: .shortened)
        return a + " – " + b
    }

    static func nextHour() -> Date {
        let cal = Calendar.current
        let now = Date()
        let hour = cal.dateInterval(of: .hour, for: now)?.start ?? now
        return hour.addingTimeInterval(3600)
    }
}

/// Add or change one event. Saving shows a "Are you sure?" first.
struct EventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: EventDraft
    var onSave: (EventDraft) -> Void
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draft.title)
                    Toggle("All day", isOn: $draft.allDay)
                    DatePicker("Starts", selection: $draft.start, displayedComponents: draft.allDay ? [.date] : [.date, .hourAndMinute])
                    DatePicker("Ends", selection: $draft.end, in: draft.start..., displayedComponents: draft.allDay ? [.date] : [.date, .hourAndMinute])
                }
                Section("Notes") {
                    TextField("Notes", text: Binding(get: { draft.notes ?? "" }, set: { draft.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(draft.action == .add ? "New event" : "Edit event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { confirming = true }
                        .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: draft.start) { old, new in
                // Keep the same length when the start moves.
                let length = max(draft.end.timeIntervalSince(old), 0)
                draft.end = new.addingTimeInterval(length)
            }
            .confirmationDialog(draft.action == .add ? "Add this to your Nimbus calendar?" : "Save these changes?",
                                isPresented: $confirming, titleVisibility: .visible) {
                Button(draft.action == .add ? "Yes, add it" : "Yes, save") {
                    var d = draft
                    d.title = d.title.trimmingCharacters(in: .whitespaces)
                    onSave(d)
                    dismiss()
                }
                Button("No", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }
}
