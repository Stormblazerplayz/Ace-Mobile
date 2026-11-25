import PencilKit
import SwiftUI
import UIKit

/// Drawing one sketch. The page fills the screen, with a floating glass tool bar at the bottom:
/// pens, colors, line size, undo and redo. The top bar has the name (tap it to rename), the
/// paper, sharing and, for a timed challenge, a countdown ring. Every change saves itself.
struct SketchEditorView: View {
    @ObservedObject var store: SketchStore
    let sketchID: UUID
    /// True for a sketch that was just made, so an empty one is thrown away when you leave.
    var isNew = false

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var canvas = SketchCanvasModel()
    @State private var tool: SketchTool = .pen
    @State private var ink: UInt32 = SketchPaper.midnight.startInk
    @State private var size: SketchSize = .medium
    @State private var paper: SketchPaper = .midnight
    @State private var deadline: Date?
    @State private var challengeLength = 0
    @State private var timeUp = false
    @State private var shown = false
    @State private var dirty = false
    @State private var saveTask: Task<Void, Never>?
    @State private var renaming = false
    @State private var newTitle = ""
    @State private var confirmClear = false
    @State private var share: SharedSketch?
    @State private var paperFlips = 0
    @Namespace private var toolbarSpace

    /// A picture of the sketch, ready for the share sheet.
    struct SharedSketch: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    init(store: SketchStore, sketchID: UUID, isNew: Bool = false, challenge: SketchChallenge = .off) {
        self.store = store
        self.sketchID = sketchID
        self.isNew = isNew
        let seconds = challenge.seconds
        _challengeLength = State(initialValue: seconds)
        _deadline = State(initialValue: seconds > 0 ? Date().addingTimeInterval(TimeInterval(seconds)) : nil)
    }

    private var sketch: Sketch? { store.sketch(sketchID) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            AceTheme.background.ignoresSafeArea()
            VStack(spacing: 14) {
                topBar
                    .bounceReveal(shown)
                page
                    .bounceReveal(shown, order: 1, rise: 30)
                toolbar
                    .bounceReveal(shown, order: 2, rise: 40)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 14)

            if timeUp {
                timeUpBanner
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .onAppear(perform: start)
        .onDisappear(perform: finish)
        .onChange(of: canvas.changes) { _, _ in
            dirty = true
            scheduleSave()
        }
        .onChange(of: tool) { _, _ in applyTool() }
        .onChange(of: ink) { _, _ in applyTool() }
        .onChange(of: size) { _, _ in applyTool() }
        .task(id: deadline) { await runTimer() }
        .alert("Rename sketch", isPresented: $renaming) {
            TextField("Name", text: $newTitle)
            Button("Save") { store.rename(sketchID, to: newTitle) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear the page?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                canvas.clear()
                Haptics.shared.play(.pop)
            }
        } message: {
            Text("You can undo it.")
        }
        .sheet(item: $share) { shared in
            SketchShareSheet(items: [shared.image])
                .ignoresSafeArea()
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                finish()
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(AceTheme.ace.opacity(0.9), in: Capsule())
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.9))

            Button {
                newTitle = sketch?.title ?? ""
                renaming = true
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(sketch?.title ?? "Sketch")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Image(systemName: "pencil.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AceTheme.muted)
                    }
                    Text(canvas.strokes == 1 ? String("1 stroke") : String("\(canvas.strokes) strokes"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AceTheme.muted)
                        .contentTransition(.numericText())
                        .animation(motion(.snappy), value: canvas.strokes)
                }
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.96))
            .accessibilityLabel("Rename sketch")

            Spacer(minLength: 8)

            if let deadline {
                SketchCountdownRing(deadline: deadline, total: challengeLength, done: timeUp)
            }

            Menu {
                Picker("Paper", selection: Binding(get: { paper }, set: { changePaper(to: $0) })) {
                    ForEach(SketchPaper.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
            } label: {
                topIcon("square.grid.3x3.fill", tint: Color(hex: paper.isDark ? 0x8F7CFF : 0xFFCF3A))
            }
            .accessibilityLabel("Paper")

            Button {
                guard let image = SketchRender.image(canvas.drawing, paper: paper, width: 1600, scale: 1) else { return }
                share = SharedSketch(image: image)
            } label: {
                topIcon("square.and.arrow.up", tint: AceTheme.good)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.86))
            .disabled(canvas.strokes == 0)
            .opacity(canvas.strokes == 0 ? 0.45 : 1)
            .accessibilityLabel("Share or save to Photos")

            Button {
                confirmClear = true
            } label: {
                topIcon("trash", tint: AceTheme.bad)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.86))
            .disabled(canvas.strokes == 0)
            .opacity(canvas.strokes == 0 ? 0.45 : 1)
            .accessibilityLabel("Clear the page")
        }
    }

    private func topIcon(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.08), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: Page

    private var page: some View {
        ZStack(alignment: .topLeading) {
            SketchPaperView(paper: paper)
            SketchCanvas(model: canvas)
            if let prompt = sketch?.prompt {
                Label(prompt, systemImage: "lightbulb.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [AceTheme.accent, AceTheme.nova], startPoint: .leading, endPoint: .trailing)
                            .opacity(0.92),
                        in: Capsule()
                    )
                    .shadow(color: AceTheme.nova.opacity(0.35), radius: 10, y: 4)
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(LinearGradient(colors: [Color(hex: ink).opacity(tool.usesColor ? 0.8 : 0.3), .white.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: Color(hex: ink).opacity(tool.usesColor ? 0.28 : 0.1), radius: 26, y: 12)
        .boing(on: paperFlips, scale: 1.015)
        .animation(motion(.gentle), value: paper)
        .animation(motion(.gentle), value: ink)
    }

    // MARK: Tool bar

    /// The tool bar, centered. On a narrow screen it scrolls sideways.
    private var toolbar: some View {
        GeometryReader { geo in
            ScrollView(.horizontal) {
                toolbarContent
                    .frame(minWidth: geo.size.width)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .frame(height: 64)
    }

    private var toolbarContent: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(SketchTool.allCases) { t in
                    toolButton(t)
                }
            }
            divider
            HStack(spacing: 8) {
                ForEach(SketchInk.palette, id: \.self) { hex in
                    swatch(hex)
                }
            }
            // Still tappable with the eraser or lasso: picking a color switches back to the pen.
            .opacity(tool.usesColor ? 1 : 0.5)
            divider
            HStack(spacing: 6) {
                ForEach(SketchSize.allCases) { s in
                    sizeButton(s)
                }
            }
            .opacity(tool == .lasso ? 0.35 : 1)
            .allowsHitTesting(tool != .lasso)
            divider
            HStack(spacing: 4) {
                historyButton("arrow.uturn.backward", label: "Undo", enabled: canvas.canUndo) { canvas.undo() }
                historyButton("arrow.uturn.forward", label: "Redo", enabled: canvas.canRedo) { canvas.redo() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
        .environment(\.colorScheme, .dark)
    }

    private var divider: some View {
        Capsule()
            .fill(.white.opacity(0.15))
            .frame(width: 1.5, height: 30)
    }

    private func toolButton(_ t: SketchTool) -> some View {
        let picked = tool == t
        return Button {
            withAnimation(motion(.bouncy)) { tool = t }
            Haptics.shared.play(.tick)
        } label: {
            ZStack {
                if picked {
                    Circle()
                        .fill(LinearGradient(colors: t.usesColor ? [Color(hex: ink), AceTheme.accent] : [AceTheme.muted, AceTheme.ink],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: Color(hex: ink).opacity(t.usesColor ? 0.5 : 0), radius: 8)
                        .matchedGeometryEffect(id: "tool", in: toolbarSpace)
                }
                Image(systemName: t.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(picked ? (ink == 0xFFFFFF && t.usesColor ? AceTheme.ink : Color.white) : AceTheme.fg.opacity(0.75))
                    .symbolEffect(.bounce, value: picked)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.84))
        .accessibilityLabel(t.label)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func swatch(_ hex: UInt32) -> some View {
        let picked = ink == hex
        return Button {
            withAnimation(motion(.pop)) { ink = hex }
            if !tool.usesColor { tool = .pen }
            Haptics.shared.play(.tick)
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: picked ? 30 : 24, height: picked ? 30 : 24)
                .overlay(Circle().stroke(.white.opacity(picked ? 0.95 : 0.25), lineWidth: picked ? 3 : 1))
                .shadow(color: Color(hex: hex).opacity(picked ? 0.7 : 0), radius: 8)
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.8))
        .accessibilityLabel(SketchInk.name(hex))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func sizeButton(_ s: SketchSize) -> some View {
        let picked = size == s
        return Button {
            withAnimation(motion(.pop)) { size = s }
            Haptics.shared.play(.tick)
        } label: {
            Circle()
                .fill(picked ? Color.white : Color.white.opacity(0.45))
                .frame(width: s.dot, height: s.dot)
                .frame(width: 34, height: 44)
                .background(Circle().fill(.white.opacity(picked ? 0.14 : 0)).frame(width: 34, height: 34))
                .contentShape(Rectangle())
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.82))
        .accessibilityLabel(s.label)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func historyButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.shared.play(.tick)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.84))
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    // MARK: Challenge

    private var timeUpBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [AceTheme.pebble, AceTheme.nova], startPoint: .top, endPoint: .bottom))
                .symbolEffect(.bounce, value: timeUp)
            Text("Time's up!")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Nice work. Keep going, or tap Done to save it.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AceTheme.fg.opacity(0.85))
            Button {
                withAnimation(motion(.snappy)) { timeUp = false }
            } label: {
                Text("Keep drawing")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(LinearGradient(colors: [AceTheme.accent, AceTheme.nova], startPoint: .leading, endPoint: .trailing), in: Capsule())
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.92))
            .padding(.top, 4)
        }
        .padding(28)
        .background(Color(hex: 0x12101F).opacity(0.94), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(AceTheme.nova.opacity(0.5), lineWidth: 1.5))
        .shadow(color: AceTheme.nova.opacity(0.4), radius: 30, y: 10)
        .padding(30)
    }

    private func runTimer() async {
        guard let deadline else { return }
        let wait = deadline.timeIntervalSinceNow
        if wait > 0 {
            try? await Task.sleep(for: .seconds(wait))
        }
        guard !Task.isCancelled else { return }
        withAnimation(motion(.pop)) { timeUp = true }
        Haptics.shared.play(.success)
        SoundFX.shared.play(.success)
    }

    // MARK: Loading and saving

    private func start() {
        guard !shown else { return }
        if let sketch {
            paper = sketch.paper
            ink = sketch.paper.startInk
        }
        if let data = store.drawingData(sketchID), let drawing = try? PKDrawing(data: data) {
            canvas.load(drawing)
        }
        applyTool()
        shown = true
    }

    private func applyTool() {
        canvas.setTool(tool.pkTool(color: SketchInk.uiColor(ink), size: size))
    }

    private func changePaper(to new: SketchPaper) {
        guard new != paper else { return }
        // Swap the starting ink too, so white ink doesn't vanish on white paper.
        if ink == paper.startInk { ink = new.startInk }
        paper = new
        paperFlips += 1
        store.setPaper(sketchID, to: new)
        Haptics.shared.play(.pop)
        dirty = true
        scheduleSave()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private func save() {
        guard dirty, store.sketch(sketchID) != nil else { return }
        dirty = false
        let drawing = canvas.drawing
        let thumb = SketchRender.image(drawing, paper: paper, width: 480)?.pngData()
        store.saveDrawing(sketchID, data: drawing.dataRepresentation(), strokes: drawing.strokes.count, thumbnail: thumb)
    }

    /// Saves now, and throws away a brand-new sketch that was never drawn on.
    private func finish() {
        saveTask?.cancel()
        saveTask = nil
        save()
        if isNew, canvas.strokes == 0, let s = store.sketch(sketchID), s.strokes == 0 {
            store.delete(sketchID)
        }
    }
}

/// A ring that empties as a drawing challenge's time runs out, with the time left in the middle.
struct SketchCountdownRing: View {
    let deadline: Date
    let total: Int
    var done = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let left = max(0, deadline.timeIntervalSince(context.date))
            let fraction = total > 0 ? left / Double(total) : 0
            let secs = Int(left.rounded(.up))
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(
                        AngularGradient(colors: left < 10 ? [AceTheme.bad, AceTheme.nova, AceTheme.bad] : [AceTheme.ace, AceTheme.accent, AceTheme.ace],
                                        center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: fraction)
                if done || secs == 0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(AceTheme.good)
                } else {
                    Text(String(format: "%d:%02d", secs / 60, secs % 60))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 48, height: 48)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(secs == 0 ? String("Time's up") : String("\(secs) seconds left"))
        }
    }
}
