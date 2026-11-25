import SwiftUI

/// Writing a day: pick a mood, write a few words, tap what you did, and save.
/// Used for today on the Journal screen and for any past day you open from the month grid.
struct JournalEditor: View {
    @ObservedObject var store: JournalStore
    let date: Date
    /// Tells the screen which mood is picked, so the background can glow in its colors.
    var onMood: (JournalMood?) -> Void = { _ in }
    var onSaved: () -> Void = {}

    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mood: JournalMood?
    @State private var text = ""
    @State private var tags: [String] = []
    @State private var loadedDay: String?
    @State private var saves = 0
    @State private var justSaved = false
    @FocusState private var writing: Bool

    private var isToday: Bool { store.calendar.isDateInToday(date) }

    /// True when what's on screen differs from what's saved.
    private var changed: Bool {
        guard let mood else { return false }
        guard let saved = store.entry(on: date) else { return true }
        return saved.mood != mood
            || saved.text != text.trimmingCharacters(in: .whitespacesAndNewlines)
            || saved.tags != tags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(isToday ? String("How's today going?") : String("How was \(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))?"))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            MoodPicker(selection: $mood)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("What happened? Anything you want to remember...")
                        .foregroundStyle(AceTheme.muted)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .focused($writing)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(AceTheme.fg)
                    .font(.body)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120, maxHeight: 220)
                    .onChange(of: text) { _, new in
                        if new.count > JournalStore.maxText { text = String(new.prefix(JournalStore.maxText)) }
                    }
            }
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(writing ? (mood?.color ?? AceTheme.ace) : Color.white.opacity(0.12), lineWidth: writing ? 2 : 1)
            )
            .animation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion), value: writing)

            VStack(alignment: .leading, spacing: 10) {
                Text("What did you do?")
                    .font(.headline)
                    .foregroundStyle(AceTheme.fg.opacity(0.9))
                FlowLayout(spacing: 8) {
                    ForEach(JournalStore.tags, id: \.self) { tag in
                        TagChip(tag: tag, picked: tags.contains(tag), tint: mood?.color ?? AceTheme.ace) {
                            withAnimation(AceMotion.animation(.pop, bouncy: bouncy, reduceMotion: reduceMotion)) {
                                if let i = tags.firstIndex(of: tag) { tags.remove(at: i) } else { tags.append(tag) }
                            }
                            Haptics.shared.play(.tick)
                        }
                    }
                }
            }

            saveButton
        }
        .onAppear(perform: load)
        .onChange(of: date) { _, _ in load() }
        .onChange(of: mood) { _, new in onMood(new) }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 10) {
                Image(systemName: justSaved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    .contentTransition(.symbolEffect(.replace))
                Text(justSaved ? String("Saved") : (store.entry(on: date) == nil ? String("Save day") : String("Update day")))
                    .contentTransition(.interpolate)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(mood.map { AnyShapeStyle($0.gradient) } ?? AnyShapeStyle(Color.white.opacity(0.1)), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: (mood?.color ?? .clear).opacity(0.5), radius: 14, y: 6)
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.94))
        .boing(on: saves, scale: 1.06)
        .disabled(mood == nil || !changed)
        .opacity(mood == nil || (!changed && !justSaved) ? 0.5 : 1)
        .accessibilityHint(mood == nil ? String("Pick a mood first") : String(""))
    }

    private func load() {
        let key = store.dayKey(date)
        guard loadedDay != key else { return }
        loadedDay = key
        let saved = store.entry(on: date)
        mood = saved?.mood
        text = saved?.text ?? ""
        tags = saved?.tags ?? []
        justSaved = false
        onMood(mood)
    }

    private func save() {
        guard let mood, changed else { return }
        writing = false
        guard let entry = store.save(mood: mood, text: text, tags: tags, on: date) else { return }
        text = entry.text
        tags = entry.tags
        saves += 1
        Haptics.shared.play(.success)
        withAnimation(AceMotion.animation(.pop, bouncy: bouncy, reduceMotion: reduceMotion)) { justSaved = true }
        onSaved()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(AceMotion.animation(.gentle, bouncy: bouncy, reduceMotion: reduceMotion)) { justSaved = false }
        }
    }
}

/// A past day, opened from the month grid: its entry to read or change, and a way to delete it.
struct JournalDaySheet: View {
    @ObservedObject var store: JournalStore
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var mood: JournalMood?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                JournalGlow(mood: mood)
                ScrollView {
                    JournalEditor(store: store, date: date, onMood: { mood = $0 })
                        .padding(24)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(date.formatted(.dateTime.month(.wide).day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                if store.entry(on: date) != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(AceTheme.bad)
                        .accessibilityLabel("Delete this day")
                    }
                }
            }
            .confirmationDialog("Delete this day?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.delete(on: date)
                    dismiss()
                }
            } message: {
                Text("Its mood, words and tags will be gone.")
            }
        }
        .tint(AceTheme.ace)
        .preferredColorScheme(.dark)
    }
}
