import SwiftUI

/// Everything Ace remembers about you: search it, add to it, and forget any of it.
struct MemoryView: View {
    @ObservedObject var memory: MemoryStore
    @State private var search = ""
    @State private var newFact = ""
    @State private var confirmForgetAll = false
    @FocusState private var adding: Bool

    private var shown: [MemoryFact] { memory.search(search) }
    private struct NameItem: Identifiable {
        let alias: String
        let thing: String
        var id: String { alias }
    }
    private var names: [NameItem] {
        memory.aliases.map { NameItem(alias: $0.key, thing: $0.value) }.sorted { $0.alias < $1.alias }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("My bike is called Bolt", text: $newFact)
                        .focused($adding)
                        .submitLabel(.done)
                        .onSubmit(add)
                    Button("Add", action: add)
                        .disabled(newFact.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add a memory")
            } footer: {
                Text("You can also just tell Ace: \"remember my favorite food is pizza\".")
            }

            if !names.isEmpty && search.isEmpty {
                Section {
                    ForEach(names) { n in
                        LabeledContent(n.alias.capitalized, value: "your \(n.thing)")
                    }
                } header: {
                    Text("Names you gave things")
                } footer: {
                    Text("Say a name and Ace knows what you mean, like \"turn on \(names[0].alias.capitalized)\".")
                }
            }

            Section {
                if memory.facts.isEmpty {
                    Text("Nothing yet. Say \"remember that...\" and I'll keep it here.")
                        .foregroundStyle(AceTheme.muted)
                } else if shown.isEmpty {
                    Text("No memories with \"\(search)\".")
                        .foregroundStyle(AceTheme.muted)
                }
                ForEach(shown) { fact in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TextKit.capitalizeFirst(fact.text))
                        Text(fact.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                    }
                    .swipeActions {
                        Button("Forget", role: .destructive) {
                            Haptics.shared.play(.tick)
                            memory.remove(fact)
                        }
                    }
                    .accessibilityHint("Swipe left to forget")
                }
            } header: {
                Text(search.isEmpty ? "Memories (\(memory.facts.count))" : "Found \(shown.count)")
            } footer: {
                if !memory.facts.isEmpty { Text("Swipe a memory to forget it.") }
            }

            if !memory.facts.isEmpty {
                Section {
                    Button("Forget everything", role: .destructive) { confirmForgetAll = true }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AceTheme.background.ignoresSafeArea())
        .navigationTitle("Memories")
        .searchable(text: $search, prompt: "Search memories")
        .confirmationDialog("Forget all \(memory.facts.count) memories?", isPresented: $confirmForgetAll, titleVisibility: .visible) {
            Button("Forget everything", role: .destructive) { memory.removeAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Ace won't remember any of them anymore.")
        }
    }

    private func add() {
        let text = newFact.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        memory.add(text)
        newFact = ""
        adding = false
        Haptics.shared.play(.pop)
    }
}
