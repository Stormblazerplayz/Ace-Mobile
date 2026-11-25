import SwiftUI

/// Names a jar, sets how much it costs, and picks its icon and color, with a live jar at the top.
struct SavingsEditor: View {
    @ObservedObject var store: SavingsStore
    let target: SavingsEditTarget
    /// Called with the new jar after Make it, or nil after saving changes.
    let onDone: (SavingsGoal?) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title: String
    @State private var priceText: String
    @State private var symbol: String
    @State private var color: SavingsColor

    init(store: SavingsStore, target: SavingsEditTarget, onDone: @escaping (SavingsGoal?) -> Void) {
        self.store = store
        self.target = target
        self.onDone = onDone
        switch target {
        case .new(let idea):
            _title = State(initialValue: idea?.title ?? "")
            _priceText = State(initialValue: "")
            _symbol = State(initialValue: idea?.symbol ?? SavingsStore.symbols[0])
            _color = State(initialValue: idea?.color ?? .gold)
        case .edit(let goal):
            _title = State(initialValue: goal.title)
            _priceText = State(initialValue: Self.plain(goal.targetCents))
            _symbol = State(initialValue: goal.symbol)
            _color = State(initialValue: goal.color)
        }
    }

    /// Cents as typed money without the currency sign: 1250 becomes "12.50", 2000 becomes "20".
    static func plain(_ cents: Int) -> String {
        cents % 100 == 0 ? "\(cents / 100)" : String(format: "%ld.%02ld", cents / 100, cents % 100)
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    private var price: Int? { SavingsMoney.cents(from: priceText) }

    private var canSave: Bool {
        price != nil && !SavingsStore.clip(title, SavingsStore.maxTitle).isEmpty
    }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    preview
                    field("What are you saving for?") {
                        TextField("A new bike", text: $title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textInputAutocapitalization(.sentences)
                            .onChange(of: title) { _, new in
                                if new.count > SavingsStore.maxTitle { title = String(new.prefix(SavingsStore.maxTitle)) }
                            }
                    }
                    field("How much does it cost?") {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("49.99", text: $priceText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                            if !priceText.isEmpty && price == nil {
                                Text("Type a price like 25 or 49.99")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AceTheme.warn)
                            }
                        }
                    }
                    field("Icon") { symbolGrid }
                    field("Color") { colorRow }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "New jar" : "Edit jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Make it" : "Save") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var preview: some View {
        HStack(spacing: 18) {
            SavingsJar(progress: 0.45, color: color, symbol: symbol)
                .frame(width: 96)
                .animation(motion(.bouncy), value: color)
            VStack(alignment: .leading, spacing: 4) {
                let shown = SavingsStore.clip(title, SavingsStore.maxTitle)
                Text(shown.isEmpty ? "Your jar" : shown)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(2)
                Text(price.map { "Goal: " + SavingsMoney.text($0) } ?? "Set a price")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(color.light)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AceTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(color.light.opacity(0.4), lineWidth: 1.5))
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
            ForEach(SavingsStore.symbols, id: \.self) { name in
                let picked = name == symbol
                Button {
                    withAnimation(motion(.pop)) { symbol = name }
                    Haptics.shared.play(.tick)
                } label: {
                    Image(systemName: name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(picked ? Color.black : AceTheme.fg)
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
            ForEach(SavingsColor.allCases) { option in
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

    private func save() {
        guard let price else { return }
        switch target {
        case .new:
            guard let made = store.add(title: title, targetCents: price, symbol: symbol, color: color) else { return }
            onDone(made)
        case .edit(let goal):
            store.edit(goal.id, title: title, targetCents: price, symbol: symbol, color: color)
            onDone(nil)
        }
        Haptics.shared.play(.success)
        dismiss()
    }
}
