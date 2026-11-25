import SwiftUI

/// Write your own flashcards (a question and its answer) and see the ones you've made.
struct MyCardsView: View {
    @ObservedObject var store: StudyStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var front = ""
    @State private var back = ""
    @State private var note = ""
    @State private var problem: String?
    @State private var saves = 0
    @FocusState private var focus: Field?

    private enum Field { case front, back, note }

    private var style: (symbol: String, colors: [UInt32]) { StudyDeck.style(for: StudyDeck.myDeckName) }
    private var gradient: LinearGradient {
        LinearGradient(colors: style.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    preview
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                Section("New card") {
                    TextField("Question (front)", text: $front, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($focus, equals: .front)
                        .submitLabel(.next)
                    TextField("Answer (back)", text: $back, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($focus, equals: .back)
                    TextField("Extra note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($focus, equals: .note)
                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(AceTheme.warn)
                            .font(.subheadline)
                    }
                    Button(action: save) {
                        Label("Add card", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.aceBouncyRow)
                    .disabled(!canSave)
                }
                .listRowBackground(AceTheme.card)

                Section(store.myCards.isEmpty ? String("Your cards") : String("Your cards (\(store.myCards.count))")) {
                    if store.myCards.isEmpty {
                        Text("Cards you add show up here and in the My cards deck.")
                            .foregroundStyle(AceTheme.muted)
                    }
                    ForEach(store.myCards.reversed()) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.front)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AceTheme.fg)
                            Text(card.back)
                                .font(.subheadline)
                                .foregroundStyle(AceTheme.muted)
                        }
                        .padding(.vertical, 2)
                        .transition(.chatBubble(fromUser: true))
                        .swipeActions {
                            Button(role: .destructive) {
                                withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) {
                                    store.deleteCard(card)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listRowBackground(AceTheme.card)
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("My cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onSubmit {
                if focus == .front { focus = .back }
            }
        }
        .tint(AceTheme.ace)
        .preferredColorScheme(.dark)
    }

    /// A live preview of the card you're writing, in the My cards colors.
    private var preview: some View {
        VStack(spacing: 10) {
            Text(front.isEmpty ? "Your question" : front)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(front.isEmpty ? 0.6 : 1))
            Rectangle()
                .fill(.white.opacity(0.35))
                .frame(height: 1)
                .padding(.horizontal, 40)
            Text(back.isEmpty ? "Its answer" : back)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(back.isEmpty ? 0.6 : 0.95))
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color(hex: style.colors[0]).opacity(0.45), radius: 14, y: 8)
        .boing(on: saves, scale: 1.05)
        .accessibilityHidden(true)
    }

    private func save() {
        let result = withAnimation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)) {
            store.addCard(front: front, back: back, note: note)
        }
        switch result {
        case .success:
            front = ""
            back = ""
            note = ""
            problem = nil
            saves += 1
            focus = .front
            Haptics.shared.play(.pop)
        case .failure(let error):
            switch error {
            case .emptyFront: problem = "Write a question first."
            case .emptyBack: problem = "Write the answer too."
            case .tooLong: problem = "That's a bit long. Keep the question under \(StudyStore.maxFront) letters and the answer under \(StudyStore.maxBack)."
            case .duplicate: problem = "You already have a card with that question."
            }
            Haptics.shared.play(.alert)
        }
    }
}
