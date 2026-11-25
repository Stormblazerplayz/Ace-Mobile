import Foundation

/// What Ace says and does for flashcard asks ("study my flashcards", "make spanish flashcards",
/// "add a flashcard: hola = hello").
@MainActor
enum FlashcardSkill {
    static func handle(_ ask: FlashcardAsk, host: BrainHost, store: FlashcardStore? = nil, now: Date = Date()) -> BrainReply {
        let store = store ?? FlashcardStore.shared
        switch ask {
        case .open:
            host.showFlashcards(deckID: nil, study: false, practice: false)
            if store.decks.isEmpty {
                return reply("Here's your flashcard shelf. It's empty for now, so tap + to make a deck, or ask me for one.",
                             chips: ["Make Spanish flashcards", "Make space flashcards"])
            }
            return reply("Here are your flashcards. " + summary(store, now: now), card: card(nil, title: "Your flashcards"))

        case .due:
            guard !store.decks.isEmpty else { return noDecks() }
            let due = store.dueCount(at: now)
            if due > 0 {
                let text = due == 1 ? "1 card is ready to review." : "\(due) cards are ready to review."
                return reply(text + " " + perDeck(store, now: now), card: card(nil, title: "Ready to review"))
            }
            return reply("Nothing's due right now. " + nextLine(store.nextDue, now: now), card: card(nil, title: "Your flashcards"))

        case .study(let name):
            guard !store.decks.isEmpty else { return noDecks() }
            var deck: FlashDeck?
            if let name {
                guard let d = store.deck(named: name) else {
                    let names = store.decks.prefix(3).map { "Study my \($0.name) flashcards" }
                    return reply("I can't find a deck called \(name). You have " + list(store.decks.map(\.name)) + ".",
                                 chips: Array(names), mood: .idle)
                }
                deck = d
            }
            let pool = deck.map { [$0] } ?? store.decks
            let cards = pool.reduce(0) { $0 + $1.cards.count }
            let label = deck.map { "your \($0.name) deck" } ?? "your decks"
            guard cards > 0 else {
                return reply("There are no cards in \(label) yet. Add one like \"add a flashcard: hola = hello\".",
                             card: card(deck?.id, title: deck?.name ?? "Your flashcards"))
            }
            let queue = store.queue(deckID: deck?.id, practice: false, at: now)
            if queue.total > 0 {
                host.showFlashcards(deckID: deck?.id, study: true, practice: false)
                let n = queue.total == 1 ? "1 card" : "\(queue.total) cards"
                return reply("Let's go! \(n) from \(label). Tap a card to flip it, then say how well you knew it.",
                             card: card(deck?.id, title: deck?.name ?? "Your flashcards"))
            }
            return reply("You're all caught up on \(label). " + nextLine(pool.compactMap(\.nextDue).min(), now: now)
                         + " You can still practice, and it won't change when cards come back.",
                         card: card(deck?.id, title: deck?.name ?? "Your flashcards"))

        case .newDeck(let name):
            if let old = store.deck(named: name), FlashcardStore.key(old.name) == FlashcardStore.key(name) {
                return reply("You already have a deck called \(old.name), with \(count(old.cards.count)).",
                             card: card(old.id, title: old.name))
            }
            let deck = store.newDeck(named: name, now: now)
            return reply("Made a new deck called \(deck.name). Add cards like \"add a flashcard: hola = hello\", or tap Add cards.",
                         card: card(deck.id, title: deck.name))

        case .make(let topic):
            return make(topic, store: store, now: now)

        case .add(let front, let back, let deckName):
            return add(front: front, back: back, deckName: deckName, store: store, now: now)

        case .help:
            return reply("Tell me the front and the back, like \"add a flashcard: hola = hello\" or "
                         + "\"add photosynthesis - how plants make food to my science deck\". "
                         + "You can also paste a whole list in the Flashcards screen.",
                         chips: ["Show my flashcards"], mood: .idle)
        }
    }

    // MARK: Making decks

    private static func make(_ topic: String, store: FlashcardStore, now: Date) -> BrainReply {
        let t = topic.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else {
            return reply("Sure! I can make a ready-made deck for a language (like Spanish or French) or a topic "
                         + "(like space or animals), or an empty deck for your own cards. Which one?",
                         chips: ["Make Spanish flashcards", "Make space flashcards", "Make a deck called Vocab"], mood: .idle)
        }
        guard let source = FlashcardSources.source(for: t) else {
            // No ready-made cards for this, so make an empty deck you can fill.
            let name = FlashcardText.deckName(t) ?? FlashcardStore.cleanName(t)
            if let old = store.deck(named: name), FlashcardStore.key(old.name) == FlashcardStore.key(name) {
                return reply("You already have a deck called \(old.name), with \(count(old.cards.count)).", card: card(old.id, title: old.name))
            }
            let deck = store.newDeck(named: name, now: now)
            return reply("I don't have ready-made cards about \(t), so I made an empty \(deck.name) deck for you. "
                         + "Add cards like \"add a flashcard: question = answer\", or paste a list with Add cards.",
                         card: card(deck.id, title: deck.name))
        }
        let tag = FlashcardSources.tag(source)
        if let old = store.deck(source: tag) {
            return reply("You already have a \(old.name) deck, with \(count(old.cards.count)). Want to study it?",
                         card: card(old.id, title: old.name), chips: ["Study my \(old.name) flashcards"])
        }
        guard let fresh = FlashcardSources.deck(source, now: now) else {
            return reply("I couldn't find cards for \(FlashcardSources.name(source)) in my data, sorry.", mood: .idle)
        }
        let deck = store.addDeck(fresh)
        let from: String
        switch source {
        case .language: from = "phrases from my phrasebook"
        case .trivia: from = "questions from my trivia"
        }
        return reply("Made a \(deck.name) deck with \(count(deck.cards.count)), \(from). Want to start studying?",
                     card: card(deck.id, title: deck.name), chips: ["Study my \(deck.name) flashcards"])
    }

    private static func add(front: String, back: String, deckName: String?, store: FlashcardStore, now: Date) -> BrainReply {
        var deck: FlashDeck?
        var made = false
        if let deckName {
            deck = store.deck(named: deckName)
            if deck == nil {
                deck = store.newDeck(named: deckName, now: now)
                made = true
            }
        } else if let last = store.lastDeck {
            deck = last
        } else if store.decks.count == 1 {
            deck = store.decks.first
        } else if store.decks.isEmpty {
            deck = store.newDeck(named: "My cards", now: now)
            made = true
        }
        guard let target = deck else {
            return reply("Which deck should it go in? You have " + list(store.decks.map(\.name)) + ".", mood: .idle)
        }
        guard let result = store.addCard(front: front, back: back, to: target.id, now: now) else {
            return reply("I couldn't add that card. It needs words on both sides.", mood: .idle)
        }
        let total = store.deck(target.id)?.cards.count ?? 0
        let start = made ? "Made a \(target.name) deck and added it. " : (result.isNew ? "Added to \(target.name). " : "Updated that card in \(target.name). ")
        return reply(start + "That's \(count(total)) in the deck.",
                     card: FlashcardsCard(deckID: target.id, title: target.name, addedFront: result.card.front, addedBack: result.card.back))
    }

    // MARK: Words

    private static func noDecks() -> BrainReply {
        reply("You don't have any flashcards yet. I can make a deck for a language or a topic, or an empty one for your own cards.",
              chips: ["Make Spanish flashcards", "Make space flashcards", "Show my flashcards"], mood: .idle)
    }

    private static func summary(_ store: FlashcardStore, now: Date) -> String {
        let decks = store.decks.count
        let due = store.dueCount(at: now)
        let first = "You have \(decks == 1 ? "1 deck" : "\(decks) decks") with \(count(store.cardCount))"
        return first + (due > 0 ? ", and \(due) ready to review." : ". " + nextLine(store.nextDue, now: now))
    }

    private static func perDeck(_ store: FlashcardStore, now: Date) -> String {
        let parts = store.decks.compactMap { d -> String? in
            let n = d.dueCount(at: now)
            return n > 0 ? "\(n) in \(d.name)" : nil
        }
        return parts.count > 1 ? "That's " + list(parts) + "." : ""
    }

    static func nextLine(_ next: Date?, now: Date) -> String {
        guard let next else { return "" }
        return "The next card is ready " + when(next, now: now) + "."
    }

    /// "in 20 minutes", "at 4:30 PM", "tomorrow at 9:00 AM", "on Friday", "on Dec 4".
    static func when(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let seconds = date.timeIntervalSince(now)
        if seconds <= 60 { return "now" }
        if seconds < 3600 {
            let m = Int((seconds / 60).rounded(.up))
            return "in \(m) minute\(m == 1 ? "" : "s")"
        }
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(date, inSameDayAs: now) { return "at \(time)" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "tomorrow at \(time)"
        }
        if seconds < 6 * 86_400 { return "on " + date.formatted(.dateTime.weekday(.wide)) }
        return "on " + date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func count(_ n: Int) -> String {
        n == 1 ? "1 card" : "\(n) cards"
    }

    /// "a, b and c".
    static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        return items.dropLast().joined(separator: ", ") + " and " + items.last!
    }

    private static func card(_ deckID: UUID?, title: String) -> FlashcardsCard {
        FlashcardsCard(deckID: deckID, title: title)
    }

    private static func reply(_ text: String, card: FlashcardsCard? = nil, chips: [String] = [], mood: OrbMood = .happy) -> BrainReply {
        var cards: [AceCard] = []
        if let card { cards.append(.flashcards(card)) }
        if !chips.isEmpty { cards.append(.quickReplies(QuickReplies(token: "flashcards", replies: chips, anytime: true))) }
        return BrainReply(text: text, cards: cards, source: "flashcards", mood: mood, kind: "flashcards")
    }
}
