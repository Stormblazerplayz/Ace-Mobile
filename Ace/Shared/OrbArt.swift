import SwiftUI

/// What Ace is doing right now. The orb, the island and the widgets all draw from this.
enum OrbMood: String, Codable, CaseIterable {
    case idle, typing, listening, thinking, talking, checking, alert, happy, sleeping

    var tint: Color {
        switch self {
        case .idle, .typing: return AceTheme.ace
        case .listening: return Color(hex: 0x6FE3FF)
        case .thinking: return AceTheme.accent
        case .talking: return Color(hex: 0x7CC8FF)
        case .checking: return AceTheme.ace
        case .alert: return AceTheme.amber
        case .happy: return AceTheme.good
        case .sleeping: return Color(hex: 0x4A6FA8)
        }
    }

    /// Eyes come out only when Ace is looking at something.
    var showsEyes: Bool {
        switch self {
        case .checking, .alert, .happy: return true
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
        }
    }
}

/// The glowing ball itself. `glow` and `pulse` are 0...1.
struct OrbBody: View {
    var tint: Color
    var glow: Double = 0.7
    var pulse: Double = 0

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(tint.opacity(0.28 + 0.25 * glow))
                    .frame(width: d * (1.25 + 0.12 * pulse), height: d * (1.25 + 0.12 * pulse))
                    .blur(radius: d * 0.18)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), tint, AceTheme.accent.opacity(0.9)],
                            center: UnitPoint(x: 0.36, y: 0.3),
                            startRadius: d * 0.02,
                            endRadius: d * 0.72
                        )
                    )
                    .frame(width: d * (1 + 0.05 * pulse), height: d * (1 + 0.05 * pulse))
                    .shadow(color: tint.opacity(0.6), radius: d * 0.12)
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: max(1, d * 0.015))
                    .frame(width: d * 0.98, height: d * 0.98)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
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
            OrbBody(tint: mood.tint, glow: mood == .sleeping ? 0.3 : 0.8)
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
