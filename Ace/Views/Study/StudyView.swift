import SwiftUI

/// The Study screen: a colorful hero with today's goal and your streak, a quick review of
/// everything that's due, and a grid of decks (one per trivia topic, plus your own cards).
struct StudyView: View {
    @ObservedObject private var store = StudyStore.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var session: SessionPick?
    @State private var showMine = false

    /// Which deck to study, and whether it's a practice run.
    struct SessionPick: Identifiable {
        let deck: StudyDeck
        var practice = false
        var id: String { deck.name + (practice ? "-practice" : "") }
    }

    private let heroColors: [Color] = [AceTheme.accent, AceTheme.nova, AceTheme.pebble]

    var body: some View {
        NavigationStack {
            ZStack {
                StudyBackdrop(colors: [AceTheme.accent, AceTheme.ace, AceTheme.nova])
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        hero
                            .bounceReveal(shown)
                        actions
                            .bounceReveal(shown, order: 2)
                        Text("Decks")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(AceTheme.fg)
                            .padding(.top, 4)
                            .bounceReveal(shown, order: 3)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 16)], spacing: 16) {
                            ForEach(Array(store.decks.enumerated()), id: \.element.id) { i, deck in
                                Button {
                                    session = SessionPick(deck: deck)
                                } label: {
                                    DeckTile(deck: deck, stats: store.stats(for: deck))
                                }
                                .buttonStyle(BouncyButtonStyle(depth: 0.94))
                                .contextMenu {
                                    Button {
                                        session = SessionPick(deck: deck, practice: true)
                                    } label: {
                                        Label("Practice 20 cards", systemImage: "sparkles")
                                    }
                                    Button(role: .destructive) {
                                        withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) {
                                            store.reset(deck)
                                        }
                                    } label: {
                                        Label("Start this deck over", systemImage: "arrow.counterclockwise")
                                    }
                                }
                                .bounceReveal(shown, order: 4 + i)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 1000)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Study")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(AceTheme.ace)
        .preferredColorScheme(.dark)
        .onAppear { shown = true }
        .fullScreenCover(item: $session) { pick in
            StudySessionView(deck: pick.deck, store: store, practice: pick.practice)
        }
        .sheet(isPresented: $showMine) {
            MyCardsView(store: store)
        }
    }

    // MARK: Hero

    private var hero: some View {
        let streak = store.currentStreak()
        let today = store.reviewsToday()
        return HStack(spacing: 22) {
            ZStack {
                ProgressRing(progress: store.goalProgress(), colors: heroColors, lineWidth: 14)
                VStack(spacing: 0) {
                    Text("\(today)")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                    Text("of \(StudyStore.dailyGoal) today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
            }
            .frame(width: 132, height: 132)

            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle(today: today))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    HeroChip(symbol: "flame.fill", text: streak == 1 ? "1 day" : "\(streak) days", color: AceTheme.amber)
                        .boing(on: streak, scale: 1.2)
                    HeroChip(symbol: "star.fill", text: "\(store.masteredCount) mastered", color: AceTheme.pebble)
                    HeroChip(symbol: "clock.fill", text: "\(store.dueCount()) due", color: AceTheme.ace)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x2A1E6B), Color(hex: 0x5A1E5C), Color(hex: 0x6B3A12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .top, endPoint: .center))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: AceTheme.accent.opacity(0.35), radius: 24, y: 12)
        .accessibilityElement(children: .combine)
    }

    private func heroTitle(today: Int) -> String {
        if today >= StudyStore.dailyGoal { return "Goal done for today. Nice work!" }
        if today > 0 { return "\(StudyStore.dailyGoal - today) more to hit today's goal" }
        if store.dueCount() > 0 { return "Some cards are ready for a review" }
        return "Pick a deck and start flipping"
    }

    // MARK: Actions

    private var actions: some View {
        let review = store.reviewDeck()
        return HStack(spacing: 14) {
            Button {
                session = SessionPick(deck: review)
            } label: {
                ActionTile(symbol: review.symbol, title: "Quick review",
                           detail: review.cards.isEmpty ? "Nothing due right now" : "\(min(review.cards.count, StudyStore.sessionSize)) cards ready",
                           gradient: review.gradient)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.95))
            .disabled(review.cards.isEmpty)
            .opacity(review.cards.isEmpty ? 0.55 : 1)

            Button {
                showMine = true
            } label: {
                let style = StudyDeck.style(for: StudyDeck.myDeckName)
                ActionTile(symbol: "plus.rectangle.on.rectangle", title: "Make cards",
                           detail: store.myCards.isEmpty ? "Write your own" : "\(store.myCards.count) of yours",
                           gradient: LinearGradient(colors: style.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.95))
        }
    }
}

/// A small rounded chip in the hero: an icon and a few words.
struct HeroChip: View {
    let symbol: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .labelStyle(ChipLabelStyle(color: color))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.13), in: Capsule())
            .contentTransition(.numericText())
    }

    private struct ChipLabelStyle: LabelStyle {
        let color: Color
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 6) {
                configuration.icon.foregroundStyle(color)
                configuration.title
            }
        }
    }
}

/// A wide colorful button tile (Quick review, Make cards).
struct ActionTile: View {
    let symbol: String
    let title: String
    let detail: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
    }
}

/// A deck in the grid: its gradient, a big tilted icon, how much you've mastered and what's due.
struct DeckTile: View {
    let deck: StudyDeck
    let stats: DeckStats

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(deck.gradient)
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
            Image(systemName: deck.symbol)
                .font(.system(size: 110, weight: .bold))
                .foregroundStyle(.white.opacity(0.16))
                .rotationEffect(.degrees(-16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 18, y: 22)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Image(systemName: deck.symbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(deck.tint)
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    Spacer()
                    ZStack {
                        ProgressRing(progress: stats.progress, colors: [.white, .white.opacity(0.7)], lineWidth: 5)
                        Text("\(Int((stats.progress * 100).rounded()))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                }
                Spacer(minLength: 0)
                Text(deck.name)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                Text("\(stats.mastered) of \(stats.total) mastered")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                if stats.due > 0 {
                    Text("\(stats.due) due")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(deck.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white, in: Capsule())
                        .padding(.top, 2)
                }
            }
            .padding(18)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: deck.tint.opacity(0.45), radius: 16, y: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(deck.name) deck, \(stats.mastered) of \(stats.total) mastered, \(stats.due) due")
    }
}
