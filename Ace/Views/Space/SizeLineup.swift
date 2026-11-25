import SwiftUI

/// The planets side by side at their real sizes, all to the same scale, with the edge of the
/// giant Sun peeking in from the left. Swipe along to see them all and tap one for its card.
struct SizeLineup: View {
    let selected: Planet?
    let moves: Bool
    let pick: (Planet?) -> Void

    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            // Jupiter, the biggest planet, gets about 40% of the screen's height.
            let jupiterPoints = max(140, min(320, Double(geo.size.height) * 0.4))
            let perKm = jupiterPoints / SolarSystem.planet("jupiter")!.diameterKm
            VStack(spacing: 10) {
                Spacer(minLength: 70)
                Text("Same scale for everything: if Earth were this big, the Sun would be \(Int(SolarSystem.sun.earthsWide.rounded())) Earths wide.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AceTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .bounceReveal(shown, order: 0)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 34) {
                        SunEdge(radius: SolarSystem.sun.diameterKm * perKm / 2, height: jupiterPoints * 1.5)
                            .onTapGesture { pick(SolarSystem.sun) }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("The Sun, \(Int(SolarSystem.sun.earthsWide.rounded())) Earths wide")
                            .accessibilityAddTraits(.isButton)
                        ForEach(Array(SolarSystem.planets.enumerated()), id: \.element.id) { i, p in
                            planet(p, diameter: max(4, p.diameterKm * perKm))
                                .bounceReveal(shown, order: i + 1)
                        }
                    }
                    .padding(.trailing, 40)
                    .frame(minHeight: jupiterPoints * 1.6)
                }
                Spacer(minLength: 160)
            }
        }
        .onAppear { shown = true }
    }

    private func planet(_ p: Planet, diameter: Double) -> some View {
        let d = CGFloat(diameter)
        let picked = selected?.id == p.id
        // Saturn's rings stick out a long way, so it gets a wider box.
        let box = p.id == "saturn" ? d * 2.1 : d
        return Button { pick(picked ? nil : p) } label: {
            VStack(spacing: 8) {
                TimelineView(.animation(minimumInterval: 1 / 30, paused: !moves)) { timeline in
                    let t = moves ? timeline.date.timeIntervalSinceReferenceDate : 0
                    PlanetBall(planet: p, sunAngle: 180, spin: PlanetPanel.spin(p, t: t))
                        .frame(width: box, height: box)
                        .frame(height: max(d, 24))
                }
                .shadow(color: Color(hex: p.colors[1]).opacity(picked ? 0.8 : 0.3), radius: picked ? 22 : 10)
                Text(p.name)
                    .font(.system(.headline, design: .rounded).weight(picked ? .heavy : .bold))
                    .foregroundStyle(picked ? .white : AceTheme.fg)
                Text(widthText(p))
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(picked ? Color(hex: p.colors[1]).opacity(0.18) : .clear))
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel("\(p.name), \(widthText(p))")
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private func widthText(_ p: Planet) -> String {
        if p.id == "earth" { return "1 Earth wide" }
        let w = p.earthsWide
        return w >= 1 ? String(format: "%.1f Earths wide", w) : String(format: "%.2f Earths wide", w)
    }
}

/// Just the edge of the Sun: on this scale it's far too big to fit, so you only see its curve.
struct SunEdge: View {
    let radius: Double
    let height: Double

    var body: some View {
        Canvas { ctx, size in
            let r = CGFloat(radius)
            // The Sun's middle sits off to the left, so its right-hand curve shows.
            let center = CGPoint(x: size.width - 24 - r, y: size.height / 2)
            let disc = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            ctx.drawLayer { glow in
                glow.addFilter(.blur(radius: 26))
                glow.fill(Path(ellipseIn: disc.insetBy(dx: -14, dy: -14)), with: .color(Color(hex: 0xFFB43C).opacity(0.6)))
            }
            ctx.fill(Path(ellipseIn: disc), with: .radialGradient(
                Gradient(colors: Array(SolarSystem.sun.colors.map { Color(hex: $0) }.reversed())),
                center: CGPoint(x: disc.maxX, y: center.y), startRadius: 0, endRadius: r * 0.35))
            ctx.draw(Text("The Sun")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundColor(.black.opacity(0.7)),
                     at: CGPoint(x: size.width - 80, y: size.height / 2))
        }
        .frame(width: 160, height: CGFloat(height))
    }
}
