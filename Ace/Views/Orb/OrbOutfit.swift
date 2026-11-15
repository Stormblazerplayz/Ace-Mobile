import SwiftUI

/// Little seasonal outfits Ace's orb wears, picked by the date.
enum OrbOutfit: String, CaseIterable {
    case santaHat, snowflake, partyHat, hearts, shamrock, bunnyEars, fireworks, pumpkin

    /// What it's called ("Santa hat").
    var label: String {
        switch self {
        case .santaHat: return "Santa hat"
        case .snowflake: return "Snowflake"
        case .partyHat: return "Party hat"
        case .hearts: return "Hearts"
        case .shamrock: return "Shamrock"
        case .bunnyEars: return "Bunny ears"
        case .fireworks: return "Fireworks"
        case .pumpkin: return "Pumpkin"
        }
    }

    /// When Ace wears it, in words.
    var when: String {
        switch self {
        case .santaHat: return "December 1 to 26"
        case .snowflake: return "December 27 to 30 and January 3 to February 9"
        case .partyHat: return "December 31 to January 2"
        case .hearts: return "February 10 to 14"
        case .shamrock: return "March 15 to 17"
        case .bunnyEars: return "3 days before Easter to Easter Monday"
        case .fireworks: return "July 3 and 4"
        case .pumpkin: return "October 24 to 31"
        }
    }

    /// The outfit for a day, or nil on a plain day.
    static func forDate(_ date: Date, calendar: Calendar = .current) -> OrbOutfit? {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        // Easter moves around, so it's worked out for the year.
        if let easter = easterSunday(year: year),
           let easterDate = calendar.date(from: DateComponents(year: year, month: easter.month, day: easter.day)),
           let gap = calendar.dateComponents([.day], from: calendar.startOfDay(for: easterDate), to: calendar.startOfDay(for: date)).day,
           (-3...1).contains(gap) {
            return .bunnyEars
        }
        switch (month, day) {
        case (12, 1...26): return .santaHat
        case (12, 27...30): return .snowflake
        case (12, 31), (1, 1...2): return .partyHat
        case (1, 3...31), (2, 1...9): return .snowflake
        case (2, 10...14): return .hearts
        case (3, 15...17): return .shamrock
        case (7, 3...4): return .fireworks
        case (10, 24...31): return .pumpkin
        default: return nil
        }
    }

    /// Easter Sunday for a year (month and day), using the anonymous Gregorian method.
    static func easterSunday(year y: Int) -> (month: Int, day: Int)? {
        guard y > 1582 else { return nil }
        let a = y % 19
        let b = y / 100
        let c = y % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = (h + l - 7 * m + 114) % 31 + 1
        return (month, day)
    }
}

/// Draws an outfit on an orb that is `size` across. Put it on top of the orb, centered on it.
/// Everything stays close to the orb so it fits inside the island, and it never takes taps.
struct OrbOutfitView: View {
    var outfit: OrbOutfit
    var size: CGFloat

    var body: some View {
        ZStack {
            switch outfit {
            case .santaHat: santaHat
            case .snowflake: snowflake
            case .partyHat: partyHat
            case .hearts: hearts
            case .shamrock: shamrock
            case .bunnyEars: bunnyEars
            case .fireworks: fireworks
            case .pumpkin: pumpkin
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var d: CGFloat { size }

    // MARK: The outfits

    private var santaHat: some View {
        ZStack {
            HatShape(lean: 0.35)
                .fill(LinearGradient(colors: [Color(hex: 0xFF4D4D), Color(hex: 0xC4161C)], startPoint: .top, endPoint: .bottom))
                .frame(width: d * 0.62, height: d * 0.42)
                .offset(y: -d * 0.12)
            Capsule()
                .fill(Color.white)
                .frame(width: d * 0.7, height: d * 0.13)
                .offset(y: d * 0.08)
            Circle()
                .fill(Color.white)
                .frame(width: d * 0.15, height: d * 0.15)
                .offset(x: d * 0.33, y: -d * 0.3)
        }
        .rotationEffect(.degrees(16))
        .offset(x: d * 0.06, y: -d * 0.38)
    }

    private var partyHat: some View {
        ZStack {
            HatShape(lean: 0)
                .fill(LinearGradient(colors: [Color(hex: 0xFF6FD8), Color(hex: 0x8F7CFF)], startPoint: .top, endPoint: .bottom))
                .frame(width: d * 0.4, height: d * 0.42)
            // Dots on the hat.
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: 0xFFE08A))
                    .frame(width: d * 0.06, height: d * 0.06)
                    .offset(x: CGFloat(i - 1) * d * 0.08, y: d * (0.1 - 0.08 * CGFloat(abs(i - 1))))
            }
            Circle()
                .fill(Color(hex: 0xFFE08A))
                .frame(width: d * 0.12, height: d * 0.12)
                .offset(y: -d * 0.22)
        }
        .rotationEffect(.degrees(14))
        .offset(x: d * 0.1, y: -d * 0.4)
    }

    private var hearts: some View {
        ZStack {
            HeartShape()
                .fill(Color(hex: 0xFF5F8F))
                .frame(width: d * 0.24, height: d * 0.22)
                .rotationEffect(.degrees(-14))
                .offset(x: -d * 0.42, y: -d * 0.36)
            HeartShape()
                .fill(Color(hex: 0xFF8FB1))
                .frame(width: d * 0.3, height: d * 0.27)
                .rotationEffect(.degrees(12))
                .offset(x: d * 0.4, y: -d * 0.36)
            HeartShape()
                .fill(Color(hex: 0xFF3D6E))
                .frame(width: d * 0.18, height: d * 0.16)
                .offset(x: d * 0.44, y: d * 0.3)
        }
    }

    private var shamrock: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                HeartShape()
                    .fill(Color(hex: 0x2FBF5A))
                    .frame(width: d * 0.2, height: d * 0.18)
                    .offset(y: -d * 0.09)
                    .rotationEffect(.degrees(Double(i) * 120))
            }
            Capsule()
                .fill(Color(hex: 0x1E8C3F))
                .frame(width: d * 0.04, height: d * 0.16)
                .rotationEffect(.degrees(-25))
                .offset(x: d * 0.04, y: d * 0.13)
        }
        .offset(x: d * 0.34, y: -d * 0.36)
    }

    private var bunnyEars: some View {
        ZStack {
            bunnyEar.rotationEffect(.degrees(-16)).offset(x: -d * 0.16)
            bunnyEar.rotationEffect(.degrees(16)).offset(x: d * 0.16)
        }
        .offset(y: -d * 0.42)
    }

    private var bunnyEar: some View {
        ZStack {
            Ellipse()
                .fill(Color.white)
                .frame(width: d * 0.17, height: d * 0.42)
            Ellipse()
                .fill(Color(hex: 0xFFB3C7))
                .frame(width: d * 0.08, height: d * 0.3)
        }
    }

    private var fireworks: some View {
        ZStack {
            Burst(rays: 8)
                .stroke(Color(hex: 0xFF5A4E), style: StrokeStyle(lineWidth: max(1, d * 0.03), lineCap: .round))
                .frame(width: d * 0.34, height: d * 0.34)
                .offset(x: -d * 0.4, y: -d * 0.36)
            Burst(rays: 8)
                .stroke(Color(hex: 0x5BB6FF), style: StrokeStyle(lineWidth: max(1, d * 0.03), lineCap: .round))
                .frame(width: d * 0.38, height: d * 0.38)
                .offset(x: d * 0.4, y: -d * 0.34)
            Burst(rays: 6)
                .stroke(Color(hex: 0xFFE08A), style: StrokeStyle(lineWidth: max(1, d * 0.025), lineCap: .round))
                .frame(width: d * 0.22, height: d * 0.22)
                .offset(x: d * 0.02, y: -d * 0.5)
        }
    }

    private var snowflake: some View {
        ZStack {
            Burst(rays: 6, inner: 0)
                .stroke(Color(hex: 0xDFF3FF), style: StrokeStyle(lineWidth: max(1, d * 0.035), lineCap: .round))
                .frame(width: d * 0.36, height: d * 0.36)
                .offset(x: d * 0.38, y: -d * 0.34)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: d * 0.06, height: d * 0.06)
                .offset(x: -d * 0.42, y: -d * 0.3)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: d * 0.04, height: d * 0.04)
                .offset(x: -d * 0.3, y: -d * 0.48)
        }
    }

    private var pumpkin: some View {
        ZStack {
            // Orange ribs over the orb, so it looks like a pumpkin.
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .stroke(Color(hex: 0xFF8A1F).opacity(0.75), lineWidth: max(1, d * 0.035))
                    .frame(width: d * (0.3 + 0.32 * CGFloat(i)), height: d * 0.92)
            }
            // A stem and a leaf on top.
            RoundedRectangle(cornerRadius: d * 0.03)
                .fill(Color(hex: 0x6B8E23))
                .frame(width: d * 0.1, height: d * 0.2)
                .rotationEffect(.degrees(10))
                .offset(y: -d * 0.52)
            Ellipse()
                .fill(Color(hex: 0x3FA34D))
                .frame(width: d * 0.2, height: d * 0.09)
                .rotationEffect(.degrees(-20))
                .offset(x: d * 0.13, y: -d * 0.5)
        }
    }
}

/// A pointy hat: a cone whose tip can lean to the right (0 = straight up).
struct HatShape: Shape {
    var lean: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let tip = CGPoint(x: rect.midX + rect.width * 0.5 * lean, y: rect.minY)
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: tip, control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.25))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.4))
        p.closeSubpath()
        return p
    }
}

/// A heart.
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.3),
                   control1: CGPoint(x: rect.midX - w * 0.2, y: rect.maxY - h * 0.2),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.6))
        p.addArc(center: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.3), radius: w * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.6),
                   control2: CGPoint(x: rect.midX + w * 0.2, y: rect.maxY - h * 0.2))
        p.closeSubpath()
        return p
    }
}

/// Lines shooting out from the middle, for fireworks and snowflakes.
struct Burst: Shape {
    var rays: Int
    /// How far from the middle each line starts (0...1 of the radius).
    var inner: CGFloat = 0.35

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let count = max(1, rays)
        for i in 0..<count {
            let a = Double(i) / Double(count) * 2 * Double.pi
            let dx = CGFloat(cos(a))
            let dy = CGFloat(sin(a))
            p.move(to: CGPoint(x: c.x + dx * r * inner, y: c.y + dy * r * inner))
            p.addLine(to: CGPoint(x: c.x + dx * r, y: c.y + dy * r))
        }
        return p
    }
}
