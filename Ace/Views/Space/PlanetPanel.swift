import SwiftUI

/// The card that slides in when you pick the Sun or a planet: a big spinning globe, its numbers,
/// how far away it is on the map's date, what a backpack would weigh there, and a fun fact.
struct PlanetPanel: View {
    let planet: Planet
    let clock: SpaceClock
    let moves: Bool
    let close: () -> Void
    let step: (Int) -> Void

    static let width: CGFloat = 370

    @State private var shown = false

    /// How far a planet's bands have turned at a moment: quicker days spin faster, slowed right
    /// down so you can follow them.
    static func spin(_ p: Planet, t: Double) -> Double {
        guard p.dayHours > 0 else { return 0 }
        return t * min(0.08, 0.02 * 24 / p.dayHours)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    globe
                        .bounceReveal(shown, order: 0)
                    stats
                        .bounceReveal(shown, order: 1)
                    distance
                        .bounceReveal(shown, order: 2)
                    backpack
                        .bounceReveal(shown, order: 3)
                    fact
                        .bounceReveal(shown, order: 4)
                }
                .padding(16)
            }
        }
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(hex: 0x0D0B22).opacity(0.94)))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(LinearGradient(colors: [Color(hex: planet.colors[0]).opacity(0.8), AceTheme.cardBorder],
                                   startPoint: .top, endPoint: .bottom), lineWidth: 1.5))
        .shadow(color: Color(hex: planet.colors[1]).opacity(0.35), radius: 30)
        .id(planet.id)
        .onAppear { shown = true }
    }

    private var header: some View {
        HStack(spacing: 4) {
            BouncyIconButton(symbol: "chevron.left", label: "Closer to the Sun") { step(-1) }
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text(planet.name)
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(AceTheme.fg)
                Text(planet.kind)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: planet.colors[0]))
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            BouncyIconButton(symbol: "chevron.right", label: "Farther from the Sun") { step(1) }
            BouncyIconButton(symbol: "xmark", label: "Close") { close() }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
    }

    private var globe: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !moves)) { timeline in
            let t = moves ? timeline.date.timeIntervalSinceReferenceDate : 0
            PlanetBall(planet: planet, sunAngle: planet.isSun ? nil : 140, spin: PlanetPanel.spin(planet, t: t))
                .frame(width: planet.id == "saturn" ? 300 : 170, height: planet.id == "saturn" ? 300 : 170)
                .frame(height: 190)
                .scaleEffect(moves ? 1 + 0.015 * sin(t * 1.5) : 1)
        }
        .frame(maxWidth: .infinity)
    }

    private var stats: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            PlanetStatTile(symbol: "circle.dashed", title: "Size", value: sizeText, tint: AceTheme.ace)
            if planet.isSun {
                PlanetStatTile(symbol: "arrow.triangle.2.circlepath", title: "Spins once in", value: SolarSystem.dayText(planet), tint: AceTheme.pebble)
            } else {
                PlanetStatTile(symbol: "arrow.triangle.2.circlepath", title: "One year", value: SolarSystem.yearText(planet), tint: AceTheme.pebble)
                PlanetStatTile(symbol: "sun.max.fill", title: "One day", value: SolarSystem.dayText(planet), tint: AceTheme.amber)
                PlanetStatTile(symbol: "moon.stars.fill", title: "Moons", value: planet.moons == 0 ? "None" : "\(planet.moons)", tint: AceTheme.accent)
            }
            PlanetStatTile(symbol: "thermometer.medium", title: planet.isSun ? "Surface" : "Average temperature", value: temperature, tint: AceTheme.nova)
            PlanetStatTile(symbol: "arrow.down.circle.fill", title: "Gravity", value: gravityText, tint: AceTheme.good)
        }
    }

    /// How far away it is on the map's date. It keeps changing while the clock runs.
    private var distance: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
            let date = clock.date(at: timeline.date)
            HStack(spacing: 12) {
                Image(systemName: planet.id == "earth" ? "house.fill" : "binoculars.fill")
                    .font(.title2)
                    .foregroundStyle(AceTheme.pebble)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(distanceTitle(date))
                        .font(.headline)
                        .foregroundStyle(AceTheme.fg)
                    Text(distanceDetail(date))
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .aceCard()
        }
    }

    private var backpack: some View {
        let pounds = Locale.current.measurementSystem == .us
        let onEarth: Double = pounds ? 20 : 10
        let there = SolarSystem.weight(onEarth, on: planet)
        let unit = pounds ? "lb" : "kg"
        let thereText = there >= 100 ? "\(Int(there.rounded()))" : String(format: "%.1f", there)
        return HStack(spacing: 12) {
            Image(systemName: "backpack.fill")
                .font(.title2)
                .foregroundStyle(AceTheme.good)
                .frame(width: 34)
            Text("A backpack that weighs \(Int(onEarth)) \(unit) on Earth would feel like **\(thereText) \(unit)** \(planet.isSun ? "on the Sun" : "on \(planet.name)").")
                .font(.subheadline)
                .foregroundStyle(AceTheme.fg)
            Spacer(minLength: 0)
        }
        .aceCard()
    }

    private var fact: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(AceTheme.accent)
                .frame(width: 34)
            Text(planet.fact)
                .font(.subheadline)
                .foregroundStyle(AceTheme.fg)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .aceCard()
    }

    // MARK: Words

    private var sizeText: String {
        let wide = planet.earthsWide
        if planet.id == "earth" { return "12,756 km wide" }
        if wide >= 10 { return "\(Int(wide.rounded())) Earths wide" }
        if wide >= 0.95 { return String(format: "%.1f Earths wide", wide) }
        return "\(Int((wide * 100).rounded()))% of Earth"
    }

    private var temperature: String {
        Measurement(value: Double(planet.tempC), unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    private var gravityText: String {
        let times = planet.gravity / 9.8
        if planet.id == "earth" { return "Normal" }
        return times >= 10 ? "\(Int(times.rounded()))× Earth" : String(format: "%.1f× Earth", times)
    }

    private func distanceTitle(_ date: Date) -> String {
        if planet.id == "earth" { return "You are here" }
        let au = planet.isSun ? 1.0 : SolarSystem.distanceFromEarth(planet, at: date)
        return SolarSystem.kilometers(au).replacingOccurrences(of: "about ", with: "") + " from Earth"
    }

    private func distanceDetail(_ date: Date) -> String {
        if planet.id == "earth" { return "Earth is about 150 million km from the Sun. Its light takes 8 minutes to reach us." }
        let au = planet.isSun ? 1.0 : SolarSystem.distanceFromEarth(planet, at: date)
        let when = Calendar.current.isDateInToday(date) ? "today" : "on " + date.formatted(date: .abbreviated, time: .omitted)
        return "Its light takes \(SolarSystem.lightTime(au)) to reach us \(when)."
    }
}

/// One small number card in the planet panel.
struct PlanetStatTile: View {
    let symbol: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(AceTheme.fg)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
