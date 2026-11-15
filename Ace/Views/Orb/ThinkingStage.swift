import SwiftUI

/// What Ace shows around the orb while it thinks. It takes turns with a few looks
/// (see ThinkingAnimation) and fades from one to the next.
/// The back part goes behind the orb and the front part goes on top of it.
struct ThinkingLayer: View {
    enum Part { case back, front }

    var part: Part
    /// Seconds since Ace started thinking.
    var time: TimeInterval
    var reduceMotion: Bool
    var orbSize: CGFloat
    var tint: Color

    /// How wide the thinking area is, so there's room for an eye on each side of the orb.
    static func width(orbSize: CGFloat) -> CGFloat { orbSize * 2.7 }

    private static let gold = Color(hex: 0xFFE08A)

    var body: some View {
        let f = ThinkingAnimation.frame(at: time, reduceMotion: reduceMotion)
        ZStack {
            look(f.current)
                .opacity(1 - f.mix)
            if f.mix > 0 && f.next != f.current {
                look(f.next)
                    .opacity(f.mix)
            }
        }
        .frame(width: Self.width(orbSize: orbSize), height: orbSize)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func look(_ a: ThinkingAnimation) -> some View {
        switch part {
        case .back: back(a)
        case .front: front(a)
        }
    }

    // MARK: Behind the orb

    @ViewBuilder
    private func back(_ a: ThinkingAnimation) -> some View {
        switch a {
        case .rings:
            // Gold rings pulsing out from the orb.
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(tint.opacity(0.8 * (1 - ringPhase(i))), lineWidth: 2)
                        .frame(width: orbSize, height: orbSize)
                        .scaleEffect(1 + ringPhase(i) * 0.75)
                }
            }
        case .wave:
            // Two waves running through the island behind the orb.
            ZStack {
                WaveLine(phase: time * 4, amplitude: 0.34, cycles: 3)
                    .stroke(tint.opacity(0.9), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                WaveLine(phase: -time * 3 + 1.4, amplitude: 0.22, cycles: 2)
                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            .frame(width: Self.width(orbSize: orbSize), height: orbSize)
        default:
            EmptyView()
        }
    }

    // MARK: On top of the orb

    @ViewBuilder
    private func front(_ a: ThinkingAnimation) -> some View {
        switch a {
        case .spinGlow:
            // A dashed gold ring spinning around, and a little swirl inside, like gears turning.
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(Self.gold, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 6]))
                    .rotationEffect(.degrees(time * 220))
                    .frame(width: orbSize * 1.22, height: orbSize * 1.22)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-time * 300))
                    .frame(width: orbSize * 0.5, height: orbSize * 0.5)
            }
        case .shimmer:
            // A band of light sweeping across the orb, and a soft gold rim.
            ZStack {
                LinearGradient(colors: [.clear, Color.white.opacity(0.85), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: orbSize * 0.4, height: orbSize * 1.6)
                    .rotationEffect(.degrees(22))
                    .offset(x: shimmerOffset)
                    .frame(width: orbSize, height: orbSize)
                    .clipShape(Circle())
                    .blendMode(.plusLighter)
                Circle()
                    .stroke(tint.opacity(0.55), lineWidth: 1.5)
                    .frame(width: orbSize * 1.12, height: orbSize * 1.12)
            }
        case .sideEyes:
            // One eye on each side of the orb, outside it, glancing around together.
            ZStack {
                SideEye(look: eyeLook, open: eyeOpen, color: Self.gold)
                    .frame(width: orbSize * 0.26, height: orbSize * 0.55)
                    .offset(x: -eyeDistance)
                SideEye(look: eyeLook, open: eyeOpen, color: Self.gold)
                    .frame(width: orbSize * 0.26, height: orbSize * 0.55)
                    .offset(x: eyeDistance)
            }
        case .calm:
            // Reduce Motion: a still ring, nothing moving.
            Circle()
                .stroke(tint.opacity(0.6), lineWidth: 2)
                .frame(width: orbSize * 1.18, height: orbSize * 1.18)
        default:
            EmptyView()
        }
    }

    // MARK: Numbers for the looks

    /// 0...1 for each pulsing ring, spread out so one starts as another fades.
    private func ringPhase(_ i: Int) -> CGFloat {
        CGFloat((time * 0.7 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
    }

    /// Where the shimmer band is: it crosses the orb every 1.5 seconds.
    private var shimmerOffset: CGFloat {
        let sweep = (time / 1.5).truncatingRemainder(dividingBy: 1)
        return CGFloat(sweep * 2 - 1) * orbSize * 0.9
    }

    /// How far each eye sits from the middle of the orb.
    private var eyeDistance: CGFloat { orbSize * (0.5 + 0.24 + 0.13) }

    /// Where the eyes look (-1...1 each way). Two waves mixed together so it looks like glancing.
    private var eyeLook: CGPoint {
        let x = sin(time * 1.1) * 0.7 + sin(time * 2.9) * 0.25
        let y = cos(time * 0.8) * 0.4
        return CGPoint(x: min(1, max(-1, x)), y: min(1, max(-1, y)))
    }

    /// The eyes blink quickly every 2.3 seconds.
    private var eyeOpen: CGFloat {
        let b = (time / 2.3).truncatingRemainder(dividingBy: 1)
        guard b > 0.93 else { return 1 }
        // Shut in the middle of the blink, open again at the end.
        let shut = 1 - abs(b - 0.965) / 0.035
        return CGFloat(max(0.12, 1 - shut))
    }
}

/// One glowing eye: a rounded bar with a little shine. `look` moves it, `open` is 0 (shut) to 1.
private struct SideEye: View {
    var look: CGPoint
    var open: CGFloat
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w / 2, style: .continuous)
                    .fill(color)
                    .frame(width: w, height: max(w * 0.3, h * open))
                    .shadow(color: color.opacity(0.7), radius: 4)
                if open > 0.5 {
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: w * 0.36, height: w * 0.36)
                        .offset(x: -w * 0.1, y: -h * open * 0.28)
                }
            }
            .offset(x: look.x * w * 0.6, y: look.y * h * 0.18)
            .frame(width: w, height: h)
        }
    }
}

/// A wave line across its box that fades to flat at both ends.
struct WaveLine: Shape {
    var phase: Double
    /// How tall the wave is, as a share of the box's height (0...0.5).
    var amplitude: Double
    /// How many waves fit across the box.
    var cycles: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let steps = 60
        for i in 0...steps {
            let x = Double(i) / Double(steps)
            let envelope = sin(Double.pi * x)
            let y = 0.5 + amplitude * envelope * sin(x * cycles * 2 * Double.pi + phase)
            let point = CGPoint(x: rect.minX + CGFloat(x) * rect.width, y: rect.minY + CGFloat(y) * rect.height)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        return p
    }
}
