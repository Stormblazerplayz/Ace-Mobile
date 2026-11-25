import SwiftUI

/// The mood journal screen. Today's page on one side (mood, words and tags), and how your days
/// are going on the other: your streak, your mood line, a month of colored days and which
/// things go with your best days. Past days are listed below, with search.
struct JournalView: View {
    @ObservedObject private var store = JournalStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowMood: JournalMood?
    @State private var month = Date()
    @State private var openDay: DayPick?
    @State private var query = ""
    @State private var range = 7
    @State private var shown = false
    @State private var today = Date()

    /// A past day opened from the month grid or the list.
    struct DayPick: Identifiable {
        let date: Date
        var id: Date { date }
    }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                JournalGlow(mood: glowMood)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if sizeClass == .regular {
                            HStack(alignment: .top, spacing: 20) {
                                todayPanel
                                    .frame(maxWidth: .infinity)
                                VStack(spacing: 20) {
                                    statsGrid
                                    chartPanel
                                    monthPanel
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            todayPanel
                            statsGrid
                            chartPanel
                            monthPanel
                        }
                        pastDays
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Journal")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .tint(AceTheme.ace)
        .preferredColorScheme(.dark)
        .onAppear {
            today = Date()
            shown = true
        }
        .sheet(item: $openDay) { pick in
            JournalDaySheet(store: store, date: pick.date)
        }
    }

    // MARK: Today

    private var todayPanel: some View {
        JournalEditor(store: store, date: today, onMood: { mood in
            withAnimation(motion(.gentle)) { glowMood = mood }
        })
        .journalPanel(tint: glowMood?.color)
        .bounceReveal(shown)
    }

    // MARK: Stats

    private var statsGrid: some View {
        let streak = store.streak()
        let average = store.average(days: 7)
        let best = store.bestTag()
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(symbol: "flame.fill", colors: [AceTheme.amber, AceTheme.nova],
                     value: "\(streak)", label: streak == 1 ? "day in a row" : "days in a row")
                .boing(on: streak, scale: 1.1)
                .bounceReveal(shown, order: 1)
            StatTile(symbol: "book.pages.fill", colors: [AceTheme.ace, AceTheme.accent],
                     value: "\(store.entries.count)", label: store.entries.count == 1 ? "day written" : "days written")
                .bounceReveal(shown, order: 2)
            StatTile(symbol: average.map { JournalMood.nearest(to: $0).symbol } ?? "chart.line.uptrend.xyaxis",
                     colors: average.map { JournalMood.nearest(to: $0).colors } ?? [AceTheme.muted, AceTheme.ink],
                     value: average.map { JournalMood.nearest(to: $0).label } ?? "-",
                     label: "this week, mostly")
                .bounceReveal(shown, order: 3)
            StatTile(symbol: best.map { TagChip.symbol(for: $0.tag) } ?? "sparkles",
                     colors: [AceTheme.good, AceTheme.ace],
                     value: best?.tag ?? "-",
                     label: best == nil ? "your best days will show here" : "goes with your best days")
                .bounceReveal(shown, order: 4)
        }
    }

    // MARK: Chart

    private var chartPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Mood line")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                Picker("Range", selection: $range) {
                    Text("Week").tag(7)
                    Text("Month").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
            MoodTrendChart(points: store.trend(days: range))
                .id(range)
                .frame(height: 180)
                .transition(.opacity)
        }
        .journalPanel()
        .animation(motion(.gentle), value: range)
        .bounceReveal(shown, order: 5)
    }

    // MARK: Month

    private var monthPanel: some View {
        MonthMoodGrid(store: store, month: $month) { date in
            if store.calendar.isDateInToday(date) { return }
            openDay = DayPick(date: date)
        }
        .journalPanel()
        .bounceReveal(shown, order: 6)
    }

    // MARK: Past days

    private var pastDays: some View {
        let past = store.search(query).filter { $0.day != store.dayKey(today) }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Past days")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AceTheme.muted)
                    TextField("Search words or tags", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(AceTheme.fg)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AceTheme.muted)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .frame(maxWidth: 320)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
            if past.isEmpty {
                Text(query.isEmpty ? String("Days you write show up here.") : String("No days match \"\(query)\"."))
                    .foregroundStyle(AceTheme.muted)
                    .padding(.vertical, 10)
            }
            LazyVStack(spacing: 12) {
                ForEach(Array(past.enumerated()), id: \.element.id) { i, entry in
                    Button {
                        if let date = date(for: entry.day) { openDay = DayPick(date: date) }
                    } label: {
                        JournalEntryCard(entry: entry, date: date(for: entry.day))
                    }
                    .buttonStyle(BouncyButtonStyle(depth: 0.97))
                    .bounceReveal(shown, order: 7 + min(i, 8))
                }
            }
            .animation(motion(.bouncy), value: past.map(\.id))
        }
        .padding(.top, 6)
    }

    private func date(for day: String) -> Date? {
        let f = DateFormatter()
        f.calendar = store.calendar
        f.timeZone = store.calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: day) else { return nil }
        // Noon, so the day never slips into the one before.
        return store.calendar.date(byAdding: .hour, value: 12, to: d)
    }
}

/// A stat in a glowing tile: an icon in a gradient circle, a big value and a few words.
struct StatTile: View {
    let symbol: String
    let colors: [Color]
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                .shadow(color: (colors.first ?? .clear).opacity(0.5), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.fg.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

private struct JournalPanel: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: 0x12101F).opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(LinearGradient(colors: [(tint ?? .white).opacity(0.45), .white.opacity(0.06)],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
            )
            .shadow(color: (tint ?? .black).opacity(0.3), radius: 22, y: 10)
    }
}

private extension View {
    /// The dark glass panel the journal's sections sit on, edged in the mood's color.
    func journalPanel(tint: Color? = nil) -> some View {
        modifier(JournalPanel(tint: tint))
    }
}
