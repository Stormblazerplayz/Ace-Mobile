import SwiftUI

/// What opens breathing practice (see `AceCore.breatheScreen`).
struct BreatheScreen: Identifiable {
    let id = UUID()
    var pattern: BreathPattern?
}

/// Ace Breathe: a glowing circle to breathe along with. It grows as you breathe in and shrinks
/// as you breathe out, with a ring for each step, sparkles that drift with your breath, and a
/// count of your minutes and days in a row.
struct BreatheView: View {
    static let minuteChoices = [1, 2, 3, 5]

    enum Stage: Equatable {
        case setup
        case running
        case done(seconds: Double)
    }

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @AppStorage("ace.breathe.pattern") private var savedPattern = BreathPattern.calm.rawValue
    @AppStorage("ace.breathe.minutes") private var minutes = 2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pattern: BreathPattern = .calm
    @State private var stage: Stage = .setup
    @State private var session = BreathSession(pattern: .calm, minutes: 2)
    /// When the session started, moved forward by however long it was paused.
    @State private var startedAt = Date()
    @State private var pausedAt: Date?
    @State private var shown = false
    let start: BreathPattern?
    private let log = BreathLog.shared

    init(start: BreathPattern?) {
        self.start = start
    }

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private var isDone: Bool {
        if case .done = stage { return true }
        return false
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: pausedAt != nil || isDone)) { timeline in
            let now = pausedAt ?? timeline.date
            let moment = stage == .running ? session.moment(at: now.timeIntervalSince(startedAt))
                                           : BreathSession.idle(at: timeline.date)
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height
                let orbSide = min(geo.size.width * (wide ? 0.5 : 0.82), geo.size.height * (wide ? 0.62 : 0.48))
                ZStack {
                    background(moment.step.color)
                    VStack(spacing: 16) {
                        topBar
                            .bounceReveal(shown, order: 0)
                        Spacer(minLength: 0)
                        ZStack {
                            if moves {
                                BreathSparkles(fullness: moment.fullness, color: moment.step.color,
                                               time: timeline.date.timeIntervalSinceReferenceDate)
                                    .frame(width: orbSide * 1.25, height: orbSide * 1.25)
                            }
                            BreatheOrb(fullness: moment.fullness, color: moment.step.color, reduceMotion: reduceMotion)
                                .frame(width: orbSide, height: orbSide)
                            if stage == .running {
                                BreathRing(pattern: session.pattern, cycleProgress: moment.cycleProgress, activeStep: moment.stepIndex)
                                    .frame(width: orbSide * 0.92, height: orbSide * 0.92)
                                    .transition(.opacity)
                                stepLabel(moment)
                            }
                        }
                        .frame(width: orbSide * 1.25, height: orbSide * 1.25)
                        .animation(.easeInOut(duration: 0.8), value: moment.step)
                        Spacer(minLength: 0)
                        bottom(moment)
                            .frame(maxWidth: 720)
                            .bounceReveal(shown, order: 1)
                    }
                    .padding(20)

                    if case .done(let seconds) = stage {
                        BreatheDoneCard(pattern: session.pattern, seconds: seconds, log: log, moves: moves,
                                        again: begin, close: { dismiss() })
                            .transition(moves ? .scale(scale: 0.85).combined(with: .opacity) : .opacity)
                    }
                }
            }
            .onChange(of: moment.stepIndex + moment.breath * 10) { _, _ in
                if stage == .running { Haptics.shared.play(moment.step == .breatheIn ? .pop : .tick) }
            }
            .onChange(of: moment.finished) { _, finished in
                if finished && stage == .running { finish(seconds: session.length) }
            }
        }
        .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion), value: stage)
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .statusBarHidden()
        .onAppear {
            pattern = start ?? BreathPattern(rawValue: savedPattern) ?? .calm
            if !Self.minuteChoices.contains(minutes) { minutes = 2 }
            session = BreathSession(pattern: pattern, minutes: minutes)
            shown = true
            // Asking for a pattern by name starts it right away.
            if start != nil { begin() }
        }
    }

    // MARK: Parts

    private func background(_ color: Color) -> some View {
        ZStack {
            AceTheme.background
            RadialGradient(colors: [color.opacity(0.28), .clear], center: .center, startRadius: 0, endRadius: 600)
                .animation(.easeInOut(duration: 1.2), value: color)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close breathing") { close() }
                .background(Circle().fill(.white.opacity(0.08)))
            VStack(alignment: .leading, spacing: 0) {
                Text("Breathe")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(stage == .running ? "\(session.pattern.title) breathing" : "Breathe along with the circle")
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 8)
            let streak = log.streak()
            if streak > 0 {
                Label("\(streak) \(streak == 1 ? "day" : "days")", systemImage: "flame.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AceTheme.amber)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(AceTheme.amber.opacity(0.14)))
                    .accessibilityLabel("\(streak) days in a row")
            }
        }
    }

    private func stepLabel(_ moment: BreathMoment) -> some View {
        VStack(spacing: 4) {
            Text(moment.step.words)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
                .contentTransition(.opacity)
            Text("\(moment.secondsLeft)")
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.4), radius: 6)
                .contentTransition(.numericText(countsDown: true))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(moment.step.words), \(moment.secondsLeft)")
    }

    @ViewBuilder
    private func bottom(_ moment: BreathMoment) -> some View {
        if stage == .running {
            VStack(spacing: 14) {
                Text("Breath \(min(moment.breath + 1, session.breaths)) of \(session.breaths)")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                HStack(spacing: 12) {
                    Button { pauseOrResume() } label: {
                        Label(pausedAt == nil ? "Pause" : "Keep going", systemImage: pausedAt == nil ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button { stopEarly() } label: {
                        Label("Finish", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
                .font(.system(.headline, design: .rounded))
            }
        } else if stage == .setup {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(BreathPattern.allCases) { p in
                        patternCard(p)
                    }
                }
                Text(pattern.blurb)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 40)
                HStack(spacing: 8) {
                    ForEach(Self.minuteChoices, id: \.self) { m in
                        let on = m == minutes
                        Button {
                            minutes = m
                            Haptics.shared.play(.tick)
                        } label: {
                            Text("\(m) min")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(on ? .white : AceTheme.fg)
                                .padding(.horizontal, 16).padding(.vertical, 9)
                                .background(Capsule().fill(on ? AceTheme.accent : Color.white.opacity(0.07)))
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                Button { begin() } label: {
                    Label("Start", systemImage: "wind")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .frame(maxWidth: 320)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private func patternCard(_ p: BreathPattern) -> some View {
        let on = p == pattern
        return Button {
            pattern = p
            savedPattern = p.rawValue
            Haptics.shared.play(.pop)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: p.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .symbolEffect(.bounce, value: moves && on)
                Text(p.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Text(p.steps.map { String(Int($0.seconds)) }.joined(separator: "-"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(on ? .white.opacity(0.8) : AceTheme.muted)
            }
            .foregroundStyle(on ? .white : AceTheme.fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(on ? AnyShapeStyle(LinearGradient(colors: [AceTheme.ace, AceTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                         : AnyShapeStyle(Color.white.opacity(0.06))))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(on ? 0 : 0.1)))
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel("\(p.title) breathing")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: Actions

    private func begin() {
        session = BreathSession(pattern: pattern, minutes: minutes)
        startedAt = Date()
        pausedAt = nil
        stage = .running
        Haptics.shared.play(.pop)
    }

    private func pauseOrResume() {
        if let paused = pausedAt {
            startedAt = startedAt.addingTimeInterval(Date().timeIntervalSince(paused))
            pausedAt = nil
        } else {
            pausedAt = Date()
        }
    }

    private func stopEarly() {
        let elapsed = (pausedAt ?? Date()).timeIntervalSince(startedAt)
        finish(seconds: min(elapsed, session.length))
    }

    private func finish(seconds: Double) {
        log.add(seconds: seconds)
        pausedAt = nil
        stage = .done(seconds: seconds)
        Haptics.shared.play(.success)
    }

    /// Closing in the middle still counts the time you breathed.
    private func close() {
        if stage == .running { log.add(seconds: min((pausedAt ?? Date()).timeIntervalSince(startedAt), session.length)) }
        dismiss()
    }
}

extension BreathSession {
    /// The orb's slow idle breath on the setup screen: a calm 4 in, 6 out.
    static func idle(at date: Date) -> BreathMoment {
        let s = BreathSession(pattern: .calm, minutes: 60)
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: s.pattern.cycle)
        let m = s.moment(at: t)
        return BreathMoment(breath: 0, stepIndex: m.stepIndex, step: m.step, progress: m.progress, secondsLeft: m.secondsLeft,
                            cycleProgress: m.cycleProgress, fullness: 0.25 + 0.5 * m.fullness, finished: false)
    }
}

/// The card at the end: how long you breathed, today's minutes, and your days in a row.
struct BreatheDoneCard: View {
    let pattern: BreathPattern
    let seconds: Double
    let log: BreathLog
    let moves: Bool
    let again: () -> Void
    let close: () -> Void
    @State private var shown = false

    static func length(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s) seconds" }
        let m = s / 60, r = s % 60
        let mins = "\(m) \(m == 1 ? "minute" : "minutes")"
        return r == 0 ? mins : "\(mins) \(r) seconds"
    }

    var body: some View {
        let streak = log.streak()
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {}
            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [AceTheme.ace, AceTheme.good], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(shown || !moves ? 1 : 0.3)
                    .animation(moves ? .spring(response: 0.5, dampingFraction: 0.5) : nil, value: shown)
                Text("Nice breathing!")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text("\(Self.length(seconds)) of \(pattern.title.lowercased()) breathing.")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                HStack(spacing: 12) {
                    stat("\(log.minutes())", "min today", AceTheme.ace)
                    stat("\(streak)", streak == 1 ? "day in a row" : "days in a row", AceTheme.amber)
                    stat("\(log.totalMinutes)", "min in all", AceTheme.good)
                }
                .bounceReveal(shown, order: 2)
                HStack(spacing: 12) {
                    Button(action: again) {
                        Label("Again", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button(action: close) {
                        Label("Done", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
                .font(.system(.headline, design: .rounded))
            }
            .padding(28)
            .frame(maxWidth: 440)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x12142A)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white.opacity(0.12)))
            .shadow(color: AceTheme.good.opacity(0.3), radius: 30)
            .padding(20)
        }
        .onAppear { shown = true }
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.06)))
    }
}
