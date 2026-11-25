import SwiftUI

/// One study session: a stack of cards. Tap a card to flip it, then swipe right if you knew it
/// or left to see it again. Cards you miss come back at the end until you get them.
struct StudySessionView: View {
    let deck: StudyDeck
    @ObservedObject var store: StudyStore
    /// Practice runs through cards without moving them between boxes (for decks with nothing due).
    var practice = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var queue: [StudyCard] = []
    @State private var total = 0
    @State private var cleared = 0
    @State private var missed: Set<String> = []
    @State private var flipped = false
    @State private var drag: CGSize = .zero
    @State private var leaving = false
    @State private var loaded = false
    @State private var finished = false
    @State private var answers = 0

    /// How far you drag a card before letting go counts as an answer.
    static let swipeDistance: CGFloat = 120

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            StudyBackdrop(colors: deck.colors.map { Color(hex: $0) } + [AceTheme.accent])
            VStack(spacing: 0) {
                topBar
                if finished {
                    StudyDoneView(deck: deck, total: total, firstTry: total - missed.count,
                                  streak: store.currentStreak(), practice: isPractice,
                                  again: restart, close: { dismiss() })
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                } else if loaded && queue.isEmpty {
                    caughtUp
                        .transition(.opacity)
                } else {
                    cardStack
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                    buttons
                        .padding(.bottom, 26)
                }
            }
            .frame(maxWidth: 720)
            if finished {
                StudyConfetti(colors: deck.colors.map { Color(hex: $0) } + [AceTheme.pebble, AceTheme.good, AceTheme.nova])
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: load)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 14) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
                .tint(.white)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(isPractice ? String("\(deck.name) practice") : deck.name, systemImage: deck.symbol)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(total == 0 ? String("") : String("\(cleared) of \(total)"))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.14))
                        Capsule()
                            .fill(deck.gradient)
                            .frame(width: max(10, geo.size.width * (total == 0 ? 0 : CGFloat(cleared) / CGFloat(total))))
                            .shadow(color: deck.tint.opacity(0.7), radius: 6)
                    }
                }
                .frame(height: 10)
                .animation(motion(.bouncy), value: cleared)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var cardStack: some View {
        let pull = min(1, abs(drag.width) / Self.swipeDistance)
        return ZStack {
            // The next two cards peek out from behind, and step forward as you drag the top one away.
            ForEach(Array(queue.prefix(3).enumerated().reversed()), id: \.element.id) { i, card in
                if i == 0 {
                    topCard(card)
                } else {
                    let depth = CGFloat(i) - (moving ? pull : 0)
                    StudyFlipCard(card: card, deck: deck, angle: 0)
                        .scaleEffect(1 - depth * 0.06)
                        .offset(y: depth * 22)
                        .brightness(-Double(depth) * 0.12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func topCard(_ card: StudyCard) -> some View {
        let right = max(0, min(1, drag.width / Self.swipeDistance))
        let left = max(0, min(1, -drag.width / Self.swipeDistance))
        return StudyFlipCard(card: card, deck: deck, angle: flipped ? 180 : 0)
            .overlay(alignment: .topLeading) {
                SwipeStamp(text: "Got it", symbol: "checkmark", color: AceTheme.good, tilt: -12)
                    .opacity(right)
                    .padding(30)
            }
            .overlay(alignment: .topTrailing) {
                SwipeStamp(text: "Again", symbol: "arrow.uturn.left", color: AceTheme.bad, tilt: 12)
                    .opacity(left)
                    .padding(30)
            }
            .shadow(color: (drag.width > 0 ? AceTheme.good : drag.width < 0 ? AceTheme.bad : deck.tint).opacity(0.35 + 0.3 * max(left, right)),
                    radius: 26, y: 14)
            .offset(x: drag.width, y: moving ? drag.height * 0.25 : 0)
            .rotationEffect(.degrees(moving ? Double(drag.width) / 18 : 0), anchor: .bottom)
            .id(card.id)
            .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity), removal: .identity))
            .onTapGesture(perform: flip)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !leaving else { return }
                        drag = value.translation
                    }
                    .onEnded { value in
                        guard !leaving else { return }
                        let x = value.translation.width
                        let flung = value.predictedEndTranslation.width
                        if x > Self.swipeDistance || flung > Self.swipeDistance * 2 {
                            answer(knew: true)
                        } else if x < -Self.swipeDistance || flung < -Self.swipeDistance * 2 {
                            answer(knew: false)
                        } else {
                            withAnimation(motion(.pop)) { drag = .zero }
                        }
                    }
            )
            .accessibilityAction(named: "I knew it") { answer(knew: true) }
            .accessibilityAction(named: "Show it again") { answer(knew: false) }
    }

    private var buttons: some View {
        HStack(spacing: 18) {
            answerButton("Again", symbol: "arrow.uturn.left", color: AceTheme.bad) { answer(knew: false) }
            Button(action: flip) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 74, height: 74)
                    .background(deck.gradient, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1.5))
                    .shadow(color: deck.tint.opacity(0.6), radius: 14, y: 6)
                    .rotationEffect(.degrees(flipped ? 180 : 0))
                    .animation(motion(.pop), value: flipped)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.86))
            .accessibilityLabel(flipped ? "Show the question" : "Show the answer")
            answerButton("Got it", symbol: "checkmark", color: AceTheme.good) { answer(knew: true) }
        }
        .disabled(queue.isEmpty || leaving)
    }

    private func answerButton(_ title: String, symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 150, height: 58)
                .background(color.gradient, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                .shadow(color: color.opacity(0.5), radius: 12, y: 6)
        }
        .buttonStyle(.aceBouncy)
    }

    private var caughtUp: some View {
        VStack(spacing: 18) {
            Spacer()
            OrbStill(mood: .happy)
                .frame(width: 110, height: 110)
                .boing(on: loaded)
            Text("All caught up!")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(nextDueText)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Button {
                withAnimation(motion(.bouncy)) { loadPractice() }
            } label: {
                Label("Practice anyway", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .frame(height: 54)
                    .background(deck.gradient, in: Capsule())
                    .shadow(color: deck.tint.opacity(0.5), radius: 12, y: 6)
            }
            .buttonStyle(.aceBouncy)
            .padding(.top, 8)
            Spacer()
        }
        .padding(30)
    }

    private var nextDueText: String {
        let next = deck.cards.compactMap { store.progress[$0.id]?.due }.filter { $0 > Date() }.min()
        guard let next else { return "Nothing in \(deck.name) is waiting for you." }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return "The next \(deck.name) card comes back \(f.localizedString(for: next, relativeTo: Date()))."
    }

    // MARK: Doing things

    private func load() {
        guard !loaded else { return }
        let cards = practice ? Array(deck.cards.shuffled().prefix(StudyStore.sessionSize)) : store.session(for: deck)
        queue = cards
        total = cards.count
        loaded = true
    }

    /// Practice with a handful of cards from a deck that has nothing due.
    private func loadPractice() {
        let cards = Array(deck.cards.shuffled().prefix(10))
        practiceMode = true
        queue = cards
        total = cards.count
        cleared = 0
        missed = []
    }

    @State private var practiceMode = false

    private var isPractice: Bool { practice || practiceMode }

    private func restart() {
        withAnimation(motion(.bouncy)) {
            finished = false
            cleared = 0
            missed = []
            flipped = false
            drag = .zero
            if isPractice {
                queue = Array(deck.cards.shuffled().prefix(10))
            } else {
                queue = store.session(for: deck)
            }
            total = queue.count
        }
    }

    private func flip() {
        guard !queue.isEmpty, !leaving else { return }
        Haptics.shared.play(.tick)
        let anim: Animation? = moving ? Animation.spring(response: 0.5, dampingFraction: 0.72) : motion(.snappy)
        withAnimation(anim) {
            flipped.toggle()
        }
    }

    /// Answers the top card: it flies off to the right (knew it) or the left (again).
    private func answer(knew: Bool) {
        guard let card = queue.first, !leaving else { return }
        leaving = true
        if !isPractice { store.grade(card, knew: knew) }
        if !knew { missed.insert(card.id) }
        Haptics.shared.play(knew ? .pop : .tick)
        answers += 1

        let finish = {
            var q = queue
            q.removeFirst()
            if knew {
                cleared += 1
            } else {
                q.append(card)
            }
            withAnimation(motion(.bouncy)) {
                queue = q
                flipped = false
                drag = .zero
                if q.isEmpty {
                    finished = true
                }
            }
            leaving = false
            if q.isEmpty {
                Haptics.shared.play(.success)
                SoundFX.shared.play(.success)
            }
        }

        guard moving else {
            finish()
            return
        }
        withAnimation(.easeIn(duration: 0.22)) {
            drag = CGSize(width: knew ? 900 : -900, height: drag.height + 60)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(230))
            finish()
        }
    }
}

/// The end of a session: a ring that fills up, how you did and your streak, with confetti.
struct StudyDoneView: View {
    let deck: StudyDeck
    let total: Int
    let firstTry: Int
    let streak: Int
    let practice: Bool
    let again: () -> Void
    let close: () -> Void
    @State private var shown = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                ProgressRing(progress: shown ? 1 : 0, colors: deck.colors.map { Color(hex: $0) }, lineWidth: 16)
                    .frame(width: 170, height: 170)
                OrbStill(mood: .happy)
                    .frame(width: 96, height: 96)
                    .boing(on: shown, scale: 1.18)
            }
            .bounceReveal(shown)
            Text(firstTry == total ? "Perfect round!" : "Deck done!")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .bounceReveal(shown, order: 2)
            HStack(spacing: 14) {
                stat("\(firstTry)", "first try", "bolt.fill", AceTheme.pebble)
                stat("\(total - firstTry)", "practiced again", "arrow.uturn.left", AceTheme.nova)
                if !practice {
                    stat("\(streak)", streak == 1 ? "day streak" : "days in a row", "flame.fill", AceTheme.amber)
                }
            }
            .bounceReveal(shown, order: 4)
            HStack(spacing: 14) {
                Button(action: again) {
                    Label("Go again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 54)
                        .background(.white.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.aceBouncy)
                Button(action: close) {
                    Label("Done", systemImage: "checkmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .frame(height: 54)
                        .background(deck.gradient, in: Capsule())
                        .shadow(color: deck.tint.opacity(0.5), radius: 12, y: 6)
                }
                .buttonStyle(.aceBouncy)
            }
            .bounceReveal(shown, order: 6)
            Spacer()
        }
        .padding(30)
        .onAppear { shown = true }
    }

    private func stat(_ value: String, _ label: String, _ symbol: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(width: 130, height: 120)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.15), lineWidth: 1))
    }
}
