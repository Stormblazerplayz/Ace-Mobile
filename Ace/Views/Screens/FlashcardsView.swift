import SwiftUI
import UIKit

/// Your flashcard decks: how many cards are ready, ready-made decks, and the daily reminder.
struct FlashcardsView: View {
    /// A deck to open right away (from "add a card" buttons), or nil for the list.
    var startDeck: UUID?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FlashcardStore.shared
    @State private var path: [UUID] = []
    @State private var shown = false
    @State private var study: StudyTarget?
    @State private var askNewDeck = false
    @State private var newDeckName = ""
    @State private var deckToDelete: FlashDeck?
    @State private var deckToRename: FlashDeck?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $path) {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        summary(now: context.date)
                            .bounceReveal(shown, order: 0)
                        if store.decks.isEmpty {
                            emptyShelf
                                .bounceReveal(shown, order: 1)
                        }
                        ForEach(Array(store.decks.enumerated()), id: \.element.id) { i, deck in
                            NavigationLink(value: deck.id) {
                                DeckRow(deck: deck, now: context.date)
                            }
                            .buttonStyle(BouncyButtonStyle(depth: 0.97))
                            .contextMenu { deckMenu(deck, now: context.date) }
                            .bounceReveal(shown, order: i + 1)
                        }
                        reminderCard
                            .bounceReveal(shown, order: store.decks.count + 2)
                    }
                    .padding(16)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { id in
                DeckDetailView(deckID: id, study: $study)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) { addMenu }
            }
            .alert("New deck", isPresented: $askNewDeck) {
                TextField("Name, like Science test", text: $newDeckName)
                Button("Make it") { makeDeck() }
                Button("Cancel", role: .cancel) { newDeckName = "" }
            } message: {
                Text("You can add cards to it next.")
            }
            .alert("Rename deck", isPresented: Binding(get: { deckToRename != nil }, set: { if !$0 { deckToRename = nil } })) {
                TextField("Deck name", text: $renameText)
                Button("Save") {
                    if let d = deckToRename { store.renameDeck(d.id, to: renameText) }
                    deckToRename = nil
                }
                Button("Cancel", role: .cancel) { deckToRename = nil }
            }
            .confirmationDialog("Delete \(deckToDelete?.name ?? "this deck")?",
                                isPresented: Binding(get: { deckToDelete != nil }, set: { if !$0 { deckToDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete deck", role: .destructive) {
                    if let d = deckToDelete {
                        withAnimation(AceMotion.now(.bouncy)) { store.deleteDeck(d.id) }
                        Haptics.shared.play(.pop)
                    }
                    deckToDelete = nil
                }
            } message: {
                Text("Its \(FlashcardSkill.count(deckToDelete?.cards.count ?? 0)) will be gone for good.")
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
        .fullScreenCover(item: $study) { target in
            FlashcardStudyView(deckID: target.deckID, practice: target.practice)
        }
        .onAppear {
            if let startDeck, store.deck(startDeck) != nil { path = [startDeck] }
            shown = true
            Task { await store.checkNotifications() }
        }
    }

    // MARK: Parts

    private func summary(now: Date) -> some View {
        let due = store.dueCount(at: now)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AceTheme.ace.opacity(0.16))
                    Image(systemName: due > 0 ? "rectangle.stack.badge.play.fill" : "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(due > 0 ? AceTheme.ace : AceTheme.good)
                        .symbolEffect(.bounce, value: due)
                }
                .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(headline(due: due))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(AceTheme.fg)
                    Text(subline(due: due, now: now))
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
                Spacer(minLength: 0)
            }
            if store.cardCount > 0 {
                HStack(spacing: 10) {
                    Button {
                        Haptics.shared.play(.tick)
                        study = StudyTarget(deckID: nil, practice: due == 0)
                    } label: {
                        Label(due > 0 ? "Study all \(due)" : "Practice all", systemImage: due > 0 ? "play.fill" : "shuffle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(due > 0 ? AceTheme.ace : AceTheme.accent)
                }
            }
        }
        .aceCard()
    }

    private func headline(due: Int) -> String {
        if store.decks.isEmpty { return "No flashcards yet" }
        if due == 0 { return "All caught up!" }
        return due == 1 ? "1 card is ready" : "\(due) cards are ready"
    }

    private func subline(due: Int, now: Date) -> String {
        if store.decks.isEmpty { return "Make a deck with +, or say \"make Spanish flashcards\"." }
        let decks = store.decks.count == 1 ? "1 deck" : "\(store.decks.count) decks"
        let base = "\(decks), \(FlashcardSkill.count(store.cardCount))."
        if due > 0 { return base + " Cards you know come back later and later, and ones you miss come back soon." }
        return base + " " + FlashcardSkill.nextLine(store.nextDue, now: now)
    }

    private var emptyShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: "sparkles", title: "Start with a ready-made deck", tint: AceTheme.amber)
            Text("Pick a language from Ace's phrasebook or a topic from its trivia, or make your own deck and add cards.")
                .font(.subheadline)
                .foregroundStyle(AceTheme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(starterSources, id: \.tag) { item in
                        Button {
                            addReadyMade(item.source)
                        } label: {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                                .foregroundStyle(AceTheme.ace)
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
            }
        }
        .aceCard()
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $store.remindersOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remind me when cards are ready")
                        .foregroundStyle(AceTheme.fg)
                    Text("One notification on days cards are due, at the time you pick.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
            }
            .toggleStyle(.aceBouncy)
            if store.remindersOn {
                DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(AceTheme.fg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                if store.notificationsBlocked {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bell.slash.fill").foregroundStyle(AceTheme.warn)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notifications for Ace are off, so the reminder can't ring.")
                                .font(.caption)
                                .foregroundStyle(AceTheme.fg)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
        .aceCard()
        .animation(AceMotion.now(.bouncy), value: store.remindersOn)
    }

    /// The reminder time as a date for the picker (only the hour and minute matter).
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let m = store.reminderMinutes
                return Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.reminderMinutes = (parts.hour ?? 17) * 60 + (parts.minute ?? 0)
            }
        )
    }

    private var addMenu: some View {
        Menu {
            Button {
                newDeckName = ""
                askNewDeck = true
            } label: {
                Label("New empty deck", systemImage: "plus.rectangle.on.rectangle")
            }
            Menu {
                ForEach(languageSources, id: \.tag) { item in
                    Button(item.name) { addReadyMade(item.source) }
                        .disabled(store.deck(source: item.tag) != nil)
                }
            } label: {
                Label("Language deck", systemImage: "character.bubble")
            }
            Menu {
                ForEach(triviaSources, id: \.tag) { item in
                    Button(item.name) { addReadyMade(item.source) }
                        .disabled(store.deck(source: item.tag) != nil)
                }
            } label: {
                Label("Topic deck", systemImage: "lightbulb")
            }
        } label: {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
        }
        .accessibilityLabel("Add a deck")
    }

    @ViewBuilder
    private func deckMenu(_ deck: FlashDeck, now: Date) -> some View {
        Button {
            study = StudyTarget(deckID: deck.id, practice: deck.dueCount(at: now) == 0)
        } label: {
            Label(deck.dueCount(at: now) > 0 ? "Study" : "Practice", systemImage: "play.fill")
        }
        .disabled(deck.cards.isEmpty)
        Button {
            renameText = deck.name
            deckToRename = deck
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        Button(role: .destructive) {
            deckToDelete = deck
        } label: {
            Label("Delete deck", systemImage: "trash")
        }
    }

    // MARK: Ready-made decks

    struct ReadyMade {
        var source: FlashcardSources.Source
        var name: String
        var tag: String
    }

    private var languageSources: [ReadyMade] {
        Phrasebook.languages.filter { $0.code != "en" }.map { lang -> ReadyMade in
            let s = FlashcardSources.Source.language(lang.code)
            return ReadyMade(source: s, name: lang.name, tag: FlashcardSources.tag(s))
        }
    }

    private var triviaSources: [ReadyMade] {
        Trivia.categories.map { cat -> ReadyMade in
            let s = FlashcardSources.Source.trivia(cat)
            return ReadyMade(source: s, name: cat, tag: FlashcardSources.tag(s))
        }
    }

    private var starterSources: [ReadyMade] {
        Array(languageSources.prefix(4)) + Array(triviaSources.prefix(4))
    }

    private func addReadyMade(_ source: FlashcardSources.Source) {
        let tag = FlashcardSources.tag(source)
        if let old = store.deck(source: tag) {
            path = [old.id]
            return
        }
        guard let deck = FlashcardSources.deck(source) else { return }
        let added = withAnimation(AceMotion.now(.bouncy)) { store.addDeck(deck) }
        Haptics.shared.play(.success)
        path = [added.id]
    }

    private func makeDeck() {
        let name = newDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
        newDeckName = ""
        guard !name.isEmpty else { return }
        let deck = withAnimation(AceMotion.now(.bouncy)) { store.newDeck(named: name) }
        Haptics.shared.play(.success)
        path = [deck.id]
    }
}

/// One deck in the list: its name, how many cards are ready, and how many you know well.
struct DeckRow: View {
    let deck: FlashDeck
    let now: Date

    var body: some View {
        let due = deck.dueCount(at: now)
        let total = deck.cards.count
        let known = total == 0 ? 0 : Double(deck.masteredCount) / Double(total)
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AceTheme.ace.opacity(0.10))
                    .frame(width: 34, height: 42)
                    .rotationEffect(.degrees(-8))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AceTheme.ace.opacity(0.22))
                    .frame(width: 34, height: 42)
                Image(systemName: icon)
                    .foregroundStyle(AceTheme.ace)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                Text(deck.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(1)
                Text(detail(total: total))
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
                ProgressView(value: known)
                    .tint(AceTheme.good)
                    .accessibilityLabel("Known well")
                    .accessibilityValue("\(Int((known * 100).rounded())) percent")
            }
            Spacer(minLength: 8)
            if due > 0 {
                Text("\(due)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AceTheme.ace))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .boing(on: due)
                    .accessibilityLabel("\(due) ready")
            } else if total > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AceTheme.good)
                    .accessibilityLabel("All caught up")
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
        }
        .aceCard()
        .contentShape(Rectangle())
    }

    private var icon: String {
        if deck.source?.hasPrefix("phrasebook:") == true { return "character.bubble.fill" }
        if deck.source?.hasPrefix("trivia:") == true { return "lightbulb.fill" }
        return "rectangle.stack.fill"
    }

    private func detail(total: Int) -> String {
        guard total > 0 else { return "No cards yet" }
        let fresh = deck.newCount
        var parts = [FlashcardSkill.count(total)]
        if fresh > 0 { parts.append("\(fresh) new") }
        parts.append("\(deck.masteredCount) known well")
        return parts.joined(separator: " · ")
    }
}

// MARK: One deck

/// A deck's cards: study it, add cards (one at a time or a pasted list), edit or delete them.
struct DeckDetailView: View {
    let deckID: UUID
    @Binding var study: StudyTarget?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = FlashcardStore.shared
    @State private var front = ""
    @State private var back = ""
    @State private var added = 0
    @State private var editing: Flashcard?
    @State private var pasting = false
    @State private var confirmDelete = false
    @State private var confirmReset = false
    @State private var renaming = false
    @State private var renameText = ""
    @State private var search = ""
    @FocusState private var focus: Field?

    private enum Field { case front, back }

    var body: some View {
        Group {
            if let deck = store.deck(deckID) {
                content(deck)
            } else {
                Text("This deck was deleted.")
                    .foregroundStyle(AceTheme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AceTheme.background.ignoresSafeArea())
            }
        }
    }

    private func content(_ deck: FlashDeck) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            List {
                Section {
                    header(deck, now: context.date)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                Section("Add a card") {
                    TextField(deck.source?.hasPrefix("phrasebook:") == true ? "Front (English)" : "Front (word or question)", text: $front)
                        .focused($focus, equals: .front)
                        .submitLabel(.next)
                        .onSubmit { focus = .back }
                    TextField("Back (meaning or answer)", text: $back)
                        .focused($focus, equals: .back)
                        .submitLabel(.done)
                        .onSubmit { addCard() }
                    HStack {
                        Button {
                            addCard()
                        } label: {
                            Label("Add card", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.aceBouncy)
                        .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty || back.trimmingCharacters(in: .whitespaces).isEmpty)
                        .boing(on: added)
                        Spacer()
                        Button {
                            pasting = true
                        } label: {
                            Label("Paste a list", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.aceBouncy)
                    }
                }
                Section(deck.cards.isEmpty ? "Cards" : "Cards (\(deck.cards.count))") {
                    if deck.cards.isEmpty {
                        Text("No cards yet. Add one above, or say \"add a flashcard to \(deck.name): front = back\".")
                            .font(.subheadline)
                            .foregroundStyle(AceTheme.muted)
                    }
                    ForEach(filtered(deck)) { card in
                        Button {
                            editing = card
                        } label: {
                            CardRow(card: card, now: context.date)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                withAnimation(AceMotion.now(.snappy)) { store.deleteCard(card.id, from: deck.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .searchable(text: $search, prompt: "Search cards")
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        renameText = deck.name
                        renaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        confirmReset = true
                    } label: {
                        Label("Start over", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(deck.cards.allSatisfy(\.isNew))
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete deck", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Deck options")
            }
        }
        .sheet(item: $editing) { card in
            CardEditor(card: card) { updated in
                store.updateCard(updated, in: deck.id)
            } onDelete: {
                store.deleteCard(card.id, from: deck.id)
            }
        }
        .sheet(isPresented: $pasting) {
            PasteCardsView(deckName: deck.name) { pairs in
                store.importPairs(pairs, to: deck.id)
            }
        }
        .alert("Rename deck", isPresented: $renaming) {
            TextField("Deck name", text: $renameText)
            Button("Save") { store.renameDeck(deck.id, to: renameText) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Start \(deck.name) over?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Start over", role: .destructive) { store.resetProgress(deck.id) }
        } message: {
            Text("Every card goes back to new. The cards stay.")
        }
        .confirmationDialog("Delete \(deck.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete deck", role: .destructive) {
                store.deleteDeck(deck.id)
                dismiss()
            }
        } message: {
            Text("Its \(FlashcardSkill.count(deck.cards.count)) will be gone for good.")
        }
    }

    private func header(_ deck: FlashDeck, now: Date) -> some View {
        let due = deck.dueCount(at: now)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 18) {
                stat("\(deck.cards.count)", "cards", AceTheme.fg)
                stat("\(due)", "ready", AceTheme.ace)
                stat("\(deck.newCount)", "new", AceTheme.amber)
                stat("\(deck.masteredCount)", "known well", AceTheme.good)
            }
            if !deck.cards.isEmpty {
                HStack(spacing: 10) {
                    Button {
                        Haptics.shared.play(.tick)
                        study = StudyTarget(deckID: deck.id, practice: false)
                    } label: {
                        Label(due > 0 ? "Study \(due)" : "Nothing due", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(due == 0)
                    Button {
                        Haptics.shared.play(.tick)
                        study = StudyTarget(deckID: deck.id, practice: true)
                    } label: {
                        Label("Practice", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                if due == 0 {
                    Text(FlashcardSkill.nextLine(deck.nextDue, now: now) + " Practice doesn't change when cards come back.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
            }
        }
        .aceCard()
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
        }
    }

    private func filtered(_ deck: FlashDeck) -> [Flashcard] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return deck.cards }
        return deck.cards.filter { $0.front.lowercased().contains(q) || $0.back.lowercased().contains(q) }
    }

    private func addCard() {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else {
            focus = f.isEmpty ? .front : .back
            return
        }
        withAnimation(AceMotion.now(.bouncy)) {
            _ = store.addCard(front: f, back: b, to: deckID)
        }
        front = ""
        back = ""
        added += 1
        Haptics.shared.play(.pop)
        focus = .front
    }
}

/// A card in a deck's list: front, back, and when it comes back.
struct CardRow: View {
    let card: Flashcard
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.front)
                    .foregroundStyle(AceTheme.fg)
                    .lineLimit(2)
                Text(card.back)
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var status: String {
        if card.isNew { return "New" }
        if card.isDue(at: now) { return "Ready" }
        let days = card.due.timeIntervalSince(now) / SpacedRepetition.day
        return "in " + SpacedRepetition.label(days: days)
    }

    private var color: Color {
        if card.isNew { return AceTheme.amber }
        if card.isDue(at: now) { return AceTheme.ace }
        return card.isMastered ? AceTheme.good : AceTheme.muted
    }
}

/// Changes one card's front, back or note.
struct CardEditor: View {
    @State var card: Flashcard
    var onSave: (Flashcard) -> Void
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextField("Word or question", text: $card.front, axis: .vertical)
                }
                Section("Back") {
                    TextField("Meaning or answer", text: $card.back, axis: .vertical)
                }
                Section("Note (optional)") {
                    TextField("A hint or fun fact under the answer", text: $note, axis: .vertical)
                }
                Section {
                    LabeledContent("Reviews", value: "\(card.reviews)")
                    LabeledContent("Right in a row", value: "\(card.streak)")
                    if !card.isNew {
                        LabeledContent("Comes back", value: card.due.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                Section {
                    Button("Delete card", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var c = card
                        let n = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        c.note = n.isEmpty ? nil : n
                        onSave(c)
                        Haptics.shared.play(.success)
                        dismiss()
                    }
                    .disabled(card.front.trimmingCharacters(in: .whitespaces).isEmpty || card.back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { note = card.note ?? "" }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }
}

/// Paste lots of cards at once, one per line ("hola = hello").
struct PasteCardsView: View {
    let deckName: String
    var onAdd: ([(front: String, back: String)]) -> Int
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var result: String?

    private var pairs: [(front: String, back: String)] { FlashcardText.pairs(fromLines: text) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("One card per line, with the front and back split by =, -, :, a tab or a comma. Lines that aren't cards are skipped.")
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
                Text("hola = hello\nperro - dog\nWhat is H2O?: Water")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AceTheme.muted)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AceTheme.soft))
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 200)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.card))
                    .foregroundStyle(AceTheme.fg)
                if let result {
                    Label(result, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AceTheme.good)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Paste into \(deckName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(pairs.isEmpty ? "Add" : "Add \(pairs.count)") {
                        let n = onAdd(pairs)
                        Haptics.shared.play(.success)
                        withAnimation(AceMotion.now(.pop)) {
                            result = n == pairs.count ? "Added \(FlashcardSkill.count(n))."
                                : "Added \(FlashcardSkill.count(n)). \(pairs.count - n) were already in the deck and got updated."
                        }
                        text = ""
                    }
                    .disabled(pairs.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        if let s = UIPasteboard.general.string { text += (text.isEmpty ? "" : "\n") + s }
                    } label: {
                        Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }
}
