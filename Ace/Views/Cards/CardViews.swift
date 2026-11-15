import SwiftUI

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
                        if checked.contains(i) { checked.remove(i) } else { checked.insert(i) }
                        SoundFX.shared.play(.typeTick, gain: 0.5)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: checked.contains(i) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(checked.contains(i) ? AceTheme.good : AceTheme.muted)
                            Text(item)
                                .strikethrough(checked.contains(i))
                                .foregroundStyle(checked.contains(i) ? AceTheme.muted : AceTheme.fg)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
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
                            .buttonStyle(.plain)
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
                .buttonStyle(.plain)
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
