import Charts
import SwiftUI

// The pieces of the mood journal: the glowing backdrop, the mood picker, the month grid,
// the mood chart, the tag chips and the entry cards.

/// A dark backdrop that glows in the colors of a mood, with soft lights that drift and breathe.
/// When the mood changes the glow fades over to the new colors. It holds still with Bouncy
/// animations off or Reduce Motion on.
struct JournalGlow: View {
    var mood: JournalMood?
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        let colors = mood?.colors ?? [AceTheme.accent, AceTheme.ace]
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !moving)) { context in
            let t = moving ? context.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, d = max(w, h)
                ZStack {
                    AceTheme.background
                    Circle()
                        .fill(colors[0].opacity(0.5))
                        .frame(width: d * 0.7, height: d * 0.7)
                        .blur(radius: 100)
                        .scaleEffect(1 + 0.08 * CGFloat(sin(t / 3)))
                        .offset(x: -w * 0.3 + CGFloat(cos(t / 8)) * w * 0.12, y: -h * 0.32 + CGFloat(sin(t / 6)) * h * 0.06)
                    Circle()
                        .fill(colors[colors.count - 1].opacity(0.42))
                        .frame(width: d * 0.6, height: d * 0.6)
                        .blur(radius: 100)
                        .scaleEffect(1 + 0.08 * CGFloat(cos(t / 3.6)))
                        .offset(x: w * 0.32 + CGFloat(sin(t / 9)) * w * 0.1, y: h * 0.28 + CGFloat(cos(t / 7)) * h * 0.08)
                    Circle()
                        .fill(AceTheme.accent.opacity(0.22))
                        .frame(width: d * 0.4, height: d * 0.4)
                        .blur(radius: 90)
                        .offset(x: CGFloat(cos(t / 11)) * w * 0.25, y: CGFloat(sin(t / 10)) * h * 0.2)
                }
                .frame(width: w, height: h)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: mood)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A round mood face: the mood's gradient with its weather icon.
struct MoodBadge: View {
    let mood: JournalMood
    var size: CGFloat = 56
    var glow = true

    var body: some View {
        Image(systemName: mood.symbol)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: size * 0.44, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(mood.gradient, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1.5))
            .shadow(color: glow ? mood.color.opacity(0.55) : .clear, radius: size * 0.22, y: size * 0.08)
    }
}

/// Five mood faces in a row. The one you pick springs up and glows, the rest shrink back.
struct MoodPicker: View {
    @Binding var selection: JournalMood?
    var size: CGFloat = 70
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        HStack(spacing: 10) {
            ForEach(JournalMood.allCases) { mood in
                let picked = selection == mood
                let dim = selection != nil && !picked
                Button {
                    withAnimation(AceMotion.animation(.pop, bouncy: bouncy, reduceMotion: reduceMotion)) {
                        selection = mood
                    }
                    taps += 1
                    Haptics.shared.play(.tick)
                } label: {
                    VStack(spacing: 8) {
                        MoodBadge(mood: mood, size: size, glow: picked || selection == nil)
                            .symbolEffect(.bounce, value: picked ? taps : 0)
                            .scaleEffect(moving ? (picked ? 1.18 : dim ? 0.86 : 1) : 1)
                            .offset(y: moving && picked ? -6 : 0)
                            .overlay {
                                if picked {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .padding(-6)
                                        .transition(.scale(scale: 1.3).combined(with: .opacity))
                                }
                            }
                        Text(mood.label)
                            .font(.subheadline.weight(picked ? .heavy : .semibold))
                            .foregroundStyle(picked ? .white : AceTheme.muted)
                    }
                    .opacity(dim ? 0.6 : 1)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BouncyButtonStyle(depth: 0.88))
                .accessibilityLabel(mood.label)
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
    }
}

/// Lays its children out in rows, wrapping onto a new row when one is full (for tag chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        for row in rows {
            var x = bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var items: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows[rows.count - 1]
            let needed = row.items.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width, !row.items.isEmpty {
                let y = row.y + row.height + spacing
                rows.append(Row(items: [index], y: y, width: size.width, height: size.height))
                continue
            }
            row.items.append(index)
            row.width = needed
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.items.isEmpty }
    }
}

/// A tag chip that lights up in the mood's colors when it's picked.
struct TagChip: View {
    let tag: String
    let picked: Bool
    var tint: Color = AceTheme.ace
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: picked ? "checkmark.circle.fill" : Self.symbol(for: tag))
                    .contentTransition(.symbolEffect(.replace))
                Text(tag)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(picked ? .white : AceTheme.fg.opacity(0.85))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(picked ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.white.opacity(0.08)), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(picked ? 0.35 : 0.12), lineWidth: 1))
            .shadow(color: picked ? tint.opacity(0.45) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.9))
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    static func symbol(for tag: String) -> String {
        switch tag {
        case "School": return "graduationcap.fill"
        case "Friends": return "person.2.fill"
        case "Family": return "house.fill"
        case "Gaming": return "gamecontroller.fill"
        case "Building": return "hammer.fill"
        case "Sports": return "figure.run"
        case "Outside": return "leaf.fill"
        case "Music": return "music.note"
        case "Reading": return "book.fill"
        case "Rest": return "bed.double.fill"
        default: return "tag.fill"
        }
    }
}

/// A month of days as colored squares, one color per mood. Today has a ring around it.
/// Tap a day to open it.
struct MonthMoodGrid: View {
    @ObservedObject var store: JournalStore
    @Binding var month: Date
    let open: (Date) -> Void
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var turn = 0

    private var title: String {
        let f = DateFormatter()
        f.calendar = store.calendar
        f.timeZone = store.calendar.timeZone
        f.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return f.string(from: month)
    }

    private var isThisMonth: Bool {
        store.calendar.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        let cells = store.monthCells(for: month)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Spacer()
                BouncyIconButton(symbol: "chevron.left", label: "Last month") { step(-1) }
                BouncyIconButton(symbol: "chevron.right", label: "Next month") { step(1) }
                    .disabled(isThisMonth)
                    .opacity(isThisMonth ? 0.3 : 1)
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(store.weekdaySymbols.enumerated()), id: \.offset) { _, s in
                    Text(s)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AceTheme.muted)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { i, date in
                    if let date {
                        dayCell(date)
                            .bounceReveal(shown, order: i / 7, rise: 8)
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
            .id(turn)
            legend
        }
        .onAppear { shown = true }
    }

    private func dayCell(_ date: Date) -> some View {
        let entry = store.entry(on: date)
        let today = store.calendar.isDateInToday(date)
        let future = store.calendar.startOfDay(for: date) > store.calendar.startOfDay(for: Date())
        let number = store.calendar.component(.day, from: date)
        return Button {
            open(date)
        } label: {
            Text("\(number)")
                .font(.subheadline.weight(entry == nil ? .medium : .heavy))
                .foregroundStyle(entry == nil ? AceTheme.fg.opacity(future ? 0.25 : 0.7) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(entry.map { AnyShapeStyle($0.mood.gradient) } ?? AnyShapeStyle(Color.white.opacity(future ? 0.02 : 0.06)))
                }
                .overlay {
                    if today {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white, lineWidth: 2)
                    }
                }
                .shadow(color: entry?.mood.color.opacity(0.4) ?? .clear, radius: 5, y: 2)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.85))
        .disabled(future)
        .accessibilityLabel(accessibility(for: date, entry: entry))
    }

    private func accessibility(for date: Date, entry: JournalEntry?) -> String {
        let day = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        guard let entry else { return "\(day), nothing written" }
        return "\(day), \(entry.mood.label)"
    }

    private var legend: some View {
        let counts = store.moodCounts(inMonthOf: month)
        return HStack(spacing: 14) {
            ForEach(JournalMood.allCases) { mood in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(mood.gradient)
                        .frame(width: 14, height: 14)
                    Text("\(counts[mood] ?? 0)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(AceTheme.fg.opacity(0.85))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(counts[mood] ?? 0) \(mood.label) days")
            }
            Spacer(minLength: 0)
        }
    }

    private func step(_ by: Int) {
        guard let next = store.calendar.date(byAdding: .month, value: by, to: month) else { return }
        withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) {
            month = next
        }
        // A new month cascades in again.
        shown = false
        turn += 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            shown = true
        }
    }
}

/// The last 7 or 30 days of moods as a smooth line over a glowing area, with a dot per day.
struct MoodTrendChart: View {
    let points: [MoodPoint]
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    private var written: [(date: Date, score: Int)] {
        points.compactMap { p in p.score.map { (date: p.date, score: $0) } }
    }

    var body: some View {
        let shownPoints = written
        Chart {
            ForEach(shownPoints, id: \.date) { p in
                AreaMark(x: .value("Day", p.date, unit: .day), y: .value("Mood", grown ? p.score : 1))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [AceTheme.ace.opacity(0.45), AceTheme.ace.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Day", p.date, unit: .day), y: .value("Mood", grown ? p.score : 1))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .foregroundStyle(LinearGradient(colors: [AceTheme.accent, AceTheme.ace, AceTheme.good],
                                                    startPoint: .leading, endPoint: .trailing))
                PointMark(x: .value("Day", p.date, unit: .day), y: .value("Mood", grown ? p.score : 1))
                    .symbolSize(110)
                    .foregroundStyle(JournalMood.nearest(to: Double(p.score)).color)
            }
        }
        .chartYScale(domain: 1...5)
        .chartXScale(domain: (points.first?.date ?? Date())...(points.last?.date ?? Date()))
        .chartYAxis {
            AxisMarks(values: [1, 3, 5]) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.1))
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Image(systemName: JournalMood.nearest(to: Double(v)).symbol)
                            .foregroundStyle(JournalMood.nearest(to: Double(v)).color)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: points.count > 10 ? 7 : 1)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .foregroundStyle(AceTheme.muted)
            }
        }
        .overlay {
            if shownPoints.isEmpty {
                Text("Write a few days and your mood line shows up here.")
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            withAnimation(AceMotion.animation(.gentle, bouncy: bouncy, reduceMotion: reduceMotion)?.delay(0.15)) {
                grown = true
            }
            if reduceMotion { grown = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }

    private var summary: String {
        let scores = written.map(\.score)
        guard !scores.isEmpty else { return "No moods written yet" }
        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        return "Mood chart: \(scores.count) days written, mostly \(JournalMood.nearest(to: avg).label)"
    }
}

/// A past entry: a mood stripe, the date, the words and the tags.
struct JournalEntryCard: View {
    let entry: JournalEntry
    let date: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MoodBadge(mood: entry.mood, size: 46)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(date.map { $0.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) } ?? entry.day)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(entry.mood.label)
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(entry.mood.color)
                }
                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.body)
                        .foregroundStyle(AceTheme.fg.opacity(0.9))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                if !entry.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Label(tag, systemImage: TagChip.symbol(for: tag))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AceTheme.fg.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(entry.mood.gradient)
                .frame(width: 5)
                .padding(.vertical, 14)
        }
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}
