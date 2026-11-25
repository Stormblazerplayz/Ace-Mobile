import SwiftUI

/// Twinkling stars behind everything, plus a shooting star now and then. The stars come from
/// a fixed seed, so they stay in the same places every time.
struct Starfield: View {
    let moves: Bool

    private struct Star {
        let x: Double, y: Double, size: Double, phase: Double, speed: Double, warm: Bool
    }

    private static let stars: [Star] = {
        var seed: UInt64 = 0x5EED_ACE5
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 11) / Double(1 << 53)
        }
        return (0..<260).map { _ in
            Star(x: next(), y: next(), size: 0.5 + next() * next() * 2.2, phase: next() * 6.3, speed: 0.6 + next() * 2, warm: next() < 0.2)
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !moves)) { timeline in
            Canvas { ctx, size in
                let t = moves ? timeline.date.timeIntervalSinceReferenceDate : 0
                for s in Starfield.stars {
                    let twinkle = moves ? 0.55 + 0.45 * sin(t * s.speed + s.phase) : 0.8
                    let r = CGFloat(s.size)
                    let rect = CGRect(x: CGFloat(s.x) * size.width - r, y: CGFloat(s.y) * size.height - r, width: r * 2, height: r * 2)
                    let color: Color = s.warm ? Color(hex: 0xFFE2B8) : Color(hex: 0xDCE6FF)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(twinkle)))
                }
                guard moves else { return }
                // A shooting star every 7 seconds, crossing in about a second.
                let cycle = t.truncatingRemainder(dividingBy: 7)
                if cycle < 1 {
                    let n = Int(t / 7)
                    let startX = Double((n * 37) % 70) / 100 + 0.1
                    let startY = Double((n * 53) % 40) / 100 + 0.05
                    let k = CGFloat(cycle)
                    let head = CGPoint(x: CGFloat(startX) * size.width + 260 * k, y: CGFloat(startY) * size.height + 120 * k)
                    let tail = CGPoint(x: head.x - 90, y: head.y - 42)
                    var path = Path()
                    path.move(to: tail)
                    path.addLine(to: head)
                    ctx.stroke(path, with: .linearGradient(Gradient(colors: [.clear, .white.opacity(Double(0.9 * (1 - k)))]),
                                                         startPoint: tail, endPoint: head),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// One planet as a little lit-up ball: its colors, cloud bands on the giants that slide as it
/// spins, a dark night side away from the Sun, and rings for Saturn and Uranus.
struct PlanetBall: View {
    let planet: Planet
    /// Which way the Sun is, in degrees (0 is to the right, 90 is up). Nil lights it from the front.
    var sunAngle: Double? = nil
    /// How far the bands have turned (0 to 1), so a spinning giant's clouds slide along.
    var spin: Double = 0

    var body: some View {
        Canvas { ctx, size in
            PlanetBall.draw(planet, in: CGRect(origin: .zero, size: size), sunAngle: sunAngle, spin: spin, ctx: ctx)
        }
        .accessibilityHidden(true)
    }

    /// Draws into any Canvas, so the map can draw planets without a view for each.
    static func draw(_ planet: Planet, in box: CGRect, sunAngle: Double?, spin: Double, ctx: GraphicsContext) {
        let ringScale: CGFloat = planet.rings ? (planet.id == "saturn" ? 1.0 : 0.55) : 0
        // With rings, the ball is smaller so the rings fit.
        let side = min(box.width, box.height) / (planet.rings && planet.id == "saturn" ? 2.1 : 1)
        let ball = CGRect(x: box.midX - side / 2, y: box.midY - side / 2, width: side, height: side)
        let circle = Path(ellipseIn: ball)
        let colors = planet.colors.map { Color(hex: $0) }
        let lit = sunAngle.map { CGFloat($0 * .pi / 180) }
        let litPoint = lit.map { CGPoint(x: ball.midX + cos($0) * side * 0.3, y: ball.midY - sin($0) * side * 0.3) }
            ?? CGPoint(x: ball.midX - side * 0.22, y: ball.midY - side * 0.25)

        if planet.isSun {
            // The Sun glows instead of having a night side.
            ctx.drawLayer { glow in
                glow.addFilter(.blur(radius: side * 0.25))
                glow.fill(Path(ellipseIn: ball.insetBy(dx: -side * 0.15, dy: -side * 0.15)), with: .color(Color(hex: 0xFFB43C).opacity(0.8)))
            }
            ctx.fill(circle, with: .radialGradient(Gradient(colors: colors), center: CGPoint(x: ball.midX, y: ball.midY),
                                                   startRadius: 0, endRadius: side / 2))
            return
        }

        if ringScale > 0 {
            drawRing(planet, ball: ball, scale: ringScale, front: false, ctx: ctx)
        }
        ctx.fill(circle, with: .radialGradient(Gradient(colors: colors), center: litPoint, startRadius: 0, endRadius: side * 0.85))
        if planet.banded {
            var bands = ctx
            bands.clip(to: circle)
            let count = planet.id == "jupiter" ? 7 : 5
            for i in 0..<count {
                let y = ball.minY + side * (CGFloat(i) + 0.5) / CGFloat(count)
                let wave = CGFloat(sin((spin * 2 + Double(i) * 0.7) * .pi)) * side * 0.02
                let h = side * (i.isMultiple(of: 2) ? 0.07 : 0.045)
                bands.fill(Path(CGRect(x: ball.minX, y: y + wave - h / 2, width: side, height: h)),
                           with: .color(Color(hex: planet.colors.last ?? 0).opacity(i.isMultiple(of: 2) ? 0.28 : 0.18)))
            }
            if planet.id == "jupiter" {
                // The Great Red Spot, sliding across as Jupiter turns.
                let x = ball.minX + side * CGFloat((spin.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1))
                let spot = CGRect(x: x - side * 0.09, y: ball.midY + side * 0.12, width: side * 0.18, height: side * 0.1)
                bands.fill(Path(ellipseIn: spot), with: .color(Color(hex: 0xC4502E).opacity(0.85)))
            }
        }
        if planet.id == "earth" {
            var land = ctx
            land.clip(to: circle)
            // Simple green continents that slide as Earth spins.
            let shift = CGFloat((spin.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)) * side * 2
            for (x, y, w, h) in [(0.1, 0.25, 0.32, 0.28), (0.25, 0.55, 0.2, 0.3), (0.62, 0.3, 0.38, 0.22), (0.78, 0.55, 0.16, 0.2)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                for wrap in [-2.0, 0.0] as [CGFloat] {
                    let r = CGRect(x: ball.minX + side * (x + wrap) + shift, y: ball.minY + side * y, width: side * w, height: side * h)
                    land.fill(Path(ellipseIn: r), with: .color(Color(hex: 0x3FAE5A).opacity(0.85)))
                }
            }
            land.fill(Path(ellipseIn: CGRect(x: ball.minX + side * 0.3, y: ball.minY - side * 0.02, width: side * 0.4, height: side * 0.1)),
                      with: .color(.white.opacity(0.8)))
        }
        // The night side.
        var night = ctx
        night.clip(to: circle)
        let away = CGPoint(x: ball.midX * 2 - litPoint.x, y: ball.midY * 2 - litPoint.y)
        night.fill(circle, with: .linearGradient(Gradient(colors: [.clear, .black.opacity(0.75)]), startPoint: litPoint, endPoint: away))
        if ringScale > 0 {
            drawRing(planet, ball: ball, scale: ringScale, front: true, ctx: ctx)
        }
    }

    private static func drawRing(_ planet: Planet, ball: CGRect, scale: CGFloat, front: Bool, ctx: GraphicsContext) {
        var c = ctx
        let side = ball.width
        // Saturn's rings lie nearly flat; Uranus is tipped over, so its faint rings stand up.
        let upright = planet.id == "uranus"
        let outer = CGRect(x: ball.midX - side * (upright ? 0.38 : 1.0) * scale,
                           y: ball.midY - side * (upright ? 1.0 : 0.3) * scale,
                           width: side * (upright ? 0.76 : 2.0) * scale,
                           height: side * (upright ? 2.0 : 0.6) * scale)
        // Only the half in front of the ball is drawn over it.
        if front {
            let half = upright
                ? CGRect(x: ball.midX, y: outer.minY - 2, width: outer.width, height: outer.height + 4)
                : CGRect(x: outer.minX - 2, y: ball.midY, width: outer.width + 4, height: outer.height)
            c.clip(to: Path(half))
        }
        let color = Color(hex: planet.id == "saturn" ? 0xE8D3A0 : 0xBFEFF5)
        c.stroke(Path(ellipseIn: outer), with: .color(color.opacity(planet.id == "saturn" ? 0.85 : 0.45)),
                 lineWidth: max(1, side * (planet.id == "saturn" ? 0.12 : 0.04)))
        c.stroke(Path(ellipseIn: outer.insetBy(dx: outer.width * 0.1, dy: outer.height * 0.1)),
                 with: .color(color.opacity(planet.id == "saturn" ? 0.5 : 0.25)), lineWidth: max(1, side * 0.05))
    }
}
