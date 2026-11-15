import Foundation

/// Your favorite things, read from what Ace remembers ("my favorite food is pizza").
/// They live in Memory like any other fact, so you can see and swipe them away there.
/// Ace brings one up now and then where it fits, but never too often.
enum Favorites {
    struct Item: Equatable {
        /// "food", "color", "animal"
        var thing: String
        /// "pizza", "blue", "foxes"
        var value: String
    }

    /// Reads "my favorite food is pizza", "my favourite colour is blue" or "pizza is my favorite food".
    static func read(_ fact: String) -> Item? {
        // Keep the capitals ("Minecraft"), so only tidy the spaces and quotes.
        let t = fact.replacingOccurrences(of: "’", with: "'")
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        let fav = #"(?:favorite|favourite|fav|most favorite|very favorite)"#
        if let g = Rx.groups(#"^(?:remember (?:that )?)?my "# + fav + #" ([a-z][a-z \-]{0,30}?) (?:is|are) (?:a |an |the )?(.+)$"#, t) {
            return clean(Item(thing: g[0], value: g[1]))
        }
        if let g = Rx.groups(#"^(?:remember (?:that )?)?(?:a |an |the )?(.+?) (?:is|are) my "# + fav + #" ([a-z][a-z \-]{0,30})$"#, t) {
            return clean(Item(thing: g[1], value: g[0]))
        }
        return nil
    }

    private static func clean(_ i: Item) -> Item? {
        let thing = i.thing.lowercased().replacingOccurrences(of: "colour", with: "color").trimmingCharacters(in: .whitespaces)
        let value = i.value.trimmingCharacters(in: CharacterSet(charactersIn: " .!"))
        guard !thing.isEmpty, !value.isEmpty, value.count <= 40 else { return nil }
        return Item(thing: thing, value: value)
    }

    /// Every favorite in the facts, newest last.
    static func all(_ facts: [String]) -> [Item] {
        facts.compactMap(read)
    }

    // MARK: Food

    private static let foodThings: Set<String> = ["food", "meal", "dish", "dinner", "lunch", "breakfast", "dessert",
                                                  "snack", "treat", "sweet", "cake", "cookie", "drink", "pizza"]

    static func isFood(_ i: Item) -> Bool {
        TextKit.keywords(i.thing).contains { foodThings.contains($0) }
    }

    /// A recipe from Ace's recipe book for one of your favorite foods that fits the meal
    /// ("dinner", "dessert", or "" for any). nil when none fits.
    static func recipe(for meal: String, items: [Item]) -> RecipeBook.Entry? {
        let m = meal.lowercased()
        for i in items.reversed() where isFood(i) {
            guard let e = RecipeBook.find(i.value) else { continue }
            if m.isEmpty { return e }
            let category = e.category.lowercased()
            if m.contains(category) || (m.contains("dessert") && ["dessert", "baking"].contains(category))
                || (m.contains("snack") && ["snack", "dessert"].contains(category)) {
                return e
            }
        }
        return nil
    }

    // MARK: Bringing one up

    /// The favorite a question or answer touches, if any: its value ("tell me about foxes")
    /// or its kind of thing ("what are the primary colors" touches your favorite color).
    static func touched(by text: String, items: [Item]) -> (item: Item, valueSaid: Bool)? {
        let words = Set(TextKit.keywords(text))
        guard !words.isEmpty else { return nil }
        for i in items.reversed() {
            let value = TextKit.keywords(i.value)
            if !value.isEmpty, value.allSatisfy(words.contains) { return (i, true) }
        }
        for i in items.reversed() {
            let thing = TextKit.keywords(i.thing)
            if !thing.isEmpty, thing.allSatisfy(words.contains) { return (i, false) }
        }
        return nil
    }

    /// One short line about a favorite. `valueSaid` is true when the question named the favorite itself.
    static func aside(_ i: Item, valueSaid: Bool) -> String {
        valueSaid
            ? "That's your favorite \(i.thing), too!"
            : "Your favorite \(i.thing) is \(i.value), by the way."
    }

    /// At most one mention every 6 hours, and the same favorite at most once in 3 days, so it never gets old.
    static func mayMention(now: Date, lastAny: Date?, lastThis: Date?) -> Bool {
        if let lastAny, now.timeIntervalSince(lastAny) < 6 * 3600 { return false }
        if let lastThis, now.timeIntervalSince(lastThis) < 3 * 24 * 3600 { return false }
        return true
    }

    private static let defaults = UserDefaults.standard

    /// Checks the pacing and, when a mention is fine, notes it. Returns true when Ace may mention it.
    static func takeTurn(_ i: Item, now: Date = Date()) -> Bool {
        let key = "favoriteMentioned." + i.thing
        let lastAny = defaults.object(forKey: "favoriteMentioned.any") as? Date
        let lastThis = defaults.object(forKey: key) as? Date
        guard mayMention(now: now, lastAny: lastAny, lastThis: lastThis) else { return false }
        defaults.set(now, forKey: "favoriteMentioned.any")
        defaults.set(now, forKey: key)
        return true
    }

    /// A line for the hello when the app opens, for favorites that make sense there.
    static func greetingLine(_ i: Item) -> String? {
        let thing = TextKit.keywords(i.thing)
        if isFood(i) { return "Maybe some \(i.value) later?" }
        if thing.contains("game") { return "Up for some \(i.value) today?" }
        if thing.contains("song") || thing.contains("music") || thing.contains("band") { return "Got \(i.value) playing yet?" }
        if thing.contains("sport") { return "Any \(i.value) today?" }
        return nil
    }
}

/// The hello when the app opens.
enum Greeter {
    /// Ace doesn't greet again if the app comes back within this many minutes.
    static let quietMinutes: Double = 5

    /// Greets when the app starts, or comes back after being away for 5 minutes or more,
    /// but never twice within 5 minutes. `awaySince` is when the app went to the background.
    static func shouldGreet(now: Date, lastGreeting: Date?, awaySince: Date?, firstOpen: Bool) -> Bool {
        let quiet = quietMinutes * 60
        if let last = lastGreeting, now >= last, now.timeIntervalSince(last) < quiet { return false }
        if firstOpen { return true }
        guard let away = awaySince else { return false }
        return now.timeIntervalSince(away) >= quiet
    }

    /// "Good morning", "Good afternoon" or "Good evening".
    static func partOfDay(hour: Int) -> String {
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Different ways to say hello, so it isn't the same line every time.
    static func lines(hour: Int, name: String) -> [String] {
        let part = partOfDay(hour: hour)
        let n = name.trimmingCharacters(in: .whitespaces)
        let who = n.isEmpty ? "" : ", \(n)"
        let whoHey = n.isEmpty ? " there" : " \(n)"
        let late = hour >= 22 || hour < 5
        var out = [
            "\(part)\(who)!",
            "\(part)\(who)! Good to see you.",
            "\(part)\(who)! What are we up to?",
            "Hey\(whoHey)! \(part).",
            "Welcome back\(who)! \(part).",
            "\(part)\(who)! I'm ready when you are.",
            "Hi\(whoHey)! \(part). What's first?",
            "\(part)\(who)! Nice to have you back.",
            "\(part)\(who)! Ask me anything.",
            "There you are\(who)! \(part).",
        ]
        if late {
            out += ["Still up\(who)? \(part).", "\(part)\(who)! Burning the midnight oil?"]
        } else if hour < 12 {
            out += ["Morning\(who)! Ready for the day?"]
        }
        return out
    }
}
