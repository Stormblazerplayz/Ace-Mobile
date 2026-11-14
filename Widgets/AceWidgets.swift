import EventKit
import SwiftUI
import WidgetKit

@main
struct AceWidgetBundle: WidgetBundle {
    var body: some Widget {
        AceOrbWidget()
    }
}

struct AceEntry: TimelineEntry {
    let date: Date
    let mood: OrbMood
    let headline: String
    let nextTitle: String?
    let nextDate: Date?
    let nextAllDay: Bool
}

struct AceProvider: TimelineProvider {
    func placeholder(in context: Context) -> AceEntry {
        AceEntry(date: Date(), mood: .happy, headline: "Ace is here", nextTitle: "Soccer practice", nextDate: Date().addingTimeInterval(3600), nextAllDay: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (AceEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AceEntry>) -> Void) {
        let now = Date()
        // One entry every 15 minutes for the next 2 hours, then ask again.
        let entries = (0..<8).map { i in makeEntry(at: now.addingTimeInterval(Double(i) * 15 * 60)) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(2 * 3600))))
    }

    private func makeEntry(at date: Date) -> AceEntry {
        let hour = Calendar.current.component(.hour, from: date)
        let next = Self.nextEvent(after: date)
        let mood: OrbMood
        let headline: String
        if hour >= 22 || hour < 6 {
            mood = .sleeping
            headline = "Time to rest"
        } else if let n = next, !n.isAllDay, n.startDate.timeIntervalSince(date) < 30 * 60 {
            mood = .alert
            headline = "Coming up soon"
        } else {
            mood = hour < 12 ? .happy : .idle
            headline = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        }
        return AceEntry(date: date, mood: mood, headline: headline,
                        nextTitle: next?.title, nextDate: next?.startDate, nextAllDay: next?.isAllDay ?? false)
    }

    private static func nextEvent(after date: Date) -> EKEvent? {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return nil }
        let store = EKEventStore()
        let end = date.addingTimeInterval(24 * 3600)
        let predicate = store.predicateForEvents(withStart: date, end: end, calendars: nil)
        return store.events(matching: predicate)
            .filter { $0.endDate > date }
            .min { $0.startDate < $1.startDate }
    }
}

struct AceOrbWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AceOrb", provider: AceProvider()) { entry in
            AceWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
                .widgetURL(URL(string: "ace://talk"))
        }
        .configurationDisplayName("Ace")
        .description("Ace's orb and what's next on your calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct AceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AceEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                OrbStill(mood: entry.mood).padding(6)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Ace").font(.headline)
                Text(nextLine).font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Text("Ace: " + nextLine)
        case .systemMedium:
            HStack(spacing: 14) {
                OrbStill(mood: entry.mood)
                    .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.headline)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                    Text(nextLine)
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Link(destination: URL(string: "ace://check")!) {
                        Label("Check now", systemImage: "eye")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AceTheme.ace)
                    }
                }
                Spacer(minLength: 0)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                OrbStill(mood: entry.mood)
                    .frame(width: 58, height: 58)
                Spacer(minLength: 0)
                Text(entry.headline)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(1)
                Text(nextLine)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nextLine: String {
        guard let title = entry.nextTitle, let date = entry.nextDate else { return "Nothing coming up" }
        if entry.nextAllDay { return title + " today" }
        let time: String = date.formatted(date: .omitted, time: .shortened)
        return title + " at " + time
    }
}
