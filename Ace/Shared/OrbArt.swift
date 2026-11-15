import SwiftUI

/// What Ace is doing right now. The orb, the island and the widgets all draw from this.
enum OrbMood: String, Codable, CaseIterable {
    case idle, typing, listening, thinking, talking, checking, alert, happy, sleeping, home

    var tint: Color {
        switch self {
        case .idle, .typing: return AceTheme.ace
        // Listening is blue, thinking is gold, and home control is green.
        case .listening: return Color(hex: 0x3D8BFF)
        case .thinking: return Color(hex: 0xFFC83D)
        case .talking: return Color(hex: 0x7CC8FF)
        case .checking: return AceTheme.ace
        case .alert: return AceTheme.amber
        case .happy: return AceTheme.good
        case .sleeping: return Color(hex: 0x4A6FA8)
        case .home: return Color(hex: 0x3DF59A)
        }
    }

    /// The second color that swirls through the orb.
    var tint2: Color {
        switch self {
        case .idle, .typing, .checking: return AceTheme.accent
        case .listening: return Color(hex: 0x6FE3FF)
        case .thinking: return Color(hex: 0xFF8A3D)
        case .talking: return AceTheme.accent
        case .alert: return AceTheme.nova
        case .happy: return Color(hex: 0x6FE3FF)
        case .sleeping: return Color(hex: 0x2A3A78)
        case .home: return Color(hex: 0x2FC9B0)
        }
    }

    /// How lively the swirl is, 0 (still) to 1 (busy).
    var energy: Double {
        switch self {
        case .idle: return 0.25
        case .typing: return 0.4
        case .listening: return 0.8
        case .thinking: return 1
        case .talking: return 0.7
        case .checking, .alert: return 0.5
        case .happy: return 0.4
        case .sleeping: return 0.05
        case .home: return 0.55
        }
    }

    /// Eyes come out only when Ace is looking at something.
    var showsEyes: Bool {
        switch self {
        case .checking, .alert, .happy, .home: return true
        default: return false
        }
    }

    /// The island stretches into a pill when the eyes are out.
    var expands: Bool { showsEyes }

    var label: String {
        switch self {
        case .idle: return "Ready"
        case .typing: return "Reading along"
        case .listening: return "Listening"
        case .thinking: return "Thinking"
        case .talking: return "Talking"
        case .checking: return "Checking things"
        case .alert: return "Heads up"
        case .happy: return "All good"
        case .sleeping: return "Resting"
        case .home: return "Home done"
        }
    }
}

/// The glowing ball itself: a deep sphere with colors swirling inside,
/// an inner glow, a shiny highlight, a rim light and a soft bloom around it.
/// `glow` and `pulse` are 0...1. `time` is seconds (0 for a still picture).
struct OrbBody: View {
    var tint: Color
    var tint2: Color = AceTheme.accent
    var glow: Double = 0.7
    var pulse: Double = 0
    var time: Double = 0
    var energy: Double = 0.25
    /// Draw on the GPU for smooth animation. Widgets pass false.
    var live: Bool = true

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let ball = d * (1 + 0.04 * pulse)
            let bloom = d * (1.75 + 0.18 * pulse)
            ZStack {
                // Soft bloom of light around the ball.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.18 + 0.45 * glow), tint2.opacity(0.22 * glow), .clear],
                            center: .center,
                            startRadius: d * 0.22,
                            endRadius: bloom / 2
                        )
                    )
                    .frame(width: bloom, height: bloom)
                    .blur(radius: d * 0.06)
                OrbSphere(tint: tint, tint2: tint2, time: time, energy: energy, live: live)
                    .frame(width: ball, height: ball)
                    .shadow(color: tint.opacity(0.3 + 0.35 * glow), radius: d * 0.14)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// The ball, clipped to a circle and drawn on the GPU in one pass.
private struct OrbSphere: View {
    var tint: Color
    var tint2: Color
    var time: Double
    var energy: Double
    var live: Bool

    private static let deep = Color(hex: 0x0B0A24)

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let spin = Angle.degrees(time * (14 + 70 * energy))
            let coreX = 0.5 + 0.07 * cos(time * 0.7)
            let coreY = 0.56 + 0.06 * sin(time * 0.9)
            ZStack {
                // Deep base color.
                RadialGradient(
                    colors: [tint, tint2, Self.deep],
                    center: UnitPoint(x: 0.42, y: 0.38),
                    startRadius: 0,
                    endRadius: d * 0.62
                )
                // Colors swirling inside.
                OrbSwirl(tint: tint, tint2: tint2, time: time, energy: energy, spin: spin, size: d)
                // Shade the far edge so it looks round, not flat.
                RadialGradient(
                    colors: [.clear, .clear, Color.black.opacity(0.55)],
                    center: UnitPoint(x: 0.38, y: 0.32),
                    startRadius: 0,
                    endRadius: d * 0.74
                )
                // A warm glow from the core that drifts a little.
                RadialGradient(
                    colors: [Color.white.opacity(0.28 + 0.3 * energy), tint.opacity(0.25), .clear],
                    center: UnitPoint(x: coreX, y: coreY),
                    startRadius: 0,
                    endRadius: d * 0.36
                )
                .blendMode(.plusLighter)
                // Shiny highlight, like light on glass.
                Ellipse()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: d * 0.46, height: d * 0.27)
                    .rotationEffect(.degrees(-28))
                    .offset(x: -d * 0.13, y: -d * 0.22)
                    .blur(radius: d * 0.02)
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: d * 0.07, height: d * 0.07)
                    .offset(x: -d * 0.21, y: -d * 0.15)
                    .blur(radius: d * 0.008)
                // Rim light that slowly travels around the edge.
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [Color.white.opacity(0.55), .clear, tint.opacity(0.75), .clear, Color.white.opacity(0.55)],
                            center: .center,
                            angle: .degrees(-spin.degrees * 0.5)
                        ),
                        lineWidth: max(1, d * 0.025)
                    )
            }
            .frame(width: d, height: d)
            .clipShape(Circle())
            .modifier(Flatten(live: live))
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Renders the ball as one picture: on the GPU when animating, plainly in widgets.
private struct Flatten: ViewModifier {
    var live: Bool

    func body(content: Content) -> some View {
        if live {
            content.drawingGroup()
        } else {
            content.compositingGroup()
        }
    }
}

/// The moving colors inside the orb. iOS 18 and newer use a flowing mesh gradient;
/// older versions use two blurred, turning color wheels.
private struct OrbSwirl: View {
    var tint: Color
    var tint2: Color
    var time: Double
    var energy: Double
    var spin: Angle
    var size: CGFloat

    private static let deep = Color(hex: 0x0B0A24)

    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                mesh
            } else {
                AngularGradient(
                    colors: [tint, tint2, Color.white.opacity(0.75), tint, Self.deep, tint2, tint],
                    center: .center,
                    angle: spin
                )
                .blur(radius: size * 0.12)
                .opacity(0.8)
            }
            // A second wheel turning the other way gives the swirl.
            AngularGradient(
                colors: [.clear, tint2.opacity(0.9), .clear, tint.opacity(0.8), .clear],
                center: UnitPoint(x: 0.5 + 0.12 * cos(time * 0.6), y: 0.5 + 0.12 * sin(time * 0.6)),
                angle: .degrees(-spin.degrees * 1.4)
            )
            .blur(radius: size * 0.1)
            .blendMode(.screen)
        }
    }

    @available(iOS 18.0, *)
    private var mesh: some View {
        let s = time * (0.35 + 1.2 * energy)
        let a = 0.2
        let points: [SIMD2<Float>] = [
            Self.point(0, 0), Self.point(0.5 + a * sin(s), 0), Self.point(1, 0),
            Self.point(0, 0.5 + a * cos(s * 1.1)), Self.point(0.5 + a * cos(s * 0.8), 0.5 + a * sin(s * 1.3)), Self.point(1, 0.5 + a * sin(s * 0.9)),
            Self.point(0, 1), Self.point(0.5 + a * cos(s * 1.2), 1), Self.point(1, 1),
        ]
        let colors: [Color] = [
            Self.deep, tint2, Self.deep,
            tint, Color.white.opacity(0.85), tint2,
            tint2, tint, Self.deep,
        ]
        return MeshGradient(width: 3, height: 3, points: points, colors: colors)
            .scaleEffect(1.45)
            .rotationEffect(spin)
            .blur(radius: size * 0.05)
            .opacity(0.9)
    }

    private static func point(_ x: Double, _ y: Double) -> SIMD2<Float> {
        SIMD2<Float>(Float(x), Float(y))
    }
}

/// Two digital eyes. `look` moves them (-1...1 each way), `open` is 0 (shut) to 1.
struct OrbEyes: View {
    var look: CGPoint = .zero
    var open: CGFloat = 1
    var happy: Bool = false
    var color: Color = Color(hex: 0x0C1028)

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = h * 0.47
            let gap = h * 0.5
            let dx = look.x * h * 0.28
            let dy = look.y * h * 0.16
            HStack(spacing: gap) {
                eye(width: w, height: h)
                eye(width: w, height: h)
            }
            .offset(x: dx, y: dy)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private func eye(width: CGFloat, height: CGFloat) -> some View {
        if happy {
            HappyArc()
                .stroke(color, style: StrokeStyle(lineWidth: width * 0.42, lineCap: .round))
                .frame(width: width * 1.3, height: height * 0.45)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: width / 2, style: .continuous)
                    .fill(color)
                    .frame(width: width, height: max(width * 0.25, height * open))
                if open > 0.5 {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: width * 0.32, height: width * 0.32)
                        .offset(x: -width * 0.12, y: -height * open * 0.3)
                }
            }
            .frame(width: width, height: height)
        }
    }
}

/// An upside-down U for a smiling eye (^ ^).
struct HappyArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.6))
        return p
    }
}

/// A still picture of Ace for widgets: the orb, with eyes if the mood shows them.
struct OrbStill: View {
    var mood: OrbMood
    var look: CGPoint = CGPoint(x: 0.25, y: -0.1)

    var body: some View {
        ZStack {
            OrbBody(tint: mood.tint, tint2: mood.tint2, glow: mood == .sleeping ? 0.3 : 0.8, energy: mood.energy, live: false)
            if mood.showsEyes {
                OrbEyes(look: look, open: 1, happy: mood == .happy)
                    .scaleEffect(0.42)
            } else if mood == .sleeping {
                OrbEyes(look: .zero, open: 0.1)
                    .scaleEffect(0.42)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
