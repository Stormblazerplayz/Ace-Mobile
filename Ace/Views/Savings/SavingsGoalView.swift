import SwiftUI

/// One jar up close: a big jar that fills as coins drop in, quick buttons to add money,
/// a chart of each week's saving, a guess at when you'll get there, and every deposit.
struct SavingsGoalView: View {
    @ObservedObject var store: SavingsStore
    let goalID: UUID

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var amountText = ""
    @State private var noteText = ""
    @State private var drops = 0
    @State private var burst = 0
    @State private var editing: SavingsEditTarget?
    @State private var confirmDelete = false
    @State private var warning: String?
    @FocusState private var typing: Bool

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    private var typedCents: Int? { SavingsMoney.cents(from: amountText) }

    var body: some View {
        NavigationStack {
            Group {
                if let goal = store.goal(goalID) {
                    content(goal)
                } else {
                    Text("This jar was deleted.")
                        .foregroundStyle(AceTheme.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            if let goal = store.goal(goalID) { editing = .edit(goal) }
                        } label: { Label("Edit jar", systemImage: "pencil") }
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete jar", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(store.goal(goalID) == nil)
                    .accessibilityLabel("More")
                }
            }
            .sheet(item: $editing) { target in
                SavingsEditor(store: store, target: target) { _ in }
            }
            .confirmationDialog("Delete this jar?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.delete(goalID)
                    Haptics.shared.play(.tick)
                    dismiss()
                }
            } message: {
                Text("Its savings history goes too. This can't be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func content(_ goal: SavingsGoal) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                jarHeader(goal)
                quickAdd(goal)
                customAmount(goal)
                if let date = store.estimate(goalID) {
                    estimateCard(date)
                }
                weeksCard(goal)
                historyCard(goal)
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func jarHeader(_ goal: SavingsGoal) -> some View {
        VStack(spacing: 10) {
            ZStack {
                SavingsJar(progress: goal.progress, color: goal.color, symbol: goal.symbol)
                    .frame(width: 200)
                    .animation(motion(.bouncy), value: goal.progress)
                SavingsCoinDrop(drops: drops, moving: moving)
                SavingsBurst(fire: burst)
            }
            .padding(.top, 30)
            Text(goal.title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
                .multilineTextAlignment(.center)
            Text(SavingsMoney.text(goal.savedCents))
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(goal.color.light)
                .contentTransition(.numericText())
                .animation(motion(.pop), value: goal.savedCents)
            Text(goal.isReached ? "You reached your goal of \(SavingsMoney.text(goal.targetCents))!"
                 : "of \(SavingsMoney.text(goal.targetCents)), \(SavingsMoney.text(goal.leftCents)) to go (\(Int((goal.progress * 100).rounded(.down)))%)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(goal.isReached ? Color(hex: 0xFFD54A) : AceTheme.muted)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private func quickAdd(_ goal: SavingsGoal) -> some View {
        HStack(spacing: 10) {
            ForEach(SavingsStore.quickAmounts, id: \.self) { cents in
                Button {
                    put(cents, into: goal)
                } label: {
                    Text("+" + SavingsMoney.text(cents))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(goal.color.gradient))
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel("Add \(SavingsMoney.text(cents))")
            }
        }
    }

    private func customAmount(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Other amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($typing)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.soft))
                TextField("Note (optional)", text: $noteText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.soft))
            }
            HStack(spacing: 10) {
                Button {
                    guard let cents = typedCents else { return }
                    put(cents, into: goal)
                } label: {
                    Label("Put in", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.good))
                }
                .buttonStyle(.aceBouncy)
                .disabled(typedCents == nil)
                .opacity(typedCents == nil ? 0.5 : 1)
                Button {
                    guard let cents = typedCents else { return }
                    take(cents, from: goal)
                } label: {
                    Label("Take out", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.card))
                }
                .buttonStyle(.aceBouncy)
                .disabled(typedCents == nil || goal.savedCents == 0)
                .opacity(typedCents == nil || goal.savedCents == 0 ? 0.5 : 1)
            }
            if let warning {
                Text(warning)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.warn)
            } else if !amountText.isEmpty && typedCents == nil {
                Text("Type an amount like 4.50")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.warn)
            }
        }
        .aceCard()
    }

    private func estimateCard(_ date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AceTheme.good)
            VStack(alignment: .leading, spacing: 2) {
                Text("At this pace, you'll get there around")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
            }
            Spacer(minLength: 0)
        }
        .aceCard()
        .accessibilityElement(children: .combine)
    }

    private func weeksCard(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 8 weeks")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AceTheme.muted)
            SavingsWeekBars(weeks: store.weekly(goalID, weeks: 8), color: goal.color)
                .animation(motion(.bouncy), value: goal.savedCents)
        }
        .aceCard()
    }

    private func historyCard(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AceTheme.muted)
            if goal.entries.isEmpty {
                Text("Nothing in the jar yet. Tap a button above to put money in.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            } else {
                ForEach(Array(goal.entries.reversed().prefix(40))) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.cents >= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(entry.cents >= 0 ? AceTheme.good : AceTheme.bad)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.note.isEmpty ? (entry.cents >= 0 ? "Put in" : "Took out") : entry.note)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AceTheme.fg)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AceTheme.muted)
                        }
                        Spacer()
                        Text((entry.cents >= 0 ? "+" : "-") + SavingsMoney.text(abs(entry.cents)))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(entry.cents >= 0 ? AceTheme.good : AceTheme.bad)
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation(motion(.snappy)) { store.removeEntry(goalID, entry: entry.id) }
                            Haptics.shared.play(.tick)
                        } label: { Label("Remove", systemImage: "trash") }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aceCard()
    }

    // MARK: Money

    private func put(_ cents: Int, into goal: SavingsGoal) {
        let wasReached = goal.isReached
        let added = store.deposit(goalID, cents: cents, note: noteText)
        guard added > 0 else {
            warning = "This jar is full."
            return
        }
        warning = added < cents ? "Only \(SavingsMoney.text(added)) fit in this jar." : nil
        amountText = ""
        noteText = ""
        typing = false
        drops += 1
        Haptics.shared.play(.pop)
        if !wasReached, store.goal(goalID)?.isReached == true {
            burst += 1
            Haptics.shared.play(.success)
            SoundFX.shared.play(.success)
        }
    }

    private func take(_ cents: Int, from goal: SavingsGoal) {
        let taken = store.withdraw(goalID, cents: cents, note: noteText)
        guard taken > 0 else { return }
        warning = taken < cents ? "There was only \(SavingsMoney.text(taken)) in the jar, so that's what came out." : nil
        amountText = ""
        noteText = ""
        typing = false
        Haptics.shared.play(.tick)
    }
}
