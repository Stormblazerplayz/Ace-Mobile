import SwiftUI

/// A two-ring code wheel: plain letters outside, code letters inside. Turning the inside ring changes the shift.
/// `spin` counts turns without wrapping, so going from Z to A spins forward instead of all the way back.
struct CipherWheel: View {
    @Binding var spin: Int
    var moves = true
    @State private var lastAngle: Double?
    @State private var leftover: Double = 0

    private static let step = 360.0 / 26

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let shift = Caesar.normalize(spin)
            ZStack {
                // Outer ring: plain letters.
                Circle()
                    .fill(Color(hex: 0x1B1640))
                Circle()
                    .stroke(Color(hex: 0x7C5CFF).opacity(0.6), lineWidth: 2)
                ring(letters: Caesar.alphabet, radius: size * 0.43, size: size, color: .white, highlight: 0)

                // Inner ring: code letters, turned by the shift.
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0x2BD9C5), Color(hex: 0x7C5CFF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: size * 0.74, height: size * 0.74)
                        .shadow(color: Color(hex: 0x2BD9C5).opacity(0.5), radius: 18)
                    ring(letters: Caesar.alphabet, radius: size * 0.31, size: size, color: Color(hex: 0x0D0A24), highlight: shift)
                    ForEach(0..<26, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 2, height: size * 0.04)
                            .offset(y: -size * 0.36)
                            .rotationEffect(.degrees(Double(i) * Self.step + Self.step / 2))
                    }
                }
                .rotationEffect(.degrees(-Double(spin) * Self.step))
                .animation(moves ? .spring(response: 0.45, dampingFraction: 0.7) : nil, value: spin)

                // The hub shows the shift.
                Circle()
                    .fill(Color(hex: 0x0D0A24))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                VStack(spacing: 0) {
                    Text("\(shift)")
                        .font(.system(size: size * 0.11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(moves ? .snappy : nil, value: shift)
                    Text("SHIFT")
                        .font(.system(size: size * 0.035, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                // The pointer at the top shows the pair being used: A becomes the letter under it.
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: size * 0.06))
                    .foregroundStyle(Color(hex: 0xFFD25E))
                    .shadow(color: Color(hex: 0xFFD25E), radius: 6)
                    .offset(y: -size * 0.5)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Circle())
            .gesture(turn(center: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Code wheel")
        .accessibilityValue("Shift \(Caesar.normalize(spin)). A becomes \(String(Caesar.shifted("A", by: spin)))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: spin += 1
            case .decrement: spin -= 1
            @unknown default: break
            }
        }
    }

    private func ring(letters: [Character], radius: CGFloat, size: CGFloat, color: Color, highlight: Int) -> some View {
        ForEach(0..<letters.count, id: \.self) { i in
            Text(String(letters[i]))
                .font(.system(size: size * 0.05, weight: .heavy, design: .rounded))
                .foregroundStyle(i == highlight ? Color(hex: 0xFFD25E) : color)
                .scaleEffect(i == highlight ? 1.35 : 1)
                .offset(y: -radius)
                .rotationEffect(.degrees(Double(i) * Self.step))
        }
    }

    /// Dragging around the wheel turns it one letter at a time.
    private func turn(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let angle = atan2(Double(value.location.y - center.y), Double(value.location.x - center.x))
                if let lastAngle {
                    var delta = angle - lastAngle
                    if delta > .pi { delta -= 2 * .pi }
                    if delta < -.pi { delta += 2 * .pi }
                    leftover += delta
                }
                lastAngle = angle
                let stepRadians = Self.step * .pi / 180
                let steps = Int((leftover / stepRadians).rounded(.towardZero))
                if steps != 0 {
                    // Turning clockwise moves the letters clockwise, which is a smaller shift.
                    spin -= steps
                    leftover -= Double(steps) * stepRadians
                    Haptics.shared.play(.tick)
                }
            }
            .onEnded { _ in
                lastAngle = nil
                leftover = 0
            }
    }
}

/// A lamp that flashes Morse code, with a glow when it's on.
struct MorseLamp: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFFB020).opacity(on ? 0.35 : 0))
                .blur(radius: 40)
                .scaleEffect(on ? 1.25 : 0.8)
            Circle()
                .fill(on
                      ? RadialGradient(colors: [Color(hex: 0xFFF6D8), Color(hex: 0xFFB020)], center: .center, startRadius: 4, endRadius: 90)
                      : RadialGradient(colors: [Color(hex: 0x3A3350), Color(hex: 0x1C1830)], center: .center, startRadius: 4, endRadius: 90))
                .overlay(Circle().stroke(Color.white.opacity(on ? 0.7 : 0.15), lineWidth: 3))
                .shadow(color: Color(hex: 0xFFB020).opacity(on ? 0.9 : 0), radius: 30)
                .padding(24)
            Image(systemName: on ? "lightbulb.max.fill" : "lightbulb")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(on ? Color(hex: 0x5A3A00) : Color.white.opacity(0.35))
        }
        .animation(.easeOut(duration: 0.06), value: on)
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The dots and dashes of a message in a row. Ones that have flashed stay lit.
struct MorseTape: View {
    let code: String
    /// The last dot or dash that has flashed, or nil before playing.
    let lit: Int?

    private struct Mark: Identifiable {
        let id: Int
        let dash: Bool
        let gapBefore: CGFloat
    }

    private var marks: [Mark] {
        var result: [Mark] = []
        var symbol = 0
        var gap: CGFloat = 0
        for c in Morse.clean(code) {
            switch c {
            case ".", "-":
                result.append(Mark(id: symbol, dash: c == "-", gapBefore: gap))
                symbol += 1
                gap = 0
            case "/":
                gap = max(gap, 22)
            default:
                if c.isWhitespace { gap = max(gap, 10) }
            }
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(marks) { mark in
                        let done = (lit ?? -1) >= mark.id
                        let now = lit == mark.id
                        Capsule()
                            .fill(done ? Color(hex: 0xFFB020) : Color.white.opacity(0.18))
                            .frame(width: mark.dash ? 26 : 10, height: 10)
                            .shadow(color: now ? Color(hex: 0xFFB020) : .clear, radius: 8)
                            .scaleEffect(now ? 1.35 : 1)
                            .padding(.leading, mark.gapBefore)
                            .id(mark.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .animation(.easeOut(duration: 0.12), value: lit)
            }
            .onChange(of: lit) { _, new in
                guard let new else { return }
                proxy.scrollTo(new, anchor: .center)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The flipped alphabet: A to Z over Z to A. Letters in your message light up.
struct MirrorStrip: View {
    let message: String

    var body: some View {
        let used = Set(message.uppercased().filter { $0.isASCII && $0.isLetter })
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 13)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<26, id: \.self) { i in
                let top = Caesar.alphabet[i]
                let bottom = MirrorCode.flipped(top)
                let on = used.contains(top)
                VStack(spacing: 3) {
                    Text(String(top))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? Color.white : Color.white.opacity(0.55))
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.3))
                    Text(String(bottom))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(on ? Color(hex: 0x9EDCFF) : Color.white.opacity(0.4))
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(on ? Color(hex: 0x3FA2FF).opacity(0.35) : Color.white.opacity(0.05)))
                .scaleEffect(on ? 1.06 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: on)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Text that scrambles through random letters and settles left to right, like a code being cracked.
struct ScrambleText: View {
    let text: String
    var moves = true
    var font: Font = .system(size: 22, weight: .bold, design: .monospaced)
    @State private var shown = ""
    @State private var job: Task<Void, Never>?

    var body: some View {
        Text(shown.isEmpty ? " " : shown)
            .font(font)
            .foregroundStyle(AceTheme.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .accessibilityLabel(text)
            .onAppear { play(text) }
            .onChange(of: text) { _, new in play(new) }
            .onDisappear { job?.cancel() }
    }

    private func play(_ target: String) {
        job?.cancel()
        guard moves, !target.isEmpty else {
            shown = target
            return
        }
        let chars = Array(target)
        let frames = 10
        job = Task { @MainActor in
            for frame in 0...frames {
                if Task.isCancelled { return }
                let settled = chars.count * frame / frames
                shown = String(chars.enumerated().map { (i, c) -> Character in
                    if i < settled || !c.isLetter { return c }
                    return Caesar.alphabet.randomElement() ?? c
                })
                try? await Task.sleep(nanoseconds: 35_000_000)
            }
            shown = target
        }
    }
}
