import SwiftUI

/// Ace Graphs: a graphing calculator. Type or say a formula and watch it draw itself, pinch and
/// drag the paper, and trace along a line to read off any point.
struct GraphView: View {
    let start: GraphStart

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model = GraphModel()
    @State private var tracing = false
    @State private var shown = false
    @State private var started = false
    @FocusState private var typing: Bool

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            ZStack {
                AceTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                        .bounceReveal(shown, order: 0)
                    if wide {
                        HStack(spacing: 0) {
                            paper
                            panel
                                .frame(width: 360)
                        }
                    } else {
                        VStack(spacing: 0) {
                            paper
                            panel
                                .frame(height: geo.size.height * 0.42)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .onAppear(perform: begin)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 10) {
            BouncyIconButton(symbol: "xmark", label: "Close the graph") { dismiss() }
                .background(Circle().fill(.white.opacity(0.08)))
            VStack(alignment: .leading, spacing: 0) {
                Text("Graphs")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(tracing ? "Slide along a line to read its points" : "Drag to move, pinch to zoom, tap a line")
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 6)
            Picker("Touch", selection: $tracing) {
                Text("Move").tag(false)
                Text("Trace").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            BouncyIconButton(symbol: "minus.magnifyingglass", label: "Zoom out") { zoom(0.5) }
            BouncyIconButton(symbol: "plus.magnifyingglass", label: "Zoom in") { zoom(2) }
            BouncyIconButton(symbol: "scope", label: "Back to the middle") {
                withAnimation(animation(.gentle)) { model.resetView() }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var paper: some View {
        ZStack(alignment: .topLeading) {
            GraphCanvas(model: model, moves: moves, tracing: tracing)
            if model.lines.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AceTheme.ace)
                    Text("Type a formula, or tap an example")
                        .font(.headline)
                        .foregroundStyle(AceTheme.fg)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black.opacity(0.45)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
        .padding(10)
        .bounceReveal(shown, order: 1)
    }

    private var panel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                entry
                    .bounceReveal(shown, order: 2)
                MathKeys { insert($0) }
                    .bounceReveal(shown, order: 3)
                examples
                    .bounceReveal(shown, order: 4)
                if !model.lines.isEmpty {
                    linesList
                        .transition(.opacity)
                }
                if let line = model.pickedLine, line.shown {
                    facts(line)
                        .id(line.id)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .padding(14)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var entry: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("y =")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.muted)
                TextField("x^2 - 4", text: $model.input)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .submitLabel(.done)
                    .focused($typing)
                    .onSubmit(addInput)
                Button(action: addInput) {
                    Label("Draw", systemImage: "scribble")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(model.input.isEmpty ? Color.white.opacity(0.1) : AceTheme.ace))
                        .foregroundStyle(model.input.isEmpty ? AceTheme.muted : .black)
                }
                .buttonStyle(.aceBouncy)
                .disabled(model.input.isEmpty)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(model.problem == nil ? AceTheme.cardBorder : AceTheme.bad.opacity(0.7), lineWidth: 1))
            if let problem = model.problem {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(AceTheme.bad)
                    .transition(.opacity)
            }
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Try one")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GraphModel.examples, id: \.self) { e in
                        Button { add(e) } label: {
                            Text(GraphParse.pretty(e))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(.white.opacity(0.08)))
                                .foregroundStyle(AceTheme.fg)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Draw y = \(e)")
                    }
                }
            }
        }
    }

    private var linesList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("On the graph")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.muted)
                Spacer()
                Button("Clear all") {
                    withAnimation(animation(.snappy)) { model.clearAll() }
                }
                .font(.caption.weight(.bold))
            }
            ForEach(model.lines) { line in
                let picked = model.pickedLine?.id == line.id
                HStack(spacing: 10) {
                    Capsule()
                        .fill(Color(hex: line.color))
                        .frame(width: 22, height: 6)
                        .shadow(color: Color(hex: line.color), radius: picked ? 6 : 0)
                    Text(line.label)
                        .font(.system(.body, design: .rounded).weight(picked ? .heavy : .semibold))
                        .foregroundStyle(line.shown ? AceTheme.fg : AceTheme.muted)
                        .strikethrough(!line.shown)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Button { withAnimation(animation(.snappy)) { model.toggle(line.id) } } label: {
                        Image(systemName: line.shown ? "eye.fill" : "eye.slash")
                            .frame(width: 34, height: 34)
                    }
                    .accessibilityLabel(line.shown ? "Hide \(line.label)" : "Show \(line.label)")
                    Button { withAnimation(animation(.snappy)) { model.remove(line.id) } } label: {
                        Image(systemName: "trash")
                            .frame(width: 34, height: 34)
                            .foregroundStyle(AceTheme.bad)
                    }
                    .accessibilityLabel("Remove \(line.label)")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(picked ? Color(hex: line.color).opacity(0.14) : Color.white.opacity(0.05)))
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(animation(.snappy)) { model.picked = line.id } }
                .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .scale.combined(with: .opacity)))
            }
        }
    }

    private func facts(_ line: GraphLine) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: line.color))
            VStack(alignment: .leading, spacing: 4) {
                Text(line.label)
                    .font(.headline)
                    .foregroundStyle(AceTheme.fg)
                Text(GraphFacts.describe(line.expr))
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.fg.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                if let p = model.tracePoint {
                    Text("Trace: when x is \(GraphFacts.say(p.x)), y is \(GraphFacts.say(p.y)).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: line.color))
                }
            }
            Spacer(minLength: 0)
        }
        .aceCard()
    }

    // MARK: Actions

    private func begin() {
        guard !started else { return }
        started = true
        if case .plot(let text) = start {
            model.add(text)
        }
        withAnimation(animation(.gentle)) { shown = true }
    }

    private func addInput() {
        add(model.input)
    }

    private func add(_ text: String) {
        let ok = withAnimation(animation(.bouncy)) { model.add(text) }
        Haptics.shared.play(ok ? .pop : .alert)
        if ok { typing = false }
    }

    private func insert(_ key: String) {
        Haptics.shared.play(.tick)
        if key == "⌫" {
            if !model.input.isEmpty { model.input.removeLast() }
        } else {
            model.input += key
        }
        model.problem = nil
    }

    private func zoom(_ factor: Double) {
        withAnimation(animation(.gentle)) {
            // Zoom around the middle of the paper; the paper keeps its own size, so any size works here.
            let size = CGSize(width: 1000, height: 1000)
            model.viewport.zoom(by: factor, around: CGPoint(x: 500, y: 500), size: size)
        }
    }

    private func animation(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }
}

/// Buttons for the bits of math that are hard to type: x, powers, roots, π and the trig functions.
struct MathKeys: View {
    let tap: (String) -> Void

    private struct Key: Identifiable {
        let label: String
        let insert: String
        var id: String { label }
    }

    private let keys: [Key] = [
        Key(label: "x", insert: "x"), Key(label: "x²", insert: "^2"), Key(label: "xⁿ", insert: "^"), Key(label: "√", insert: "sqrt("),
        Key(label: "π", insert: "pi"), Key(label: "(", insert: "("), Key(label: ")", insert: ")"),
        Key(label: "sin", insert: "sin("), Key(label: "cos", insert: "cos("), Key(label: "tan", insert: "tan("),
        Key(label: "|x|", insert: "|"), Key(label: "÷", insert: "/"), Key(label: "×", insert: "*"), Key(label: "⌫", insert: "⌫"),
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(keys) { key in
                Button { tap(key.insert) } label: {
                    Text(key.label)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(key.insert == "⌫" ? AceTheme.bad.opacity(0.18) : Color.white.opacity(0.08)))
                        .foregroundStyle(key.insert == "⌫" ? AceTheme.bad : AceTheme.fg)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(spoken(key.label))
            }
        }
    }

    private func spoken(_ label: String) -> String {
        switch label {
        case "x²": return "squared"
        case "xⁿ": return "to the power of"
        case "√": return "square root"
        case "π": return "pi"
        case "|x|": return "absolute value bar"
        case "÷": return "divide"
        case "×": return "times"
        case "⌫": return "delete"
        default: return label
        }
    }
}
