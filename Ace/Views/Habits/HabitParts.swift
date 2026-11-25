import SwiftUI

/// A wavy water line. `level` is how full (0 to 1), `phase` slides the wave sideways.
struct HabitWave: Shape {
    var level: Double
    var phase: Double
    var height: Double = 5

    /// Only the water level animates. The wave itself moves with the clock.
    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = min(1, max(0, level))
        // Hide the wave when it's empty, and keep it a little over the top when it's full.
        guard clamped > 0 else { return path }
        let wave = clamped >= 1 ? 0 : height
        let y = rect.maxY - rect.height * clamped
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: y))
        let steps = 24
        for i in 0...steps {
            let x = rect.minX + rect.width * Double(i) / Double(steps)
            let angle = (Double(i) / Double(steps)) * .pi * 2 + phase
            path.addLine(to: CGPoint(x: x, y: y + sin(angle) * wave))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The round habit button that fills up with colored water as you tick it, with a wave that sloshes.
struct HabitBubble: View {
    let habit: Habit
    let count: Int
    var size: CGFloat = 78
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var level: Double { min(1, Double(count) / Double(max(1, habit.goal))) }
    private var done: Bool { count >= habit.goal }
    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.06))
            // The wave slides along with the clock; with the bounce off or Reduce Motion it stays still.
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !moving)) { timeline in
                let phase = moving ? timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4) / 2.4 * .pi * 2 : 0
                ZStack {
                    HabitWave(level: level, phase: phase)
                        .fill(habit.color.gradient)
                        .opacity(0.9)
                    HabitWave(level: level, phase: phase + .pi)
                        .fill(habit.color.light.opacity(0.35))
                }
                .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion), value: level)
            }
            Image(systemName: done ? "checkmark" : habit.symbol)
                .font(.system(size: size * 0.32, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(done ? habit.color.light : .white.opacity(0.15), lineWidth: done ? 3 : 1.5))
        .shadow(color: done ? habit.color.dark.opacity(0.6) : .clear, radius: 14)
        .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion), value: count)
    }
}

/// A big ring for the whole day, made of every habit's colors.
struct HabitDayRing: View {
    let progress: Double
    let colors: [Color]
    var lineWidth: CGFloat = 18

    var body: some View {
        let ring = colors.isEmpty ? [AceTheme.accent, AceTheme.ace] : colors
        ZStack {
            Circle().stroke(.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(AngularGradient(colors: ring + [ring[0]], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: ring[0].opacity(0.5), radius: 10)
        }
    }
}

/// Little dots that burst out of the ring when every habit is done.
struct HabitBurst: View {
    let trigger: Int
    let colors: [Color]
    @State private var out = false

    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let angle = Double(i) / 16 * .pi * 2
                Circle()
                    .fill(colors.isEmpty ? AceTheme.pebble : colors[i % colors.count])
                    .frame(width: 9, height: 9)
                    .offset(x: out ? cos(angle) * 110 : 0, y: out ? sin(angle) * 110 : 0)
                    .opacity(out ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            out = false
            withAnimation(.easeOut(duration: 0.9)) { out = true }
        }
        .onAppear { out = true }
    }
}

/// The last weeks as a grid of squares, brighter where more habits were done.
struct HabitHeatMap: View {
    @ObservedObject var store: HabitStore
    let now: Date
    var weeks = 12

    var body: some View {
        let days = store.lastDays(weeks * 7, now: now)
        let columns = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
        HStack(alignment: .top, spacing: 5) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                VStack(spacing: 5) {
                    ForEach(column, id: \.self) { day in
                        let score = store.dayScore(day)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(score > 0 ? AceTheme.good.opacity(0.25 + 0.75 * score) : Color.white.opacity(0.06))
                            .frame(width: 16, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(.white.opacity(store.calendar.isDate(day, inSameDayAs: now) ? 0.8 : 0), lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The last \(weeks) weeks of habits")
    }
}

/// A habit's last 7 days as dots, with each day's first letter.
struct HabitWeekDots: View {
    let week: [Bool]
    let days: [Date]
    let color: HabitColor
    let calendar: Calendar

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(zip(week, days).enumerated()), id: \.offset) { _, pair in
                VStack(spacing: 3) {
                    Circle()
                        .fill(pair.0 ? AnyShapeStyle(color.gradient) : AnyShapeStyle(Color.white.opacity(0.1)))
                        .frame(width: 14, height: 14)
                    Text(letter(pair.1))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Done \(week.filter { $0 }.count) of the last 7 days")
    }

    private func letter(_ day: Date) -> String {
        let index = calendar.component(.weekday, from: day) - 1
        let symbols = calendar.veryShortWeekdaySymbols
        return symbols.indices.contains(index) ? symbols[index] : ""
    }
}
