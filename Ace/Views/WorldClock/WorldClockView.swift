import SwiftUI

/// World clocks: what time it is in other cities, each on a card whose sky matches the time there,
/// with a ticking analog clock and a slider to plan a time ("if it's 4 PM here, what time is it there?").
struct WorldClockView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = WorldClockStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown = false
    @State private var adding = false
    /// Hours moved forward or back with the planning slider.
    @State private var shift: Double = 0

    private var here: TimeZone { TimeZone.current }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date.addingTimeInterval(shift * 3600)
            let hereHour = WorldTime.hour(at: now, in: here)
            ZStack {
                AceTheme.background.ignoresSafeArea()
                // The whole screen takes on the sky outside right now, faintly.
                WorldSkyView(hour: hereHour)
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: WorldSky.at(hour: hereHour))
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        topBar
                        hereCard(now: now, hour: hereHour)
                            .bounceReveal(shown, order: 0, rise: 26)
                        planner(now: now)
                            .bounceReveal(shown, order: 1)
                        if store.cities.isEmpty {
                            Text("Add a city to see its time here.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(AceTheme.muted)
                                .frame(maxWidth: .infinity)
                                .aceCard()
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                                ForEach(Array(store.cities.enumerated()), id: \.element.id) { index, city in
                                    if let zone = city.zone {
                                        cityCard(city, zone: zone, now: now)
                                            .bounceReveal(shown, order: index + 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $adding) {
            WorldCityPicker(store: store)
        }
        .onAppear {
            withAnimation(motion(.bouncy)) { shown = true }
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("World clocks")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("What time is it around the world?")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
            Button {
                Haptics.shared.play(.pop)
                adding = true
            } label: {
                Label("Add city", systemImage: "plus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AceTheme.accent))
            }
            .buttonStyle(.aceBouncy)
            .disabled(store.cities.count >= WorldClockStore.maxCities)
        }
        .padding(.top, 14)
    }

    private func timeText(_ date: Date, zone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: zone))
    }

    private func dayText(_ date: Date, zone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(timeZone: zone).weekday(.wide).month(.wide).day())
    }

    private func hereCard(now: Date, hour: Double) -> some View {
        let sky = WorldSky.at(hour: hour)
        return HStack(spacing: 22) {
            WorldAnalogClock(hour: hour, dark: sky == .night || sky == .dusk, showsSeconds: shift == 0)
                .frame(width: 150)
            VStack(alignment: .leading, spacing: 6) {
                Label("Here", systemImage: "location.fill")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.8))
                Text(timeText(now, zone: here))
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(dayText(now, zone: here))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Label(sky.label, systemImage: sky.symbol)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .background(WorldSkyView(hour: hour))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.15), lineWidth: 1))
        .shadow(color: Color(hex: sky.hexes.1).opacity(0.35), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
    }

    /// Slide to try a different time here and see it everywhere else.
    private func planner(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(shift == 0 ? "Plan a time" : "If it's \(timeText(now, zone: here)) here...", systemImage: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Spacer()
                if shift != 0 {
                    Button("Back to now") {
                        Haptics.shared.play(.tick)
                        withAnimation(motion(.snappy)) { shift = 0 }
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AceTheme.ace)
                }
            }
            Slider(value: $shift, in: -12...12, step: 0.25) {
                Text("Hours from now")
            } minimumValueLabel: {
                Text("-12h").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(AceTheme.muted)
            } maximumValueLabel: {
                Text("+12h").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(AceTheme.muted)
            }
            .tint(AceTheme.accent)
            .onChange(of: shift) { _, _ in Haptics.shared.play(.tick) }
            Text(shift == 0 ? "Slide to see what time it would be in every city." : Self.shiftText(shift))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.muted)
        }
        .aceCard()
    }

    /// "2 hours 15 minutes from now" or "45 minutes ago".
    static func shiftText(_ hours: Double) -> String {
        let total = Int((abs(hours) * 60).rounded())
        let h = total / 60
        let m = total % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) \(h == 1 ? "hour" : "hours")") }
        if m > 0 { parts.append("\(m) \(m == 1 ? "minute" : "minutes")") }
        guard !parts.isEmpty else { return "Now" }
        return parts.joined(separator: " ") + (hours > 0 ? " from now" : " ago")
    }

    private func cityCard(_ city: WorldCity, zone: TimeZone, now: Date) -> some View {
        let hour = WorldTime.hour(at: now, in: zone)
        let sky = WorldSky.at(hour: hour)
        let awake = WorldTime.isAwakeHours(hour)
        return HStack(spacing: 14) {
            WorldAnalogClock(hour: hour, dark: sky == .night || sky == .dusk, showsSeconds: shift == 0)
                .frame(width: 74)
            VStack(alignment: .leading, spacing: 3) {
                Text(city.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(timeText(now, zone: zone))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(WorldTime.dayWord(at: now, in: zone, here: here)), \(WorldTime.differenceText(WorldTime.difference(zone, from: here, at: now)))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                Label(awake ? "Good time to call" : "Probably asleep", systemImage: awake ? "phone.fill" : "moon.zzz.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.black.opacity(0.25)))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(WorldSkyView(hour: hour))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(motion(.snappy)) { store.remove(city) }
                Haptics.shared.play(.tick)
            } label: { Label("Remove \(city.name)", systemImage: "trash") }
        }
    }
}

/// Search and tap cities to add or remove them.
struct WorldCityPicker: View {
    @ObservedObject var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(WorldClockStore.search(query)) { city in
                    let added = store.has(city)
                    Button {
                        if added {
                            store.remove(city)
                        } else {
                            store.add(city)
                        }
                        Haptics.shared.play(.tick)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AceTheme.fg)
                                Text(city.country)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AceTheme.muted)
                            }
                            Spacer()
                            if let zone = city.zone {
                                Text(Date().formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: zone)))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AceTheme.muted)
                            }
                            Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(added ? AceTheme.good : AceTheme.ace)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .disabled(!added && store.cities.count >= WorldClockStore.maxCities)
                    .accessibilityLabel("\(city.name), \(city.country)\(added ? ", added" : "")")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .searchable(text: $query, prompt: "City or country")
            .navigationTitle("Add cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
