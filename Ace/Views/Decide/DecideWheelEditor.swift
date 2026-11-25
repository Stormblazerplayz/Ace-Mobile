import SwiftUI

/// Makes or changes a wheel: a name and one choice per line, with a live wheel at the top.
struct DecideWheelEditor: View {
    @ObservedObject var store: DecideStore
    let target: DecideEditTarget
    /// Called with the saved wheel after Save, or nil after Delete.
    let onDone: (DecideWheel?) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String
    @State private var text: String
    @State private var confirmDelete = false

    init(store: DecideStore, target: DecideEditTarget, onDone: @escaping (DecideWheel?) -> Void) {
        self.store = store
        self.target = target
        self.onDone = onDone
        switch target {
        case .new:
            _title = State(initialValue: "")
            _text = State(initialValue: "")
        case .wheel(let wheel):
            _title = State(initialValue: wheel.title)
            _text = State(initialValue: wheel.options.joined(separator: "\n"))
        }
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    /// The choices as they'll be saved.
    private var choices: [String] {
        DecideStore.cleanOptions(text.components(separatedBy: .newlines))
    }

    private var tooMany: Bool {
        DecideMath.cleanNames(text.components(separatedBy: .newlines)).count > DecideStore.maxOptions
    }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    preview
                    field("Name") {
                        TextField("My wheel", text: $title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: title) { _, new in
                                if new.count > 40 { title = String(new.prefix(40)) }
                            }
                    }
                    field("Choices, one per line") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $text)
                                .scrollContentBackground(.hidden)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .frame(minHeight: 180)
                                .accessibilityLabel("Choices, one per line")
                            Text(hint)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(choices.count < 2 || tooMany ? AceTheme.warn : AceTheme.muted)
                        }
                    }
                    if !isNew {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete this wheel", systemImage: "trash")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AceTheme.bad.opacity(0.15)))
                                .foregroundStyle(AceTheme.bad)
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
                .padding(20)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New wheel" : "Edit wheel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Make it" : "Save") { save() }
                        .bold()
                        .disabled(choices.count < 2)
                }
            }
            .confirmationDialog("Delete this wheel?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { delete() }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hint: String {
        if choices.count < 2 { return "Add at least two choices." }
        if tooMany { return "Only the first \(DecideStore.maxOptions) choices fit on the wheel." }
        return "\(choices.count) choices"
    }

    /// The wheel as it will look, updating as you type.
    private var preview: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                DecideWheelView(options: choices.count >= 2 ? choices : ["?", "?"], rotation: 0)
                    .frame(width: 220, height: 220)
                    .padding(.top, 14)
                    .opacity(choices.count >= 2 ? 1 : 0.4)
                    .animation(motion(.bouncy), value: choices)
                DecidePointer()
                    .scaleEffect(0.7)
            }
            Text(title.trimmingCharacters(in: .whitespaces).isEmpty ? "My wheel" : title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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

    private func save() {
        let lines = text.components(separatedBy: .newlines)
        switch target {
        case .new:
            guard let made = store.add(title: title, options: lines) else { return }
            onDone(made)
        case .wheel(let wheel):
            guard store.setOptions(wheel.id, lines) else { return }
            store.rename(wheel.id, to: title)
            onDone(store.wheel(wheel.id))
        }
        Haptics.shared.play(.success)
        dismiss()
    }

    private func delete() {
        guard case .wheel(let wheel) = target else { return }
        store.delete(wheel.id)
        Haptics.shared.play(.tick)
        onDone(nil)
        dismiss()
    }
}
