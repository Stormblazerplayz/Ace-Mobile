import SwiftUI

/// Makes or changes a habit, with a live bubble at the top that shows how it'll look.
struct HabitEditor: View {
    @ObservedObject var store: HabitStore
    let target: HabitEditTarget

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String
    @State private var symbol: String
    @State private var color: HabitColor
    @State private var goal: Int
    @State private var problem: String?
    @State private var previewCount = 0

    init(store: HabitStore, target: HabitEditTarget) {
        self.store = store
        self.target = target
        switch target {
        case .new:
            _title = State(initialValue: "")
            _symbol = State(initialValue: HabitStore.symbols[0])
            _color = State(initialValue: .sky)
            _goal = State(initialValue: 1)
        case .edit(let habit):
            _title = State(initialValue: habit.title)
            _symbol = State(initialValue: habit.symbol)
            _color = State(initialValue: habit.color)
            _goal = State(initialValue: habit.goal)
        }
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    private var editingID: UUID? {
        if case .edit(let habit) = target { return habit.id }
        return nil
    }

    private var canSave: Bool { !HabitStore.clip(title).isEmpty }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    /// The habit as it'll look, for the preview bubble.
    private var draft: Habit {
        Habit(id: editingID ?? UUID(), title: HabitStore.clip(title), symbol: symbol, color: color,
              goal: goal, created: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    preview
                    field("Name") {
                        TextField("Like \"Read 20 pages\" or \"Walk the dog\"", text: $title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: title) { _, new in
                                if new.count > HabitStore.maxTitle {
                                    title = String(new.prefix(HabitStore.maxTitle))
                                }
                                problem = nil
                            }
                    }
                    field("Times a day") {
                        Stepper(value: $goal.animation(motion(.snappy)), in: 1...HabitStore.maxGoal) {
                            Text(goal == 1 ? "Once a day" : "\(goal) times a day")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .contentTransition(.numericText(value: Double(goal)))
                        }
                    }
                    field("Icon") { symbolGrid }
                    field("Color") { colorRow }
                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AceTheme.warn)
                    }
                }
                .padding(20)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New habit" : "Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Pieces

    /// Tap the bubble to see it fill up.
    private var preview: some View {
        let habit = draft
        return HStack(spacing: 18) {
            Button {
                withAnimation(motion(.bouncy)) {
                    previewCount = previewCount >= habit.goal ? 0 : previewCount + 1
                }
                Haptics.shared.play(.tick)
            } label: {
                HabitBubble(habit: habit, count: min(previewCount, habit.goal), size: 96)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.88))
            .accessibilityLabel("Preview. Tap to see it fill up")
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title.isEmpty ? "Your habit" : habit.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg.opacity(habit.title.isEmpty ? 0.5 : 1))
                    .lineLimit(2)
                Text("Tap the bubble to try it")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(color.dark.opacity(0.18))
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.light.opacity(0.4), lineWidth: 1))
        .animation(motion(.snappy), value: color)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(AceTheme.muted)
            content()
                .aceCard()
        }
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 10)], spacing: 10) {
            ForEach(HabitStore.symbols, id: \.self) { name in
                let picked = name == symbol
                Button {
                    withAnimation(motion(.pop)) { symbol = name }
                    Haptics.shared.play(.tick)
                } label: {
                    Image(systemName: name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(picked ? .white : AceTheme.fg)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(picked ? AnyShapeStyle(color.gradient) : AnyShapeStyle(AceTheme.soft))
                        )
                        .scaleEffect(picked ? 1.08 : 1)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(name.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 12) {
            ForEach(HabitColor.allCases) { option in
                let picked = option == color
                Button {
                    withAnimation(motion(.pop)) { color = option }
                    Haptics.shared.play(.tick)
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(option.gradient)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(.white, lineWidth: picked ? 3 : 0))
                            .scaleEffect(picked ? 1.12 : 1)
                        Text(option.label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(picked ? AceTheme.fg : AceTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(option.label)
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
    }

    // MARK: Saving

    private func save() {
        guard canSave else { return }
        if store.has(title, except: editingID) {
            problem = "You already have a habit called that."
            Haptics.shared.play(.alert)
            return
        }
        switch target {
        case .new:
            guard store.add(title: title, symbol: symbol, color: color, goal: goal) != nil else {
                problem = "Couldn't add that habit."
                return
            }
        case .edit(let habit):
            var changed = habit
            changed.title = title
            changed.symbol = symbol
            changed.color = color
            changed.goal = goal
            store.update(changed)
        }
        Haptics.shared.play(.success)
        SoundFX.shared.play(.success)
        dismiss()
    }
}
