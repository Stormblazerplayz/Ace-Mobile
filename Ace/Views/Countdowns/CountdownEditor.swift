import SwiftUI

/// Makes or changes a countdown. A live preview card at the top shows how it'll look as you go.
struct CountdownEditor: View {
    @ObservedObject var store: CountdownStore
    let target: CountdownEditTarget

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String
    @State private var date: Date
    @State private var allDay: Bool
    @State private var repeatsYearly: Bool
    @State private var symbol: String
    @State private var theme: CountdownTheme
    @State private var problem: String?
    @State private var confirmDelete = false

    init(store: CountdownStore, target: CountdownEditTarget) {
        self.store = store
        self.target = target
        switch target {
        case .new:
            let tomorrow = store.calendar.date(byAdding: .day, value: 1, to: store.calendar.startOfDay(for: Date())) ?? Date()
            _title = State(initialValue: "")
            _date = State(initialValue: tomorrow)
            _allDay = State(initialValue: true)
            _repeatsYearly = State(initialValue: false)
            _symbol = State(initialValue: CountdownStore.symbols[0])
            _theme = State(initialValue: .sunset)
        case .edit(let item):
            _title = State(initialValue: item.title)
            _date = State(initialValue: item.date)
            _allDay = State(initialValue: item.allDay)
            _repeatsYearly = State(initialValue: item.repeatsYearly)
            _symbol = State(initialValue: item.symbol)
            _theme = State(initialValue: item.theme)
        }
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    /// A countdown built from what's on screen, for the preview and for saving.
    private var draft: Countdown {
        var item: Countdown
        if case .edit(let old) = target {
            item = old
        } else {
            item = Countdown(id: UUID(), title: "", date: date, allDay: allDay, repeatsYearly: repeatsYearly,
                             symbol: symbol, theme: theme, created: Date())
        }
        item.title = CountdownStore.clip(title)
        item.date = date
        item.allDay = allDay
        item.repeatsYearly = repeatsYearly
        item.symbol = symbol
        item.theme = theme
        return item
    }

    private var canSave: Bool { !CountdownStore.clip(title).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    preview
                    field("Name") {
                        TextField("Like \"My birthday\" or \"Trip to Disney\"", text: $title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .onChange(of: title) { _, new in
                                if new.count > CountdownStore.maxTitle {
                                    title = String(new.prefix(CountdownStore.maxTitle))
                                }
                                problem = nil
                            }
                    }
                    field("When") {
                        VStack(spacing: 10) {
                            DatePicker("Date", selection: $date,
                                       displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                            Toggle("All day", isOn: $allDay.animation(motion(.snappy)))
                                .toggleStyle(.aceBouncy)
                            Toggle("Every year (birthdays and holidays)", isOn: $repeatsYearly.animation(motion(.snappy)))
                                .toggleStyle(.aceBouncy)
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .onChange(of: date) { _, _ in problem = nil }
                        .onChange(of: repeatsYearly) { _, _ in problem = nil }
                    }
                    field("Icon") { symbolGrid }
                    field("Colors") { themeRow }
                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AceTheme.warn)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if !isNew {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete countdown", systemImage: "trash")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AceTheme.bad)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.bad.opacity(0.12)))
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
                .padding(20)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New countdown" : "Edit countdown")
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
            .confirmationDialog("Delete this countdown?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if case .edit(let item) = target { store.delete(item.id) }
                    Haptics.shared.play(.tick)
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Pieces

    /// How the card will look, updating as you type and pick.
    private var preview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let item = draft
            let happening = store.isHappening(item, now: timeline.date)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.2)))
                        .contentTransition(.symbolEffect(.replace))
                    Text(item.title.isEmpty ? "Your countdown" : item.title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(item.title.isEmpty ? 0.6 : 1))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                if happening {
                    Text("Today's the day! 🎉")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    CountdownClock(left: store.left(item, now: timeline.date), big: false)
                }
                Text(CountdownFormat.when(store.occurrence(item, now: timeline.date), allDay: item.allDay))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CountdownBackdrop(theme: item.theme, symbol: item.symbol, corner: 24))
            .shadow(color: item.theme.color.opacity(0.45), radius: 20, y: 10)
            .animation(motion(.bouncy), value: item.theme)
        }
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
            ForEach(CountdownStore.symbols, id: \.self) { name in
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
                                .fill(picked ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(AceTheme.soft))
                        )
                        .scaleEffect(picked ? 1.08 : 1)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(name.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
    }

    private var themeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CountdownTheme.allCases) { option in
                    let picked = option == theme
                    Button {
                        withAnimation(motion(.pop)) { theme = option }
                        Haptics.shared.play(.tick)
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(option.gradient)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(.white, lineWidth: picked ? 3 : 0))
                                .scaleEffect(picked ? 1.12 : 1)
                            Text(option.label)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(picked ? AceTheme.fg : AceTheme.muted)
                        }
                    }
                    .buttonStyle(.aceBouncy)
                    .accessibilityLabel(option.label)
                    .accessibilityAddTraits(picked ? .isSelected : [])
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }

    // MARK: Saving

    private func save() {
        guard canSave else { return }
        switch target {
        case .new:
            if store.add(title: title, date: date, allDay: allDay, repeatsYearly: repeatsYearly,
                         symbol: symbol, theme: theme) == nil {
                withAnimation(motion(.pop)) {
                    problem = "That day has already passed. Pick a later one, or turn on Every year."
                }
                Haptics.shared.play(.alert)
                return
            }
        case .edit:
            store.update(draft)
        }
        Haptics.shared.play(.success)
        SoundFX.shared.play(.success)
        dismiss()
    }
}
