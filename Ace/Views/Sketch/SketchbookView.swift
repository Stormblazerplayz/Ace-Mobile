import SwiftUI
import UIKit

/// The sketchbook: today's drawing challenge up top (with a timer if you want one), your
/// stats, and every sketch as a tilted card on a glowing, drifting backdrop. Tap a card to keep
/// drawing, or press and hold it to rename, copy or delete it.
struct SketchbookView: View {
    @ObservedObject private var store = SketchStore.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var prompt = SketchPrompts.daily()
    @State private var isDaily = true
    @State private var challenge: SketchChallenge = .off
    @State private var paper: SketchPaper = .midnight
    @State private var open: OpenSketch?
    @State private var renaming: Sketch?
    @State private var newTitle = ""
    @State private var deleting: Sketch?
    @State private var shuffles = 0

    /// A sketch being drawn in the editor.
    struct OpenSketch: Identifiable {
        let id: UUID
        let isNew: Bool
        let challenge: SketchChallenge
    }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SketchAurora()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        challengeCard
                            .bounceReveal(shown)
                        stats
                            .bounceReveal(shown, order: 1)
                        HStack {
                            Text("Your sketches")
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                startDrawing(prompt: nil)
                            } label: {
                                Label("Blank page", systemImage: "plus")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .frame(height: 40)
                                    .background(Color.white.opacity(0.1), in: Capsule())
                                    .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
                            }
                            .buttonStyle(BouncyButtonStyle(depth: 0.92))
                        }
                        .bounceReveal(shown, order: 2)
                        gallery
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Sketchbook")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(AceTheme.ace)
        .preferredColorScheme(.dark)
        .onAppear { shown = true }
        .fullScreenCover(item: $open) { o in
            SketchEditorView(store: store, sketchID: o.id, isNew: o.isNew, challenge: o.challenge)
        }
        .alert("Rename sketch", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newTitle)
            Button("Save") {
                if let s = renaming { store.rename(s.id, to: newTitle) }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .confirmationDialog("Delete this sketch?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let s = deleting {
                    withAnimation(motion(.bouncy)) { store.delete(s.id) }
                    Haptics.shared.play(.pop)
                }
                deleting = nil
            }
        } message: {
            Text("It can't be brought back.")
        }
    }

    // MARK: Challenge

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(LinearGradient(colors: [AceTheme.pebble, AceTheme.nova], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                Text(isDaily ? String("Today's challenge") : String("Drawing challenge"))
                    .font(.headline)
                    .foregroundStyle(AceTheme.fg.opacity(0.9))
                Spacer()
                Button {
                    withAnimation(motion(.bouncy)) {
                        prompt = SketchPrompts.random(excluding: prompt)
                        isDaily = false
                    }
                    shuffles += 1
                    Haptics.shared.play(.tick)
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: shuffles)
                        .rotationEffect(.degrees(AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) ? Double(shuffles) * 90 : 0))
                        .animation(motion(.pop), value: shuffles)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(BouncyButtonStyle(depth: 0.84))
                .accessibilityLabel("Another challenge")
            }

            Text(prompt)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, Color(hex: 0xD9D2FF)], startPoint: .top, endPoint: .bottom))
                .fixedSize(horizontal: false, vertical: true)
                .id(prompt)
                .transition(.asymmetric(insertion: .push(from: .bottom).combined(with: .opacity),
                                        removal: .push(from: .top).combined(with: .opacity)))

            VStack(alignment: .leading, spacing: 10) {
                chipRow(title: "Timer") {
                    ForEach(SketchChallenge.allCases) { c in
                        chip(c.label, picked: challenge == c, tint: AceTheme.nova) {
                            withAnimation(motion(.pop)) { challenge = c }
                        }
                    }
                }
                chipRow(title: "Paper") {
                    ForEach(SketchPaper.allCases) { p in
                        paperChip(p)
                    }
                }
            }

            Button {
                startDrawing(prompt: prompt)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "paintbrush.pointed.fill")
                    Text(challenge == .off ? String("Draw it") : String("Draw it in \(challenge.label)"))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(colors: [AceTheme.accent, AceTheme.nova, AceTheme.amber], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
                .shadow(color: AceTheme.nova.opacity(0.45), radius: 16, y: 6)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.94))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(hex: 0x12101F).opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(LinearGradient(colors: [AceTheme.nova.opacity(0.6), AceTheme.accent.opacity(0.3), .white.opacity(0.05)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.4)
        )
        .shadow(color: AceTheme.accent.opacity(0.3), radius: 26, y: 12)
    }

    private func chipRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.heavy))
                .foregroundStyle(AceTheme.muted)
                .frame(width: 46, alignment: .leading)
            ScrollView(.horizontal) {
                HStack(spacing: 8) { content() }
                    .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func paperChip(_ p: SketchPaper) -> some View {
        let picked = paper == p
        return Button {
            withAnimation(motion(.pop)) { paper = p }
            Haptics.shared.play(.tick)
        } label: {
            HStack(spacing: 7) {
                SketchPaperView(paper: p)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(.white.opacity(0.3), lineWidth: 1))
                Text(p.label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(picked ? AceTheme.ace.opacity(0.35) : Color.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().stroke(picked ? AceTheme.ace : Color.white.opacity(0.1), lineWidth: picked ? 2 : 1))
            .scaleEffect(picked && AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) ? 1.05 : 1)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.9))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func chip(_ label: String, picked: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.shared.play(.tick)
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(picked ? tint.opacity(0.4) : Color.white.opacity(0.07), in: Capsule())
                .overlay(Capsule().stroke(picked ? tint : Color.white.opacity(0.1), lineWidth: picked ? 2 : 1))
                .scaleEffect(picked && AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) ? 1.05 : 1)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.9))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    // MARK: Stats

    private var stats: some View {
        let streak = store.streak()
        return HStack(spacing: 14) {
            SketchStat(symbol: "photo.stack.fill", colors: [AceTheme.ace, AceTheme.accent],
                       value: "\(store.sketches.count)", label: store.sketches.count == 1 ? "sketch" : "sketches")
            SketchStat(symbol: "flame.fill", colors: [AceTheme.amber, AceTheme.nova],
                       value: "\(streak)", label: streak == 1 ? "day in a row" : "days in a row")
                .boing(on: streak, scale: 1.08)
            SketchStat(symbol: "scribble.variable", colors: [AceTheme.good, AceTheme.ace],
                       value: "\(store.totalStrokes)", label: store.totalStrokes == 1 ? "stroke" : "strokes")
        }
    }

    // MARK: Gallery

    private var gallery: some View {
        Group {
            if store.sketches.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scribble.variable")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [AceTheme.ace, AceTheme.nova], startPoint: .leading, endPoint: .trailing))
                    Text("Nothing here yet")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)
                    Text("Try today's challenge, or start a blank page. Draw with your finger or an Apple Pencil.")
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .bounceReveal(shown, order: 3)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 18)], spacing: 22) {
                    ForEach(Array(store.sketches.enumerated()), id: \.element.id) { i, sketch in
                        Button {
                            open = OpenSketch(id: sketch.id, isNew: false, challenge: .off)
                        } label: {
                            SketchCard(sketch: sketch, thumbnail: store.thumbnailData(sketch.id), tilt: i % 2 == 0 ? -1.6 : 1.4)
                        }
                        .buttonStyle(BouncyButtonStyle(depth: 0.95))
                        .contextMenu {
                            Button {
                                open = OpenSketch(id: sketch.id, isNew: false, challenge: .off)
                            } label: { Label("Open", systemImage: "pencil.tip") }
                            Button {
                                newTitle = sketch.title
                                renaming = sketch
                            } label: { Label("Rename", systemImage: "character.cursor.ibeam") }
                            Button {
                                withAnimation(motion(.bouncy)) { _ = store.duplicate(sketch.id) }
                            } label: { Label("Make a copy", systemImage: "plus.square.on.square") }
                            Button(role: .destructive) {
                                deleting = sketch
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                        .bounceReveal(shown, order: 3 + min(i, 8), rise: 30)
                    }
                }
                .animation(motion(.bouncy), value: store.sketches.map(\.id))
            }
        }
    }

    // MARK: Actions

    private func startDrawing(prompt: String?) {
        let sketch = store.create(paper: paper, prompt: prompt)
        Haptics.shared.play(.pop)
        open = OpenSketch(id: sketch.id, isNew: true, challenge: challenge)
    }
}

/// A sketch's card: its picture on its paper (tilted a little, like a photo on a desk, and
/// straightening when you press it), with its name, strokes and when you last drew on it.
struct SketchCard: View {
    let sketch: Sketch
    let thumbnail: Data?
    var tilt: Double = 0
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let thumbnail, let image = UIImage(data: thumbnail) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    SketchPaperView(paper: sketch.paper)
                    Image(systemName: "scribble")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(hex: sketch.paper.lineHex).opacity(sketch.paper.isDark ? 1 : 0.9))
                }
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
            .rotationEffect(.degrees(moving ? tilt : 0))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if sketch.prompt != nil {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AceTheme.pebble)
                    }
                    Text(sketch.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sketch.title), \(subtitle)")
    }

    private var subtitle: String {
        let strokes = sketch.strokes == 1 ? "1 stroke" : "\(sketch.strokes) strokes"
        return "\(strokes) · \(sketch.updated.formatted(.relative(presentation: .named)))"
    }
}

/// A stat in a glowing tile: an icon in a gradient circle, a big number and a few words.
struct SketchStat: View {
    let symbol: String
    let colors: [Color]
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                .shadow(color: (colors.first ?? .clear).opacity(0.5), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.fg.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The sketchbook's backdrop: dark, with colored lights that drift like ink in water.
/// It holds still with Bouncy animations off or Reduce Motion on.
struct SketchAurora: View {
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !moving)) { context in
            let t = moving ? context.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, d = max(w, h)
                ZStack {
                    AceTheme.background
                    Circle()
                        .fill(AceTheme.nova.opacity(0.42))
                        .frame(width: d * 0.6, height: d * 0.6)
                        .blur(radius: 110)
                        .offset(x: -w * 0.32 + CGFloat(sin(t / 7)) * w * 0.12, y: -h * 0.3 + CGFloat(cos(t / 9)) * h * 0.08)
                    Circle()
                        .fill(AceTheme.ace.opacity(0.38))
                        .frame(width: d * 0.55, height: d * 0.55)
                        .blur(radius: 110)
                        .offset(x: w * 0.34 + CGFloat(cos(t / 8)) * w * 0.1, y: h * 0.1 + CGFloat(sin(t / 6)) * h * 0.1)
                    Circle()
                        .fill(AceTheme.pebble.opacity(0.22))
                        .frame(width: d * 0.4, height: d * 0.4)
                        .blur(radius: 100)
                        .offset(x: CGFloat(sin(t / 11)) * w * 0.25, y: h * 0.38 + CGFloat(cos(t / 10)) * h * 0.06)
                }
                .frame(width: w, height: h)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
