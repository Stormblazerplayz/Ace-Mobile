import SwiftUI

/// Countdowns: the next big day on a huge colorful card with a rolling clock, the rest as tiles
/// with rings that fill up as the day gets closer, and one-tap holidays. Confetti falls on the day.
struct CountdownsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CountdownStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var editing: CountdownEditTarget?
    @State private var shown = false
    @State private var drift = false
    @State private var deleting: Countdown?

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let upcoming = store.upcoming(now: now)
            ZStack {
                backdrop(theme: upcoming.first?.theme ?? .galaxy)
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        topBar
                        if let next = upcoming.first {
                            hero(next, now: now)
                                .bounceReveal(shown, order: 0, rise: 26)
                        } else {
                            empty
                                .bounceReveal(shown, order: 0)
                        }
                        if upcoming.count > 1 {
                            section("Coming up")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                                ForEach(Array(upcoming.dropFirst().enumerated()), id: \.element.id) { index, item in
                                    tile(item, now: now)
                                        .bounceReveal(shown, order: index + 1)
                                }
                            }
                        }
                        holidays
                        pastList(now: now)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $editing) { target in
            CountdownEditor(store: store, target: target)
        }
        .confirmationDialog("Delete this countdown?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible, presenting: deleting) { item in
            Button("Delete \(item.title)", role: .destructive) {
                withAnimation(motion(.snappy)) { store.delete(item.id) }
                Haptics.shared.play(.tick)
            }
        }
        .onAppear {
            withAnimation(motion(.bouncy)) { shown = true }
            if moving {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { drift = true }
            }
        }
    }

    // MARK: Pieces

    /// The whole screen glows in the colors of the next countdown, with blobs that slowly drift.
    private func backdrop(theme: CountdownTheme) -> some View {
        ZStack {
            AceTheme.background
            Circle()
                .fill(Color(hex: theme.hexes[0]).opacity(0.35))
                .frame(width: 520, height: 520)
                .blur(radius: 120)
                .offset(x: drift ? -160 : -60, y: drift ? -260 : -180)
            Circle()
                .fill(Color(hex: theme.hexes[2]).opacity(0.35))
                .frame(width: 480, height: 480)
                .blur(radius: 120)
                .offset(x: drift ? 200 : 120, y: drift ? 320 : 220)
        }
        .animation(motion(.gentle), value: theme)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Countdowns")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text(store.countdowns.isEmpty ? "Count down to the days you're waiting for" : countLine)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
            Button {
                Haptics.shared.play(.pop)
                editing = .new
            } label: {
                Label("New", systemImage: "plus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AceTheme.accent))
            }
            .buttonStyle(.aceBouncy)
            .accessibilityLabel("New countdown")
        }
        .padding(.top, 14)
    }

    private var countLine: String {
        let n = store.countdowns.count
        return n == 1 ? "1 countdown" : "\(n) countdowns"
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(AceTheme.fg)
    }

    /// The big card for the countdown that's soonest.
    private func hero(_ item: Countdown, now: Date) -> some View {
        let happening = store.isHappening(item, now: now)
        let when = store.occurrence(item, now: now)
        return Button {
            editing = .edit(item)
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(.white.opacity(0.2)))
                        .symbolEffect(.bounce, value: happening)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(happening ? "It's here!" : "Next up")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(item.title)
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    if item.repeatsYearly {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityLabel("Every year")
                    }
                }
                if happening {
                    Text(item.allDay ? "Today's the day! 🎉" : "Happening now! 🎉")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 18)
                } else {
                    CountdownClock(left: store.left(item, now: now))
                        .frame(maxWidth: .infinity)
                }
                HStack {
                    Label(CountdownFormat.when(when, allDay: item.allDay), systemImage: "calendar")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    if !happening {
                        ProgressView(value: store.progress(item, now: now))
                            .tint(.white)
                            .frame(width: 120)
                            .accessibilityLabel("How close it is")
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CountdownBackdrop(theme: item.theme, symbol: item.symbol, corner: 30))
            .overlay(
                Group {
                    if happening {
                        CountdownConfetti(still: !moving)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    }
                }
            )
            .shadow(color: item.theme.color.opacity(0.5), radius: 30, y: 14)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.97))
        .contextMenu { menu(item) }
    }

    /// A smaller card for a countdown further away.
    private func tile(_ item: Countdown, now: Date) -> some View {
        let happening = store.isHappening(item, now: now)
        let left = store.left(item, now: now)
        return Button {
            editing = .edit(item)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: item.symbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    ZStack {
                        CountdownRing(progress: happening ? 1 : store.progress(item, now: now), lineWidth: 4)
                        Text(happening ? "🎉" : "\(left.days)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(countsDown: true))
                    }
                    .frame(width: 40, height: 40)
                }
                Text(item.title)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(happening ? "Today!" : "in \(left.short)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Text(CountdownFormat.when(store.occurrence(item, now: now), allDay: item.allDay))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(CountdownBackdrop(theme: item.theme, symbol: item.symbol, corner: 22))
            .overlay(
                Group {
                    if happening {
                        CountdownConfetti(still: !moving)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            )
            .shadow(color: item.theme.color.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.95))
        .contextMenu { menu(item) }
        .accessibilityLabel("\(item.title), \(happening ? "today" : "in \(left.short)")")
    }

    @ViewBuilder
    private func menu(_ item: Countdown) -> some View {
        Button { editing = .edit(item) } label: { Label("Edit", systemImage: "pencil") }
        Button(role: .destructive) { deleting = item } label: { Label("Delete", systemImage: "trash") }
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(AceTheme.pebble)
                .symbolEffect(.pulse, isActive: moving)
            Text("Nothing to count down to yet")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            Text("Add a birthday, a trip, a game launch or the last day of school, and watch the days tick away.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
            Button {
                editing = .new
            } label: {
                Label("Add a countdown", systemImage: "plus")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(CountdownTheme.galaxy.gradient))
            }
            .buttonStyle(.aceBouncy)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .aceCard(padding: 0)
    }

    /// Holidays you haven't added yet, one tap each.
    @ViewBuilder
    private var holidays: some View {
        let missing = CountdownPreset.all.filter { !store.has($0) }
        if !missing.isEmpty {
            section("Add a holiday")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(missing) { preset in
                        Button {
                            withAnimation(motion(.bouncy)) { _ = store.add(preset) }
                            Haptics.shared.play(.success)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: preset.symbol)
                                Text(preset.title)
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(preset.theme.gradient))
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Add \(preset.title)")
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }

    /// One-time countdowns that are over.
    @ViewBuilder
    private func pastList(now: Date) -> some View {
        let past = store.past(now: now)
        if !past.isEmpty {
            section("Done")
            VStack(spacing: 8) {
                ForEach(past) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.symbol)
                            .foregroundStyle(item.theme.color)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AceTheme.fg)
                            Text(CountdownFormat.when(item.date, allDay: item.allDay))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AceTheme.muted)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            deleting = item
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(AceTheme.muted)
                                .padding(8)
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Delete \(item.title)")
                    }
                    .aceCard(padding: 12)
                }
            }
        }
    }
}

/// What the editor sheet is for: a new countdown, or changing one.
enum CountdownEditTarget: Identifiable {
    case new
    case edit(Countdown)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let item): return item.id.uuidString
        }
    }
}
