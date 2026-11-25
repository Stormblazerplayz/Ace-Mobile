import SwiftUI

/// The big keyboard on the typing screen. Tap it to type. The next key glows, the finger to use
/// shows as a colored dot, and after a lesson it can turn into a heat map of the keys you missed.
struct TypingKeyboard: View {
    let next: (key: String, shift: Bool)?
    let shift: Bool
    let misses: [String: Int]
    let heatMap: Bool
    let keyHits: [String: Int]
    let moves: Bool
    let tap: (String) -> Void

    static let fingerColors: [Color] = [
        Color(hex: 0xFF5F8F), Color(hex: 0xFF9F43), Color(hex: 0xFFCF3A), Color(hex: 0x45D483),
        Color(hex: 0x5BB6FF), Color(hex: 0x8F7CFF), Color(hex: 0xC77DFF), Color(hex: 0xFF7AD9),
    ]

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 7
            let unit = (geo.size.width - gap * 10) / 11
            let keyHeight = min(unit * 0.95, (geo.size.height - gap * 3) / 4)
            VStack(spacing: gap) {
                ForEach(Array(TypingKeys.rows.enumerated()), id: \.offset) { r, row in
                    HStack(spacing: gap) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                            keyView(key)
                                .frame(width: width(of: key, row: r, unit: unit, gap: gap), height: keyHeight)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func width(of key: String, row: Int, unit: CGFloat, gap: CGFloat) -> CGFloat {
        switch key {
        case TypingKeys.space: return unit * 6 + gap * 5
        case TypingKeys.delete: return unit
        case TypingKeys.shift: return unit
        default: return unit
        }
    }

    private var maxMiss: Int { misses.values.max() ?? 0 }

    @ViewBuilder
    private func keyView(_ key: String) -> some View {
        let glow = isNext(key)
        let heat = heatMap && maxMiss > 0 ? Double(misses[key] ?? 0) / Double(maxMiss) : 0
        Button { tap(key) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fill(key, glow: glow, heat: heat))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(glow ? AceTheme.ace : Color.white.opacity(0.1), lineWidth: glow ? 2.5 : 1)
                label(for: key)
                if TypingKeys.bumps.contains(key) {
                    Capsule().fill(AceTheme.fg.opacity(0.5)).frame(width: 12, height: 3).offset(y: 14)
                }
                if !heatMap, let f = TypingKeys.finger(for: key) {
                    Circle().fill(Self.fingerColors[f]).frame(width: 6, height: 6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }
                if heatMap, let n = misses[key], n > 0 {
                    Text("\(n)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(5)
                }
            }
            .shadow(color: glow ? AceTheme.ace.opacity(0.8) : .clear, radius: glow ? 10 : 0)
            .scaleEffect(glow && moves ? 1.06 : 1)
            .animation(moves ? .spring(response: 0.3, dampingFraction: 0.5) : nil, value: glow)
            .boing(on: keyHits[key] ?? 0, scale: 0.9)
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel(spoken(key))
    }

    private func isNext(_ key: String) -> Bool {
        guard let next else { return false }
        if key == TypingKeys.shift { return next.shift && !shift }
        return key == next.key
    }

    private func fill(_ key: String, glow: Bool, heat: Double) -> AnyShapeStyle {
        if heat > 0 {
            return AnyShapeStyle(AceTheme.bad.opacity(0.18 + 0.7 * heat))
        }
        if glow {
            return AnyShapeStyle(LinearGradient(colors: [AceTheme.ace.opacity(0.55), AceTheme.accent.opacity(0.35)],
                                                startPoint: .top, endPoint: .bottom))
        }
        if key == TypingKeys.shift && shift { return AnyShapeStyle(AceTheme.accent.opacity(0.45)) }
        let special = key == TypingKeys.shift || key == TypingKeys.delete
        return AnyShapeStyle(Color.white.opacity(special ? 0.12 : 0.07))
    }

    @ViewBuilder
    private func label(for key: String) -> some View {
        switch key {
        case TypingKeys.shift:
            Image(systemName: shift ? "shift.fill" : "shift").font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AceTheme.fg)
        case TypingKeys.delete:
            Image(systemName: "delete.left").font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AceTheme.fg)
        case TypingKeys.space:
            Text("space").font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.muted)
        default:
            Text(shift ? key.uppercased() : key)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
        }
    }

    private func spoken(_ key: String) -> String {
        switch key {
        case TypingKeys.shift: return "Shift"
        case TypingKeys.delete: return "Delete"
        case TypingKeys.space: return "Space"
        case "'": return "Apostrophe"
        case ",": return "Comma"
        case ".": return "Period"
        case "!": return "Exclamation mark"
        case "?": return "Question mark"
        default: return shift ? key.uppercased() : key
        }
    }
}
