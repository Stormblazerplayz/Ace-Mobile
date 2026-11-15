import Foundation

/// Ace's own recipe book (Resources/recipes.json). Works with no internet.
enum RecipeBook {
    struct Entry: Decodable {
        let id: String
        let name: String
        let aliases: [String]
        let category: String
        let servings: Int
        let time: String
        let main: [String]
        let ingredients: [String]
        let steps: [String]

        var card: RecipeCard {
            RecipeCard(name: name, category: category, area: nil, imageURL: nil,
                       ingredients: ingredients, steps: steps, sourceURL: nil,
                       servings: servings, time: time, builtIn: true)
        }
    }

    private struct File: Decodable { let recipes: [Entry] }

    static let all: [Entry] = {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.recipes
    }()

    /// Words that don't help find a dish.
    private static let filler: Set<String> = [
        "a", "an", "the", "some", "my", "for", "of", "to", "how", "make", "making", "cook", "cooking", "bake", "baking",
        "recipe", "recipes", "homemade", "home", "made", "easy", "simple", "best", "good", "quick", "classic", "yummy",
        "delicious", "healthy", "kids", "kid", "please", "me", "i", "you", "can", "do", "want", "with",
        "dinner", "lunch", "breakfast", "dessert", "snack", "food", "something", "meal", "tonight", "today",
    ]

    /// Quick versions of a dish. "chocolate cake" is the full cake; "quick chocolate cake" or
    /// "mug cake" is the 5-minute one.
    static let quickVersions: [String: String] = ["chocolate-cake": "chocolate-mug-cake"]

    /// Words that ask for the fast, small version of a dish.
    private static let quickPattern = #"\b(mug|quick|quickly|fast|single|single serve|single serving|microwave|microwaved|5 minute|five minute|5 min|for one|one person|individual)\b"#

    /// True when the words ask for a quick or single-serve version ("quick chocolate cake", "mug cake").
    static func wantsQuick(_ dish: String) -> Bool {
        Rx.matches(quickPattern, TextKit.normalize(dish).replacingOccurrences(of: "-", with: " "))
    }

    /// The quick version of a recipe, if Ace has one.
    static func quickVersion(of e: Entry) -> Entry? {
        guard let id = quickVersions[e.id] else { return nil }
        return all.first { $0.id == id }
    }

    /// The line Ace adds under a full recipe when there's a quick version ("Want a quick 5-minute mug version instead?").
    static func quickOffer(for e: Entry) -> String? {
        guard let q = quickVersion(of: e) else { return nil }
        let minutes = Int(q.time.split(separator: " ").first ?? "") ?? 0
        let kind = q.id.contains("mug") ? "mug" : "quick"
        let size = minutes > 0 ? "\(minutes)-minute " : ""
        return "Want a quick \(size)\(kind) version instead?"
    }

    /// True when a recipe is the quick version of another one (the mug cake).
    static func isQuickVersion(_ e: Entry) -> Bool {
        quickVersions.values.contains(e.id)
    }

    /// Finds a recipe by name ("pancakes", "choc chip cookies", "spaghetti bolognese").
    /// The plain dish wins over its quick version unless you ask for quick, mug or microwave.
    static func find(_ dish: String) -> Entry? {
        let t = TextKit.normalize(dish)
        guard !t.isEmpty else { return nil }
        guard let e = match(t) else {
            // "microwave chocolate cake": no name has every word, so drop the quick words and use the quick version.
            guard wantsQuick(t) else { return nil }
            let plain = t.replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: quickPattern, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"\b(version|serve|serving|size|sized|minute|minutes|min)\b"#, with: " ", options: .regularExpression)
            let cleaned = plain.split(separator: " ").joined(separator: " ")
            guard !cleaned.isEmpty, cleaned != t, let base = match(cleaned) else { return nil }
            return quickVersion(of: base) ?? base
        }
        // "quick chocolate cake": the words found the full cake, but you want the fast one.
        if wantsQuick(t), let q = quickVersion(of: e) { return q }
        return e
    }

    private static func match(_ t: String) -> Entry? {
        // Exact name or alias first.
        if let e = all.first(where: { $0.name.lowercased() == t || $0.aliases.contains(t) }) { return e }
        let words = t.split(separator: " ").map { singular(String($0)) }.filter { !filler.contains($0) }
        guard !words.isEmpty else { return nil }
        let wanted = words.joined(separator: " ")
        if let e = all.first(where: { $0.aliases.contains(wanted) || $0.aliases.map(singularPhrase).contains(wanted) }) { return e }
        // Every word you typed is in the name or an alias ("chocolate cookies" -> chocolate chip cookies).
        // Small typos are fine in long words ("spagetti"), but not short ones ("friends" isn't "fried").
        // The recipe's own name beats an alias, and fewer extra words is better.
        var best: (Entry, Double)?
        for e in all {
            let names = ([e.name.lowercased()] + e.aliases).map(singularPhrase)
            for (i, n) in names.enumerated() {
                let nameWords = Set(n.split(separator: " ").map(String.init))
                let hits = words.filter { w in nameWords.contains(w) || (w.count >= 7 && nameWords.contains { HomeService.distance($0, w) <= 1 }) }.count
                guard hits == words.count else { continue }
                // A quick version only wins when nothing plainer fits.
                let score = Double(nameWords.count - hits) + (i == 0 ? 0 : 1.5) + (isQuickVersion(e) ? 3 : 0)
                if best == nil || score < best!.1 { best = (e, score) }
            }
        }
        return best?.0
    }

    /// True when Ace has a recipe with that name (used so "how do I make pancakes" is a recipe
    /// but "how do I make a crafting table" isn't).
    static func knows(_ dish: String) -> Bool { find(dish) != nil }

    /// Recipes you can make with what you have ("eggs, cheese and bread"), best first.
    static func ideas(with items: [String], limit: Int = 3) -> [(entry: Entry, uses: [String])] {
        let have = items.map { singularPhrase(TextKit.normalize($0)) }.filter { !$0.isEmpty }
        guard !have.isEmpty else { return [] }
        var scored: [(Entry, [String], Double)] = []
        for e in all {
            let main = e.main.map(singularPhrase)
            let text = e.ingredients.joined(separator: " ").lowercased()
            var uses: [String] = []
            for h in have where main.contains(where: { $0 == h || $0.contains(h) || h.contains($0) }) || text.contains(h) {
                uses.append(h)
            }
            guard !uses.isEmpty else { continue }
            let mainHits = Double(have.filter { h in main.contains { $0 == h || $0.contains(h) || h.contains($0) } }.count)
            // More of your things used, and fewer other main things needed, is better.
            let score = Double(uses.count) * 2 + mainHits - Double(max(0, main.count - Int(mainHits))) * 0.4
            scored.append((e, uses, score))
        }
        return scored.sorted { $0.2 != $1.2 ? $0.2 > $1.2 : $0.0.name < $1.0.name }.prefix(limit).map { ($0.0, $0.1) }
    }

    /// Splits "eggs, cheese and bread" into ["eggs", "cheese", "bread"].
    static func splitItems(_ text: String) -> [String] {
        // Commas are kept as " and " first, because normalizing drops them.
        let pieces = TextKit.normalize(text.replacingOccurrences(of: ",", with: " and "))
            .replacingOccurrences(of: " and ", with: ",")
            .replacingOccurrences(of: " or ", with: ",")
            .replacingOccurrences(of: " plus ", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { $0.replacingOccurrences(of: #"^(some|a|an|the|my|leftover|fresh|frozen)\s+"#, with: "", options: .regularExpression) }
            .filter { !$0.isEmpty && !["stuff", "things", "that", "it"].contains($0) }
        // Spoken lists often have no commas ("eggs cheese bread"). A piece no recipe knows
        // as one ingredient ("peanut butter" is one, "eggs cheese" isn't) is split into words.
        return pieces.flatMap { piece -> [String] in
            let words = piece.split(separator: " ").map(String.init)
            guard words.count > 1, !knownIngredient(piece) else { return [piece] }
            return words.filter { !filler.contains($0) }
        }
    }

    private static let ingredientText: String = all.flatMap { $0.ingredients + $0.main }.joined(separator: " | ").lowercased()

    private static func knownIngredient(_ phrase: String) -> Bool {
        ingredientText.contains(phrase) || ingredientText.contains(singularPhrase(phrase))
    }

    /// A random idea for a meal ("what should I make for dinner").
    static func suggestion(for meal: String?) -> Entry? {
        let m = (meal ?? "").lowercased()
        let pool: [Entry]
        if m.contains("breakfast") { pool = all.filter { $0.category == "Breakfast" } }
        else if m.contains("dessert") || m.contains("bake") || m.contains("sweet") || m.contains("snack") {
            pool = all.filter { ["Dessert", "Baking", "Snack", "Drink"].contains($0.category) }
        }
        else if m.contains("lunch") { pool = all.filter { ["Lunch", "Snack"].contains($0.category) } }
        else { pool = all.filter { $0.category == "Dinner" } }
        return (pool.isEmpty ? all : pool).randomElement()
    }

    static func singular(_ w: String) -> String {
        switch w {
        case "tomatoes": return "tomato"
        case "potatoes": return "potato"
        case "cookies": return "cookie"
        case "brownies": return "brownie"
        case "noodles": return "noodle"
        case "leaves": return "leaf"
        case "berries": return "berry"
        case "cherries": return "cherry"
        case "loaves": return "loaf"
        case "knives": return "knife"
        case "dishes": return "dish"
        case "sandwiches": return "sandwich"
        case "peaches": return "peach"
        case "radishes": return "radish"
        case "oats", "hummus", "nachos", "chips", "grits", "molasses", "asparagus", "couscous", "swiss", "fries": return w
        default:
            if w.hasSuffix("ies"), w.count > 4 { return String(w.dropLast(3)) + "y" }
            if w.hasSuffix("s"), !w.hasSuffix("ss"), !w.hasSuffix("us"), w.count > 3 { return String(w.dropLast()) }
            return w
        }
    }

    static func singularPhrase(_ p: String) -> String {
        p.split(separator: " ").map { singular(String($0)) }.joined(separator: " ")
    }
}

/// Reads how long a recipe step waits ("Bake for 25 to 30 minutes", "Chill overnight")
/// so the step can get a timer button. Pure text rules, so they're tested.
enum StepTimer {
    struct Found: Equatable {
        var seconds: Int
        /// What the timer is for ("baking", "cooling"...).
        var activity: String
    }

    private static let units = #"(seconds?|secs?|minutes?|mins?|hours?|hrs?|h)"#
    private static let number = #"\b(\d+(?:\.\d+)?(?:\s+\d/\d)?|\d/\d|an?|one|two|three|four|five|six|seven|eight|nine|ten|twelve|fifteen|twenty|thirty|forty|forty-five|forty five|sixty|ninety|half an?|a half)"#

    /// Steps that only say "until golden" or "until done" have no set time, so no timer.
    static func find(in step: String) -> Found? {
        let t = step.lowercased()
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "½", with: " 1/2")
        let activity = Self.activity(t)
        if Rx.matches(#"\b(overnight)\b"#, t) { return Found(seconds: 8 * 3600, activity: activity) }

        var best = 0
        // "1 hour 15 minutes", "1 hour and 15 minutes", "1 hr 15 min"
        if let g = Rx.groups(number + #"\s*(?:hours?|hrs?|h)\b\s*(?:and\s+)?"# + number + #"\s*(?:minutes?|mins?)\b"#, t),
           let h = value(g[0]), let m = value(g[1]) {
            best = max(best, Int((h * 3600 + m * 60).rounded()))
        }
        // "25 to 30 minutes", "25-30 minutes", "25 or 30 minutes" (use the longer one)
        if best == 0, let g = Rx.groups(number + #"\s*(?:to|-|or)\s*"# + number + #"\s*"# + units + #"\b"#, t),
           let b = value(g[1]) {
            best = Int((b * seconds(per: g[2])).rounded())
        }
        // "20 minutes", "an hour", "1 1/2 hours", "half an hour"
        if best == 0 {
            for g in Rx.allGroups(number + #"\s*"# + units + #"\b"#, t) {
                if let v = value(g[0]) { best = max(best, Int((v * seconds(per: g[1])).rounded())) }
            }
        }
        if best == 0, Rx.matches(#"\bhalf an hour\b"#, t) { best = 1800 }
        guard best >= 10, best <= 48 * 3600 else { return nil }
        return Found(seconds: best, activity: activity)
    }

    /// "baking", "cooling", "chilling"...
    static func activity(_ t: String) -> String {
        let pairs: [(String, String)] = [
            (#"\b(bake|baking)\b"#, "baking"), (#"\b(roast|roasting)\b"#, "roasting"),
            (#"\b(cool|cooling)\b"#, "cooling"), (#"\b(chill|chilling|refrigerate|fridge)\b"#, "chilling"),
            (#"\b(freeze|freezer)\b"#, "freezing"), (#"\b(rest|resting|sit|stand)\b"#, "resting"),
            (#"\b(rise|rising|proof|double)\b"#, "rising"), (#"\b(simmer|simmering)\b"#, "simmering"),
            (#"\b(boil|boiling)\b"#, "boiling"), (#"\b(marinate|marinating|soak)\b"#, "marinating"),
            (#"\b(microwave)\b"#, "in the microwave"), (#"\b(fry|frying|saute|sear|brown)\b"#, "cooking"),
            (#"\b(steep|brew)\b"#, "steeping"), (#"\b(grill|grilling|broil)\b"#, "grilling"),
            (#"\b(blend|whisk|beat|mix|knead|stir)\b"#, "mixing"),
        ]
        for (p, word) in pairs where Rx.matches(p, t) { return word }
        return "cooking"
    }

    /// A timer label like "Cookies baking" from the recipe name and the step.
    static func label(recipe: String, activity: String) -> String {
        var name = recipe
        for drop in ["Fluffy ", "Easy ", "Classic ", "Homemade ", "Simple ", "Best "] where name.hasPrefix(drop) {
            name = String(name.dropFirst(drop.count))
        }
        return TextKit.capitalizeFirst("\(name.lowercased()) \(activity)")
    }

    private static func seconds(per unit: String) -> Double {
        if unit.hasPrefix("h") { return 3600 }
        if unit.hasPrefix("m") { return 60 }
        return 1
    }

    private static func value(_ s: String) -> Double? {
        let w = s.trimmingCharacters(in: .whitespaces)
        let words: [String: Double] = [
            "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
            "nine": 9, "ten": 10, "twelve": 12, "fifteen": 15, "twenty": 20, "thirty": 30, "forty": 40,
            "forty-five": 45, "forty five": 45, "sixty": 60, "ninety": 90, "half a": 0.5, "half an": 0.5, "a half": 0.5,
        ]
        if let v = words[w] { return v }
        let parts = w.split(separator: " ")
        var total = 0.0
        for p in parts {
            if p.contains("/") {
                let f = p.split(separator: "/")
                guard f.count == 2, let a = Double(f[0]), let b = Double(f[1]), b != 0 else { return nil }
                total += a / b
            } else if let v = Double(p) {
                total += v
            } else {
                return nil
            }
        }
        return total
    }
}
