import SwiftUI

/// Habits: a big ring for the day, round buttons that fill with colored water as you tick them,
/// a flame for each streak, the week as dots and the last 12 weeks as a glowing grid.
struct HabitsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = HabitStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var editing: HabitEditTarget?
    @State private var deleting: Habit?
    @State private var shown = false
    @State private var bursts = 0
    @State private var taps: [UUID: Int] = [:]

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        // Redraws each minute so the screen moves on to a new day at midnight.
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let now = timeline.date
            ZStack {
                AceTheme.background.ignoresSafeArea()
                aurora
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        topBar(now: now)
                        if store.habits.isEmpty {
                            empty.bounceReveal(shown, order: 0)
                        } else {
                            today(now: now).bounceReveal(shown, order: 0, rise: 24)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], spacing: 14) {
                                ForEach(Array(store.habits.enumerated()), id: \.element.id) { index, habit in
                                    card(habit, now: now)
                                        .bounceReveal(shown, order: index + 1)
                                }
                            }
                            history(now: now)
                        }
                        ideas
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
            HabitEditor(store: store, target: target)
        }
        .confirmationDialog("Delete this habit?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible, presenting: deleting) { habit in
            Button("Delete \(habit.title) and its streak", role: .destructive) {
                withAnimation(motion(.snappy)) { store.delete(habit.id) }
                Haptics.shared.play(.tick)
            }
        }
        .onAppear { withAnimation(motion(.bouncy)) { shown = true } }
    }

    // MARK: Pieces

    /// Soft colored glows behind everything, in the colors of your habits.
    private var aurora: some View {
        let colors = store.habits.map(\.color.dark)
        let a = colors.first ?? AceTheme.accent
        let b = colors.dropFirst().first ?? AceTheme.ace
        return ZStack {
            Circle().fill(a.opacity(0.28)).frame(width: 500, height: 500).blur(radius: 130).offset(x: -200, y: -260)
            Circle().fill(b.opacity(0.24)).frame(width: 460, height: 460).blur(radius: 130).offset(x: 220, y: 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func topBar(now: Date) -> some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Habits")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
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
            .accessibilityLabel("New habit")
        }
        .padding(.top, 14)
    }

    /// The day's big ring and what's left.
    private func today(now: Date) -> some View {
        let progress = store.todayProgress(now: now)
        let done = store.doneToday(now: now)
        let total = store.habits.count
        let colors = store.habits.map(\.color.light)
        let best = store.habits.map { store.streak($0, now: now) }.max() ?? 0
        return HStack(spacing: 26) {
            ZStack {
                HabitDayRing(progress: progress, colors: colors)
                    .animation(motion(.bouncy), value: progress)
                VStack(spacing: 0) {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AceTheme.fg)
                        .contentTransition(.numericText(value: progress))
                        .animation(motion(.snappy), value: progress)
                    Text("today")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                }
                if moving {
                    HabitBurst(trigger: bursts, colors: colors)
                }
            }
            .frame(width: 150, height: 150)
            VStack(alignment: .leading, spacing: 8) {
                Text(done == total ? "All done today!" : "\(done) of \(total) done")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text(done == total ? "Every habit is ticked. Nice work." : "Tap a bubble each time you do it.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                if best > 0 {
                    Label("Best streak going: \(best) \(best == 1 ? "day" : "days")", systemImage: "flame.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.warn)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
    }

    private func card(_ habit: Habit, now: Date) -> some View {
        let count = store.count(habit, on: now)
        let streak = store.streak(habit, now: now)
        let done = count >= habit.goal
        return HStack(spacing: 16) {
            Button {
                tick(habit, now: now)
            } label: {
                HabitBubble(habit: habit, count: count)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.88))
            .boing(on: taps[habit.id] ?? 0, scale: 1.1)
            .accessibilityLabel("\(habit.title), \(count) of \(habit.goal)")
            .accessibilityHint(done ? "Tap to start today over" : "Tap to tick it")
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(habit.title)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .strikethrough(done, color: habit.color.light)
                        .foregroundStyle(AceTheme.fg)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .symbolEffect(.bounce, value: streak)
                            Text("\(streak)")
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(streak)))
                        }
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [AceTheme.pebble, AceTheme.bad], startPoint: .top, endPoint: .bottom))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AceTheme.warn.opacity(0.15)))
                        .accessibilityLabel("\(streak) day streak")
                    }
                }
                Text(habit.goal > 1 ? "\(count) of \(habit.goal) today" : (done ? "Done today" : "Not yet today"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(done ? habit.color.light : AceTheme.muted)
                    .contentTransition(.numericText(value: Double(count)))
                HabitWeekDots(week: store.week(habit, now: now), days: store.lastDays(7, now: now),
                              color: habit.color, calendar: store.calendar)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(done ? AnyShapeStyle(habit.color.dark.opacity(0.18)) : AnyShapeStyle(AceTheme.card))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(done ? habit.color.light.opacity(0.5) : AceTheme.cardBorder, lineWidth: 1)
        )
        .animation(motion(.snappy), value: done)
        .contextMenu {
            Button { undo(habit, now: now) } label: { Label("Take one tick away", systemImage: "minus.circle") }
                .disabled(count == 0)
            Button { editing = .edit(habit) } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { deleting = habit } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func history(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 12 weeks")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            ScrollView(.horizontal, showsIndicators: false) {
                HabitHeatMap(store: store, now: now)
                    .padding(4)
            }
            .defaultScrollAnchor(.trailing)
            HStack(spacing: 6) {
                Text("Less")
                ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { score in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(score > 0 ? AceTheme.good.opacity(0.25 + 0.75 * score) : Color.white.opacity(0.06))
                        .frame(width: 12, height: 12)
                }
                Text("More")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(AceTheme.muted)
        }
        .aceCard(padding: 18)
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(HabitColor.sky.gradient)
                .symbolEffect(.pulse, isActive: moving)
            Text("Build a habit")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            Text("Pick something you want to do every day. Tap its bubble each time and watch it fill up and your streak grow.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
            Button {
                editing = .new
            } label: {
                Label("Make a habit", systemImage: "plus")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(HabitColor.grape.gradient))
            }
            .buttonStyle(.aceBouncy)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .aceCard(padding: 0)
    }

    /// Ready-made habits you haven't added yet.
    @ViewBuilder
    private var ideas: some View {
        let missing = HabitIdea.all.filter { !store.has($0.title) }
        if !missing.isEmpty {
            Text("Ideas")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(missing) { idea in
                        Button {
                            withAnimation(motion(.bouncy)) { _ = store.add(idea) }
                            Haptics.shared.play(.success)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: idea.symbol)
                                Text(idea.goal > 1 ? "\(idea.title) ×\(idea.goal)" : idea.title)
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(idea.color.gradient))
                        }
                        .buttonStyle(.aceBouncy)
                        .accessibilityLabel("Add \(idea.title)")
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Actions

    private func tick(_ habit: Habit, now: Date) {
        let wasAllDone = !store.habits.isEmpty && store.doneToday(now: now) == store.habits.count
        let finished = store.tap(habit, now: now)
        taps[habit.id, default: 0] += 1
        let allDone = store.doneToday(now: now) == store.habits.count
        if finished && allDone && !wasAllDone {
            bursts += 1
            Haptics.shared.play(.success)
            SoundFX.shared.play(.success)
        } else if finished {
            Haptics.shared.play(.success)
        } else {
            Haptics.shared.play(.tick)
        }
    }

    private func undo(_ habit: Habit, now: Date) {
        store.undo(habit, now: now)
        Haptics.shared.play(.tick)
    }
}

/// What the editor sheet is for: a new habit, or changing one.
enum HabitEditTarget: Identifiable {
    case new
    case edit(Habit)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let habit): return habit.id.uuidString
        }
    }
}
