import SwiftUI

/// The Ace Games screen: a tile for each game, your wins, and your best streak.
/// Tapping a tile closes the screen and starts the game in the chat, where you can
/// play by tapping or by talking.
struct GamesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var core: AceCore
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Turns true when the screen opens, so the tiles cascade in.
    @State private var shown = false
    @State private var scores: [ArcadeGame: GameStats.Score] = [:]
    @State private var totalWins = 0
    @State private var totalPlayed = 0
    @State private var bestStreak = 0
    @State private var askReset = false

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsHeader
                        .bounceReveal(shown, order: 0)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(ArcadeGame.allCases.enumerated()), id: \.element) { i, game in
                            GameTile(game: game, score: scores[game] ?? GameStats.Score(), index: i, disabled: core.busy) {
                                play(game)
                            }
                            .bounceReveal(shown, order: i + 1)
                        }
                    }
                    Text("You can play by voice too. Say \"Play hangman\" or \"Let's play tic-tac-toe on hard\", and say \"Stop the game\" to quit.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                        .bounceReveal(shown, order: ArcadeGame.allCases.count + 1)
                    if totalPlayed > 0 {
                        Button(role: .destructive) {
                            askReset = true
                        } label: {
                            Label("Reset scores", systemImage: "arrow.counterclockwise")
                                .font(.footnote)
                        }
                        .buttonStyle(.aceBouncy)
                        .bounceReveal(shown, order: ArcadeGame.allCases.count + 2)
                    }
                }
                .padding(16)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .background(ArcadeBackground().ignoresSafeArea())
            .navigationTitle("Ace Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset all game scores?", isPresented: $askReset, titleVisibility: .visible) {
                Button("Reset scores", role: .destructive) {
                    core.brain.gameStats.clearAll()
                    Haptics.shared.play(.pop)
                    refresh()
                }
            } message: {
                Text("Wins, losses and streaks go back to zero. Trivia's own high score stays.")
            }
            .onAppear {
                refresh()
                shown = true
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }

    private var statsHeader: some View {
        HStack(spacing: 12) {
            stat("\(totalWins)", label: totalWins == 1 ? "win" : "wins", icon: "trophy.fill", tint: AceTheme.pebble)
            stat("\(totalPlayed)", label: totalPlayed == 1 ? "game played" : "games played", icon: "gamecontroller.fill", tint: AceTheme.ace)
            stat("\(bestStreak)", label: "best streak", icon: "flame.fill", tint: AceTheme.nova)
        }
    }

    private func stat(_ value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.6), radius: 8)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(AceTheme.fg)
                .contentTransition(.numericText())
                .boing(on: value)
            Text(label)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .aceCard()
        .accessibilityElement(children: .combine)
    }

    private func refresh() {
        let stats = core.brain.gameStats
        withAnimation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion)) {
            scores = Dictionary(uniqueKeysWithValues: ArcadeGame.allCases.map { ($0, stats.score($0)) })
            totalWins = stats.totalWins
            totalPlayed = stats.totalPlayed
            bestStreak = stats.bestStreak
        }
    }

    /// Closes the screen, then asks for the game in the chat, the same as typing it.
    private func play(_ game: ArcadeGame) {
        guard !core.busy else { return }
        Haptics.shared.play(.pop)
        dismiss()
        let ask = game.ask
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            core.send(ask)
        }
    }
}

/// A game's tile: a glowing gradient, a bobbing icon, and your record.
/// The more you've won, the brighter the glow.
struct GameTile: View {
    let game: ArcadeGame
    let score: GameStats.Score
    let index: Int
    let disabled: Bool
    let action: () -> Void
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bob = false

    /// 0 with no wins, up to 1 at 10 wins or more.
    private var glow: Double { min(1, Double(score.wins) / 10) }

    var body: some View {
        let colors = game.colors
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 52, height: 52)
                            .shadow(color: (colors.first ?? AceTheme.ace).opacity(0.35 + 0.45 * glow), radius: 6 + 12 * glow)
                        Image(systemName: game.symbol)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(y: bob && moving ? -5 : 0)
                    .rotationEffect(.degrees(moving ? (bob ? 4 : -4) : 0))
                    Spacer()
                    if score.streak >= 2 {
                        Label("\(score.streak)", systemImage: "flame.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AceTheme.nova.opacity(0.2)))
                            .foregroundStyle(AceTheme.nova)
                            .accessibilityLabel("\(score.streak) wins in a row")
                    }
                }
                Text(game.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(AceTheme.fg)
                Text(game.blurb)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    Label(score.played == 0 ? "New" : "\(score.wins) won", systemImage: score.played == 0 ? "sparkles" : "trophy.fill")
                        .foregroundStyle(score.wins > 0 ? AceTheme.pebble : AceTheme.muted)
                    if score.played > 0 {
                        Text("\(score.played) played")
                            .foregroundStyle(AceTheme.muted)
                    }
                    if let best = score.best, game == .numberGuess || game == .hangman {
                        Text(game == .numberGuess ? "Best: \(best) " + (best == 1 ? "guess" : "guesses") : "Best: \(best) " + (best == 1 ? "miss" : "misses"))
                            .foregroundStyle(AceTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "play.fill")
                        .foregroundStyle(colors.first ?? AceTheme.ace)
                }
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: colors.map { $0.opacity(0.16 + 0.1 * glow) } + [AceTheme.card],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LinearGradient(colors: colors.map { $0.opacity(0.35 + 0.5 * glow) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5)
            )
            .shadow(color: (colors.first ?? AceTheme.ace).opacity(0.12 + 0.3 * glow), radius: 10 + 10 * glow)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.95))
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
        .accessibilityLabel("\(game.title). \(game.blurb) \(score.wins) won.")
        .accessibilityHint("Starts the game in the chat")
        .onAppear {
            guard moving else { return }
            // Each tile bobs on its own beat so the grid feels alive.
            withAnimation(.easeInOut(duration: 1.4 + Double(index % 3) * 0.25).repeatForever(autoreverses: true).delay(Double(index) * 0.12)) {
                bob = true
            }
        }
    }
}

/// A dark arcade backdrop with soft colored lights.
struct ArcadeBackground: View {
    var body: some View {
        ZStack {
            AceTheme.background
            RadialGradient(colors: [AceTheme.accent.opacity(0.22), .clear], center: .topLeading, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [AceTheme.nova.opacity(0.14), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 460)
        }
        .accessibilityHidden(true)
    }
}
