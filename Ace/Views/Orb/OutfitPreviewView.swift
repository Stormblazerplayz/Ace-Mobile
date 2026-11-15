import SwiftUI

/// Every seasonal outfit on a sample orb, with its name and the days Ace wears it.
/// Opened from Settings ("Preview outfits").
struct OutfitPreviewView: View {
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(OrbOutfit.allCases, id: \.self) { outfit in
                    OutfitPreviewCell(outfit: outfit)
                }
            }
            .padding(16)
        }
        .background(AceTheme.background.ignoresSafeArea())
        .navigationTitle("Orb outfits")
    }
}

/// One outfit: a big orb wearing it, the island the way it looks at the top, and when it shows.
private struct OutfitPreviewCell: View {
    var outfit: OrbOutfit

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                OrbBody(tint: AceTheme.ace, tint2: AceTheme.accent, glow: 0.8, energy: 0.25, live: false)
                    .frame(width: 72, height: 72)
                OrbOutfitView(outfit: outfit, size: 72)
            }
            .frame(width: 110, height: 110)
            // The small island, as it shows at the top of the screen.
            ZStack {
                Capsule(style: .continuous).fill(Color.black)
                HStack(spacing: 0) {
                    ZStack {
                        OrbBody(tint: AceTheme.ace, tint2: AceTheme.accent, glow: 0.8, energy: 0.25, live: false)
                        OrbOutfitView(outfit: outfit, size: 30)
                    }
                    .frame(width: 30, height: 30)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(Color(white: 0.08))
                        .overlay(Circle().stroke(Color(white: 0.22), lineWidth: 1))
                        .frame(width: 9, height: 9)
                        .padding(.trailing, 6)
                }
                .padding(.horizontal, 5)
                .clipShape(Capsule(style: .continuous))
            }
            .frame(width: 120, height: 40)
            Text(outfit.label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            Text(outfit.when)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AceTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
