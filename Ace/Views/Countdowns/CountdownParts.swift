import SwiftUI

/// Shared look for countdowns: the gradient card, the rolling clock, the progress ring and the confetti.
enum CountdownFormat {
    /// "Friday, December 25" (with the time for one that isn't all day).
    static func when(_ date: Date, allDay: Bool) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate(allDay ? "EEEEMMMMd" : "EEEEMMMMdjmm")
        return f.string(from: date)
    }

    static func two(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }
}

/// One number of the clock (days, hours, minutes or seconds) in a glassy cell. The digits roll
/// like an odometer when they change.
struct CountdownCell: View {
    let value: Int
    let unit: String
    var big = true
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            Text(unit == "days" ? "\(value)" : CountdownFormat.two(value))
                .font(.system(size: big ? 46 : 26, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion), value: value)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(minWidth: big ? 74 : 44)
                .padding(.vertical, big ? 10 : 6)
                .padding(.horizontal, big ? 8 : 4)
                .background(
                    RoundedRectangle(cornerRadius: big ? 16 : 10, style: .continuous)
                        .fill(.black.opacity(0.22))
                )
                .overlay(
                    // The fold line across the middle, like a flip clock.
                    Rectangle()
                        .fill(.black.opacity(0.18))
                        .frame(height: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: big ? 16 : 10, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
            Text(unit)
                .font(.system(size: big ? 12 : 10, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit)")
    }
}

/// Days, hours, minutes and seconds side by side.
struct CountdownClock: View {
    let left: CountdownLeft
    var big = true

    var body: some View {
        HStack(alignment: .top, spacing: big ? 10 : 6) {
            CountdownCell(value: left.days, unit: "days", big: big)
            CountdownCell(value: left.hours, unit: "hours", big: big)
            CountdownCell(value: left.minutes, unit: "min", big: big)
            CountdownCell(value: left.seconds, unit: "sec", big: big)
        }
    }
}

/// A ring that fills up as the day gets closer.
struct CountdownRing: View {
    let progress: Double
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// The colorful card a countdown sits on: its theme's gradient, soft glowing blobs and a big faded icon.
struct CountdownBackdrop: View {
    let theme: CountdownTheme
    let symbol: String
    var corner: CGFloat = 26

    var body: some View {
        ZStack {
            theme.gradient
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: -90, y: -70)
            Circle()
                .fill(Color(hex: theme.hexes[0]).opacity(0.5))
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .offset(x: 120, y: 80)
            Image(systemName: symbol)
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white.opacity(0.12))
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 18, y: 22)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }
}

/// Confetti that rains down while a countdown is happening. With Reduce Motion it stays still.
struct CountdownConfetti: View {
    var still = false

    private struct Piece {
        let x: Double
        let speed: Double
        let delay: Double
        let size: Double
        let spin: Double
        let color: Color
    }

    private static let colors: [Color] = [
        AceTheme.pebble, AceTheme.nova, AceTheme.ace, AceTheme.good, AceTheme.accent, .white
    ]

    /// The same pieces every time, so the confetti doesn't jump when the view redraws.
    private static let pieces: [Piece] = (0..<70).map { i in
        let a = Double((i * 37) % 100) / 100
        let b = Double((i * 61) % 100) / 100
        let c = Double((i * 13) % 100) / 100
        return Piece(x: a, speed: 0.12 + b * 0.18, delay: c, size: 5 + b * 6, spin: 1 + a * 4,
                     color: CountdownConfetti.colors[i % CountdownConfetti.colors.count])
    }

    var body: some View {
        if still {
            Canvas { context, size in draw(context, size: size, time: 0.35) }
                .allowsHitTesting(false)
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    draw(context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func draw(_ context: GraphicsContext, size: CGSize, time: Double) {
        for p in Self.pieces {
            let fall = (time * p.speed + p.delay).truncatingRemainder(dividingBy: 1)
            let y = fall * (size.height + 40) - 20
            let x = p.x * size.width + sin(time * p.spin + p.delay * 6) * 14
            var piece = context
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(time * p.spin + p.delay * 10))
            let rect = CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)
            piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(p.color))
        }
    }
}
