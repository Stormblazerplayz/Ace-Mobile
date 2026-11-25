import SwiftUI

/// Everything Ace can open, in one place. The top row only has room for a few buttons,
/// so the Apps button opens this grid instead of squeezing an icon in for every screen.
enum AceApp: String, CaseIterable, Identifiable {
    case studyCards, flashcards, games, piano, space, graphs, typing, codes
    case converter, countdowns, clocks, sketchbook, habits, journal, breathe, decide, savings, lists

    var id: String { rawValue }

    var title: String {
        switch self {
        case .studyCards: return "Study cards"
        case .flashcards: return "Flashcards"
        case .games: return "Ace Games"
        case .piano: return "Ace Piano"
        case .space: return "Ace Space"
        case .graphs: return "Ace Graphs"
        case .typing: return "Ace Typing"
        case .codes: return "Secret codes"
        case .converter: return "Converter"
        case .countdowns: return "Countdowns"
        case .clocks: return "World clocks"
        case .sketchbook: return "Sketchbook"
        case .habits: return "Habits"
        case .journal: return "Mood journal"
        case .breathe: return "Ace Breathe"
        case .decide: return "Pick for me"
        case .savings: return "Savings jars"
        case .lists: return "Lists"
        }
    }

    var symbol: String {
        switch self {
        case .studyCards: return "rectangle.on.rectangle.angled"
        case .flashcards: return "rectangle.stack.fill"
        case .games: return "gamecontroller.fill"
        case .piano: return "pianokeys"
        case .space: return "globe.americas.fill"
        case .graphs: return "function"
        case .typing: return "keyboard"
        case .codes: return "key.fill"
        case .converter: return "ruler.fill"
        case .countdowns: return "hourglass"
        case .clocks: return "clock.fill"
        case .sketchbook: return "scribble.variable"
        case .habits: return "drop.circle"
        case .journal: return "book.closed.fill"
        case .breathe: return "wind"
        case .decide: return "dice"
        case .savings: return "dollarsign.circle"
        case .lists: return "checklist"
        }
    }

    /// The tile's color.
    var tint: Color {
        switch self {
        case .studyCards, .flashcards, .typing, .graphs: return AceTheme.ace
        case .games, .decide, .codes: return AceTheme.nova
        case .piano, .sketchbook, .journal: return AceTheme.accent
        case .space, .clocks, .breathe: return AceTheme.good
        case .converter, .countdowns, .savings: return AceTheme.amber
        case .habits, .lists: return AceTheme.pebble
        }
    }
}

/// The Apps grid: tap a tile and its screen opens.
struct AceAppsView: View {
    let open: (AceApp) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @State private var shown = false

    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 140), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(AceApp.allCases.enumerated()), id: \.element) { index, app in
                        Button { open(app) } label: { tile(app) }
                            .buttonStyle(BouncyButtonStyle(depth: 0.9))
                            .accessibilityLabel(app.title)
                            .accessibilityIdentifier("app-\(app.rawValue)")
                            .opacity(shown ? 1 : 0)
                            .scaleEffect(shown ? 1 : 0.8)
                            .animation(appear(index), value: shown)
                    }
                }
                .padding(20)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Ace apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .onAppear { shown = true }
    }

    /// Tiles pop in one after another (all at once with Reduce Motion or the bounce off).
    private func appear(_ index: Int) -> Animation? {
        guard AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) else { return nil }
        return .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.02)
    }

    private func tile(_ app: AceApp) -> some View {
        VStack(spacing: 10) {
            Image(systemName: app.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(app.tint)
                .frame(width: 58, height: 58)
                .background(Circle().fill(app.tint.opacity(0.16)))
            Text(app.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AceTheme.fg)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 124)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AceTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
    }
}
