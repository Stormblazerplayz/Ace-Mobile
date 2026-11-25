import SwiftUI

/// What the goal editor is working on.
enum SavingsEditTarget: Identifiable {
    case new(SavingsIdea?)
    case edit(SavingsGoal)

    var id: String {
        switch self {
        case .new(let idea): return "new-" + (idea?.id ?? "blank")
        case .edit(let goal): return goal.id.uuidString
        }
    }
}

/// Which goal is open.
struct SavingsOpen: Identifiable, Equatable {
    let id: UUID
}

/// Savings jars: one glass jar per thing you're saving for, filling with coins as you put money in.
struct SavingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = SavingsStore.shared
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var editing: SavingsEditTarget?
    @State private var opened: SavingsOpen?
    @State private var openAfter: SavingsOpen?
    @State private var shown = false
    @State private var drift = false
    @State private var deleting: SavingsGoal?

    private var moving: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            backdrop
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    hero
                        .bounceReveal(shown, order: 0, rise: 26)
                    if store.goals.isEmpty {
                        empty
                            .bounceReveal(shown, order: 1)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
                            ForEach(Array(store.sorted.enumerated()), id: \.element.id) { index, goal in
                                card(goal)
                                    .bounceReveal(shown, order: index + 1)
                            }
                        }
                    }
                    ideas
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 40)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $editing, onDismiss: {
            if let next = openAfter {
                openAfter = nil
                opened = next
            }
        }) { target in
            SavingsEditor(store: store, target: target) { made in
                if let made { openAfter = SavingsOpen(id: made.id) }
            }
        }
        .sheet(item: $opened) { open in
            SavingsGoalView(store: store, goalID: open.id)
        }
        .confirmationDialog("Delete this jar?", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible, presenting: deleting) { goal in
            Button("Delete \(goal.title)", role: .destructive) {
                withAnimation(motion(.snappy)) { store.delete(goal.id) }
                Haptics.shared.play(.tick)
            }
        } message: { _ in
            Text("Its savings history goes too. This can't be undone.")
        }
        .onAppear {
            withAnimation(motion(.bouncy)) { shown = true }
            if moving {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { drift = true }
            }
        }
    }

    // MARK: Pieces

    private var backdrop: some View {
        ZStack {
            AceTheme.background
            Circle()
                .fill(Color(hex: 0xF5B83D).opacity(0.32))
                .frame(width: 540, height: 540)
                .blur(radius: 130)
                .offset(x: drift ? 160 : 90, y: drift ? -280 : -200)
            Circle()
                .fill(Color(hex: 0x17B27C).opacity(0.28))
                .frame(width: 480, height: 480)
                .blur(radius: 130)
                .offset(x: drift ? -170 : -90, y: drift ? 320 : 240)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Savings jars")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("Save up for the things you want")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
            Button {
                Haptics.shared.play(.pop)
                editing = .new(nil)
            } label: {
                Label("New jar", systemImage: "plus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(SavingsColor.gold.gradient))
            }
            .buttonStyle(.aceBouncy)
        }
        .padding(.top, 14)
    }

    /// The total in every jar, with a row of mini jars.
    private var hero: some View {
        let reached = store.goals.filter(\.isReached).count
        return HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Saved in all jars")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.black.opacity(0.6))
                Text(SavingsMoney.text(store.totalSaved))
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText())
                    .animation(motion(.pop), value: store.totalSaved)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(store.goals.isEmpty ? "Make a jar to start saving"
                     : "\(store.goals.count) \(store.goals.count == 1 ? "jar" : "jars")" + (reached > 0 ? ", \(reached) reached" : ""))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.65))
            }
            Spacer(minLength: 0)
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .symbolEffect(.bounce, value: store.totalSaved)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFE38A), Color(hex: 0xF5A623)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: Color(hex: 0xF5A623).opacity(0.4), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
    }

    private func card(_ goal: SavingsGoal) -> some View {
        Button {
            Haptics.shared.play(.pop)
            opened = SavingsOpen(id: goal.id)
        } label: {
            HStack(spacing: 14) {
                SavingsJar(progress: goal.progress, color: goal.color, symbol: goal.symbol)
                    .frame(width: 78)
                    .animation(motion(.bouncy), value: goal.progress)
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(SavingsMoney.text(goal.savedCents)) of \(SavingsMoney.text(goal.targetCents))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.muted)
                    progressBar(goal)
                    if goal.isReached {
                        Label("Reached!", systemImage: "star.fill")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0xFFD54A))
                    } else {
                        Text("\(SavingsMoney.text(goal.leftCents)) to go")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(goal.color.light)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AceTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(goal.isReached ? Color(hex: 0xFFD54A).opacity(0.7) : AceTheme.cardBorder, lineWidth: goal.isReached ? 2 : 1))
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel("\(goal.title), \(SavingsMoney.text(goal.savedCents)) of \(SavingsMoney.text(goal.targetCents))")
        .contextMenu {
            Button { editing = .edit(goal) } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { deleting = goal } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func progressBar(_ goal: SavingsGoal) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AceTheme.soft)
                Capsule()
                    .fill(goal.color.gradient)
                    .frame(width: max(8, geo.size.width * goal.progress))
            }
        }
        .frame(height: 8)
        .animation(motion(.bouncy), value: goal.progress)
    }

    private var empty: some View {
        VStack(spacing: 12) {
            SavingsJar(progress: 0.35, color: .gold, symbol: "star.fill")
                .frame(width: 110)
            Text("No jars yet")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            Text("Make a jar for something you want, then add money as you save. Ace shows how close you are.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .aceCard()
    }

    /// One-tap starting points. You still type the price.
    private var ideas: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ideas")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AceTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SavingsIdea.all) { idea in
                        Button {
                            Haptics.shared.play(.pop)
                            editing = .new(idea)
                        } label: {
                            Label(idea.title, systemImage: idea.symbol)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AceTheme.fg)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(idea.color.dark.opacity(0.3)))
                                .overlay(Capsule().stroke(idea.color.light.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
