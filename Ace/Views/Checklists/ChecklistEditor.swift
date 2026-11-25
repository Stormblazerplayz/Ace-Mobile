import SwiftUI

/// Names a list and picks its icon and color, with a live card at the top.
struct ChecklistEditor: View {
    @ObservedObject var store: ChecklistStore
    let target: ChecklistEditTarget
    /// Called with the new list after Add, or nil after saving changes.
    let onDone: (Checklist?) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String
    @State private var symbol: String
    @State private var tint: ListTint

    init(store: ChecklistStore, target: ChecklistEditTarget, onDone: @escaping (Checklist?) -> Void) {
        self.store = store
        self.target = target
        self.onDone = onDone
        switch target {
        case .new:
            _title = State(initialValue: "")
            _symbol = State(initialValue: ChecklistStore.symbols[0])
            _tint = State(initialValue: .purple)
        case .edit(let list):
            _title = State(initialValue: list.title)
            _symbol = State(initialValue: list.symbol)
            _tint = State(initialValue: list.tint)
        }
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
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
                        TextField(isNew ? store.nextTitle() : "List name", text: $title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: title) { _, new in
                                if new.count > ChecklistStore.maxTitle {
                                    title = String(new.prefix(ChecklistStore.maxTitle))
                                }
                            }
                    }
                    field("Icon") { symbolGrid }
                    field("Color") { tintRow }
                }
                .padding(20)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New list" : "Edit list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Make it" : "Save") { save() }
                        .bold()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var preview: some View {
        let shown = ChecklistStore.clip(title, ChecklistStore.maxTitle)
        return HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.2)))
                .contentTransition(.symbolEffect(.replace))
            Text(shown.isEmpty ? (isNew ? store.nextTitle() : "List") : shown)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(tint.gradient))
        .shadow(color: tint.dark.opacity(0.5), radius: 18, y: 8)
        .animation(motion(.bouncy), value: tint)
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
            ForEach(ChecklistStore.symbols, id: \.self) { name in
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
                                .fill(picked ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(AceTheme.soft))
                        )
                        .scaleEffect(picked ? 1.08 : 1)
                }
                .buttonStyle(.aceBouncy)
                .accessibilityLabel(name.replacingOccurrences(of: ".fill", with: "").replacingOccurrences(of: ".", with: " "))
                .accessibilityAddTraits(picked ? .isSelected : [])
            }
        }
    }

    private var tintRow: some View {
        HStack(spacing: 12) {
            ForEach(ListTint.allCases) { option in
                let picked = option == tint
                Button {
                    withAnimation(motion(.pop)) { tint = option }
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

    private func save() {
        switch target {
        case .new:
            let made = store.create(title: title, symbol: symbol, tint: tint)
            onDone(made)
        case .edit(let list):
            store.edit(list.id, title: title, symbol: symbol, tint: tint)
            onDone(nil)
        }
        Haptics.shared.play(.success)
        dismiss()
    }
}
