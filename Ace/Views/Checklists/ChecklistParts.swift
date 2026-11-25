import SwiftUI

/// A check circle whose tick draws itself in when you tick it.
struct ChecklistTick: View {
    let done: Bool
    let tint: ListTint
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .stroke(done ? Color.clear : AceTheme.muted.opacity(0.6), lineWidth: 2)
            Circle()
                .fill(tint.gradient)
                .scaleEffect(done ? 1 : 0.2)
                .opacity(done ? 1 : 0)
            ChecklistTickShape()
                .trim(from: 0, to: done ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
                .padding(size * 0.26)
        }
        .frame(width: size, height: size)
    }
}

/// The tick mark, drawn from the short arm to the long one so `trim` animates it like a pen.
struct ChecklistTickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.1))
        return path
    }
}

/// A progress bar that fills with the list's colors and has a light sweeping across it.
struct ChecklistBar: View {
    let progress: Double
    let tint: ListTint
    var height: CGFloat = 12
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width * min(1, max(0, progress))
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.1))
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(progress > 0 ? height : 0, width))
                    .overlay(
                        LinearGradient(colors: [.clear, .white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 60)
                            .offset(x: sweep ? width : -60)
                            .opacity(progress > 0 ? 1 : 0),
                        alignment: .leading
                    )
                    .clipShape(Capsule())
                    .shadow(color: tint.dark.opacity(0.6), radius: progress > 0 ? 6 : 0)
            }
        }
        .frame(height: height)
        .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion), value: progress)
        .onAppear {
            guard AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) else { return }
            withAnimation(.linear(duration: 1.8).delay(0.4).repeatForever(autoreverses: false)) { sweep = true }
        }
        .accessibilityElement()
        .accessibilityLabel("\(Int((progress * 100).rounded())) percent done")
    }
}

/// Stars that pop out when a whole list is ticked.
struct ChecklistCheer: View {
    let trigger: Int
    let tint: ListTint
    @State private var out = true

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) / 12 * .pi * 2
                Image(systemName: i.isMultiple(of: 2) ? "star.fill" : "sparkle")
                    .font(.system(size: i.isMultiple(of: 3) ? 18 : 12, weight: .bold))
                    .foregroundStyle(i.isMultiple(of: 2) ? tint.light : AceTheme.pebble)
                    .offset(x: out ? cos(angle) * 150 : 0, y: out ? sin(angle) * 90 : 0)
                    .scaleEffect(out ? 0.3 : 1)
                    .opacity(out ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            out = false
            withAnimation(.easeOut(duration: 1.0)) { out = true }
        }
    }
}
