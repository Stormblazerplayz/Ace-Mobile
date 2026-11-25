import SwiftUI

/// A speedometer for words a minute: a colored arc from 0 to 60 with a needle that springs to the speed.
struct SpeedGauge: View {
    let wpm: Double
    let best: Int
    let moves: Bool
    static let top = 60.0

    /// Where the needle points, from -120° (0) to 120° (60 or more).
    static func angle(for wpm: Double) -> Double {
        -120 + min(max(wpm, 0), top) / top * 240
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let r = side / 2 - 8
            ZStack {
                // The track and the colored part, from green (slow and steady) to pink (zooming).
                Circle()
                    .trim(from: 0, to: 240.0 / 360)
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: side * 0.07, lineCap: .round))
                    .rotationEffect(.degrees(150))
                Circle()
                    .trim(from: 0, to: 240.0 / 360 * min(wpm, Self.top) / Self.top)
                    .stroke(AngularGradient(colors: [AceTheme.good, AceTheme.ace, AceTheme.accent, AceTheme.nova],
                                            center: .center, startAngle: .degrees(0), endAngle: .degrees(240)),
                            style: StrokeStyle(lineWidth: side * 0.07, lineCap: .round))
                    .rotationEffect(.degrees(150))
                    .shadow(color: AceTheme.ace.opacity(0.5), radius: 8)

                // Ticks every 10.
                ForEach(0..<7) { i in
                    let a = Angle.degrees(-120 + Double(i) * 40 - 90)
                    Text("\(i * 10)")
                        .font(.system(size: max(9, side * 0.06), weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                        .position(x: geo.size.width / 2 + cos(a.radians) * (r - side * 0.14),
                                  y: geo.size.height / 2 + sin(a.radians) * (r - side * 0.14))
                }

                // Your best, as a little gold mark on the arc.
                if best > 0 {
                    let a = Angle.degrees(Self.angle(for: Double(best)) - 90)
                    Circle()
                        .fill(AceTheme.pebble)
                        .frame(width: side * 0.05, height: side * 0.05)
                        .shadow(color: AceTheme.pebble, radius: 4)
                        .position(x: geo.size.width / 2 + cos(a.radians) * r,
                                  y: geo.size.height / 2 + sin(a.radians) * r)
                        .accessibilityHidden(true)
                }

                // The needle.
                Capsule()
                    .fill(LinearGradient(colors: [.white, AceTheme.nova], startPoint: .bottom, endPoint: .top))
                    .frame(width: max(3, side * 0.025), height: r * 0.78)
                    .offset(y: -r * 0.39)
                    .rotationEffect(.degrees(Self.angle(for: wpm)))
                    .shadow(color: AceTheme.nova.opacity(0.6), radius: 4)
                    .animation(moves ? .spring(response: 0.6, dampingFraction: 0.45) : .linear(duration: 0.2), value: Int(wpm))
                Circle()
                    .fill(AceTheme.fg)
                    .frame(width: side * 0.09, height: side * 0.09)

                VStack(spacing: 0) {
                    Text("\(Int(wpm.rounded()))")
                        .font(.system(size: side * 0.2, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(AceTheme.fg)
                    Text("words a minute")
                        .font(.system(size: max(9, side * 0.065), weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
                .offset(y: side * 0.27)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speed")
        .accessibilityValue("\(Int(wpm.rounded())) words a minute")
    }
}

/// A ring that fills with how many keys you got right.
struct AccuracyRing: View {
    let accuracy: Double
    let moves: Bool

    var color: Color {
        accuracy >= 95 ? AceTheme.good : accuracy >= 85 ? AceTheme.warn : AceTheme.bad
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: side * 0.1)
                Circle()
                    .trim(from: 0, to: accuracy / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: side * 0.1, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 6)
                    .animation(moves ? .spring(response: 0.5, dampingFraction: 0.6) : nil, value: accuracy)
                VStack(spacing: 0) {
                    Text("\(Int(accuracy.rounded()))%")
                        .font(.system(size: side * 0.24, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AceTheme.fg)
                    Text("right")
                        .font(.system(size: max(9, side * 0.11), weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Accuracy")
        .accessibilityValue("\(Int(accuracy.rounded())) percent")
    }
}

/// A side-to-side wobble, for a wrong key.
struct Shake: GeometryEffect {
    var travel: CGFloat = 9
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * 4), y: 0))
    }
}

/// Confetti that falls from the top for a few seconds when a lesson is finished.
struct TypingConfetti: View {
    let seed: Int
    private static let colors: [Color] = [AceTheme.ace, AceTheme.nova, AceTheme.pebble, AceTheme.good, AceTheme.accent]
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < 4 else { return }
                var rng = SeededRandom(seed: UInt64(truncatingIfNeeded: seed) &+ 7)
                for i in 0..<90 {
                    let x0 = Double(rng.next() % 1000) / 1000 * size.width
                    let speed = 220 + Double(rng.next() % 260)
                    let drift = (Double(rng.next() % 200) - 100)
                    let spin = Double(rng.next() % 720) - 360
                    let delay = Double(rng.next() % 600) / 1000
                    let life = t - delay
                    guard life > 0 else { continue }
                    let y = -20 + speed * life + 60 * life * life
                    guard y < size.height + 20 else { continue }
                    let x = x0 + drift * life + sin(life * 3 + Double(i)) * 18
                    var piece = ctx
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .degrees(spin * life))
                    piece.opacity = min(1, max(0, (4 - t) / 1.2))
                    let rect = CGRect(x: -5, y: -3, width: 10, height: 6)
                    piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Self.colors[i % Self.colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { start = Date() }
    }
}
