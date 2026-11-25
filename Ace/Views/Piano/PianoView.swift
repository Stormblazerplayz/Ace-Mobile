import SwiftUI

/// Ace Piano: a full-screen piano with a glowing keyboard, falling-note songs, and lessons
/// that wait for you to press the right key.
struct PianoView: View {
    let start: PianoStart
    @EnvironmentObject var core: AceCore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @AppStorage("pianoSound") private var soundName = PianoSound.grand.rawValue
    @AppStorage("pianoLabels") private var labels = true
    @StateObject private var model = PianoModel()
    @State private var showSongs = false
    @State private var shown = false

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }
    private var sound: PianoSound { PianoSound(rawValue: soundName) ?? .grand }

    var body: some View {
        GeometryReader { geo in
            let keysHeight = min(320, max(180, geo.size.height * 0.36))
            ZStack {
                Color(hex: 0x07060E).ignoresSafeArea()
                PianoGlow(hues: model.glowHues, moves: moves)
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .bounceReveal(shown, order: 0)
                    songBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    PianoStage(model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    PianoKeyboard(model: model, labels: labels)
                        .frame(height: keysHeight)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 6)
                        .background(
                            LinearGradient(colors: [Color(hex: 0x1B1830), Color(hex: 0x0B0A14)], startPoint: .top, endPoint: .bottom)
                                .overlay(alignment: .top) {
                                    // The felt strip above the keys, lit by whatever is playing.
                                    Rectangle()
                                        .fill(LinearGradient(colors: [Color(hue: model.glowHues.first ?? 0.6, saturation: 0.8, brightness: 0.9).opacity(0.85),
                                                                      Color(hex: 0x5A1730)],
                                                             startPoint: .leading, endPoint: .trailing))
                                        .frame(height: 5)
                                }
                        )
                        .offset(y: shown || !moves ? 0 : keysHeight)
                }
                if let finish = model.finish {
                    PianoFinishCard(finish: finish, moves: moves,
                                    again: { model.learn(finish.song) },
                                    next: { nextSong(after: finish.song) },
                                    freePlay: { model.freePlay() })
                        .transition(moves ? .scale(scale: 0.8).combined(with: .opacity) : .opacity)
                        .zIndex(2)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .sheet(isPresented: $showSongs) {
            PianoSongsSheet(progress: model.progress,
                            learn: { song in showSongs = false; model.learn(song) },
                            listen: { song in showSongs = false; model.listen(song) })
        }
        .onAppear {
            model.moves = moves
            model.onLessonDone = { song, stars, newBest in core.pianoLessonDone(song, stars: stars, newBest: newBest) }
            PianoSynth.shared.sound = sound
            PianoSynth.shared.start()
            model.open(start)
            if start == .songs { showSongs = true }
            withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) { shown = true }
        }
        .onDisappear {
            model.close()
            PianoSynth.shared.stop()
        }
        .onChange(of: soundName) { _, _ in PianoSynth.shared.sound = sound }
        .onChange(of: moves) { _, now in model.moves = now }
        // A voice call takes over the audio, so the piano closes.
        .onChange(of: core.call.isLive) { _, live in if live { dismiss() } }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            BouncyIconButton(symbol: "xmark", label: "Close the piano") { dismiss() }
            VStack(alignment: .leading, spacing: 1) {
                Text("Ace Piano")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if case .free = model.mode {
                HStack(spacing: 2) {
                    BouncyIconButton(symbol: "chevron.left", label: "Lower octave") { model.shiftOctave(-1) }
                        .disabled(model.freeLow <= 36)
                        .opacity(model.freeLow <= 36 ? 0.4 : 1)
                    Text(PianoTheory.name(model.freeLow) + "–" + PianoTheory.name(model.freeLow + 24))
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(AceTheme.fg)
                        .frame(minWidth: 64)
                        .accessibilityLabel("Keys from \(PianoTheory.name(model.freeLow)) to \(PianoTheory.name(model.freeLow + 24))")
                    BouncyIconButton(symbol: "chevron.right", label: "Higher octave") { model.shiftOctave(1) }
                        .disabled(model.freeLow >= 72)
                        .opacity(model.freeLow >= 72 ? 0.4 : 1)
                }
                .padding(.horizontal, 4)
                .background(Capsule().fill(.white.opacity(0.07)))
            }
            Menu {
                Picker("Sound", selection: $soundName) {
                    ForEach(PianoSound.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s.rawValue)
                    }
                }
                Toggle(isOn: $labels) { Label("Note names", systemImage: "textformat") }
            } label: {
                Label(sound.rawValue, systemImage: sound.symbol)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.09)))
                    .foregroundStyle(AceTheme.fg)
            }
            .accessibilityLabel("Sound: \(sound.rawValue)")
            Button {
                Haptics.shared.play(.pop)
                showSongs = true
            } label: {
                Label("Songs", systemImage: "music.note.list")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AceTheme.ace))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.aceBouncy)
        }
    }

    private var subtitle: String {
        switch model.mode {
        case .free: return "Free play. Use lots of fingers!"
        case .learn(let l): return l.done ? "You did it!" : "Learning \(l.song.title)"
        case .listen(let s): return model.listenDone ? "That was \(s.title)" : "Ace is playing \(s.title)"
        }
    }

    // MARK: Song bar

    @ViewBuilder
    private var songBar: some View {
        switch model.mode {
        case .free:
            EmptyView()
        case .learn(let lesson):
            HStack(spacing: 12) {
                ProgressView(value: lesson.progress)
                    .tint(AceTheme.good)
                    .animation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion), value: lesson.progress)
                Text("\(lesson.index)/\(lesson.song.notes.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(AceTheme.fg)
                if lesson.mistakes > 0 {
                    Label("\(lesson.mistakes)", systemImage: "xmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AceTheme.bad)
                        .accessibilityLabel("\(lesson.mistakes) wrong notes")
                }
                smallButton("Listen", symbol: "ear") { model.listen(lesson.song) }
                smallButton("Restart", symbol: "arrow.counterclockwise") { model.learn(lesson.song) }
                smallButton("Free play", symbol: "pianokeys") { model.freePlay() }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
        case .listen(let song):
            HStack(spacing: 12) {
                TimelineView(.periodic(from: .now, by: 0.25)) { t in
                    ProgressView(value: min(1, max(0, model.beat(at: t.date) / max(1, song.beats))))
                        .tint(AceTheme.ace)
                }
                if model.listenDone {
                    smallButton("Learn it", symbol: "graduationcap.fill", prominent: true) { model.learn(song) }
                    smallButton("Again", symbol: "play.fill") { model.listen(song) }
                } else {
                    smallButton("Stop", symbol: "stop.fill") { model.freePlay() }
                }
                smallButton("Free play", symbol: "pianokeys") { model.freePlay() }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
        }
    }

    private func smallButton(_ title: String, symbol: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tick)
            action()
        } label: {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(prominent ? AceTheme.good : .white.opacity(0.1)))
                .foregroundStyle(prominent ? .black : AceTheme.fg)
        }
        .buttonStyle(.aceBouncy)
    }

    private func nextSong(after song: PianoSong) {
        let all = PianoSongs.all
        guard let i = all.firstIndex(of: song) else { return model.freePlay() }
        model.learn(all[(i + 1) % all.count])
    }
}

/// The end of a lesson: stars pop in one by one, with confetti when it moves.
struct PianoFinishCard: View {
    let finish: PianoModel.Finish
    let moves: Bool
    let again: () -> Void
    let next: () -> Void
    let freePlay: () -> Void
    @State private var lit = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            if moves && finish.stars == 3 {
                PianoConfetti()
            }
            VStack(spacing: 16) {
                Text(finish.stars == 3 ? "Perfect!" : finish.stars == 2 ? "Great playing!" : "You made it!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text("You played \(finish.song.title).")
                    .font(.headline)
                    .foregroundStyle(AceTheme.muted)
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < lit ? "star.fill" : "star")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(i < lit ? AceTheme.pebble : .white.opacity(0.25))
                            .shadow(color: i < lit ? AceTheme.pebble.opacity(0.8) : .clear, radius: 14)
                            .scaleEffect(i < lit && moves ? 1 : (moves ? 0.7 : 1))
                            .rotationEffect(.degrees(i < lit || !moves ? 0 : -30))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(finish.stars) out of 3 stars")
                HStack(spacing: 18) {
                    stat("\(Int((finish.accuracy * 100).rounded()))%", "right")
                    stat("\(finish.mistakes)", finish.mistakes == 1 ? "wrong note" : "wrong notes")
                    stat("\(finish.song.notes.count)", "notes")
                }
                if finish.newBest {
                    Text("New best!")
                        .font(.subheadline.weight(.heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AceTheme.good))
                        .foregroundStyle(.black)
                }
                HStack(spacing: 10) {
                    button("Again", "arrow.counterclockwise", action: again)
                    button("Next song", "forward.fill", prominent: true, action: next)
                    button("Free play", "pianokeys", action: freePlay)
                }
                .padding(.top, 4)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x17152A)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 30, y: 12)
            .padding(24)
        }
        .onAppear(perform: popStars)
    }

    private func popStars() {
        guard moves else {
            lit = finish.stars
            return
        }
        for i in 0..<finish.stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.32) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.45)) { lit = i + 1 }
                Haptics.shared.play(.pop)
            }
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.monospacedDigit().weight(.heavy))
                .foregroundStyle(AceTheme.fg)
            Text(label)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private func button(_ title: String, _ symbol: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(prominent ? AceTheme.ace : .white.opacity(0.1)))
                .foregroundStyle(prominent ? .black : AceTheme.fg)
        }
        .buttonStyle(.aceBouncy)
    }
}

/// Colored paper falling for a perfect lesson.
struct PianoConfetti: View {
    private struct Piece {
        let x: Double, speed: Double, spin: Double, hue: Double, size: Double, delay: Double
    }

    @State private var born = Date()
    private let pieces: [Piece] = (0..<70).map { _ in
        Piece(x: .random(in: 0...1), speed: .random(in: 0.25...0.55), spin: .random(in: -6...6),
              hue: .random(in: 0...1), size: .random(in: 6...12), delay: .random(in: 0...0.8))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let age = timeline.date.timeIntervalSince(born)
                for p in pieces {
                    let t = age - p.delay
                    guard t > 0 else { continue }
                    let y = -20 + CGFloat(t * p.speed) * size.height
                    guard y < size.height + 20 else { continue }
                    let x = CGFloat(p.x) * size.width + CGFloat(sin(t * 3 + p.spin) * 18)
                    let s = CGFloat(p.size)
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(t * p.spin))
                    c.fill(Path(CGRect(x: -s / 2, y: -s / 4, width: s, height: s / 2)),
                           with: .color(Color(hue: p.hue, saturation: 0.75, brightness: 1)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
