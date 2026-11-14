import SwiftUI

/// Nimbus colors, so Ace on the iPad matches Ace in Nimbus on the PC.
enum AceTheme {
    static let bg = Color(hex: 0x06060B)
    static let window = Color(hex: 0x0A0A10)
    static let ink = Color(hex: 0x14121F)
    static let fg = Color(hex: 0xECEBF5)
    static let muted = Color(hex: 0x9A97B2)
    static let accent = Color(hex: 0x8F7CFF)
    static let ace = Color(hex: 0x5BB6FF)
    static let pebble = Color(hex: 0xFFCF3A)
    static let nova = Color(hex: 0xFF5F8F)
    static let good = Color(hex: 0x45D483)
    static let warn = Color(hex: 0xFFB020)
    static let bad = Color(hex: 0xFF5A4E)
    static let amber = Color(hex: 0xF5B83D)
    static let card = Color.white.opacity(0.07)
    static let cardBorder = Color.white.opacity(0.08)
    static let soft = Color.white.opacity(0.05)

    static let background = LinearGradient(
        colors: [Color(hex: 0x0E0C1F), bg],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    /// Makes a color from a hex number like 0x5BB6FF.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// The rounded card look used across the app.
struct AceCardStyle: ViewModifier {
    var padding: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AceTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AceTheme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func aceCard(padding: CGFloat = 14) -> some View {
        modifier(AceCardStyle(padding: padding))
    }
}
