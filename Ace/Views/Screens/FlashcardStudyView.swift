import SwiftUI

/// Studying flashcards full screen: tap the card to flip it, then say how well you knew it.
/// Missed cards come back a few cards later, and the end shows how you did.
struct FlashcardStudyView: View {
    /// One deck, or nil for every deck.
    let deckID: UUID?
    /// Practice doesn't change when cards come back (for when nothing is due).
    let practice: Bool

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FlashcardStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var queue = StudyQueue([])
    @State private var practicing = false
    @State private var started = false
    @State private var angle: Double = 0
    @State private var flips = 0
    @State private var finished = false
    @State private var cheer = 0

    private var flipped: Bool { angle >= 90 }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    private var title: String {
        store.deck(deckID)?.name ?? "All decks"
    }

    var body: some View {
        ZStack {
            AceTheme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                topBar
                if !started {
                    Spacer()
                } else if finished || queue.isDone {
                    doneView
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                } else if let item = queue.current, let card = store.card(item) {
                    studyCard(card, item: item)
                } else {
                    // The card was deleted while you studied: skip it.
                    Color.clear.onAppear { skipMissing() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 760)
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .onAppear(perform: start)
        .onDisappear {
            VoiceOut.shared.stop()
            store.refreshReminder()
        }
    }

    // MARK: Parts

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AceTheme.card))
                }
                .buttonStyle(BouncyButtonStyle(depth: 0.85))
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Stop studying")
                Spacer()
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                    if practicing {
                        Text("Practice")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AceTheme.accent)
                    }
                }
                Spacer()
                Text(finished || queue.isDone ? "" : "\(queue.left) left")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(AceTheme.muted)
                    .frame(width: 70, alignment: .trailing)
                    .contentTransition(.numericText())
            }
            ProgressView(value: finished ? 1 : queue.progress)
                .tint(AceTheme.ace)
                .animation(motion(.snappy), value: queue.progress)
        }
    }

    private func studyCard(_ card: Flashcard, item: StudyItem) -> some View {
        let speech = store.deck(item.deck)?.speech
        let deckName = store.deck(item.deck)?.name ?? ""
        return VStack(spacing: 18) {
            Spacer(minLength: 0)
            FlipCard(angle: angle, front: face(card.front, label: deckID == nil ? deckName : "Front", hint: "Tap to flip"),
                     back: back(card))
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .contentShape(Rectangle())
                .onTapGesture { flip() }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(flipped ? "Answer: \(card.back)" : "Question: \(card.front)")
                .accessibilityHint(flipped ? "" : "Double tap to see the answer")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { flip() }
                .id(item)
                .transition(cardTransition)
            Spacer(minLength: 0)
            if flipped {
                if let speech {
                    Button {
                        VoiceOut.shared.speak(card.back, language: speech)
                        Haptics.shared.play(.tick)
                    } label: {
                        Label("Say it", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                    }
                    .buttonStyle(.aceBouncy)
                    .keyboardShortcut("s", modifiers: [])
                }
                gradeButtons(card)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button {
                    flip()
                } label: {
                    Label("Show answer", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AceTheme.ace))
                        .foregroundStyle(Color.black.opacity(0.85))
                }
                .buttonStyle(.aceBouncy)
                .keyboardShortcut(.space, modifiers: [])
                .transition(.opacity)
            }
        }
    }

    private func face(_ text: String, label: String, hint: String) -> some View {
        CardFace(tint: AceTheme.ace) {
            VStack(spacing: 14) {
                Text(label.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AceTheme.muted)
                Spacer(minLength: 0)
                Text(text)
                    .font(.system(size: fontSize(text), weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
        }
    }

    private func back(_ card: Flashcard) -> some View {
        CardFace(tint: AceTheme.good) {
            VStack(spacing: 12) {
                Text("ANSWER")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AceTheme.muted)
                Spacer(minLength: 0)
                Text(card.back)
                    .font(.system(size: fontSize(card.back), weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                if let note = card.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }
                Spacer(minLength: 0)
                Text(card.front)
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(1)
            }
        }
    }

    private func fontSize(_ text: String) -> CGFloat {
        text.count < 20 ? 40 : text.count < 60 ? 30 : text.count < 140 ? 22 : 18
    }

    private func gradeButtons(_ card: Flashcard) -> some View {
        HStack(spacing: 10) {
            ForEach(FlashGrade.allCases) { grade in
                Button {
                    answer(grade)
                } label: {
                    VStack(spacing: 3) {
                        Text(grade.title)
                            .font(.headline)
                        Text(practicing ? "\(grade.rawValue + 1)" : SpacedRepetition.label(grade, for: card))
                            .font(.caption.monospacedDigit())
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color(grade).opacity(0.2)))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color(grade).opacity(0.5), lineWidth: 1))
                    .foregroundStyle(color(grade))
                }
                .buttonStyle(.aceBouncy)
                .keyboardShortcut(KeyEquivalent(Character("\(grade.rawValue + 1)")), modifiers: [])
                .accessibilityLabel(grade.title)
                .accessibilityHint(practicing ? "" : "Comes back in \(SpacedRepetition.label(grade, for: card))")
            }
        }
    }

    private func color(_ grade: FlashGrade) -> Color {
        switch grade {
        case .again: return AceTheme.bad
        case .hard: return AceTheme.warn
        case .good: return AceTheme.good
        case .easy: return AceTheme.ace
        }
    }

    private var cardTransition: AnyTransition {
        guard AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.85)).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var doneView: some View {
        let answered = queue.answered
        let right = queue.right
        let percent = answered == 0 ? 0 : Int((Double(right) / Double(answered) * 100).rounded())
        let missed = queue.missed.count
        return VStack(spacing: 18) {
            Spacer(minLength: 0)
            Image(systemName: queue.total == 0 ? "checkmark.seal.fill" : "party.popper.fill")
                .font(.system(size: 64))
                .foregroundStyle(queue.total == 0 ? AceTheme.good : AceTheme.amber)
                .symbolEffect(.bounce, value: cheer)
            Text(queue.total == 0 ? "Nothing to study" : "Nice work!")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(AceTheme.fg)
            if queue.total > 0 {
                HStack(spacing: 24) {
                    result("\(queue.total)", queue.total == 1 ? "card" : "cards", AceTheme.fg)
                    result("\(percent)%", "right first try", AceTheme.good)
                    result("\(missed)", "to keep working on", missed > 0 ? AceTheme.warn : AceTheme.muted)
                }
                .aceCard()
            }
            Text(endLine)
                .font(.subheadline)
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                if hasCards {
                    Button {
                        restart(practice: true)
                    } label: {
                        Label("Practice more", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func result(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
        }
    }

    private var hasCards: Bool {
        if let deckID { return !(store.deck(deckID)?.cards.isEmpty ?? true) }
        return store.cardCount > 0
    }

    private var endLine: String {
        let next = store.deck(deckID).map { [$0] } ?? store.decks
        let line = FlashcardSkill.nextLine(next.compactMap(\.nextDue).min(), now: Date())
        if queue.total == 0 { return hasCards ? "You're all caught up. " + line : "This deck has no cards yet." }
        if practicing { return "Practice doesn't change when cards come back. " + line }
        return line.isEmpty ? "See you next time!" : line
    }

    // MARK: Actions

    private func start() {
        guard !started else { return }
        practicing = practice
        queue = store.queue(deckID: deckID, practice: practice)
        // Nothing due? Practice instead of showing an empty screen.
        if queue.total == 0, !practice, hasCards {
            practicing = true
            queue = store.queue(deckID: deckID, practice: true)
        }
        withAnimation(motion(.gentle)) { started = true }
        if queue.total == 0 { finished = true }
    }

    private func restart(practice: Bool) {
        practicing = practice
        angle = 0
        withAnimation(motion(.bouncy)) {
            queue = store.queue(deckID: deckID, practice: practice)
            finished = queue.total == 0
        }
    }

    private func flip() {
        guard queue.current != nil else { return }
        Haptics.shared.play(.tick)
        flips += 1
        withAnimation(motion(.bouncy)) {
            angle = flipped ? 0 : 180
        }
    }

    private func answer(_ grade: FlashGrade) {
        guard let item = queue.current else { return }
        store.grade(item, grade, practice: practicing)
        Haptics.shared.play(grade.isRight ? .pop : .blink)
        VoiceOut.shared.stop()
        // The next card starts face up, without a backwards flip.
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { angle = 0 }
        withAnimation(motion(.bouncy)) {
            queue.answer(grade)
            if queue.isDone { finished = true }
        }
        if queue.isDone {
            cheer += 1
            Haptics.shared.play(.success)
            store.refreshReminder()
        }
    }

    private func skipMissing() {
        queue.answer(.good)
        if queue.isDone { finished = true }
    }
}

/// A card that turns over in 3D. Past halfway it shows the back (drawn the right way round).
struct FlipCard<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let showBack = angle >= 90
        ZStack {
            front
                .opacity(showBack ? 0 : 1)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

/// The big rounded card a flashcard is drawn on.
struct CardFace<Content: View>: View {
    var tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.16), AceTheme.ink], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: tint.opacity(0.18), radius: 18, y: 8)
    }
}
