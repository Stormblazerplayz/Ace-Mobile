import Foundation

/// Countries Ace knows by name, and who leads them.
/// Used to answer "who is the prime minister of the UK", to fix questions with the wrong title
/// in them ("president of the UK", "king of the USA"), and to check that a web result is about
/// the place you asked about.
enum Leaders {
    /// One top job in a country.
    struct Post: Equatable {
        /// "President", "King", "Prime Minister", "Chancellor"...
        var title: String
        /// Who had the job when Ace's built-in facts were checked. nil when Ace isn't sure.
        var person: String?
    }

    struct Country: Equatable {
        /// "the United Kingdom"
        var name: String
        /// "the UK" (said in answers)
        var short: String
        /// Its Wikidata id, used to look up who leads it right now.
        var wikidata: String
        /// Ways people write the country, lowercased ("uk", "britain"...).
        var names: [String]
        /// Words for its people ("british"), so a web result about it still counts.
        var people: [String]
        /// The head of state (a president, king, queen or emperor).
        var state: Post
        /// Who runs the government. nil when the head of state does both (like the US president).
        var government: Post?
    }

    /// When the built-in names below were last checked. Fresh names come from the web when it's on.
    static let checked = "June 2026"

    // MARK: Countries

    static let countries: [Country] = [
        Country(name: "the United Kingdom", short: "the UK", wikidata: "Q145",
                names: ["united kingdom", "uk", "u.k", "u.k.", "britain", "great britain", "england"],
                people: ["british", "britain's"],
                state: Post(title: "King", person: "Charles III"),
                government: Post(title: "Prime Minister", person: "Keir Starmer")),
        Country(name: "the United States", short: "the US", wikidata: "Q30",
                names: ["united states", "united states of america", "usa", "u.s", "u.s.", "u.s.a", "u.s.a.", "america"],
                people: ["american"],
                state: Post(title: "President", person: "Donald Trump"), government: nil),
        Country(name: "Canada", short: "Canada", wikidata: "Q16", names: ["canada"], people: ["canadian"],
                state: Post(title: "King", person: "Charles III"),
                government: Post(title: "Prime Minister", person: "Mark Carney")),
        Country(name: "Australia", short: "Australia", wikidata: "Q408", names: ["australia"], people: ["australian"],
                state: Post(title: "King", person: "Charles III"),
                government: Post(title: "Prime Minister", person: "Anthony Albanese")),
        Country(name: "New Zealand", short: "New Zealand", wikidata: "Q664", names: ["new zealand"], people: ["new zealander", "kiwi"],
                state: Post(title: "King", person: "Charles III"),
                government: Post(title: "Prime Minister", person: "Christopher Luxon")),
        Country(name: "Ireland", short: "Ireland", wikidata: "Q27", names: ["ireland", "republic of ireland", "eire"], people: ["irish"],
                state: Post(title: "President", person: "Catherine Connolly"),
                government: Post(title: "Taoiseach", person: "Micheál Martin")),
        Country(name: "Germany", short: "Germany", wikidata: "Q183", names: ["germany", "deutschland"], people: ["german"],
                state: Post(title: "President", person: "Frank-Walter Steinmeier"),
                government: Post(title: "Chancellor", person: "Friedrich Merz")),
        Country(name: "Austria", short: "Austria", wikidata: "Q40", names: ["austria"], people: ["austrian"],
                state: Post(title: "President", person: "Alexander Van der Bellen"),
                government: Post(title: "Chancellor", person: "Christian Stocker")),
        Country(name: "France", short: "France", wikidata: "Q142", names: ["france"], people: ["french"],
                state: Post(title: "President", person: "Emmanuel Macron"),
                government: Post(title: "Prime Minister", person: nil)),
        Country(name: "Italy", short: "Italy", wikidata: "Q38", names: ["italy"], people: ["italian"],
                state: Post(title: "President", person: "Sergio Mattarella"),
                government: Post(title: "Prime Minister", person: "Giorgia Meloni")),
        Country(name: "Spain", short: "Spain", wikidata: "Q29", names: ["spain"], people: ["spanish"],
                state: Post(title: "King", person: "Felipe VI"),
                government: Post(title: "Prime Minister", person: "Pedro Sánchez")),
        Country(name: "Portugal", short: "Portugal", wikidata: "Q45", names: ["portugal"], people: ["portuguese"],
                state: Post(title: "President", person: nil),
                government: Post(title: "Prime Minister", person: "Luís Montenegro")),
        Country(name: "Greece", short: "Greece", wikidata: "Q41", names: ["greece"], people: ["greek"],
                state: Post(title: "President", person: "Konstantinos Tasoulas"),
                government: Post(title: "Prime Minister", person: "Kyriakos Mitsotakis")),
        Country(name: "the Netherlands", short: "the Netherlands", wikidata: "Q55", names: ["netherlands", "holland"], people: ["dutch"],
                state: Post(title: "King", person: "Willem-Alexander"),
                government: Post(title: "Prime Minister", person: nil)),
        Country(name: "Belgium", short: "Belgium", wikidata: "Q31", names: ["belgium"], people: ["belgian"],
                state: Post(title: "King", person: "Philippe"),
                government: Post(title: "Prime Minister", person: "Bart De Wever")),
        Country(name: "Norway", short: "Norway", wikidata: "Q20", names: ["norway"], people: ["norwegian"],
                state: Post(title: "King", person: "Harald V"),
                government: Post(title: "Prime Minister", person: "Jonas Gahr Støre")),
        Country(name: "Sweden", short: "Sweden", wikidata: "Q34", names: ["sweden"], people: ["swedish"],
                state: Post(title: "King", person: "Carl XVI Gustaf"),
                government: Post(title: "Prime Minister", person: nil)),
        Country(name: "Denmark", short: "Denmark", wikidata: "Q35", names: ["denmark"], people: ["danish"],
                state: Post(title: "King", person: "Frederik X"),
                government: Post(title: "Prime Minister", person: nil)),
        Country(name: "Finland", short: "Finland", wikidata: "Q33", names: ["finland"], people: ["finnish"],
                state: Post(title: "President", person: "Alexander Stubb"),
                government: Post(title: "Prime Minister", person: "Petteri Orpo")),
        Country(name: "Poland", short: "Poland", wikidata: "Q36", names: ["poland"], people: ["polish"],
                state: Post(title: "President", person: "Karol Nawrocki"),
                government: Post(title: "Prime Minister", person: "Donald Tusk")),
        Country(name: "Ukraine", short: "Ukraine", wikidata: "Q212", names: ["ukraine"], people: ["ukrainian"],
                state: Post(title: "President", person: "Volodymyr Zelenskyy"),
                government: Post(title: "Prime Minister", person: "Yulia Svyrydenko")),
        Country(name: "Russia", short: "Russia", wikidata: "Q159", names: ["russia", "russian federation"], people: ["russian"],
                state: Post(title: "President", person: "Vladimir Putin"),
                government: Post(title: "Prime Minister", person: "Mikhail Mishustin")),
        Country(name: "Turkey", short: "Turkey", wikidata: "Q43", names: ["turkey", "turkiye", "türkiye"], people: ["turkish"],
                state: Post(title: "President", person: "Recep Tayyip Erdoğan"), government: nil),
        Country(name: "Israel", short: "Israel", wikidata: "Q801", names: ["israel"], people: ["israeli"],
                state: Post(title: "President", person: "Isaac Herzog"),
                government: Post(title: "Prime Minister", person: "Benjamin Netanyahu")),
        Country(name: "Egypt", short: "Egypt", wikidata: "Q79", names: ["egypt"], people: ["egyptian"],
                state: Post(title: "President", person: "Abdel Fattah el-Sisi"),
                government: Post(title: "Prime Minister", person: "Mostafa Madbouly")),
        Country(name: "Saudi Arabia", short: "Saudi Arabia", wikidata: "Q851", names: ["saudi arabia", "saudi"], people: ["saudi"],
                state: Post(title: "King", person: "Salman"),
                government: Post(title: "Prime Minister", person: "Mohammed bin Salman")),
        Country(name: "South Africa", short: "South Africa", wikidata: "Q258", names: ["south africa"], people: ["south african"],
                state: Post(title: "President", person: "Cyril Ramaphosa"), government: nil),
        Country(name: "Nigeria", short: "Nigeria", wikidata: "Q1033", names: ["nigeria"], people: ["nigerian"],
                state: Post(title: "President", person: "Bola Tinubu"), government: nil),
        Country(name: "Kenya", short: "Kenya", wikidata: "Q114", names: ["kenya"], people: ["kenyan"],
                state: Post(title: "President", person: "William Ruto"), government: nil),
        Country(name: "India", short: "India", wikidata: "Q668", names: ["india", "bharat"], people: ["indian"],
                state: Post(title: "President", person: "Droupadi Murmu"),
                government: Post(title: "Prime Minister", person: "Narendra Modi")),
        Country(name: "Pakistan", short: "Pakistan", wikidata: "Q843", names: ["pakistan"], people: ["pakistani"],
                state: Post(title: "President", person: "Asif Ali Zardari"),
                government: Post(title: "Prime Minister", person: "Shehbaz Sharif")),
        Country(name: "China", short: "China", wikidata: "Q148", names: ["china", "people's republic of china", "prc"], people: ["chinese"],
                state: Post(title: "President", person: "Xi Jinping"),
                government: Post(title: "Premier", person: "Li Qiang")),
        Country(name: "Japan", short: "Japan", wikidata: "Q17", names: ["japan"], people: ["japanese"],
                state: Post(title: "Emperor", person: "Naruhito"),
                government: Post(title: "Prime Minister", person: "Sanae Takaichi")),
        Country(name: "South Korea", short: "South Korea", wikidata: "Q884", names: ["south korea", "korea", "republic of korea"], people: ["korean"],
                state: Post(title: "President", person: "Lee Jae-myung"),
                government: Post(title: "Prime Minister", person: "Kim Min-seok")),
        Country(name: "Singapore", short: "Singapore", wikidata: "Q334", names: ["singapore"], people: ["singaporean"],
                state: Post(title: "President", person: "Tharman Shanmugaratnam"),
                government: Post(title: "Prime Minister", person: "Lawrence Wong")),
        Country(name: "Thailand", short: "Thailand", wikidata: "Q869", names: ["thailand"], people: ["thai"],
                state: Post(title: "King", person: "Vajiralongkorn"),
                government: Post(title: "Prime Minister", person: nil)),
        Country(name: "Indonesia", short: "Indonesia", wikidata: "Q252", names: ["indonesia"], people: ["indonesian"],
                state: Post(title: "President", person: "Prabowo Subianto"), government: nil),
        Country(name: "the Philippines", short: "the Philippines", wikidata: "Q928", names: ["philippines"], people: ["filipino", "philippine"],
                state: Post(title: "President", person: "Ferdinand Marcos Jr."), government: nil),
        Country(name: "Mexico", short: "Mexico", wikidata: "Q96", names: ["mexico"], people: ["mexican"],
                state: Post(title: "President", person: "Claudia Sheinbaum"), government: nil),
        Country(name: "Brazil", short: "Brazil", wikidata: "Q155", names: ["brazil", "brasil"], people: ["brazilian"],
                state: Post(title: "President", person: "Luiz Inácio Lula da Silva"), government: nil),
        Country(name: "Argentina", short: "Argentina", wikidata: "Q414", names: ["argentina"], people: ["argentine", "argentinian"],
                state: Post(title: "President", person: "Javier Milei"), government: nil),
        Country(name: "Chile", short: "Chile", wikidata: "Q298", names: ["chile"], people: ["chilean"],
                state: Post(title: "President", person: "José Antonio Kast"), government: nil),
    ]

    /// A name that's part of a longer, different place ("northern ireland", "north korea", "new mexico").
    private static let notAfter: [String: [String]] = [
        "ireland": ["northern", "north"], "korea": ["north"], "mexico": ["new"], "england": ["new"],
        "america": ["south", "central", "latin", "north"], "guinea": ["new", "papua"],
    ]

    /// Lowercase, tidy text that place names are matched in.
    static func tidy(_ text: String) -> String {
        TextKit.canonical(TextKit.normalize(text))
    }

    /// True when the place's name (or its people's name) is in the text.
    static func mentions(_ country: Country, in text: String) -> Bool {
        let t = tidy(text)
        return (country.names + country.people).contains { found($0, in: t) }
    }

    /// Every country named in the text.
    static func countries(in text: String) -> [Country] {
        let t = tidy(text)
        return countries.filter { c in c.names.contains { found($0, in: t) } }
    }

    /// The one country this whole phrase names ("the uk", "britain"), or nil.
    static func country(named phrase: String) -> Country? {
        var p = tidy(phrase)
        for lead in ["the ", "country of ", "nation of "] where p.hasPrefix(lead) { p = String(p.dropFirst(lead.count)) }
        if p.hasSuffix("'s") { p = String(p.dropLast(2)) }
        p = p.trimmingCharacters(in: .whitespaces)
        guard !p.isEmpty else { return nil }
        return countries.first { c in c.names.contains(p) || c.names.contains(tidy(p)) }
    }

    private static func found(_ name: String, in text: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        guard let re = try? NSRegularExpression(pattern: #"(?<![\p{L}\p{N}])"# + escaped + #"(?![\p{L}\p{N}])"#) else { return false }
        let range = NSRange(text.startIndex..., in: text)
        for m in re.matches(in: text, range: range) {
            guard let r = Range(m.range, in: text) else { continue }
            let before = text[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
            let lastWord = before.split(separator: " ").last.map(String.init) ?? ""
            if let blocked = notAfter[name], blocked.contains(lastWord) { continue }
            return true
        }
        return false
    }

    // MARK: Reading the question

    /// What job the question asks about.
    enum Role: Equatable {
        case president, primeMinister, chancellor
        /// "king", "queen", "monarch", "emperor"...: the word you used.
        case monarch(String)
        /// "leader", "ruler", "who runs": both top jobs.
        case leader
        case headOfState, headOfGovernment
    }

    struct Ask: Equatable {
        var role: Role
        /// The country's Wikidata id (countries are matched by it).
        var country: String
        /// "does the UK have a president" (a yes or no question).
        var yesNo: Bool = false
    }

    private static let roleWords = #"president|prime minister|pm|premier|chancellor|king|queen|monarch|emperor|empress|leader|ruler|head of state|head of the state|head of government|head of the government|taoiseach"#
    private static let lead = #"(?:the |a |an )?(?:current |present |new |sitting |actual |real |reigning )?"#
    private static let when = #"(?: (?:right now|now|currently|today|at the moment|these days|this year|in 2026|in 2027))?"#

    static func role(_ word: String) -> Role? {
        switch word {
        case "president": return .president
        case "prime minister", "pm", "premier", "taoiseach": return .primeMinister
        case "chancellor": return .chancellor
        case "king", "queen", "monarch", "emperor", "empress": return .monarch(word)
        case "leader", "ruler": return .leader
        case "head of state", "head of the state": return .headOfState
        case "head of government", "head of the government": return .headOfGovernment
        default: return nil
        }
    }

    /// Reads "who is the president of the UK", "who leads canada", "uk prime minister",
    /// "does the UK have a president". nil when it isn't a question about a country's leader.
    static func parse(_ raw: String) -> Ask? {
        var t = TextKit.normalize(raw)
        guard !t.isEmpty else { return nil }
        t = t.replacingOccurrences(of: #"\s+(please|ace)$"#, with: "", options: .regularExpression)
        let r = roleWords
        // Each pattern says which group is the job and which is the place (-1 means "leader").
        let patterns: [(pattern: String, role: Int, place: Int)] = [
            // "who is the current president of the uk", "who's the king of england right now"
            (#"^(?:who|what) (?:is|are|was) "# + lead + "(" + r + #") (?:of|in|for) (.+?)"# + when + "$", 0, 1),
            // "who is the uk's prime minister", "who is britain's king"
            (#"^(?:who|what) is (?:the )?(?:current )?(.+?)'s "# + lead + "(" + r + ")" + when + "$", 1, 0),
            // "who leads canada", "who is in charge of the uk"
            (#"^who (?:leads|runs|rules|governs|is in charge of|is leading|is running|is ruling|is the boss of|controls) (.+?)"# + when + "$", -1, 0),
            // "tell me who the prime minister of japan is"
            (#"^(?:tell me |do you know )?who (?:the )?(?:current )?("# + r + #") (?:of|in) (.+?) is"# + when + "$", 0, 1),
            // "uk prime minister", "current uk prime minister"
            (#"^"# + lead + #"(.+?) ("# + r + ")" + when + "$", 1, 0),
            // "prime minister of the uk"
            (#"^"# + lead + "(" + r + #") (?:of|in) (.+?)"# + when + "$", 0, 1),
        ]
        for p in patterns {
            guard let g = Rx.groups(p.pattern, t), p.place < g.count, p.role < g.count else { continue }
            guard let role = p.role < 0 ? Role.leader : role(g[p.role]),
                  let c = country(named: g[p.place]) else { continue }
            return Ask(role: role, country: c.wikidata)
        }
        // "does the uk have a president", "is there a king of the usa"
        if let g = Rx.groups(#"^(?:does|do|did) (.+?) (?:have|has|still have) (?:a |an |any )?("# + r + #")s?"# + when + "$", t),
           let role = role(g[1]), let c = country(named: g[0]) {
            return Ask(role: role, country: c.wikidata, yesNo: true)
        }
        if let g = Rx.groups(#"^(?:is there|are there) (?:a |an |any )?("# + r + #")s? (?:of|in) (.+?)"# + when + "$", t),
           let role = role(g[0]), let c = country(named: g[1]) {
            return Ask(role: role, country: c.wikidata, yesNo: true)
        }
        return nil
    }

    static func country(id: String) -> Country? { countries.first { $0.wikidata == id } }

    // MARK: Answering

    /// The answer. `fresh` holds names looked up on the web just now (nil when Ace couldn't look),
    /// and without them the answer says how old Ace's built-in names are.
    static func answer(_ ask: Ask, fresh: (state: String?, government: String?)?) -> String {
        guard var c = country(id: ask.country) else { return "" }
        if let f = fresh {
            if let s = f.state, !s.isEmpty { c.state.person = s }
            if let g = f.government, !g.isEmpty { c.government?.person = g }
        }
        let place = c.short
        let Place = TextKit.capitalizeFirst(place)
        var text: String
        switch match(ask.role, c) {
        case .state:
            text = ask.yesNo
                ? "Yes. " + titled(c.state) + " is " + possessive(place) + " " + c.state.title.lowercased() + "."
                : holder(c.state, place: place)
            if c.government == nil, c.state.title == "President", ask.role == .president, !ask.yesNo {
                text += " The president leads both the country and the government."
            }
        case .government:
            let g = c.government ?? c.state
            text = ask.yesNo
                ? "Yes. " + titled(g) + " is " + possessive(place) + " " + g.title.lowercased() + "."
                : holder(g, place: place)
            if g.title == "Taoiseach", ask.role == .primeMinister { text += " Ireland calls its prime minister the Taoiseach." }
            if g.title == "Premier", ask.role == .primeMinister { text += " China calls its prime minister the premier." }
        case .both:
            text = TextKit.capitalizeFirst(leadership(c, place: place))
        case .otherMonarch(let word):
            // "queen of the uk" when the UK has a king, "king of japan" when Japan has an emperor.
            text = Place + " has " + article(c.state.title.lowercased()) + " right now, not " + article(word) + ". "
                + "It's " + titled(c.state) + "."
        case .wrong(let word):
            text = (ask.yesNo ? "No. " : "") + Place + " doesn't have " + article(word) + ". " + TextKit.capitalizeFirst(leadership(c, place: place))
        }
        // Built-in names can go out of date, so say how old they are.
        let names = [c.state.person, c.government?.person].compactMap { $0 }
        if fresh == nil, names.contains(where: { text.contains($0) }) {
            text += " That's from my built-in facts from \(checked), so it may have changed."
        }
        return text
    }

    /// "The prime minister of the UK is Keir Starmer.", or that Ace doesn't have the name.
    private static func holder(_ p: Post, place: String) -> String {
        let job = p.title.lowercased()
        guard let person = p.person else {
            return TextKit.capitalizeFirst(place) + " has " + article(job) + ", but I don't have their name right now."
        }
        return "The " + job + " of " + place + " is " + person + "."
    }

    private enum Match: Equatable { case state, government, both, otherMonarch(String), wrong(String) }

    private static let monarchTitles: Set<String> = ["King", "Queen", "Emperor", "Empress"]

    private static func match(_ role: Role, _ c: Country) -> Match {
        let gov = c.government?.title
        switch role {
        case .president:
            if c.state.title == "President" { return .state }
            return .wrong("president")
        case .primeMinister:
            if let gov, ["Prime Minister", "Taoiseach", "Premier"].contains(gov) { return .government }
            return .wrong("prime minister")
        case .chancellor:
            if gov == "Chancellor" { return .government }
            return .wrong("chancellor")
        case .monarch(let word):
            guard monarchTitles.contains(c.state.title) else { return .wrong(word == "monarch" ? "king or queen" : word) }
            if word == "monarch" || word == c.state.title.lowercased() { return .state }
            return .otherMonarch(word)
        case .leader:
            return c.government == nil ? .state : .both
        case .headOfState:
            return .state
        case .headOfGovernment:
            return .government
        }
    }

    /// "Its head of state is King Charles III, and its government is led by Prime Minister Keir Starmer."
    static func leadership(_ c: Country, place: String) -> String {
        guard let g = c.government else {
            return possessive(place) + " president, " + (c.state.person ?? "whose name I don't have right now")
                + ", leads both the country and the government."
        }
        return possessive(place) + " head of state is " + titled(c.state)
            + ", and its government is led by " + titled(g) + "."
    }

    /// "King Charles III", or "a prime minister" when Ace doesn't have the name.
    static func titled(_ p: Post) -> String {
        guard let person = p.person else { return unknown(p) }
        return p.title + " " + person
    }

    private static func unknown(_ p: Post) -> String {
        article(p.title.lowercased()) + " (I don't have their name right now)"
    }

    static func possessive(_ place: String) -> String {
        place.hasSuffix("s") ? place + "'" : place + "'s"
    }

    static func article(_ word: String) -> String {
        guard let first = word.first else { return word }
        return ("aeiou".contains(first) ? "an " : "a ") + word
    }

    /// Questions about what's true right now ("current", "now", "latest"), which need fresh facts
    /// and shouldn't be saved as a lasting answer.
    static func isTimeSensitive(_ text: String) -> Bool {
        let t = TextKit.normalize(text)
        if parse(text) != nil { return true }
        return Rx.matches(#"\b(current|currently|right now|now|today|tonight|latest|newest|this (week|month|year)|at the moment|these days|still|so far|live|score|price|weather|news)\b"#, t)
    }
}
