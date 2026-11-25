import SwiftUI

/// Ace Typing: lessons from the home row up to whole sentences. Letters turn green or red as you go,
/// a speedometer shows your words a minute, and the next key glows on a big keyboard you can tap
/// (or use a real keyboard plugged into the iPad).
struct TypingView: View {
    static let lessonKey = "ace.typing.lesson"

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: TypingModel
    @FocusState private var keysFocused: Bool
    @State private var shown = false
    @State private var heatMap = false

    init(start: TypingLesson?) {
        let saved = UserDefaults.standard.string(forKey: Self.lessonKey).flatMap(TypingLesson.init(rawValue:))
        _model = StateObject(wrappedValue: TypingModel(lesson: start ?? saved ?? .homeRow))
    }

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                AceTheme.background.ignoresSafeArea()
                RadialGradient(colors: [AceTheme.ace.opacity(0.18), .clear], center: .bottom,
                               startRadius: 0, endRadius: geo.size.height * 0.7)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    topBar
                        .bounceReveal(shown, order: 0)
                    lessonChips
                        .bounceReveal(shown, order: 1)
                    if wide {
                        HStack(alignment: .top, spacing: 16) {
                            textCard(fontSize: 32)
                            VStack(spacing: 14) {
                                gauge.frame(width: 210, height: 210)
                                AccuracyRing(accuracy: model.run.accuracy, moves: moves)
                                    .frame(width: 112, height: 112)
                            }
                            .frame(width: 220)
                        }
                        .bounceReveal(shown, order: 2)
                    } else {
                        HStack(spacing: 24) {
                            gauge.frame(width: 190, height: 190)
                            AccuracyRing(accuracy: model.run.accuracy, moves: moves)
                                .frame(width: 112, height: 112)
                        }
                        .bounceReveal(shown, order: 2)
                        textCard(fontSize: 28)
                            .bounceReveal(shown, order: 3)
                    }
                    TypingKeyboard(next: model.result == nil ? model.nextKey : nil, shift: model.shift,
                                   misses: model.misses, heatMap: heatMap, keyHits: model.keyHits,
                                   moves: moves, tap: { model.tap($0) })
                        .frame(maxWidth: 980)
                        .frame(height: min(geo.size.height * (wide ? 0.38 : 0.3), 340))
                        .bounceReveal(shown, order: 4)
                }
                .padding(16)

                if let result = model.result {
                    TypingFinishCard(result: result, lesson: model.lesson, misses: model.misses, moves: moves,
                                     seed: model.keyHits.values.reduce(0, +),
                                     showMisses: {
                                         heatMap = true
                                         model.fresh()
                                     },
                                     next: { model.fresh() })
                        .transition(moves ? .scale(scale: 0.8).combined(with: .opacity) : .opacity)
                        .zIndex(2)
                }
            }
            .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion), value: model.result)
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .statusBarHidden()
        .focusable()
        .focused($keysFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: .down) { press in hardwareKey(press) }
        .onAppear {
            shown = true
            keysFocused = true
        }
        .onChange(of: model.lesson) { _, lesson in
            UserDefaults.standard.set(lesson.rawValue, forKey: Self.lessonKey)
        }
    }

    // MARK: Parts

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close typing practice") { dismiss() }
                .background(Circle().fill(.white.opacity(0.08)))
            VStack(alignment: .leading, spacing: 0) {
                Text("Typing")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(model.lesson.blurb)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if model.best > 0 {
                Label("Best \(model.best) wpm", systemImage: "trophy.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AceTheme.pebble)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(AceTheme.pebble.opacity(0.14)))
            }
            BouncyIconButton(symbol: heatMap ? "flame.fill" : "flame", label: heatMap ? "Hide missed keys" : "Show missed keys") {
                heatMap.toggle()
            }
            .background(Circle().fill(heatMap ? AceTheme.bad.opacity(0.25) : .white.opacity(0.08)))
            BouncyIconButton(symbol: "arrow.clockwise", label: "New text") { model.fresh() }
                .background(Circle().fill(.white.opacity(0.08)))
        }
    }

    private var lessonChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TypingLesson.allCases) { lesson in
                    let on = lesson == model.lesson
                    Button {
                        model.choose(lesson)
                        Haptics.shared.play(.pop)
                    } label: {
                        Label(lesson.title, systemImage: lesson.symbol)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(on ? .white : AceTheme.fg)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Capsule().fill(on ? AnyShapeStyle(LinearGradient(colors: [AceTheme.ace, AceTheme.accent],
                                                                                         startPoint: .leading, endPoint: .trailing))
                                                          : AnyShapeStyle(Color.white.opacity(0.07))))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(on ? 0 : 0.1)))
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var gauge: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            SpeedGauge(wpm: model.run.wordsPerMinute(at: context.date), best: model.best, moves: moves)
        }
    }

    private func textCard(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.styled(model.run, fontSize: fontSize))
                .lineSpacing(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(Shake(animatableData: CGFloat(model.shakes)))
                .animation(moves ? .linear(duration: 0.3) : nil, value: model.shakes)
                .accessibilityLabel("Type this: " + String(model.run.target))
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(LinearGradient(colors: [AceTheme.good, AceTheme.ace], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, bar.size.width * model.run.progress))
                            .animation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion), value: model.run.progress)
                    }
                }
                .frame(height: 8)
                Text(model.run.startedAt == nil ? "Start typing!" : "\(model.run.mistakes) \(model.run.mistakes == 1 ? "mistake" : "mistakes")")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(model.run.mistakes == 0 ? AceTheme.muted : AceTheme.bad)
                    .fixedSize()
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.08)))
        .contentShape(Rectangle())
        .onTapGesture { keysFocused = true }
    }

    /// The practice text with typed letters green (right) or red (wrong), and the next letter lit up.
    static func styled(_ run: TypingRun, fontSize: CGFloat) -> AttributedString {
        var out = AttributedString()
        for (i, ch) in run.target.enumerated() {
            var piece: AttributedString
            if i < run.position {
                let right = run.correct[i]
                // A missed space shows as a dot, so you can see it.
                piece = AttributedString(!right && ch == " " ? "·" : String(ch))
                piece.foregroundColor = right ? AceTheme.good : AceTheme.bad
                if !right { piece.backgroundColor = AceTheme.bad.opacity(0.22) }
            } else if i == run.position {
                piece = AttributedString(String(ch))
                piece.foregroundColor = .white
                piece.backgroundColor = AceTheme.ace.opacity(0.45)
                piece.underlineStyle = Text.LineStyle(pattern: .solid, color: AceTheme.ace)
            } else {
                piece = AttributedString(String(ch))
                piece.foregroundColor = AceTheme.muted
            }
            piece.font = .system(size: fontSize, weight: .medium, design: .monospaced)
            out += piece
        }
        return out
    }

    static func headline(_ result: TypingResult) -> String {
        switch result.stars {
        case 3: return "Amazing typing!"
        case 2: return "Great job!"
        default: return result.accuracy < 90 ? "Nice try! Slow down a little." : "Done! Keep practicing."
        }
    }

    /// One tip from how the run went: the key missed most, or what to work on for another star.
    static func tip(_ result: TypingResult, misses: [String: Int]) -> String? {
        if let worst = misses.max(by: { $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key) }), worst.value >= 2 {
            let name = worst.key == " " ? "the space bar" : "\"\(worst.key.uppercased())\""
            return "You missed \(name) \(worst.value) times. Turn on the flame to see all your missed keys."
        }
        if result.stars == 3 { return nil }
        if result.accuracy < 97 { return "Get 97% right for 3 stars. Accuracy first, speed comes later!" }
        return "Type a bit faster for the next star: 3 stars is 25 words a minute."
    }

    // MARK: Real keyboard

    private func hardwareKey(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            dismiss()
            return .handled
        }
        if model.result != nil {
            if press.key == .return || press.key == .space { model.fresh() }
            return .handled
        }
        if press.key == .delete {
            model.backspace()
            return .handled
        }
        // Only keys that type something you can see (arrow keys and the like are skipped).
        let chars = press.characters.filter(Self.typeable)
        guard !chars.isEmpty else { return .ignored }
        for c in chars { model.type(c) }
        return .handled
    }

    /// Plain printable characters and the iPad's curly quotes.
    static func typeable(_ c: Character) -> Bool {
        if "‘’“”".contains(c) { return true }
        guard let v = c.asciiValue else { return false }
        return v >= 0x20 && v < 0x7F
    }
}

/// The card at the end of a lesson: stars that pop in, your speed and accuracy, a tip, and confetti for a great run.
struct TypingFinishCard: View {
    let result: TypingResult
    let lesson: TypingLesson
    let misses: [String: Int]
    let moves: Bool
    let seed: Int
    let showMisses: () -> Void
    let next: () -> Void
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture {}
            if moves && (result.stars >= 2 || result.newBest) {
                TypingConfetti(seed: seed).ignoresSafeArea()
            }
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Image(systemName: i < result.stars ? "star.fill" : "star")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(i < result.stars ? AceTheme.pebble : AceTheme.muted.opacity(0.5))
                            .shadow(color: i < result.stars ? AceTheme.pebble.opacity(0.7) : .clear, radius: 10)
                            .scaleEffect(shown || !moves ? 1 : 0.2)
                            .rotationEffect(.degrees(shown || !moves ? 0 : -40))
                            .animation(moves ? .spring(response: 0.45, dampingFraction: 0.45).delay(0.15 + Double(i) * 0.18) : nil,
                                       value: shown)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(result.stars) of 3 stars")
                Text(TypingView.headline(result))
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                    .multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    stat("\(result.wpm)", "words a minute", AceTheme.ace)
                    stat("\(result.accuracy)%", "right", result.accuracy >= 95 ? AceTheme.good : AceTheme.warn)
                    stat("\(result.best)", "best", AceTheme.pebble)
                }
                .bounceReveal(shown, order: 2)
                if result.newBest {
                    Label("New best for \(lesson.title.lowercased())!", systemImage: "trophy.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AceTheme.pebble)
                        .bounceReveal(shown, order: 4)
                } else if result.firstTime {
                    Label("First score saved. Now beat it!", systemImage: "flag.checkered")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AceTheme.ace)
                        .bounceReveal(shown, order: 4)
                }
                if let tip = TypingView.tip(result, misses: misses) {
                    Text(tip)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 12) {
                    Button(action: showMisses) {
                        Label("Missed keys", systemImage: "flame.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(misses.isEmpty)
                    Button(action: next) {
                        Label("Next text", systemImage: "arrow.right").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
                .font(.system(.headline, design: .rounded))
            }
            .padding(28)
            .frame(maxWidth: 460)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x15132A)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white.opacity(0.12)))
            .shadow(color: AceTheme.accent.opacity(0.35), radius: 30)
            .padding(20)
        }
        .onAppear { shown = true }
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.06)))
    }
}
