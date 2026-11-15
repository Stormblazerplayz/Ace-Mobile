import SwiftUI

/// Ace at the top of the screen, like the Dynamic Island: a black pill with the
/// glowing orb inside it at one end. It's small while Ace rests, stretches out while
/// Ace listens, reads, thinks or talks, and goes wide with two digital eyes when
/// Ace looks around.
struct OrbIsland: View {
    var mood: OrbMood
    var look: CGPoint
    var eyeOpen: CGFloat
    var status: String
    /// The widest the pill may get when it stretches out (keeps it on small screens).
    var maxExpandedWidth: CGFloat = 330
    /// How loud you are while Ace listens (0...1), so the rings grow when you talk.
    var level: Double = 0
    /// A seasonal outfit for the orb (a Santa hat in December...), or nil for none.
    var outfit: OrbOutfit? = nil
    var onTap: () -> Void
    /// Hold the orb to talk: true when the hold starts, false when you let go.
    var onHold: (Bool) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var motion = OrbMotion()
    /// Running timers, so a focus session can fill a ring around the orb.
    @ObservedObject private var timers = KitchenTimers.shared
    @State private var start = Date()
    @State private var pressStart: Date?
    @State private var holding = false
    @State private var holdTask: Task<Void, Never>?
    /// When Ace started thinking, so the thinking looks always start from the first one.
    @State private var thinkingStart = Date()

    /// The words show only when the pill is wide enough for them.
    private func showsStatus(_ stretch: IslandStretch, width: CGFloat) -> Bool {
        switch stretch {
        case .compact: return false
        case .medium: return width >= 200
        case .wide: return width >= 290
        }
    }

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
            island(at: context.date)
        }
        // Stretches and shrinks with a springy bounce, like the real island.
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: mood)
        .onChange(of: mood) { oldMood, newMood in
            if newMood == .thinking && oldMood != .thinking { thinkingStart = Date() }
        }
        // Tilt the iPad and the orb leans with it.
        .rotation3DEffect(.degrees(Double(motion.tilt.height) * -10), axis: (x: 1, y: 0, z: 0))
        .rotation3DEffect(.degrees(Double(motion.tilt.width) * 10), axis: (x: 0, y: 1, z: 0))
        .offset(x: motion.tilt.width * 3, y: motion.tilt.height * -2)
        .onAppear { if !reduceMotion { motion.start() } }
        .onDisappear { motion.stop() }
        .onChange(of: reduceMotion) { _, reduce in if reduce { motion.stop() } else { motion.start() } }
        .onChange(of: scenePhase) { _, phase in
            guard !reduceMotion else { return }
            if phase == .active { motion.start() } else if phase == .background { motion.stop() }
        }
        .contentShape(Capsule(style: .continuous))
        .scaleEffect(holding ? 1.12 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: holding)
        // A quick tap opens Settings. Press and hold to talk, let go to send.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard pressStart == nil else { return }
                    pressStart = Date()
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        guard !Task.isCancelled, pressStart != nil else { return }
                        holding = true
                        onHold(true)
                    }
                }
                .onEnded { _ in
                    holdTask?.cancel()
                    holdTask = nil
                    pressStart = nil
                    if holding {
                        holding = false
                        onHold(false)
                    } else {
                        onTap()
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(focusText.map { "Ace, \(mood.label), \($0)" } ?? "Ace, \(mood.label)")
        .accessibilityHint("Double tap to open Settings. Use the Talk action to speak to Ace.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) { onTap() }
        .accessibilityAction(named: "Talk") {
            if holding { holding = false; onHold(false) } else { holding = true; onHold(true) }
        }
    }

    /// The island at one moment: the black pill and what's inside it.
    @ViewBuilder
    private func island(at date: Date) -> some View {
        let stretch = mood.stretch
        let width = stretch.width(fitting: maxExpandedWidth)
        let height = stretch.height
        ZStack {
            // The island itself: a solid black pill with a faint glow in Ace's color.
            Capsule(style: .continuous)
                .fill(Color.black)
                .overlay(Capsule(style: .continuous).stroke(mood.tint.opacity(stretch == .compact ? 0.22 : 0.45), lineWidth: 1))
                .shadow(color: mood.tint.opacity(stretch == .compact ? 0.2 : 0.45), radius: stretch == .compact ? 8 : 18)
            pillContent(at: date, stretch: stretch, width: width, height: height)
                .frame(width: width, height: height)
                // Everything stays inside the island, like the real one.
                .clipShape(Capsule(style: .continuous))
        }
        .frame(width: width, height: height)
    }

    /// The orb at the front end of the pill, then the eyes and words when there's room.
    @ViewBuilder
    private func pillContent(at date: Date, stretch: IslandStretch, width: CGFloat, height: CGFloat) -> some View {
        let orbSize = height - 10
        let statusWidth: CGFloat = stretch == .wide ? 140 : CGFloat.infinity
        HStack(spacing: stretch == .wide ? 12 : 10) {
            orbArea(at: date, size: orbSize)
            if stretch == .wide {
                OrbEyes(look: look, open: eyeOpen, happy: mood == .happy || mood == .home, color: mood.tint)
                    .frame(width: 96, height: height * 0.62)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
            if showsStatus(stretch, width: width) {
                Text(status)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.fg.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: statusWidth, alignment: .leading)
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
            if stretch == .compact {
                // A little camera lens at the far end, like the real island.
                Circle()
                    .fill(Color(white: 0.08))
                    .overlay(Circle().stroke(Color(white: 0.22), lineWidth: 1))
                    .frame(width: 9, height: 9)
                    .padding(.trailing, 6)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, (height - orbSize) / 2)
    }

    /// The orb. While Ace thinks, the thinking looks play around it (some behind, some on top).
    @ViewBuilder
    private func orbArea(at date: Date, size: CGFloat) -> some View {
        // Seconds since the orb appeared, so the numbers stay small and smooth.
        let t = date.timeIntervalSince(start) * (reduceMotion ? 0.35 : 1)
        let breathe: Double = (sin(t * speed) + 1) / 2
        let thinking = mood == .thinking
        let thinkTime = date.timeIntervalSince(thinkingStart)
        let focus = FocusSession.current.map { FocusSession.progress(of: $0, at: date) }
        ZStack {
            if thinking {
                ThinkingLayer(part: .back, time: thinkTime, reduceMotion: reduceMotion, orbSize: size, tint: mood.tint)
            }
            orb(breathe: breathe, t: t, focus: focus)
                .frame(width: size, height: size)
            if thinking {
                ThinkingLayer(part: .front, time: thinkTime, reduceMotion: reduceMotion, orbSize: size, tint: mood.tint)
            }
            if let outfit {
                OrbOutfitView(outfit: outfit, size: size)
            }
        }
        .frame(width: thinking ? ThinkingLayer.width(orbSize: size) : size, height: size)
    }

    /// "12 minutes of focus left" for VoiceOver.
    private var focusText: String? {
        guard let t = FocusSession.current else { return nil }
        let minutes = max(1, Int((t.end.timeIntervalSinceNow / 60).rounded(.up)))
        return "\(minutes) minute\(minutes == 1 ? "" : "s") of focus left"
    }

    @ViewBuilder
    private func orb(breathe: Double, t: TimeInterval, focus: Double?) -> some View {
        ZStack {
            if let focus {
                // A focus session fills this ring as the time goes by.
                Circle()
                    .stroke(Color(hex: 0x3DF59A).opacity(0.18), lineWidth: 3)
                    .scaleEffect(1.32)
                Circle()
                    .trim(from: 0, to: max(0.01, focus))
                    .stroke(Color(hex: 0x3DF59A), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(1.32)
            }
            if mood == .listening {
                ForEach(0..<3, id: \.self) { i in
                    let phase = (t * 0.9 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    Circle()
                        .stroke(mood.tint.opacity(0.6 * (1 - phase)), lineWidth: 2)
                        .scaleEffect(1 + phase * (0.9 + level * 0.8))
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
