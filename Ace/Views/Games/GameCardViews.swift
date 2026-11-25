import SwiftUI
import UIKit

// MARK: Win and lose effects

/// Finished games that already celebrated, so scrolling back up doesn't replay the confetti.
@MainActor
enum GameFX {
    static var celebrated: Set<UUID> = []
}

extension GameOutcome {
    /// The glow color for a finished game.
    var tint: Color {
        switch self {
        case .won: return AceTheme.good
        case .lost: return AceTheme.bad
        case .draw: return AceTheme.amber
        case .playing: return AceTheme.ace
        }
    }

    var badge: (text: String, symbol: String)? {
        switch self {
        case .won: return ("You win!", "trophy.fill")
        case .lost: return ("Ace wins", "flag.checkered")
        case .draw: return ("Draw", "equal.circle.fill")
        case .playing: return nil
        }
    }
}

/// A side-to-side wobble for a lost game. `amount` goes from 0 to 1 and ends where it started.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(amount * .pi * 6), y: 0))
    }
}

/// Confetti bursting out from the middle of a card when you win.
struct ConfettiBurst: View {
    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let dx: CGFloat
        let dy: CGFloat
        let spin: Double
        let size: CGSize
        let delay: Double
    }

    @State private var pieces: [Piece] = ConfettiBurst.make()
    @State private var fired = false

    static func make(count: Int = 34) -> [Piece] {
        let colors = [AceTheme.ace, AceTheme.nova, AceTheme.pebble, AceTheme.good, AceTheme.accent, AceTheme.amber]
        return (0..<count).map { _ in
            Piece(color: colors.randomElement() ?? AceTheme.ace,
                  dx: CGFloat.random(in: -170...170),
                  dy: CGFloat.random(in: -150...90),
                  spin: Double.random(in: -540...540),
                  size: CGSize(width: CGFloat.random(in: 5...9), height: CGFloat.random(in: 8...14)),
                  delay: Double.random(in: 0...0.12))
        }
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size.width, height: p.size.height)
                    .rotationEffect(.degrees(fired ? p.spin : 0))
                    .offset(x: fired ? p.dx : 0, y: fired ? p.dy : 0)
                    .opacity(fired ? 0 : 1)
                    .animation(.easeOut(duration: 1.3).delay(p.delay), value: fired)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { fired = true }
    }
}

/// The score glow around a game card, plus confetti for a win and a shake for a loss.
/// With Bouncy animations off there's just the glow, and Reduce Motion keeps it all still.
struct GameGlow: ViewModifier {
    let outcome: GameOutcome
    /// The chat message, so each finished game celebrates once.
    let key: UUID
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confetti = false
    @State private var shake: CGFloat = 0
    @State private var pulse = false

    func body(content: Content) -> some View {
        let done = outcome != .playing
        content
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(outcome.tint.opacity(done ? 0.85 : 0), lineWidth: 2)
            )
            .shadow(color: outcome.tint.opacity(done ? (pulse ? 0.7 : 0.35) : 0), radius: pulse ? 20 : 9)
            .modifier(ShakeEffect(amount: shake))
            .overlay {
                if confetti { ConfettiBurst() }
            }
            .onAppear(perform: celebrate)
    }

    private func celebrate() {
        guard outcome != .playing, !GameFX.celebrated.contains(key) else { return }
        GameFX.celebrated.insert(key)
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        switch outcome {
        case .won:
            Haptics.shared.play(.success)
            if moving { confetti = true }
        case .lost:
            Haptics.shared.play(.alert)
            if moving { withAnimation(.linear(duration: 0.55)) { shake = 1 } }
        default:
            Haptics.shared.play(.pop)
        }
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) { pulse = true }
    }
}

extension View {
    /// The win or lose glow (and confetti or a shake) for a game card.
    func gameGlow(_ outcome: GameOutcome, key: UUID) -> some View {
        modifier(GameGlow(outcome: outcome, key: key))
    }
}

/// "You win!", "Ace wins" or "Draw" at the bottom of a finished game.
struct GameResultBadge: View {
    let outcome: GameOutcome

    var body: some View {
        if let b = outcome.badge {
            Label(b.text, systemImage: b.symbol)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(outcome.tint.opacity(0.2)))
                .overlay(Capsule().stroke(outcome.tint.opacity(0.6), lineWidth: 1))
                .foregroundStyle(outcome.tint)
                .boing(on: outcome)
        }
    }
}

/// The small title row on every game card.
struct GameCardTitle: View {
    let game: ArcadeGame
    var detail: String?
    var trailing: String?

    var body: some View {
        HStack(spacing: 6) {
            Label(game.title, systemImage: game.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(game.colors.first ?? AceTheme.ace)
            if let detail {
                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AceTheme.soft))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 4)
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                    .contentTransition(.numericText())
            }
        }
    }
}

// MARK: Tic-tac-toe

/// The X and O marks, drawn on with a stroke.
struct XShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct TicTacToeMark: View {
    let mark: String
    let tint: Color
    @State private var progress: CGFloat

    init(mark: String, tint: Color, drawIn: Bool) {
        self.mark = mark
        self.tint = tint
        _progress = State(initialValue: drawIn ? 0 : 1)
    }

    var body: some View {
        Group {
            if mark == "X" {
                XShape()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
            } else if mark == "O" {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(18)
        .shadow(color: tint.opacity(0.6), radius: 6)
        .onAppear {
            guard progress < 1 else { return }
            // AceMotion.now is nil with Reduce Motion on, so the mark is simply there.
            withAnimation(AceMotion.now(.gentle) == nil ? nil : .easeOut(duration: 0.4).delay(0.15)) { progress = 1 }
        }
    }
}

struct TicTacToeCardView: View {
    let card: TicTacToeCard
    let messageID: UUID
    @EnvironmentObject var core: AceCore
    @State private var tapped: Int?

    private var live: Bool { tapped == nil && card.outcome == .playing && core.brain.gameToken == card.token }
    private var you: Color { AceTheme.ace }
    private var ace: Color { AceTheme.nova }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameCardTitle(game: .ticTacToe, detail: card.level == "normal" ? nil : card.level.capitalized,
                          trailing: "\(card.wins) W · \(card.losses) L · \(card.draws) D")
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { col in
                            square(row * 3 + col)
                        }
                    }
                }
            }
            .frame(maxWidth: 300)
            .frame(maxWidth: .infinity)
            HStack {
                if card.outcome == .playing {
                    Label(live ? "Your turn: you're X" : "Waiting", systemImage: live ? "hand.tap.fill" : "hourglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(live ? AceTheme.fg : AceTheme.muted)
                } else {
                    GameResultBadge(outcome: card.outcome)
                }
                Spacer()
            }
        }
        .aceCard()
        .gameGlow(card.outcome, key: messageID)
    }

    private func square(_ i: Int) -> some View {
        let mark = card.board[i].isEmpty && tapped == i ? card.you : card.board[i]
        let inLine = card.winLine?.contains(i) == true
        let open = card.board[i].isEmpty && live
        return Button {
            guard open else { return }
            tapped = i
            Haptics.shared.play(.tick)
            core.send(TextKit.capitalizeFirst(TicTacToe.names[i]))
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(inLine ? card.outcome.tint.opacity(0.32) : AceTheme.ace.opacity(open ? 0.1 : 0.06))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(inLine ? card.outcome.tint : AceTheme.cardBorder, lineWidth: inLine ? 2 : 1)
                if !mark.isEmpty {
                    TicTacToeMark(mark: mark, tint: mark == card.you ? you : ace, drawIn: i == card.aceLast || i == tapped)
                        .opacity(tapped == i ? 0.6 : 1)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .boing(on: inLine, scale: 1.08)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.9))
        .disabled(!open)
        .accessibilityLabel(TicTacToe.names[i] + ", " + (mark.isEmpty ? "empty" : mark))
    }
}

// MARK: Hangman

/// The gallows and the figure, one part per miss. The newest part draws itself on.
struct HangmanDrawing: View {
    let misses: Int
    let lost: Bool
    @State private var newest: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let parts = Self.parts(w: w, h: h)
            let tint = lost ? AceTheme.bad : AceTheme.fg
            let style = StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            ZStack {
                Self.gallows(w: w, h: h)
                    .stroke(AceTheme.muted.opacity(0.7), style: style)
                ForEach(0..<min(misses, parts.count), id: \.self) { i in
                    parts[i]
                        .trim(from: 0, to: i == misses - 1 ? newest : 1)
                        .stroke(tint, style: style)
                }
            }
        }
        .onAppear {
            withAnimation(AceMotion.now(.gentle) == nil ? nil : .easeOut(duration: 0.45)) { newest = 1 }
        }
        .accessibilityElement()
        .accessibilityLabel("\(misses) of \(Hangman.maxMisses) misses")
    }

    static func gallows(w: CGFloat, h: CGFloat) -> Path {
        var frame = Path()
        frame.move(to: CGPoint(x: w * 0.1, y: h * 0.95))
        frame.addLine(to: CGPoint(x: w * 0.7, y: h * 0.95))
        frame.move(to: CGPoint(x: w * 0.25, y: h * 0.95))
        frame.addLine(to: CGPoint(x: w * 0.25, y: h * 0.05))
        frame.addLine(to: CGPoint(x: w * 0.65, y: h * 0.05))
        frame.addLine(to: CGPoint(x: w * 0.65, y: h * 0.18))
        return frame
    }

    /// Head, body, arms and legs.
    static func parts(w: CGFloat, h: CGFloat) -> [Path] {
        let cx = w * 0.65
        let head = Path(ellipseIn: CGRect(x: cx - w * 0.1, y: h * 0.18, width: w * 0.2, height: w * 0.2))
        let neck = h * 0.18 + w * 0.2
        func line(_ a: CGPoint, _ b: CGPoint) -> Path {
            var p = Path()
            p.move(to: a)
            p.addLine(to: b)
            return p
        }
        let hip = CGPoint(x: cx, y: h * 0.66)
        return [
            head,
            line(CGPoint(x: cx, y: neck), hip),
            line(CGPoint(x: cx, y: neck + h * 0.07), CGPoint(x: cx - w * 0.15, y: neck + h * 0.2)),
            line(CGPoint(x: cx, y: neck + h * 0.07), CGPoint(x: cx + w * 0.15, y: neck + h * 0.2)),
            line(hip, CGPoint(x: cx - w * 0.13, y: h * 0.86)),
            line(hip, CGPoint(x: cx + w * 0.13, y: h * 0.86)),
        ]
    }
}

struct HangmanCardView: View {
    let card: HangmanCard
    let messageID: UUID
    @EnvironmentObject var core: AceCore
    @State private var tapped: String?

    private var live: Bool { tapped == nil && card.outcome == .playing && core.brain.gameToken == card.token }
    private let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameCardTitle(game: .hangman, detail: card.category, trailing: "Misses \(card.misses) of \(card.maxMisses)")
            HStack(alignment: .center, spacing: 14) {
                HangmanDrawing(misses: card.misses, lost: card.outcome == .lost)
                    .frame(width: 86, height: 104)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 4) {
                        ForEach(Array(card.letters.enumerated()), id: \.offset) { _, letter in
                            VStack(spacing: 3) {
                                Text(letter.isEmpty ? " " : letter)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .foregroundStyle(card.outcome == .lost && !card.guessed.contains(letter) ? AceTheme.bad : AceTheme.fg)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .boing(on: letter, scale: 1.3)
                                Capsule()
                                    .fill(letter.isEmpty ? AceTheme.muted.opacity(0.6) : card.outcome.tint)
                                    .frame(height: 3)
                            }
                            .frame(minWidth: 0, maxWidth: 26)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(card.letters.map { $0.isEmpty ? "blank" : $0 }.joined(separator: ", "))
                    if card.outcome != .playing {
                        GameResultBadge(outcome: card.outcome)
                    } else {
                        Text("\(card.letters.filter { !$0.isEmpty }.count) of \(card.letters.count) letters")
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                    }
                }
            }
            if card.outcome == .playing {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 9), spacing: 5) {
                    ForEach(alphabet, id: \.self) { key($0) }
                }
                .opacity(live || tapped != nil ? 1 : 0.5)
            }
        }
        .aceCard()
        .gameGlow(card.outcome, key: messageID)
    }

    private func key(_ letter: String) -> some View {
        let tried = card.guessed.contains(letter)
        let hit = tried && card.letters.contains(letter)
        return Button {
            guard live, !tried else { return }
            tapped = letter
            Haptics.shared.play(.tick)
            core.send(letter)
        } label: {
            Text(letter)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(hit ? AceTheme.good.opacity(0.3) : tried ? AceTheme.bad.opacity(0.18) : tapped == letter ? AceTheme.ace.opacity(0.35) : AceTheme.ace.opacity(0.12))
                )
                .foregroundStyle(tried && !hit ? AceTheme.muted : AceTheme.fg)
                .strikethrough(tried && !hit, color: AceTheme.bad)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.86))
        .disabled(!live || tried)
        .accessibilityLabel(letter + (tried ? (hit ? ", in the word" : ", not in the word") : ""))
    }
}

// MARK: Guess the number

struct NumberGuessCardView: View {
    let card: NumberGuessCard
    let messageID: UUID
    @EnvironmentObject var core: AceCore
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tapped = false
    @State private var shown = false

    private var live: Bool { !tapped && card.outcome == .playing && core.brain.gameToken == card.token }
    private var span: CGFloat { CGFloat(NumberGuess.high - NumberGuess.low) }
    private var heatColor: Color {
        switch card.heat {
        case "hot": return AceTheme.bad
        case "warm": return AceTheme.amber
        default: return AceTheme.ace
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameCardTitle(game: .numberGuess, detail: card.best.map { "Best: \($0)" },
                          trailing: card.outcome == .playing ? "\(card.left) left" : nil)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let secret = card.secret {
                    Text("\(secret)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(card.outcome.tint)
                        .contentTransition(.numericText())
                    Text(card.outcome == .won ? "You found it!" : "was the number")
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                } else {
                    Text("\(card.low) to \(card.high)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                        .contentTransition(.numericText())
                    if let heat = card.heat {
                        Label(heat == "hot" ? "Hot!" : "Warm", systemImage: heat == "hot" ? "flame.fill" : "thermometer.medium")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(heatColor.opacity(0.2)))
                            .foregroundStyle(heatColor)
                            .boing(on: card.guesses.count)
                    }
                }
            }
            rangeBar
                .frame(height: 26)
            if !card.guesses.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(card.guesses.enumerated()), id: \.offset) { i, g in
                        let hint = i < card.hints.count ? card.hints[i] : ""
                        HStack(spacing: 2) {
                            Text("\(g)")
                            if hint == "higher" { Image(systemName: "arrow.up") }
                            if hint == "lower" { Image(systemName: "arrow.down") }
                            if hint == "right" { Image(systemName: "checkmark") }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(hint == "right" ? AceTheme.good.opacity(0.25) : AceTheme.soft))
                        .foregroundStyle(hint == "right" ? AceTheme.good : AceTheme.fg)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            if card.outcome == .playing {
                let middle = (card.low + card.high) / 2
                Button {
                    guard live else { return }
                    tapped = true
                    Haptics.shared.play(.tick)
                    core.send("\(middle)")
                } label: {
                    Label("Try the middle: \(middle)", systemImage: "scope")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                        .foregroundStyle(AceTheme.ace)
                }
                .buttonStyle(.aceBouncy)
                .disabled(!live)
                .opacity(live ? 1 : 0.5)
            } else {
                GameResultBadge(outcome: card.outcome)
            }
        }
        .aceCard()
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(heatColor.opacity(card.outcome == .playing && card.heat != nil ? 0.7 : 0), lineWidth: 2)
        )
        .gameGlow(card.outcome, key: messageID)
        .onAppear {
            withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) { shown = true }
        }
    }

    /// 1 to 100, with the part the number could still be in lit up, and a dot for each guess.
    private var rangeBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x: (Int) -> CGFloat = { CGFloat($0 - NumberGuess.low) / span * w }
            let lo = shown ? x(card.low) : 0
            let hi = shown ? x(card.high) : w
            ZStack(alignment: .leading) {
                Capsule().fill(AceTheme.soft).frame(height: 10)
                Capsule()
                    .fill(LinearGradient(colors: [AceTheme.ace, heatColor], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(10, hi - lo), height: 10)
                    .offset(x: lo)
                    .shadow(color: heatColor.opacity(0.6), radius: 6)
                ForEach(Array(card.guesses.enumerated()), id: \.offset) { _, g in
                    Circle()
                        .fill(AceTheme.fg)
                        .frame(width: 8, height: 8)
                        .offset(x: x(g) - 4)
                }
                if let secret = card.secret {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(card.outcome.tint)
                        .offset(x: x(secret) - 6, y: -12)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityLabel("The number is from \(card.low) to \(card.high)")
    }
}

// MARK: Rock paper scissors

struct RPSCardView: View {
    let card: RPSCard
    let messageID: UUID
    @EnvironmentObject var core: AceCore
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tapped: String?
    @State private var revealed = false

    private var live: Bool { tapped == nil && card.outcome == .playing && core.brain.gameToken == card.token }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameCardTitle(game: .rps, detail: card.round > 0 ? "Round \(card.round)" : "First to \(RPS.target)",
                          trailing: "You \(card.yourScore) · Ace \(card.aceScore)")
            if let you = card.you, let ace = card.ace {
                HStack(spacing: 0) {
                    hand(you, label: "You", winner: card.result == "win", fromLeft: true)
                    Text("VS")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(AceTheme.muted)
                        .frame(width: 44)
                    hand(ace, label: "Ace", winner: card.result == "lose", fromLeft: false)
                }
                .frame(maxWidth: .infinity)
            }
            if card.outcome == .playing {
                HStack(spacing: 10) {
                    ForEach(RPS.moves, id: \.self) { move in
                        Button {
                            guard live else { return }
                            tapped = move
                            Haptics.shared.play(.tick)
                            core.send(TextKit.capitalizeFirst(move))
                        } label: {
                            VStack(spacing: 4) {
                                Text(RPS.emoji(move)).font(.system(size: 30))
                                Text(TextKit.capitalizeFirst(move))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AceTheme.fg)
                            }
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(tapped == move ? AceTheme.ace.opacity(0.35) : AceTheme.ace.opacity(0.1))
                            )
                        }
                        .buttonStyle(BouncyButtonStyle(depth: 0.88))
                        .disabled(!live)
                        .accessibilityLabel(move)
                    }
                }
                .opacity(live || tapped != nil ? 1 : 0.5)
            } else {
                GameResultBadge(outcome: card.outcome)
            }
        }
        .aceCard()
        .gameGlow(card.outcome, key: messageID)
        .onAppear {
            withAnimation(AceMotion.animation(.pop, bouncy: bouncy, reduceMotion: reduceMotion)?.delay(0.1)) { revealed = true }
        }
    }

    private func hand(_ move: String, label: String, winner: Bool, fromLeft: Bool) -> some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        return VStack(spacing: 4) {
            Text(RPS.emoji(move))
                .font(.system(size: 52))
                .scaleEffect(revealed || !moving ? (winner ? 1.15 : 1) : 0.3)
                .rotationEffect(.degrees(revealed || !moving ? 0 : (fromLeft ? -40 : 40)))
                .opacity(revealed || reduceMotion ? 1 : 0)
                .shadow(color: winner ? AceTheme.good.opacity(0.8) : .clear, radius: 14)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(winner ? AceTheme.good : AceTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(move)")
    }
}

// MARK: Game colors

extension ArcadeGame {
    /// The two colors each game's tile and card use.
    var colors: [Color] {
        switch self {
        case .ticTacToe: return [AceTheme.ace, AceTheme.nova]
        case .hangman: return [AceTheme.amber, AceTheme.bad]
        case .trivia: return [AceTheme.pebble, AceTheme.ace]
        case .twenty: return [AceTheme.nova, AceTheme.pebble]
        case .numberGuess: return [AceTheme.good, AceTheme.ace]
        case .rps: return [AceTheme.accent, AceTheme.amber]
        }
    }
}
