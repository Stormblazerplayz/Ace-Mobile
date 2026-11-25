import SwiftUI

extension BreathStep {
    /// Blue breathing in, purple holding, green breathing out, gray resting.
    var color: Color {
        switch self {
        case .breatheIn: return AceTheme.ace
        case .hold: return AceTheme.accent
        case .breatheOut: return AceTheme.good
        case .rest: return AceTheme.muted
        }
    }
}

/// The glowing circle that grows as you breathe in and shrinks as you breathe out.
/// With Reduce Motion on it stays one size and brightens and dims instead.
struct BreatheOrb: View {
    let fullness: Double
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let scale = reduceMotion ? 0.8 : 0.42 + 0.58 * fullness
            let glow = reduceMotion ? 0.35 + 0.65 * fullness : 1
            ZStack {
                // Soft halo.
                Circle()
                    .fill(RadialGradient(colors: [color.opacity(0.55 * glow), color.opacity(0)],
                                         center: .center, startRadius: side * 0.15, endRadius: side * 0.55))
                    .frame(width: side, height: side)
                    .scaleEffect(reduceMotion ? 1 : 0.7 + 0.3 * fullness)
                // Ripples, a little behind the orb.
                ForEach(0..<3) { i in
                    Circle()
                        .strokeBorder(color.opacity(0.25 - Double(i) * 0.06), lineWidth: 2)
                        .frame(width: side * 0.62, height: side * 0.62)
                        .scaleEffect(scale * (1.08 + Double(i) * 0.1))
                }
                // The orb itself.
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.95), color, color.opacity(0.75)],
                                         center: UnitPoint(x: 0.38, y: 0.32), startRadius: 0, endRadius: side * 0.36))
                    .frame(width: side * 0.62, height: side * 0.62)
                    .scaleEffect(scale)
                    .opacity(0.55 + 0.45 * glow)
                    .shadow(color: color.opacity(0.8), radius: 24 * glow)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A ring around the orb with one colored arc for each step, and a dot that travels round as you breathe.
struct BreathRing: View {
    let pattern: BreathPattern
    let cycleProgress: Double
    let activeStep: Int

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let steps = pattern.steps
            let gap = 0.012
            ZStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                    let start = steps.prefix(i).reduce(0) { $0 + $1.seconds } / pattern.cycle
                    let end = start + s.seconds / pattern.cycle
                    Circle()
                        .trim(from: start + gap, to: max(start + gap, end - gap))
                        .stroke(s.step.color.opacity(i == activeStep ? 0.95 : 0.3),
                                style: StrokeStyle(lineWidth: side * (i == activeStep ? 0.026 : 0.016), lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                // The traveling dot.
                let a = Angle.degrees(cycleProgress * 360 - 90)
                Circle()
                    .fill(.white)
                    .frame(width: side * 0.045, height: side * 0.045)
                    .shadow(color: .white, radius: 6)
                    .position(x: geo.size.width / 2 + cos(a.radians) * side / 2,
                              y: geo.size.height / 2 + sin(a.radians) * side / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Little sparkles circling the orb: they drift in as you breathe in and float out as you breathe out.
struct BreathSparkles: View {
    let fullness: Double
    let color: Color
    let time: Double

    var body: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<44 {
                let angle0 = Self.noise(i, 1) * 2 * .pi
                let speed = 0.04 + Self.noise(i, 2) * 0.1
                let jitter = Self.noise(i, 3)
                let size0 = 1.5 + Self.noise(i, 4) * 3
                let angle = angle0 + time * speed * (i.isMultiple(of: 2) ? 1 : -1)
                let r = side * (0.34 + 0.3 * (1 - fullness) + 0.08 * jitter)
                let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                let twinkle = 0.45 + 0.55 * abs(sin(time * 1.3 + Double(i)))
                ctx.opacity = twinkle
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - size0, y: p.y - size0, width: size0 * 2, height: size0 * 2)),
                         with: .color(i % 3 == 0 ? .white : color))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A steady "random" number from 0 to 1 for sparkle `i`, so sparkles keep their places between frames.
    static func noise(_ i: Int, _ k: Int) -> Double {
        let x = sin(Double(i * 127 + k * 311) * 12.9898) * 43_758.5453
        return x - floor(x)
    }
}
