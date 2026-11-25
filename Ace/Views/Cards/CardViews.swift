import SwiftUI
import UIKit

/// Draws any special card that rides along with a chat message.
struct CardView: View {
    let card: AceCard
    let messageID: UUID
    @EnvironmentObject var core: AceCore

    var body: some View {
        switch card {
        case .recipe(let r): RecipeCardView(recipe: r)
        case .weather(let w): WeatherCardView(weather: w)
        case .web(let w): WebCardView(card: w)
        case .links(let l): LinksCardView(links: l)
        case .eventDraft(let d): EventDraftView(draft: d, messageID: messageID)
        case .events(let e): EventsCardView(events: e)
        case .check(let c): CheckReportView(report: c)
        case .files(let f): FilesCardView(files: f)
        case .screenshots(let s): ScreenshotsCardView(hits: s)
        case .image(let i): ImageReportView(report: i)
        case .timer(let t): TimerCardView(timer: t)
        case .power(let p): PowerCardView(card: p)
        case .greeting(let g): GreetingCardView(card: g)
        case .code(let c): CodeCardView(card: c)
        case .trivia(let t): TriviaCardView(card: t)
        case .translation(let t): TranslationCardView(card: t)
        case .quickReplies(let q): QuickRepliesView(card: q)
        case .steps(let s): StepsCardView(card: s)
        case .whatsNew(let w): WhatsNewCardView(card: w)
        case .flashcards(let f): FlashcardsCardView(card: f)
        case .ticTacToe(let t): TicTacToeCardView(card: t, messageID: messageID)
        case .hangman(let h): HangmanCardView(card: h, messageID: messageID)
        case .numberGuess(let n): NumberGuessCardView(card: n, messageID: messageID)
        case .rps(let r): RPSCardView(card: r, messageID: messageID)
        }
    }
}

// MARK: Flashcards

/// Flashcards in the chat: the deck (or all decks), how many cards are ready, and buttons to
/// study, practice or add cards. The numbers are read live, so they're right even on an old card.
struct FlashcardsCardView: View {
    let card: FlashcardsCard
    @EnvironmentObject var core: AceCore
    @ObservedObject private var store = FlashcardStore.shared
    @State private var shown = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            content(now: context.date)
        }
        .aceCard()
        .onAppear { shown = true }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let deck = store.deck(card.deckID)
        if card.deckID != nil && deck == nil {
            Label("This deck was deleted.", systemImage: "rectangle.stack.badge.minus")
                .font(.subheadline)
                .foregroundStyle(AceTheme.muted)
        } else {
            let decks = deck.map { [$0] } ?? store.decks
            let total = decks.reduce(0) { $0 + $1.cards.count }
            let due = decks.reduce(0) { $0 + $1.dueCount(at: now) }
            let known = decks.reduce(0) { $0 + $1.masteredCount }
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(icon: "rectangle.stack.fill", title: deck?.name ?? card.title)
                if let front = card.addedFront, let back = card.addedBack {
                    HStack(spacing: 8) {
                        Text(front).foregroundStyle(AceTheme.fg)
                        Image(systemName: "arrow.right").font(.caption).foregroundStyle(AceTheme.muted)
                        Text(back).foregroundStyle(AceTheme.good)
                    }
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AceTheme.soft))
                    .bounceReveal(shown, order: 1)
                }
                HStack(spacing: 18) {
                    number("\(total)", total == 1 ? "card" : "cards", AceTheme.fg)
                    number("\(due)", "ready", AceTheme.ace)
                    number("\(known)", "known well", AceTheme.good)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 8) {
                    if total > 0 {
                        button(due > 0 ? "Study \(due)" : "Practice", icon: due > 0 ? "play.fill" : "shuffle", primary: true) {
                            core.showFlashcards(deckID: deck?.id, study: true, practice: due == 0)
                        }
                    }
                    button(deck == nil ? "Open" : "Add cards", icon: deck == nil ? "rectangle.stack" : "plus", primary: total == 0) {
                        core.showFlashcards(deckID: deck?.id, study: false, practice: false)
                    }
                }
            }
        }
    }

    private func number(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
        }
    }

    private func button(_ title: String, icon: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.play(.tick)
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(primary ? AceTheme.ace : AceTheme.ace.opacity(0.16)))
                .foregroundStyle(primary ? Color.black.opacity(0.85) : AceTheme.ace)
        }
        .buttonStyle(.aceBouncy)
    }
}

/// The What's new card: the build number and a short list of what changed.
struct WhatsNewCardView: View {
    let card: WhatsNewCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: "sparkles", title: "What's new in build \(card.build)", tint: AceTheme.amber)
            WhatsNewList(items: card.items)
        }
        .aceCard()
    }
}

/// The list of changes, used by the card and by Settings.
struct WhatsNewList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(AceTheme.amber)
                        .padding(.top, 4)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct CardHeader: View {
    var icon: String
    var title: String
    var tint: Color = AceTheme.ace

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AceTheme.fg)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
    }
}

// MARK: Recipe

struct RecipeCardView: View {
    let recipe: RecipeCard
    @EnvironmentObject var core: AceCore
    @State private var checked: Set<Int> = []
    @State private var showAllSteps = false
    @State private var cooking = false
    @State private var shoppingNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let url = recipe.imageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(AceTheme.soft)
                    }
                }
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            CardHeader(icon: "fork.knife", title: recipe.name, tint: AceTheme.amber)
            HStack(spacing: 6) {
                if let c = recipe.category { Chip(text: c) }
                if let a = recipe.area { Chip(text: a) }
                if let time = recipe.time { Chip(text: time) }
                if let n = recipe.servings { Chip(text: "Serves \(n)") }
                Chip(text: "\(recipe.ingredients.count) ingredients")
            }
            Text("Ingredients")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { i, item in
                    Button {
                        withAnimation(AceMotion.now(.pop)) {
                            if checked.contains(i) { checked.remove(i) } else { checked.insert(i) }
                        }
                        SoundFX.shared.play(.typeTick, gain: 0.5)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: checked.contains(i) ? "checkmark.circle.fill" : "circle")
                                .contentTransition(.symbolEffect(.replace))
                                .foregroundStyle(checked.contains(i) ? AceTheme.good : AceTheme.muted)
                            Text(item)
                                .strikethrough(checked.contains(i))
                                .foregroundStyle(checked.contains(i) ? AceTheme.muted : AceTheme.fg)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(BouncyButtonStyle(depth: 0.97))
                }
            }
            Text("Steps")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AceTheme.muted)
            let steps = showAllSteps ? recipe.steps : Array(recipe.steps.prefix(4))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.caption.weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(AceTheme.amber.opacity(0.25)))
                            .foregroundStyle(AceTheme.amber)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step)
                                .foregroundStyle(AceTheme.fg)
                                .fixedSize(horizontal: false, vertical: true)
                            if let found = StepTimer.find(in: step) {
                                StepTimerButton(recipe: recipe.name, found: found)
                            }
                        }
                    }
                }
            }
            HStack {
                if recipe.steps.count > 4 {
                    Button(showAllSteps ? "Show fewer steps" : "Show all \(recipe.steps.count) steps") {
                        withAnimation { showAllSteps.toggle() }
                    }
                }
                Spacer()
                if let src = recipe.sourceURL {
                    Button {
                        core.openLink(src, title: recipe.name)
                    } label: {
                        Label("Source", systemImage: "safari")
                    }
                }
            }
            .font(.subheadline)
            .tint(AceTheme.ace)
            if !recipe.ingredients.isEmpty {
                Button {
                    Haptics.shared.play(.tick)
                    Task { await addToShopping() }
                } label: {
                    Label(shoppingNote ?? "Add ingredients to Shopping list", systemImage: shoppingNote == nil ? "cart.badge.plus" : "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.bordered)
                .tint(AceTheme.ace)
                .disabled(shoppingNote != nil)
            }
            if !recipe.steps.isEmpty {
                Button {
                    cooking = true
                    SoundFX.shared.play(.orbWake, gain: 0.6)
                } label: {
                    Label("Start cooking", systemImage: "frying.pan.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(AceTheme.amber)
            }
        }
        .aceCard()
        .fullScreenCover(isPresented: $cooking) { CookingModeView(recipe: recipe) }
    }

    /// Puts the ingredients on the Shopping list in Reminders (skipping ones already there).
    private func addToShopping() async {
        let cal = CalendarService.shared
        guard await cal.requestReminderAccess(), let r = await cal.addToShopping(recipe.ingredients) else {
            shoppingNote = "Turn on Reminders for Ace in Settings"
            return
        }
        if r.added.isEmpty {
            shoppingNote = "Already on your Shopping list"
        } else {
            shoppingNote = "Added \(r.added.count) to your Shopping list"
        }
    }
}

struct Chip: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(AceTheme.soft))
            .foregroundStyle(AceTheme.muted)
    }
}

// MARK: Weather

struct WeatherCardView: View {
    let weather: WeatherCard

    var body: some View {
        let now = WebService.describe(code: weather.code)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: now.symbol)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 44))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(weather.temperature.rounded()))\(weather.unit)")
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                    Text("\(now.text.capitalized) in \(weather.place)")
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                    if let f = weather.feelsLike {
                        Text("Feels like \(Int(f.rounded()))\(weather.unit)")
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                    }
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(weather.days, id: \.date) { d in
                    let info = WebService.describe(code: d.code)
                    VStack(spacing: 6) {
                        Text(d.date.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AceTheme.muted)
                        Image(systemName: info.symbol)
                            .symbolRenderingMode(.multicolor)
                        Text("\(Int(d.high.rounded()))°")
                            .foregroundStyle(AceTheme.fg)
                        Text("\(Int(d.low.rounded()))°")
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                        if let r = d.rainChance, r > 0 {
                            Text("\(r)%")
                                .font(.caption2)
                                .foregroundStyle(AceTheme.ace)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AceTheme.soft))
                }
            }
            Text("Weather from Open-Meteo")
                .font(.caption2)
                .foregroundStyle(AceTheme.muted.opacity(0.7))
        }
        .aceCard()
    }
}

// MARK: Web

struct WebCardView: View {
    let card: WebCard
    @EnvironmentObject var core: AceCore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                if let url = card.imageURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() } else { AceTheme.soft }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                CardHeader(icon: "globe", title: card.title)
            }
            if !card.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(card.bullets, id: \.self) { b in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(AceTheme.ace).frame(width: 5, height: 5).padding(.top, 7)
                            Text(b).font(.subheadline).foregroundStyle(AceTheme.fg.opacity(0.9))
                        }
                    }
                }
            }
            if !card.sources.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(card.sources) { s in
                            Button {
                                core.openLink(s.url, title: s.title)
                            } label: {
                                Label(s.title, systemImage: "link")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(AceTheme.soft))
                            }
                            .buttonStyle(.aceBouncy)
                            .foregroundStyle(AceTheme.ace)
                        }
                    }
                }
            }
        }
        .aceCard()
    }
}

struct LinksCardView: View {
    let links: [LinkItem]
    @EnvironmentObject var core: AceCore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(links) { l in
                Button {
                    core.openLink(l.url, title: l.title)
                } label: {
                    HStack {
                        Image(systemName: "safari").foregroundStyle(AceTheme.ace)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.title).foregroundStyle(AceTheme.fg).lineLimit(1)
                            Text(l.url.host ?? l.url.absoluteString).font(.caption).foregroundStyle(AceTheme.muted).lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").foregroundStyle(AceTheme.muted)
                    }
                }
                .buttonStyle(BouncyButtonStyle(depth: 0.97))
            }
        }
        .aceCard(padding: 12)
    }
}

// MARK: Calendar

struct EventDraftView: View {
    let draft: EventDraft
    let messageID: UUID
    @EnvironmentObject var core: AceCore

    private var verb: String {
        switch draft.action {
        case .add: return "Add to Nimbus calendar"
        case .edit: return "Change event"
        case .delete: return "Delete event"
        }
    }

    private var whenText: String {
        if draft.allDay {
            let day: String = draft.start.formatted(.dateTime.weekday(.wide).month().day())
            return day + " · all day"
        }
        let start: String = draft.start.formatted(.dateTime.weekday(.wide).month().day().hour().minute())
        let end: String = draft.end.formatted(date: .omitted, time: .shortened)
        return start + " – " + end
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: draft.action == .delete ? "calendar.badge.minus" : "calendar.badge.plus", title: verb,
                       tint: draft.action == .delete ? AceTheme.bad : AceTheme.ace)
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AceTheme.fg)
                Text(whenText)
                    .foregroundStyle(AceTheme.muted)
            }
            switch draft.status {
            case .waiting:
                HStack(spacing: 10) {
                    Button {
                        core.answerDraft(messageID: messageID, draftID: draft.id, yes: true)
                    } label: {
                        Text(draft.action == .delete ? "Yes, delete" : "Yes").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(draft.action == .delete ? AceTheme.bad : AceTheme.ace)
                    Button {
                        core.answerDraft(messageID: messageID, draftID: draft.id, yes: false)
                    } label: {
                        Text("No").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AceTheme.muted)
                }
            case .done:
                Label(draft.resultText ?? "Done", systemImage: "checkmark.circle.fill").foregroundStyle(AceTheme.good)
            case .cancelled:
                Label(draft.resultText ?? "Cancelled", systemImage: "xmark.circle").foregroundStyle(AceTheme.muted)
            case .failed:
                Label(draft.resultText ?? "That didn't work", systemImage: "exclamationmark.triangle.fill").foregroundStyle(AceTheme.warn)
            }
        }
        .aceCard()
    }
}

struct EventsCardView: View {
    let events: [EventItem]

    static func when(_ e: EventItem) -> String {
        if e.allDay {
            let day: String = e.start.formatted(.dateTime.weekday().month().day())
            return day + " · all day"
        }
        return e.start.formatted(.dateTime.weekday().month().day().hour().minute())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: "calendar", title: events.count == 1 ? "1 event" : "\(events.count) events")
            ForEach(events.prefix(12)) { e in
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(e.calendar == CalendarService.calendarName ? AceTheme.ace : AceTheme.accent)
                        .frame(width: 4, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.title).foregroundStyle(AceTheme.fg)
                        Text(Self.when(e))
                            .font(.caption)
                            .foregroundStyle(AceTheme.muted)
                    }
                    Spacer()
                    if !e.calendar.isEmpty {
                        Text(e.calendar).font(.caption2).foregroundStyle(AceTheme.muted)
                    }
                }
            }
        }
        .aceCard()
    }
}

// MARK: Checks

struct CheckReportView: View {
    let report: CheckReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: report.needsAttention ? "exclamationmark.circle.fill" : "checkmark.seal.fill",
                       title: "Check at \(report.date.formatted(date: .omitted, time: .shortened))",
                       tint: report.needsAttention ? AceTheme.warn : AceTheme.good)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 8)], spacing: 8) {
                ForEach(report.items) { item in
                    CheckItemTile(item: item)
                }
            }
        }
        .aceCard()
    }
}

struct CheckItemTile: View {
    let item: CheckItem

    private var tint: Color {
        switch item.level {
        case .ok: return AceTheme.good
        case .info: return AceTheme.ace
        case .warn: return AceTheme.warn
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(AceTheme.fg).lineLimit(1)
                Text(item.detail).font(.caption).foregroundStyle(AceTheme.muted).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.08)))
    }
}

// MARK: Files, screenshots, pictures, timers, PC

struct FilesCardView: View {
    let files: [FileHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(icon: "folder", title: "\(files.count) file\(files.count == 1 ? "" : "s")")
            ForEach(files.prefix(15)) { f in
                HStack {
                    Image(systemName: "doc").foregroundStyle(AceTheme.ace)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.name).foregroundStyle(AceTheme.fg).lineLimit(1)
                        if let s = f.snippet { Text(s).font(.caption).foregroundStyle(AceTheme.muted).lineLimit(2) }
                    }
                    Spacer()
                    Text(SystemMonitor.bytes(f.size)).font(.caption).foregroundStyle(AceTheme.muted)
                }
            }
        }
        .aceCard()
    }
}

struct ScreenshotsCardView: View {
    let hits: [ScreenshotHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(icon: "photo.on.rectangle", title: "\(hits.count) screenshot\(hits.count == 1 ? "" : "s")")
            ForEach(hits.prefix(10)) { h in
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.snippet).font(.subheadline).foregroundStyle(AceTheme.fg).lineLimit(2)
                    if let d = h.date { Text(d.formatted()).font(.caption).foregroundStyle(AceTheme.muted) }
                }
            }
        }
        .aceCard()
    }
}

struct ImageReportView: View {
    let report: ImageReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(icon: "eye", title: "What I see")
            if !report.labels.isEmpty {
                HStack { ForEach(report.labels.prefix(5), id: \.self) { Chip(text: $0) } }
            }
            if let t = report.text, !t.isEmpty {
                Text(t).font(.callout.monospaced()).foregroundStyle(AceTheme.fg).lineLimit(8)
            }
            ForEach(report.codes, id: \.self) { c in
                Label(c, systemImage: "qrcode").foregroundStyle(AceTheme.ace)
            }
        }
        .aceCard()
    }
}

struct TimerCardView: View {
    let timer: TimerCard

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let left = max(0, timer.fireDate.timeIntervalSince(context.date))
            HStack(spacing: 14) {
                Image(systemName: left > 0 ? "timer" : "bell.fill")
                    .font(.title2)
                    .foregroundStyle(left > 0 ? AceTheme.ace : AceTheme.good)
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.label).foregroundStyle(AceTheme.fg)
                    Text(left > 0 ? "Done at \(timer.fireDate.formatted(date: .omitted, time: .shortened))" : "Done!")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
                Spacer()
                Text(Self.clock(left))
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(left > 0 ? AceTheme.fg : AceTheme.good)
            }
        }
        .aceCard()
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }
}

struct GreetingCardView: View {
    let card: GreetingCard
    @EnvironmentObject var core: AceCore

    private var icon: String {
        let hour = Calendar.current.component(.hour, from: card.date)
        return hour < 12 ? "sun.max.fill" : hour < 17 ? "sun.haze.fill" : "moon.stars.fill"
    }

    private let quick: [(String, String, String)] = [
        ("Focus 25 min", "brain.head.profile", "focus for 25 minutes"),
        ("Dinner idea", "fork.knife", "what should I make for dinner"),
        ("Weather", "cloud.sun.fill", "what is the weather"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AceTheme.amber)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.hello)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(AceTheme.fg)
                    Text(card.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                }
            }
            if card.calendarAllowed {
                if card.events.isEmpty {
                    Label("Nothing else on your calendar today", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.muted)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(card.events.prefix(3)) { e in
                            HStack(spacing: 8) {
                                Text(e.allDay ? "All day" : e.start.formatted(date: .omitted, time: .shortened))
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(AceTheme.ace)
                                    .frame(width: 64, alignment: .leading)
                                Text(e.title)
                                    .font(.subheadline)
                                    .foregroundStyle(AceTheme.fg)
                                    .lineLimit(1)
                            }
                        }
                        if card.events.count > 3 {
                            Text("and \(card.events.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(AceTheme.muted)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                ForEach(quick, id: \.0) { item in
                    Button {
                        Haptics.shared.play(.tick)
                        core.send(item.2)
                    } label: {
                        Label(item.0, systemImage: item.1)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                            .foregroundStyle(AceTheme.ace)
                    }
                    .buttonStyle(.aceBouncy)
                }
            }
        }
        .aceCard()
    }
}

struct PowerCardView: View {
    let card: PowerCard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.action == "restart" ? "arrow.clockwise.circle.fill" : "power.circle.fill")
                .font(.title)
                .foregroundStyle(card.status == .done ? AceTheme.good : AceTheme.warn)
            VStack(alignment: .leading, spacing: 2) {
                Text(card.action == "restart" ? "Restart PC" : card.action == "shutdown" ? "Shut down PC" : card.action.capitalized)
                    .foregroundStyle(AceTheme.fg)
                Text(card.detail).font(.caption).foregroundStyle(AceTheme.muted)
            }
            Spacer()
        }
        .aceCard()
    }
}

// MARK: Code

/// A script from Ace's library: colored code, a Copy button and where to put it.
struct CodeCardView: View {
    let card: CodeCard
    var startOpen = false
    @State private var showAll = false
    @State private var copied = false

    private static let shortLines = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(AceTheme.ace)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AceTheme.fg)
                    Text("\(card.language) · \(card.kind)")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
                Spacer(minLength: 0)
                Button {
                    UIPasteboard.general.string = card.code
                    copied = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(copied ? AceTheme.good : AceTheme.ace)
                .accessibilityLabel(copied ? "Copied" : "Copy the code")
            }

            Label(card.`where`, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(AceTheme.fg)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AceTheme.ace.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(CodeCardView.colored(shownCode, language: card.language))
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(12)
            }
            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))

            if lineCount > Self.shortLines {
                Button(showAll ? "Show less" : "Show all \(lineCount) lines") {
                    withAnimation { showAll.toggle() }
                }
                .font(.subheadline)
                .tint(AceTheme.ace)
            }

            Text(card.about)
                .font(.caption)
                .foregroundStyle(AceTheme.muted)
        }
        .aceCard()
        .onAppear { if startOpen { showAll = true } }
    }

    private var lineCount: Int { card.code.split(separator: "\n", omittingEmptySubsequences: false).count }

    private var shownCode: String {
        guard !showAll, lineCount > Self.shortLines else { return card.code }
        return card.code.split(separator: "\n", omittingEmptySubsequences: false).prefix(Self.shortLines).joined(separator: "\n") + "\n…"
    }

    static func colored(_ code: String, language: String) -> AttributedString {
        var out = AttributedString()
        for piece in CodeHighlighter.pieces(code, language: language) {
            var part = AttributedString(piece.text)
            switch piece.kind {
            case .plain: part.foregroundColor = AceTheme.fg
            case .keyword: part.foregroundColor = Color(hex: 0xFF7AB6)
            case .string: part.foregroundColor = Color(hex: 0xA5E075)
            case .comment: part.foregroundColor = Color(hex: 0x8A87A6)
            case .number: part.foregroundColor = Color(hex: 0xFFB86C)
            case .builtin: part.foregroundColor = Color(hex: 0x6CC8FF)
            case .preprocessor: part.foregroundColor = Color(hex: 0xC792EA)
            }
            out += part
        }
        return out
    }
}

// MARK: Games and the translator

/// A trivia question: tap an answer. Once it's answered (or a newer question comes), the buttons stop working.
struct TriviaCardView: View {
    let card: TriviaCard
    @EnvironmentObject var core: AceCore
    @State private var tapped: Int?

    private var live: Bool { tapped == nil && core.brain.gameToken == card.token }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Trivia · \(card.category)", systemImage: "questionmark.bubble.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AceTheme.ace)
                Spacer()
                Text("\(card.number) of \(card.total) · Score \(card.score)")
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
            Text(card.question)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(card.choices.enumerated()), id: \.offset) { i, choice in
                    Button {
                        guard live else { return }
                        tapped = i
                        Haptics.shared.play(.tick)
                        core.send(choice)
                    } label: {
                        HStack(spacing: 6) {
                            Text(Trivia.letter(i))
                                .font(.caption.weight(.bold))
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(AceTheme.ace.opacity(0.22)))
                            Text(choice)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(tapped == i ? AceTheme.ace.opacity(0.3) : AceTheme.ace.opacity(0.1)))
                    }
                    .buttonStyle(BouncyButtonStyle(depth: 0.95))
                    .disabled(!live)
                    .accessibilityLabel("\(Trivia.letter(i)), \(choice)")
                }
            }
            .opacity(live || tapped != nil ? 1 : 0.55)
        }
        .aceCard()
    }
}

/// A translation: the words, how to say them, and a button to hear them.
struct TranslationCardView: View {
    let card: TranslationCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("English to \(card.language)", systemImage: "character.bubble.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.ace)
            Text(card.english)
                .font(.subheadline)
                .foregroundStyle(AceTheme.muted)
            Text(card.text)
                .font(.title2.weight(.semibold))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if let say = card.say, !say.isEmpty {
                Text("Say it like: \(say)")
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
            }
            HStack(spacing: 10) {
                Button {
                    Haptics.shared.play(.tick)
                    VoiceOut.shared.speak(card.text, language: Phrasebook.speechCodes[card.code] ?? card.code)
                } label: {
                    Label("Say it", systemImage: "speaker.wave.2.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                        .foregroundStyle(AceTheme.ace)
                }
                .buttonStyle(.aceBouncy)
                Button {
                    UIPasteboard.general.string = card.text
                    Haptics.shared.play(.tick)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                        .foregroundStyle(AceTheme.ace)
                }
                .buttonStyle(.aceBouncy)
            }
        }
        .aceCard()
    }
}

/// Quick answer buttons (Yes, No, Maybe, I don't know) for 20 questions.
struct QuickRepliesView: View {
    let card: QuickReplies
    @EnvironmentObject var core: AceCore
    @State private var tapped: String?

    private var live: Bool { tapped == nil && (card.anytime == true || core.brain.gameToken == card.token) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(card.replies, id: \.self) { reply in
                Button {
                    guard live else { return }
                    tapped = reply
                    Haptics.shared.play(.tick)
                    core.send(reply)
                } label: {
                    Text(reply)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(tapped == reply ? AceTheme.ace.opacity(0.32) : AceTheme.ace.opacity(0.16)))
                        .foregroundStyle(AceTheme.ace)
                }
                .buttonStyle(.aceBouncy)
                .disabled(!live)
            }
        }
        .opacity(live || tapped != nil ? 1 : 0.5)
    }
}

// MARK: Homework steps

/// A worked math problem. Steps show one at a time ("Next step"), so you can try each one first.
struct StepsCardView: View {
    let card: StepsCard
    @State private var shown = 1
    @State private var copied = false

    private var allShown: Bool { shown >= card.steps.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Step by step", systemImage: "function")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AceTheme.ace)
            Text(card.problem)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(AceTheme.fg)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(card.steps.prefix(shown).enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.caption.weight(.bold))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AceTheme.ace.opacity(0.18)))
                        .foregroundStyle(AceTheme.ace)
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(AceTheme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if allShown {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AceTheme.ace)
                    Text("Answer: \(card.answer)")
                        .font(.headline)
                        .foregroundStyle(AceTheme.fg)
                        .textSelection(.enabled)
                }
                .padding(.top, 2)
            }
            HStack(spacing: 10) {
                if !allShown {
                    Button {
                        Haptics.shared.play(.tick)
                        withAnimation(AceMotion.now(.bouncy)) { shown += 1 }
                    } label: {
                        Label("Next step", systemImage: "arrow.down.circle.fill")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(AceTheme.ace.opacity(0.16)))
                            .foregroundStyle(AceTheme.ace)
                    }
                    .buttonStyle(.aceBouncy)
                    Button {
                        withAnimation(AceMotion.now(.bouncy)) { shown = card.steps.count }
                    } label: {
                        Text("Show all")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(AceTheme.soft))
                            .foregroundStyle(AceTheme.muted)
                    }
                    .buttonStyle(.aceBouncy)
                }
                Spacer(minLength: 0)
                Button {
                    UIPasteboard.general.string = ([card.problem] + card.steps + ["Answer: \(card.answer)"]).joined(separator: "\n")
                    Haptics.shared.play(.tick)
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AceTheme.soft))
                        .foregroundStyle(AceTheme.muted)
                }
                .buttonStyle(.aceBouncy)
            }
        }
        .aceCard()
        .onAppear { if card.steps.isEmpty { shown = 0 } }
    }
}
