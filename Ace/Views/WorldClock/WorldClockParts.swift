import SwiftUI

/// An analog clock with hour marks and three hands. The second hand is optional.
struct WorldAnalogClock: View {
    /// The hour there, 0 to 24 with fractions.
    let hour: Double
    var dark = true
    var showsSeconds = true

    /// Hand angles in degrees, clockwise from 12.
    static func angles(hour: Double) -> (hour: Double, minute: Double, second: Double) {
        let h = hour.truncatingRemainder(dividingBy: 12)
        let minutes = hour * 60
        let seconds = hour * 3600
        return (h * 30, minutes.truncatingRemainder(dividingBy: 60) * 6, seconds.truncatingRemainder(dividingBy: 60) * 6)
    }

    var body: some View {
        let a = Self.angles(hour: hour)
        let face: Color = dark ? Color(hex: 0x14121F).opacity(0.75) : Color.white.opacity(0.85)
        let ink: Color = dark ? .white : Color(hex: 0x14121F)
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(face)
                Circle().stroke(ink.opacity(0.25), lineWidth: max(1, size * 0.02))
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(ink.opacity(i % 3 == 0 ? 0.9 : 0.45))
                        .frame(width: max(1.5, size * (i % 3 == 0 ? 0.035 : 0.02)), height: size * (i % 3 == 0 ? 0.1 : 0.06))
                        .offset(y: -size * 0.4)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                hand(length: 0.26, width: 0.055, color: ink, angle: a.hour, size: size)
                hand(length: 0.38, width: 0.035, color: ink, angle: a.minute, size: size)
                if showsSeconds {
                    hand(length: 0.42, width: 0.015, color: Color(hex: 0xFF5F8F), angle: a.second, size: size)
                }
                Circle()
                    .fill(Color(hex: 0xFF5F8F))
                    .frame(width: size * 0.07, height: size * 0.07)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color, angle: Double, size: CGFloat) -> some View {
        Capsule()
            .fill(color)
            .frame(width: max(1.5, size * width), height: size * length)
            .offset(y: -size * length / 2)
            .rotationEffect(.degrees(angle))
    }
}

/// A sky for a time of day: a gradient, stars at night, and the sun or moon along an arc.
struct WorldSkyView: View {
    let hour: Double

    /// Where the sun (in the day) or moon (at night) sits, 0 at the left edge to 1 at the right.
    static func arcPosition(hour: Double) -> Double {
        let h = hour.truncatingRemainder(dividingBy: 24)
        if h >= 6 && h < 18 { return (h - 6) / 12 }
        let night = h >= 18 ? h - 18 : h + 6
        return night / 12
    }

    var body: some View {
        let sky = WorldSky.at(hour: hour)
        let isDay = hour >= 6 && hour < 18
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = CGFloat(Self.arcPosition(hour: hour))
            // The arc: low at the edges, high in the middle.
            let lift = CGFloat(sin(Double(x) * .pi))
            ZStack {
                LinearGradient(colors: [Color(hex: sky.hexes.0), Color(hex: sky.hexes.1)], startPoint: .top, endPoint: .bottom)
                if sky == .night || sky == .dusk {
                    Canvas { context, size in
                        for i in 0..<28 {
                            let sx = CGFloat((i * 73) % 100) / 100 * size.width
                            let sy = CGFloat((i * 41) % 60) / 100 * size.height
                            let r: CGFloat = i % 4 == 0 ? 1.6 : 1
                            context.fill(Path(ellipseIn: CGRect(x: sx, y: sy, width: r * 2, height: r * 2)),
                                         with: .color(.white.opacity(sky == .night ? 0.8 : 0.35)))
                        }
                    }
                }
                Circle()
                    .fill(isDay ? Color(hex: 0xFFE07A) : Color(hex: 0xF2F0FF))
                    .frame(width: 30, height: 30)
                    .shadow(color: isDay ? Color(hex: 0xFFB020).opacity(0.9) : Color.white.opacity(0.5), radius: isDay ? 16 : 8)
                    .overlay(alignment: .topTrailing) {
                        if !isDay {
                            // A bite out of the moon to make a crescent.
                            Circle()
                                .fill(Color(hex: sky.hexes.0))
                                .frame(width: 22, height: 22)
                                .offset(x: 4, y: -4)
                        }
                    }
                    .position(x: 20 + x * (w - 40), y: h * 0.62 - lift * h * 0.45)
            }
        }
        .accessibilityHidden(true)
    }
}
