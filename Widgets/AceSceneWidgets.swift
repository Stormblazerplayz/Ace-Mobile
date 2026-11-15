import SwiftUI
import WidgetKit

/// Something a widget button asks Ace to do (opens Ace and runs it).
struct AceQuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let command: String
    let color: Color

    var url: URL {
        var c = URLComponents()
        c.scheme = "ace"
        c.host = "ask"
        c.queryItems = [URLQueryItem(name: "q", value: command)]
        return c.url ?? URL(string: "ace://talk")!
    }

    static let all: [AceQuickAction] = [
        AceQuickAction(id: "goodnight", title: "Goodnight", icon: "moon.stars.fill", command: "run the goodnight scene", color: Color(hex: 0x8F7CFF)),
        AceQuickAction(id: "movie", title: "Movie", icon: "popcorn.fill", command: "run the movie scene", color: Color(hex: 0xFF8A3D)),
        AceQuickAction(id: "morning", title: "Morning", icon: "sun.max.fill", command: "run the morning scene", color: Color(hex: 0xFFC83D)),
        AceQuickAction(id: "focus", title: "Focus", icon: "book.fill", command: "run the focus scene", color: Color(hex: 0x5BB6FF)),
        AceQuickAction(id: "party", title: "Party", icon: "party.popper.fill", command: "run the party scene", color: Color(hex: 0xFF5F8F)),
        AceQuickAction(id: "vacuum", title: "Vacuum", icon: "fan.fill", command: "start the vacuum", color: Color(hex: 0x3DF59A)),
    ]
}

private struct StaticEntry: TimelineEntry { let date: Date }

private struct StaticProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticEntry { StaticEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (StaticEntry) -> Void) { completion(StaticEntry(date: Date())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StaticEntry>) -> Void) {
        completion(Timeline(entries: [StaticEntry(date: Date())], policy: .never))
    }
}

/// Home Screen buttons for Ace's scenes and the vacuum.
struct AceScenesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AceScenes", provider: StaticProvider()) { _ in
            AceScenesView()
                .containerBackground(for: .widget) { Color("WidgetBackground") }
        }
        .configurationDisplayName("Ace Scenes")
        .description("One tap for Goodnight, Movie, Party, the vacuum and more.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct AceScenesView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                OrbStill(mood: .home).frame(width: 22, height: 22)
                Text("Ace Home")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AceTheme.fg)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(AceQuickAction.all) { action in
                    Link(destination: action.url) {
                        VStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.system(size: family == .systemLarge ? 26 : 18, weight: .semibold))
                            Text(action.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(action.color)
                        .frame(maxWidth: .infinity, minHeight: family == .systemLarge ? 92 : 44)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(action.color.opacity(0.16)))
                    }
                }
            }
            if family == .systemLarge { Spacer(minLength: 0) }
        }
    }
}

/// A Lock Screen button that runs Ace's goodnight scene.
struct AceGoodnightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AceGoodnight", provider: StaticProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "moon.stars.fill").font(.system(size: 20, weight: .semibold))
            }
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(AceQuickAction.all[0].url)
            .accessibilityLabel("Goodnight")
        }
        .configurationDisplayName("Goodnight")
        .description("Tap to run Ace's goodnight scene.")
        .supportedFamilies([.accessoryCircular])
    }
}

/// A Lock Screen button that starts the robot vacuum.
struct AceVacuumWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AceVacuum", provider: StaticProvider()) { _ in
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "fan.fill").font(.system(size: 20, weight: .semibold))
            }
            .containerBackground(for: .widget) { Color.clear }
            .widgetURL(AceQuickAction.all[5].url)
            .accessibilityLabel("Start the vacuum")
        }
        .configurationDisplayName("Start the Vacuum")
        .description("Tap to start your robot vacuum.")
        .supportedFamilies([.accessoryCircular])
    }
}
