import SwiftUI

/// Colors for the wheel's slices, going round.
enum DecidePalette {
    static let slices: [UInt32] = [0xFF5F8F, 0xFFB020, 0x45D483, 0x5BB6FF, 0x8F7CFF, 0xFF8A3D, 0x1BC6FF, 0xB86BFF]

    static func color(_ index: Int, of count: Int) -> Color {
        // The last slice sits next to the first, so it never gets the first slice's color.
        var i = index % slices.count
        if count > 1, index == count - 1, i == 0 { i = 2 }
        return Color(hex: slices[i])
    }
}

/// The spinning wheel: colored slices with their names, a shiny rim and a hub in the middle.
struct DecideWheelView: View {
    let options: [String]
    let rotation: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Canvas { context, canvasSize in
                    draw(&context, size: canvasSize)
                }
                .rotationEffect(.degrees(rotation))
                Circle()
                    .stroke(
                        AngularGradient(colors: [.white.opacity(0.9), .white.opacity(0.2), .white.opacity(0.9), .white.opacity(0.2), .white.opacity(0.9)],
                                        center: .center),
                        lineWidth: 8
                    )
                Circle()
                    .fill(RadialGradient(colors: [.white, Color(hex: 0xDAD6F0)], center: .topLeading, startRadius: 2, endRadius: size * 0.12))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: size * 0.06, weight: .bold))
                            .foregroundStyle(AceTheme.accent)
                    )
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A wheel with \(options.count) choices: \(options.joined(separator: ", "))")
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize) {
        let count = max(1, options.count)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 4
        let slice = 360 / Double(count)
        for i in 0..<count {
            // Slices start at the top and go clockwise (SwiftUI angles start at the right, so take 90 off).
            let start = Angle.degrees(Double(i) * slice - 90)
            let end = Angle.degrees(Double(i + 1) * slice - 90)
            var path = Path()
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
            path.closeSubpath()
            context.fill(path, with: .color(DecidePalette.color(i, of: count)))
            context.stroke(path, with: .color(.white.opacity(0.35)), lineWidth: 1.5)

            guard i < options.count else { continue }
            let mid = Angle.degrees(Double(i) * slice + slice / 2 - 90)
            var label = context
            label.translateBy(x: center.x, y: center.y)
            label.rotate(by: mid)
            let fontSize = max(11, min(22, radius * 0.11 * (count > 10 ? 0.8 : 1)))
            let text = Text(options[i])
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            label.draw(text, at: CGPoint(x: radius * 0.6, y: 0), anchor: .center)
        }
    }
}

/// The pointer at the top of the wheel. It wiggles when the wheel stops.
struct DecidePointer: View {
    var body: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(LinearGradient(colors: [.white, Color(hex: 0xD9D4FF)], startPoint: .top, endPoint: .bottom))
            .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
            .accessibilityHidden(true)
    }
}

/// One die face with its dots.
struct DecideDie: View {
    let value: Int
    var size: CGFloat = 86
    var tint: Color = .white

    /// Where the dots go on a 3 by 3 grid (0 to 8, left to right, top to bottom).
    static func spots(_ value: Int) -> [Int] {
        switch value {
        case 1: return [4]
        case 2: return [0, 8]
        case 3: return [0, 4, 8]
        case 4: return [0, 2, 6, 8]
        case 5: return [0, 2, 4, 6, 8]
        case 6: return [0, 2, 3, 5, 6, 8]
        default: return []
        }
    }

    var body: some View {
        let dots = Set(Self.spots(value))
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(LinearGradient(colors: [tint, tint.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .overlay(
                Grid(horizontalSpacing: size * 0.1, verticalSpacing: size * 0.1) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { col in
                                Circle()
                                    .fill(Color(hex: 0x14121F))
                                    .frame(width: size * 0.16, height: size * 0.16)
                                    .opacity(dots.contains(row * 3 + col) ? 1 : 0)
                            }
                        }
                    }
                }
            )
            .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
            .accessibilityElement()
            .accessibilityLabel("\(value)")
    }
}

/// A coin with heads on one side and tails on the other.
struct DecideCoinFace: View {
    let heads: Bool
    var size: CGFloat = 170

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFFE38A), Color(hex: 0xF5B83D), Color(hex: 0xC98A12)],
                                     center: .topLeading, startRadius: 4, endRadius: size))
            Circle()
                .stroke(Color(hex: 0xFFF2C2).opacity(0.8), lineWidth: size * 0.04)
                .padding(size * 0.06)
            VStack(spacing: 2) {
                Image(systemName: heads ? "crown.fill" : "bolt.fill")
                    .font(.system(size: size * 0.3, weight: .heavy))
                Text(heads ? "HEADS" : "TAILS")
                    .font(.system(size: size * 0.1, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(hex: 0x8A5A00))
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: 0xF5B83D).opacity(0.5), radius: 20)
    }
}
