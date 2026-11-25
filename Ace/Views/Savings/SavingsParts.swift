import SwiftUI

/// The outline of a glass jar: a short neck at the top and a round-cornered body.
struct SavingsJarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let neckInset = w * 0.16
        let neckHeight = h * 0.1
        let shoulder = h * 0.08
        let corner = w * 0.2
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + neckInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - neckInset, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - neckInset, y: rect.minY + neckHeight))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + neckHeight + shoulder),
                       control: CGPoint(x: rect.maxX, y: rect.minY + neckHeight))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - corner, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - corner), control: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + neckHeight + shoulder))
        p.addQuadCurve(to: CGPoint(x: rect.minX + neckInset, y: rect.minY + neckHeight),
                       control: CGPoint(x: rect.minX, y: rect.minY + neckHeight))
        p.closeSubpath()
        return p
    }
}

/// A rising level that SwiftUI can animate smoothly.
struct SavingsFill: Shape {
    var level: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let top = rect.maxY - rect.height * max(0, min(1, level))
        return Path(CGRect(x: rect.minX, y: top, width: rect.width, height: rect.maxY - top))
    }
}

/// A glass jar that fills up with coins as you save. The coins stack in rows from the bottom.
struct SavingsJar: View {
    let progress: Double
    let color: SavingsColor
    let symbol: String
    var showsCoins = true

    /// Where coin number `index` sits, as fractions of the jar (x across, y up from the bottom).
    /// The same index always lands in the same place, so the pile doesn't jump around.
    static func coinSpot(_ index: Int, perRow: Int = 6) -> (x: Double, y: Double) {
        let row = index / perRow
        let col = index % perRow
        let shift = row % 2 == 0 ? 0 : 0.5
        let wobble = Double((index * 37) % 11) / 11 * 0.03
        let x = (Double(col) + 0.5 + shift) / (Double(perRow) + 0.5) + wobble - 0.015
        let y = (Double(row) + 0.5) * 0.085
        return (x, y)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let level = max(0, min(1, progress))
            ZStack {
                SavingsJarShape()
                    .fill(Color.white.opacity(0.06))
                SavingsFill(level: level * 0.86)
                    .fill(LinearGradient(colors: [color.light.opacity(0.55), color.dark.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .clipShape(SavingsJarShape())
                if showsCoins {
                    Canvas { context, canvasSize in
                        drawCoins(&context, size: canvasSize, level: level * 0.86)
                    }
                    .clipShape(SavingsJarShape())
                }
                Image(systemName: symbol)
                    .font(.system(size: size.width * 0.2, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .offset(y: size.height * 0.08)
                // Glass shine and outline.
                SavingsJarShape()
                    .stroke(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: max(2, size.width * 0.025))
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: size.width * 0.06, height: size.height * 0.4)
                    .offset(x: -size.width * 0.3, y: size.height * 0.05)
                // The lid.
                RoundedRectangle(cornerRadius: size.width * 0.04, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: size.width * 0.78, height: size.height * 0.07)
                    .offset(y: -size.height * 0.5 + size.height * 0.02)
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Jar \(Int((max(0, min(1, progress)) * 100).rounded())) percent full")
    }

    private func drawCoins(_ context: inout GraphicsContext, size: CGSize, level: Double) {
        let perRow = 6
        let coin = size.width / 6.2
        let rows = Int((level / 0.085).rounded(.down))
        let count = rows * perRow
        guard count > 0 else { return }
        for i in 0..<count {
            let spot = Self.coinSpot(i, perRow: perRow)
            let center = CGPoint(x: spot.x * size.width, y: size.height - spot.y * size.height)
            let rect = CGRect(x: center.x - coin / 2, y: center.y - coin * 0.32, width: coin, height: coin * 0.64)
            let ellipse = Path(ellipseIn: rect)
            context.fill(ellipse, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE38A), Color(hex: 0xC98A12)]),
                                                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            context.stroke(ellipse, with: .color(Color(hex: 0x8A5A00).opacity(0.6)), lineWidth: 1)
        }
    }
}

/// A gold coin that drops from above into the jar each time `drops` goes up.
struct SavingsCoinDrop: View {
    let drops: Int
    let moving: Bool
    @State private var falling = false
    @State private var visible = false

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xFFF0B0), Color(hex: 0xF5B83D), Color(hex: 0xB97A0C)],
                                 center: .topLeading, startRadius: 2, endRadius: 40))
            .overlay(Text("$").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0x8A5A00)))
            .frame(width: 44, height: 44)
            .rotation3DEffect(.degrees(falling ? 540 : 0), axis: (x: 0, y: 1, z: 0))
            .offset(y: falling ? 30 : -220)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: drops) { _, _ in
                guard moving else { return }
                // Start back at the top first, then fall on the next frame so the drop always shows.
                falling = false
                visible = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 20_000_000)
                    withAnimation(.easeIn(duration: 0.55)) { falling = true }
                    try? await Task.sleep(nanoseconds: 560_000_000)
                    withAnimation(.easeOut(duration: 0.15)) { visible = false }
                }
            }
    }
}

/// Bars for the money saved each week, newest on the right.
struct SavingsWeekBars: View {
    let weeks: [Int]
    let color: SavingsColor

    var body: some View {
        let top = max(1, weeks.map { abs($0) }.max() ?? 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { index, cents in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(cents >= 0 ? AnyShapeStyle(color.gradient) : AnyShapeStyle(AceTheme.bad.opacity(0.7)))
                        .frame(height: max(4, 90 * CGFloat(abs(cents)) / CGFloat(top)))
                        .opacity(cents == 0 ? 0.25 : 1)
                    Text(index == weeks.count - 1 ? "Now" : "\(weeks.count - 1 - index)w")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 112, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Saved each week, oldest first: " + weeks.map { SavingsMoney.text($0) }.joined(separator: ", "))
    }
}

/// A burst of gold stars when a goal is reached.
struct SavingsBurst: View {
    let fire: Int
    @State private var go = false

    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                let angle = Double(i) / 14 * 2 * Double.pi
                Image(systemName: i % 2 == 0 ? "star.fill" : "sparkle")
                    .font(.system(size: i % 3 == 0 ? 22 : 15, weight: .bold))
                    .foregroundStyle(i % 2 == 0 ? Color(hex: 0xFFD54A) : Color.white)
                    .offset(x: go ? cos(angle) * 170 : 0, y: go ? sin(angle) * 170 : 0)
                    .scaleEffect(go ? 0.4 : 1.2)
                    .opacity(go ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .opacity(fire == 0 ? 0 : 1)
        .onChange(of: fire) { _, _ in
            go = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 20_000_000)
                withAnimation(.easeOut(duration: 1.1)) { go = true }
            }
        }
    }
}
