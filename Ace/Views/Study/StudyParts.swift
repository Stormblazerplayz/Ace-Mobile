import SwiftUI

// Pieces the Study screens share: the glowing backdrop, the progress ring, the flip card and the confetti.

/// A dark backdrop with big soft blobs of color that drift around slowly.
/// They hold still with Bouncy animations off or Reduce Motion on.
struct StudyBackdrop: View {
    var colors: [Color]
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !moving)) { context in
            let t = moving ? context.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    AceTheme.background
                    ForEach(Array(colors.prefix(4).enumerated()), id: \.offset) { i, color in
                        let phase = Double(i) * 1.9
                        Circle()
                            .fill(color.opacity(0.55))
                            .frame(width: max(w, h) * 0.62, height: max(w, h) * 0.62)
                            .blur(radius: 90)
                            .offset(x: CGFloat(cos(t / 7 + phase)) * w * 0.28 + (i.isMultiple(of: 2) ? -w * 0.22 : w * 0.22),
                                    y: CGFloat(sin(t / 9 + phase)) * h * 0.18 + (i < 2 ? -h * 0.25 : h * 0.25))
                    }
                }
                .frame(width: w, height: h)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A round progress ring with a gradient stroke that springs to its new value.
struct ProgressRing: View {
    var progress: Double
    var colors: [Color]
    var lineWidth: CGFloat = 8
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let clamped = min(1, max(0, progress))
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(AngularGradient(gradient: Gradient(colors: colors + [colors.first ?? .white]), center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: (colors.first ?? .white).opacity(0.6), radius: lineWidth * 0.8)
        }
        .animation(AceMotion.animation(.gentle, bouncy: bouncy, reduceMotion: reduceMotion), value: clamped)
        .accessibilityElement()
        .accessibilityLabel("\(Int((clamped * 100).rounded())) percent")
    }
}

/// A flashcard that flips over in 3D. `angle` is 0 for the question side and 180 for the answer side.
/// It's Animatable, so the side swaps exactly when the card is edge-on.
struct FlipCard: View, Animatable {
    let card: StudyCard
    let deck: StudyDeck
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let showBack = angle.truncatingRemainder(dividingBy: 360) > 90
        ZStack {
            front
                .opacity(showBack ? 0 : 1)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showBack ? String("Answer: \(card.back). \(card.note)") : String("Question: \(card.front)"))
        .accessibilityHint("Double tap to flip")
    }

    private var front: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(hex: 0x15132A))
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(deck.tint.opacity(0.14))
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(deck.gradient, lineWidth: 2.5)
            VStack(spacing: 18) {
                HStack {
                    Label(deck.name, systemImage: deck.symbol)
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(deck.tint)
                    Spacer()
                    Text("Question")
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(AceTheme.muted)
                }
                Spacer(minLength: 0)
                Text(card.front)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AceTheme.fg)
                    .minimumScaleFactor(0.45)
                Spacer(minLength: 0)
                Label("Tap to flip", systemImage: "hand.tap.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AceTheme.muted)
            }
            .padding(28)
        }
    }

    private var back: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(deck.gradient)
            // A soft shine across the top of the card.
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
            Image(systemName: deck.symbol)
                .font(.system(size: 170, weight: .bold))
                .foregroundStyle(.white.opacity(0.12))
                .rotationEffect(.degrees(-14))
                .offset(x: 110, y: 90)
                .clipped()
            VStack(spacing: 16) {
                HStack {
                    Text("Answer")
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                }
                Spacer(minLength: 0)
                Text(card.back)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.4)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                if !card.note.isEmpty {
                    Text(card.note)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                        .minimumScaleFactor(0.6)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Spacer(minLength: 0)
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
    }
}

/// A big stamp ("Got it" or "Again") that fades in on the card as you drag it.
struct SwipeStamp: View {
    let text: String
    let symbol: String
    let color: Color
    let tilt: Double

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .textCase(.uppercase)
            .foregroundStyle(color)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color, lineWidth: 4))
            .rotationEffect(.degrees(tilt))
    }
}

/// Confetti that bursts out from the middle and falls. Draws nothing with motion turned down.
struct ConfettiBurst: View {
    var colors: [Color]
    var count = 70
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var pieces: [Piece] = []

    struct Piece {
        let vx: Double
        let vy: Double
        let spin: Double
        let size: CGSize
        let color: Int
    }

    /// How long the confetti lasts.
    static let duration = 3.2

    var body: some View {
        if AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion), !colors.isEmpty {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSince(start)
                Canvas { ctx, size in
                    guard t < Self.duration else { return }
                    let origin = CGPoint(x: size.width / 2, y: size.height * 0.38)
                    let fade = max(0, min(1, (Self.duration - t) / 0.8))
                    for p in pieces {
                        let x = origin.x + p.vx * t
                        let y = origin.y + p.vy * t + 0.5 * 900 * t * t
                        var c = ctx
                        c.opacity = fade
                        c.translateBy(x: x, y: y)
                        c.rotate(by: .radians(p.spin * t))
                        let rect = CGRect(x: -p.size.width / 2, y: -p.size.height / 2, width: p.size.width, height: p.size.height)
                        c.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(colors[p.color % colors.count]))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                start = Date()
                pieces = (0..<count).map { _ in
                    let angle = Double.random(in: -Double.pi...0)
                    let speed = Double.random(in: 380...900)
                    return Piece(vx: cos(angle) * speed, vy: sin(angle) * speed,
                                 spin: Double.random(in: -9...9),
                                 size: CGSize(width: Double.random(in: 7...13), height: Double.random(in: 10...18)),
                                 color: Int.random(in: 0..<1_000))
                }
            }
        }
    }
}
