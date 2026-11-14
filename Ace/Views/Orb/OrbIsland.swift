import SwiftUI

/// Ace at the top of the screen. A calm glowing orb most of the time.
/// When Ace looks around, it stretches into a pill (like the Dynamic Island)
/// and two digital eyes come out and glance around.
struct OrbIsland: View {
    var mood: OrbMood
    var look: CGPoint
    var eyeOpen: CGFloat
    var status: String
    /// The widest the pill may get when it stretches out (keeps it on small screens).
    var maxExpandedWidth: CGFloat = 330
    var onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private let height: CGFloat = 58

    private var expandedWidth: CGFloat { max(height, min(330, maxExpandedWidth)) }
    private var showsStatus: Bool { expandedWidth >= 290 }

    private var speed: Double {
        switch mood {
        case .thinking: return 3.2
        case .talking: return 7
        case .sleeping: return 0.8
        default: return 1.4
        }
    }

    var body: some View {
        // Redraws every screen frame (60 or 120 a second); slower while resting.
        TimelineView(.animation(minimumInterval: mood == .sleeping ? 1 / 20 : nil)) { context in
            // Seconds since the orb appeared, so the numbers stay small and smooth.
            let t = context.date.timeIntervalSince(start) * (reduceMotion ? 0.35 : 1)
            let breathe: Double = (sin(t * speed) + 1) / 2
            let expanded = mood.expands
            ZStack {
                // The island body (a dark pill) shows only when expanded.
                Capsule(style: .continuous)
                    .fill(AceTheme.ink.opacity(expanded ? 0.96 : 0))
                    .overlay(Capsule(style: .continuous).stroke(mood.tint.opacity(expanded ? 0.45 : 0), lineWidth: 1.2))
                    .shadow(color: mood.tint.opacity(expanded ? 0.45 : 0), radius: 18)

                HStack(spacing: 12) {
                    orb(breathe: breathe, t: t)
                        .frame(width: height - 8, height: height - 8)
                    if expanded {
                        OrbEyes(look: look, open: eyeOpen, happy: mood == .happy, color: mood.tint)
                            .frame(width: 96, height: height * 0.62)
                            .transition(.scale(scale: 0.2).combined(with: .opacity))
                        if showsStatus {
                            Text(status)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AceTheme.fg.opacity(0.85))
                                .lineLimit(1)
                                .frame(maxWidth: 140, alignment: .leading)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, expanded ? 6 : 0)
            }
            .frame(width: expanded ? expandedWidth : height, height: height)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: mood)
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ace, \(mood.label)")
        .accessibilityHint("Double tap to open Settings")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func orb(breathe: Double, t: TimeInterval) -> some View {
        ZStack {
            if mood == .listening {
                ForEach(0..<3, id: \.self) { i in
                    let phase = (t * 0.9 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Circle()
                        .stroke(mood.tint.opacity(0.6 * (1 - phase)), lineWidth: 2)
                        .scaleEffect(1 + phase * 0.9)
                }
            }
            OrbBody(
                tint: mood.tint,
                tint2: mood.tint2,
                glow: mood == .sleeping ? 0.3 : min(1, 0.5 + 0.35 * breathe + 0.2 * mood.energy),
                pulse: breathe,
                time: t,
                energy: reduceMotion ? mood.energy * 0.4 : mood.energy
            )
            if mood == .thinking {
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(AceTheme.amber, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 6]))
                    .rotationEffect(.degrees(t * 220))
                    .scaleEffect(1.22)
                // A little swirl inside, like gears turning.
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-t * 300))
                    .scaleEffect(0.5)
            }
            if mood == .talking {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 3.5, height: 6 + 12 * abs(sin(t * 9 + Double(i) * 1.3)))
                    }
                }
            }
            if mood == .typing {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.4 + 0.5 * (sin(t * 6 - Double(i)) + 1) / 2))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
    }
}
