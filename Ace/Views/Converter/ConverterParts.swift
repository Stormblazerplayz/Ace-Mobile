import SwiftUI

/// One tile in the grid of kinds (Length, Weight and so on). The picked one glows in its colors.
struct MeasureKindTile: View {
    let kind: MeasureKind
    let picked: Bool
    let glow: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .symbolEffect(.bounce, value: picked)
                Text(kind.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(picked ? Color.black : AceTheme.fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AceTheme.card)
                    if picked {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(hex: kind.hexes.0), Color(hex: kind.hexes.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: Color(hex: kind.hexes.0).opacity(0.5), radius: 14, y: 4)
                            .matchedGeometryEffect(id: "kindGlow", in: glow)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AceTheme.cardBorder, lineWidth: picked ? 0 : 1)
            )
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel(kind.title)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }
}

/// A big number that rolls its digits when it changes.
struct RollingNumber: View {
    let text: String
    let value: Double
    let size: CGFloat
    let color: Color
    let moves: Bool

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .contentTransition(moves ? .numericText(value: value) : .identity)
            .animation(moves ? Animation.spring(response: 0.45, dampingFraction: 0.78) : nil, value: text)
    }
}

/// A thermometer that fills up and turns from icy blue to red, with marks for freezing,
/// room temperature, body temperature and boiling.
struct ConverterThermometer: View {
    let celsius: Double
    /// How to label the marks (in the unit you converted to).
    let label: (Double) -> String
    let moves: Bool

    private var fill: Double { Converter.thermometerFill(celsius: celsius) }

    private var liquid: Color {
        let warm = fill
        return Color(
            red: 0.25 + 0.75 * warm,
            green: 0.6 - 0.25 * warm,
            blue: 1 - 0.75 * warm
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            GeometryReader { geo in
                let tubeHeight = geo.size.height - 44
                // The liquid sits 36 points up (inside the bulb) and can rise this far.
                let rise = tubeHeight - 12
                let bottom = geo.size.height - 36
                ZStack(alignment: .bottom) {
                    // The glass tube.
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1.5))
                        .frame(width: 26, height: tubeHeight)
                        .padding(.bottom, 30)
                    // The liquid.
                    Capsule()
                        .fill(LinearGradient(colors: [liquid.opacity(0.85), liquid], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: max(14, rise * fill))
                        .padding(.bottom, 36)
                        .animation(moves ? Animation.spring(response: 0.6, dampingFraction: 0.7) : nil, value: fill)
                    // The bulb.
                    Circle()
                        .fill(liquid)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
                        .shadow(color: liquid.opacity(0.6), radius: 12)
                        .animation(moves ? Animation.easeInOut(duration: 0.4) : nil, value: fill)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay(alignment: .topLeading) {
                    // Marks for the landmarks, lined up with the tube.
                    ForEach(Converter.landmarks) { mark in
                        let y = bottom - rise * Converter.thermometerFill(celsius: mark.celsius) - 1
                        Rectangle()
                            .fill(Color.white.opacity(0.45))
                            .frame(width: 10, height: 2)
                            .offset(x: geo.size.width / 2 + 15, y: y)
                    }
                }
            }
            .frame(width: 70, height: 280)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Converter.landmarks.reversed()) { mark in
                    let passed = celsius >= mark.celsius
                    HStack(spacing: 8) {
                        Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(passed ? AceTheme.good : AceTheme.muted)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(mark.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AceTheme.fg)
                            Text(label(mark.celsius))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AceTheme.muted)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(height: 280)
            Spacer(minLength: 0)
        }
    }
}

/// Bars that show how an amount compares with real things. The middle line is "one of them":
/// bars past it mean you need more than one, shorter bars mean less than one.
struct CompareBars: View {
    let comparisons: [MeasureComparison]
    let hexes: (UInt32, UInt32)
    let shown: Bool
    let moves: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(comparisons.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: item.reference.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: hexes.0))
                            .frame(width: 22)
                        Text(Converter.sentence(item))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AceTheme.fg)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07))
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: hexes.0), Color(hex: hexes.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: shown ? max(10, geo.size.width * Converter.barFill(item.times)) : 10)
                                .animation(
                                    moves ? Animation.spring(response: 0.7, dampingFraction: 0.72).delay(Double(index) * 0.08) : nil,
                                    value: shown
                                )
                                .animation(moves ? Animation.spring(response: 0.5, dampingFraction: 0.8) : nil, value: item.times)
                            // The "one of them" line in the middle.
                            Rectangle()
                                .fill(Color.white.opacity(0.55))
                                .frame(width: 2, height: 16)
                                .offset(x: geo.size.width * 0.5 - 1)
                        }
                    }
                    .frame(height: 12)
                    .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
            HStack {
                Text("less than one")
                Spacer()
                Text("one")
                Spacer()
                Text("lots")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(AceTheme.muted)
            .accessibilityHidden(true)
        }
    }
}
