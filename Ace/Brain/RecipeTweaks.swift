import Foundation

/// Changes the last recipe: "for 8 people", "double it", "make it spicier", "make it vegetarian"...
enum RecipeTweaks {
    enum Change: Equatable {
        /// "for 8 people"
        case people(Int)
        /// "double it" (2), "halve it" (0.5)
        case scale(Double)
        /// "spicier", "healthier", "vegetarian", "vegan", "gluten free", "dairy free", "sweeter", "less sweet", "cheesier", "milder"
        case style(String)
    }

    struct Result {
        var card: RecipeCard
        /// What changed, said simply ("chickpeas or tofu instead of the chicken").
        var changes: [String]
        /// The recipe didn't say how many it serves, so Ace guessed 4.
        var guessedServings = false
    }

    // MARK: Understanding the ask

    private static let lead = #"^(?:(?:can you|could you|please|now|ok|okay|and|so|then|hey ace|ace) )*"#
    private static let it = #"(?:it|that|this|them|the recipe|this recipe|that recipe|the dish|the ingredients)"#
    private static let people = #"(?:people|persons|servings|kids|friends|guests|of us|portions)"#

    /// What a message asks for, or nil when it isn't a change to a recipe.
    static func parse(_ text: String) -> Change? {
        let t = TextKit.normalize(text).replacingOccurrences(of: "-", with: " ")
        // "make it for 8 people", "scale it to 6 servings"
        if let g = Rx.groups(lead + #"(?:make|change|scale|turn|do|redo|cook|resize|adjust) "# + it + #" (?:for|to feed|to serve|so it serves|serving) ([a-z0-9]+)(?: "# + people + #")?(?: please| instead)?$"#, t),
           let n = number(g[0]), (1...100).contains(n) {
            return .people(n)
        }
        // "scale it to 6 servings" ("turn it to 50" isn't about recipes, so the people word is needed here)
        if let g = Rx.groups(lead + #"(?:make|change|scale|resize|adjust) "# + it + #" (?:up |down )?to ([a-z0-9]+) "# + people + #"(?: please| instead)?$"#, t),
           let n = number(g[0]), (1...100).contains(n) {
            return .people(n)
        }
        // "what about for 8 people", "i need to feed 10 people", "for 6 servings"
        if let g = Rx.groups(lead + #"(?:what about |how about )?(?:for|to feed|to serve|i need to feed|i am feeding|i want to feed|make enough for|enough for|it needs to serve|it needs to feed) ([a-z0-9]+) "# + people + #"(?: instead| now| please)?$"#, t),
           let n = number(g[0]), (1...100).contains(n) {
            return .people(n)
        }
        // "double it", "triple the recipe", "halve it", "cut it in half", "make twice as much"
        if let g = Rx.groups(lead + #"(double|triple|quadruple|halve|half) "# + it + #"(?: please)?$"#, t) {
            return .scale(["double": 2, "triple": 3, "quadruple": 4, "halve": 0.5, "half": 0.5][g[0]] ?? 2)
        }
        if Rx.matches(lead + #"(?:cut|make) "# + it + #" (?:in|by) half(?: please)?$"#, t) { return .scale(0.5) }
        if let g = Rx.groups(lead + #"(?:make|cook) (twice|double|three times|half) as much(?: please)?$"#, t) {
            return .scale(["twice": 2, "double": 2, "three times": 3, "half": 0.5][g[0]] ?? 2)
        }
        // "make it spicier", "make it more spicy", "can you make it vegetarian"
        let styles = #"(spicier|spicy|healthier|healthy|vegetarian|veggie|meatless|vegan|gluten free|dairy free|sweeter|sweet|less sweet|less sugary|cheesier|cheesy|milder|mild|less spicy|kid friendly|not spicy)"#
        if let g = Rx.groups(lead + #"(?:make|change|turn|do) "# + it + #" (?:a (?:bit|little|lot) |even |more |extra |way |super )?"# + styles + #"(?: please| instead| too)?$"#, t),
           let s = style(g[0]) {
            return .style(s)
        }
        // "a vegetarian version", "is there a vegan version", "what about a spicy one"
        if let g = Rx.groups(lead + #"(?:make|give me|show me|what about|how about|is there|can i have|can you make|i want|i need|make me) (?:a |an )?(?:more )?"# + styles + #" (?:version|one|kind|way)(?: of (?:it|that|this))?(?: please)?$"#, t),
           let s = style(g[0]) {
            return .style(s)
        }
        // "without meat", "no dairy", "no gluten"
        if let g = Rx.groups(lead + #"(?:make (?:it|that|this) |can i make (?:it|that|this) |what about |how about )?(?:without|with no|no) (meat|dairy|milk|gluten|eggs|animal stuff|animal products|sugar|spice|spices)(?: please)?$"#, t) {
            switch g[0] {
            case "meat": return .style("vegetarian")
            case "dairy", "milk": return .style("dairy free")
            case "gluten": return .style("gluten free")
            case "eggs", "animal stuff", "animal products": return .style("vegan")
            case "sugar": return .style("less sweet")
            default: return .style("milder")
            }
        }
        return nil
    }

    private static func style(_ word: String) -> String? {
        switch word {
        case "spicier", "spicy": return "spicier"
        case "healthier", "healthy": return "healthier"
        case "vegetarian", "veggie", "meatless": return "vegetarian"
        case "vegan": return "vegan"
        case "gluten free": return "gluten free"
        case "dairy free": return "dairy free"
        case "sweeter", "sweet": return "sweeter"
        case "less sweet", "less sugary": return "less sweet"
        case "cheesier", "cheesy": return "cheesier"
        case "milder", "mild", "less spicy", "kid friendly", "not spicy": return "milder"
        default: return nil
        }
    }

    static func number(_ s: String) -> Int? {
        if let n = Int(s) { return n }
        let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
                     "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
                     "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "dozen": 12]
        return words[s]
    }

    // MARK: Changing the recipe

    static func apply(_ change: Change, to card: RecipeCard) -> Result {
        switch change {
        case .people(let n):
            let base = card.servings ?? 4
            var r = Result(card: scaled(card, by: Double(n) / Double(base)), changes: [], guessedServings: card.servings == nil)
            r.card.servings = n
            r.changes = ["for \(n) \(n == 1 ? "person" : "people")"]
            return r
        case .scale(let f):
            var r = Result(card: scaled(card, by: f), changes: [])
            if let s = card.servings { r.card.servings = max(1, Int((Double(s) * f).rounded())) }
            r.changes = [f == 0.5 ? "half as much" : f == 2 ? "twice as much" : "\(MathEval.format(f)) times as much"]
            r.card.name = tagged(card.name, f == 0.5 ? "half batch" : f == 2 ? "double batch" : "\(MathEval.format(f))x batch")
            return r
        case .style(let s):
            return restyle(card, s)
        }
    }

    /// "Chicken tacos" -> "Chicken tacos (vegetarian)", and "(vegetarian)" -> "(vegetarian, spicier)".
    static func tagged(_ name: String, _ tag: String) -> String {
        if name.hasSuffix(")"), let open = name.lastIndex(of: "(") {
            let inside = name[name.index(after: open)..<name.index(before: name.endIndex)]
            if inside.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }).contains(tag) { return name }
            return String(name[..<name.index(before: name.endIndex)]) + ", " + tag + ")"
        }
        return name + " (" + tag + ")"
    }

    // MARK: Amounts

    static func scaled(_ card: RecipeCard, by factor: Double) -> RecipeCard {
        var c = card
        c.ingredients = card.ingredients.map { scaleLine($0, by: factor) }
        return c
    }

    private static let qty = #"(\d+ \d+/\d+|\d+/\d+|\d+(?:\.\d+)?)"#

    /// "1 1/2 cups (190 g) flour" x2 -> "3 cups (380 g) flour".
    static func scaleLine(_ line: String, by factor: Double) -> String {
        guard factor != 1 else { return line }
        var out = line
        var newAmount: Double?
        // The amount at the start, and "2 to 3" ranges.
        if let r = out.range(of: "^" + qty + #"(?:\s*(?:to|-)\s*"# + qty + ")?", options: .regularExpression) {
            let part = String(out[r])
            let pieces = part.components(separatedBy: CharacterSet(charactersIn: "-")).flatMap { $0.components(separatedBy: " to ") }
            let values = pieces.compactMap { value(of: $0.trimmingCharacters(in: .whitespaces)) }
            if !values.isEmpty {
                // You can't use half an egg, so eggs round to whole ones (at least 1).
                let isEgg = Rx.matches(#"^[0-9 /.]+(?:(?:to|-) ?[0-9 /.]+)?(?:large |medium |small |big )?eggs?\b"#, out)
                let scaledValues = values.map { isEgg ? max(1, ($0 * factor).rounded()) : $0 * factor }
                newAmount = scaledValues.last
                let joined = scaledValues.map(fraction).joined(separator: " to ")
                out.replaceSubrange(r, with: joined)
            }
        }
        // Metric amounts in brackets: "(190 g)", "(300 ml)".
        if let re = try? NSRegularExpression(pattern: #"\((\d+(?:\.\d+)?)\s*(g|ml|kg|l|oz)\b"#) {
            let ns = out as NSString
            var result = ""
            var last = 0
            for m in re.matches(in: out, range: NSRange(location: 0, length: ns.length)) {
                let numRange = m.range(at: 1)
                result += ns.substring(with: NSRange(location: last, length: numRange.location - last))
                let v = (Double(ns.substring(with: numRange)) ?? 0) * factor
                let unit = ns.substring(with: m.range(at: 2))
                result += metric(v, unit: unit)
                last = numRange.location + numRange.length
            }
            if last > 0 {
                result += ns.substring(from: last)
                out = result
            }
        }
        if let amount = newAmount { out = fixPlural(out, amount: amount) }
        return out
    }

    private static func value(of s: String) -> Double? {
        let parts = s.split(separator: " ")
        if parts.count == 2, let whole = Double(parts[0]), let f = value(of: String(parts[1])) { return whole + f }
        if s.contains("/") {
            let ab = s.split(separator: "/")
            guard ab.count == 2, let a = Double(ab[0]), let b = Double(ab[1]), b != 0 else { return nil }
            return a / b
        }
        return Double(s)
    }

    /// 1.5 -> "1 1/2", 0.33 -> "1/3", 2 -> "2".
    static func fraction(_ v: Double) -> String {
        guard v > 0 else { return "0" }
        var whole = Int(v)
        let rest = v - Double(whole)
        let parts: [(Double, String)] = [(0, ""), (0.125, "1/8"), (0.25, "1/4"), (1.0 / 3, "1/3"), (0.5, "1/2"),
                                         (2.0 / 3, "2/3"), (0.75, "3/4"), (1, "")]
        var best = parts[0]
        for p in parts where abs(p.0 - rest) < abs(best.0 - rest) { best = p }
        if best.0 == 1 { whole += 1; best = parts[0] }
        if whole == 0 && best.1.isEmpty { return "1/8" }
        if whole == 0 { return best.1 }
        return best.1.isEmpty ? "\(whole)" : "\(whole) \(best.1)"
    }

    private static func metric(_ v: Double, unit: String) -> String {
        if unit == "kg" || unit == "l" || unit == "oz" {
            let r = (v * 10).rounded() / 10
            return MathEval.format(r)
        }
        if v >= 50 { return "\(Int((v / 5).rounded() * 5))" }
        return "\(max(1, Int(v.rounded())))"
    }

    private static let plurals: [String: String] = [
        "cup": "cups", "tablespoon": "tablespoons", "teaspoon": "teaspoons", "egg": "eggs", "clove": "cloves", "can": "cans",
        "slice": "slices", "stick": "sticks", "banana": "bananas", "lemon": "lemons", "lime": "limes", "onion": "onions",
        "tomato": "tomatoes", "potato": "potatoes", "carrot": "carrots", "apple": "apples", "tortilla": "tortillas",
        "bag": "bags", "package": "packages", "sheet": "sheets", "piece": "pieces", "pound": "pounds", "ounce": "ounces",
        "bunch": "bunches", "handful": "handfuls", "pinch": "pinches", "jar": "jars", "box": "boxes", "packet": "packets",
        "breast": "breasts", "fillet": "fillets", "pepper": "peppers", "avocado": "avocados", "orange": "oranges",
        "strawberry": "strawberries", "yolk": "yolks", "bun": "buns",
        "pita": "pitas", "muffin": "muffins", "cookie": "cookies", "cracker": "crackers",
    ]
    private static let sizes: Set<String> = ["large", "medium", "small", "big", "ripe", "whole", "heaping", "level", "boneless", "skinless"]

    /// "1 cups" -> "1 cup", "2 egg" -> "2 eggs".
    private static func fixPlural(_ line: String, amount: Double) -> String {
        var words = line.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        // Skip the amount itself ("1 1/2", "2 to 3") and any size words.
        var i = 0
        while i < words.count, words[i].first?.isNumber == true || words[i] == "to" { i += 1 }
        while i < words.count, sizes.contains(words[i].lowercased()) { i += 1 }
        guard i < words.count else { return line }
        let raw = words[i]
        let core = raw.trimmingCharacters(in: CharacterSet(charactersIn: ",.;:()"))
        let tail = String(raw.dropFirst(core.count))
        let lower = core.lowercased()
        // "2 egg yolks" and "2 egg whites" are already right.
        if lower == "egg", i + 1 < words.count, Rx.matches(#"^(yolks?|whites?)\b"#, words[i + 1].lowercased()) { return line }
        let plural = amount > 1.0001
        if plural, let p = plurals[lower] {
            words[i] = p + tail
        } else if !plural, let s = plurals.first(where: { $0.value == lower })?.key {
            words[i] = s + tail
        }
        return words.joined(separator: " ")
    }

    // MARK: Styles

    private struct Swap {
        let pattern: String
        let with: String
        let short: String
        let name: String
    }

    private static let meat: [Swap] = [
        Swap(pattern: #"\b(chicken|beef) (broth|stock)\b"#, with: "vegetable broth", short: "vegetable broth", name: "the meat broth"),
        Swap(pattern: #"\b(ground beef|minced beef|beef mince|hamburger meat)\b"#, with: "cooked lentils or plant-based mince", short: "lentils", name: "the ground beef"),
        Swap(pattern: #"\b(ground turkey|turkey)\b"#, with: "crumbled extra-firm tofu", short: "tofu", name: "the turkey"),
        Swap(pattern: #"\b(chicken breasts?|chicken thighs?|chicken)\b"#, with: "chickpeas or extra-firm tofu", short: "tofu", name: "the chicken"),
        Swap(pattern: #"\b(steak|beef)\b"#, with: "big mushrooms, sliced", short: "mushrooms", name: "the beef"),
        Swap(pattern: #"\b(bacon)\b"#, with: "smoky fried mushrooms or tempeh", short: "mushrooms", name: "the bacon"),
        Swap(pattern: #"\b(pepperoni)\b"#, with: "veggie pepperoni or sliced peppers", short: "veggie pepperoni", name: "the pepperoni"),
        Swap(pattern: #"\b(sausages?)\b"#, with: "veggie sausage", short: "veggie sausage", name: "the sausage"),
        Swap(pattern: #"\b(ham)\b"#, with: "smoked tofu or extra cheese", short: "smoked tofu", name: "the ham"),
        Swap(pattern: #"\b(pork)\b"#, with: "jackfruit or tofu", short: "jackfruit", name: "the pork"),
        Swap(pattern: #"\b(tuna)\b"#, with: "mashed chickpeas", short: "chickpeas", name: "the tuna"),
        Swap(pattern: #"\b(shrimp|prawns?|salmon|fish|cod)\b"#, with: "tofu or chickpeas", short: "tofu", name: "the fish"),
        Swap(pattern: #"\b(anchov(?:y|ies))\b"#, with: "chopped capers", short: "capers", name: "the anchovies"),
        Swap(pattern: #"\b(gelatin|gelatine)\b"#, with: "agar agar", short: "agar agar", name: "the gelatin"),
        Swap(pattern: #"\b(meat)\b"#, with: "beans or lentils", short: "beans", name: "the meat"),
    ]

    private static let dairy: [Swap] = [
        Swap(pattern: #"\b(cream cheese)\b"#, with: "dairy-free cream cheese", short: "dairy-free cream cheese", name: "the cream cheese"),
        Swap(pattern: #"\b(sour cream|yogurt|yoghurt)\b"#, with: "plain plant-based yogurt", short: "plant yogurt", name: "the sour cream or yogurt"),
        Swap(pattern: #"\b(heavy cream|whipping cream|double cream|cream)\b"#, with: "coconut cream", short: "coconut cream", name: "the cream"),
        Swap(pattern: #"\b(buttermilk)\b"#, with: "oat milk with 1 tablespoon lemon juice", short: "oat milk", name: "the buttermilk"),
        Swap(pattern: #"\b(condensed milk)\b"#, with: "sweetened condensed coconut milk", short: "coconut condensed milk", name: "the condensed milk"),
        Swap(pattern: #"\b(milk)\b"#, with: "oat or soy milk", short: "oat milk", name: "the milk"),
        Swap(pattern: #"\b(butter)\b"#, with: "dairy-free butter or oil", short: "dairy-free butter", name: "the butter"),
        Swap(pattern: #"\b(parmesan|cheddar|mozzarella|cheese)\b"#, with: "dairy-free cheese", short: "dairy-free cheese", name: "the cheese"),
        Swap(pattern: #"\b(chocolate chips|milk chocolate|chocolate)\b"#, with: "dairy-free chocolate", short: "dairy-free chocolate", name: "the chocolate"),
    ]

    private static let animal: [Swap] = [
        Swap(pattern: #"\b(eggs?|egg yolks?|egg whites?)\b"#, with: "flax eggs (1 tablespoon ground flaxseed + 3 tablespoons water for each egg)", short: "flax egg", name: "the eggs"),
        Swap(pattern: #"\b(honey)\b"#, with: "maple syrup", short: "maple syrup", name: "the honey"),
        Swap(pattern: #"\b(mayonnaise|mayo)\b"#, with: "vegan mayo", short: "vegan mayo", name: "the mayo"),
    ]

    private static let gluten: [Swap] = [
        Swap(pattern: #"\b(soy sauce)\b"#, with: "tamari (gluten-free soy sauce)", short: "tamari", name: "the soy sauce"),
        Swap(pattern: #"\b(bread ?crumbs|panko)\b"#, with: "gluten-free breadcrumbs", short: "gluten-free breadcrumbs", name: "the breadcrumbs"),
        Swap(pattern: #"\b(graham crackers?|crackers?|cookies)\b"#, with: "gluten-free crackers or cookies", short: "gluten-free crackers", name: "the crackers"),
        Swap(pattern: #"\b(all-purpose flour|plain flour|self-rising flour|bread flour|whole wheat flour|flour)\b"#, with: "a 1:1 gluten-free flour blend", short: "gluten-free flour", name: "the flour"),
        Swap(pattern: #"\b(flour tortillas?|tortillas?)\b"#, with: "corn tortillas", short: "corn tortillas", name: "the tortillas"),
        Swap(pattern: #"\b(spaghetti|macaroni|pasta|noodles|penne|lasagna sheets)\b"#, with: "gluten-free pasta", short: "gluten-free pasta", name: "the pasta"),
        Swap(pattern: #"\b(oats|rolled oats)\b"#, with: "certified gluten-free oats", short: "gluten-free oats", name: "the oats"),
        Swap(pattern: #"\b(buns?|bread|rolls?|pizza dough|pita)\b"#, with: "gluten-free bread or buns", short: "gluten-free bread", name: "the bread"),
    ]

    private static let lighter: [Swap] = [
        Swap(pattern: #"\b(heavy cream|whipping cream|double cream)\b"#, with: "milk with a spoon of Greek yogurt", short: "milk and yogurt", name: "the cream"),
        Swap(pattern: #"\b(sour cream|mayonnaise|mayo)\b"#, with: "plain Greek yogurt", short: "Greek yogurt", name: "the sour cream or mayo"),
        Swap(pattern: #"\b(white rice)\b"#, with: "brown rice", short: "brown rice", name: "the white rice"),
        Swap(pattern: #"\b(ground beef)\b"#, with: "lean ground turkey", short: "lean turkey", name: "the ground beef"),
        Swap(pattern: #"\b(bacon)\b"#, with: "turkey bacon", short: "turkey bacon", name: "the bacon"),
    ]

    /// Desserts, drinks, pancakes and the like (they get cinnamon instead of chili).
    static func isSweet(_ card: RecipeCard) -> Bool {
        if let c = card.category?.lowercased(), ["dessert", "baking", "drink", "drinks"].contains(c) { return true }
        let all = card.ingredients.joined(separator: " ").lowercased()
        return Rx.matches(#"\b(sugar|honey|syrup|chocolate|vanilla|cinnamon)\b"#, all)
            && !Rx.matches(#"\b(chicken|beef|bacon|ham|sausage|onions?|garlic|tuna|turkey|soy sauce|pepperoni|salt and pepper)\b"#, all)
    }

    private static func swapAll(_ card: inout RecipeCard, _ swaps: [Swap], changes: inout [String]) {
        var seen = Set<String>()
        card.ingredients = card.ingredients.map { line in
            for s in swaps where Rx.matches(s.pattern, line) {
                if !seen.contains(s.name) { changes.append("\(s.with) instead of \(s.name)"); seen.insert(s.name) }
                return "\(TextKit.capitalizeFirst(s.with)) (instead of: \(line))"
            }
            return line
        }
        card.steps = card.steps.map { step in
            var out = step
            for s in swaps where seen.contains(s.name) {
                out = out.replacingOccurrences(of: s.pattern, with: s.short, options: [.regularExpression, .caseInsensitive])
            }
            return out
        }
    }

    private static func restyle(_ original: RecipeCard, _ style: String) -> Result {
        var card = original
        var changes: [String] = []
        let sweet = isSweet(original)
        switch style {
        case "vegetarian":
            swapAll(&card, meat, changes: &changes)
            if !changes.isEmpty {
                // Swaps don't go from pink to cooked, so "until no pink is left" becomes "until golden".
                card.steps = card.steps.map {
                    $0.replacingOccurrences(of: #",? until (?:no pink is left(?: inside)?|(?:it is |they are )?no longer pink|(?:it is |they are )?cooked through)"#,
                                            with: ", until hot and golden", options: [.regularExpression, .caseInsensitive])
                }
                card.steps.insert("Cook the swaps until hot and golden. They don't need as long as meat.", at: 0)
            }
        case "vegan":
            swapAll(&card, meat + dairy + animal, changes: &changes)
        case "dairy free":
            swapAll(&card, dairy, changes: &changes)
        case "gluten free":
            swapAll(&card, gluten, changes: &changes)
        case "healthier":
            swapAll(&card, lighter, changes: &changes)
            card.ingredients = card.ingredients.map { line in
                if Rx.matches(#"\bsugar\b"#, line), !line.contains("instead of") {
                    changes.append("a third less sugar")
                    return line + " (use about a third less)"
                }
                if Rx.matches(#"^\S.*\bbutter\b"#, line), !Rx.matches(#"for the pan|for greasing"#, line), !line.contains("instead of") {
                    changes.append("less butter")
                    return line + " (use about a quarter less)"
                }
                return line
            }
            if !sweet {
                card.ingredients.append("A big handful of vegetables, like spinach, peppers or peas")
                card.steps.append("Stir in the vegetables near the end so they stay bright.")
                changes.append("extra vegetables")
            }
        case "spicier":
            if sweet {
                card.ingredients.append("1 teaspoon ground cinnamon")
                card.ingredients.append("1/4 teaspoon ground ginger or nutmeg")
                card.steps.insert("Mix the cinnamon and ginger in with the dry ingredients.", at: 0)
                changes.append("cinnamon and ginger for a warm kick")
            } else {
                card.ingredients.append("1/2 teaspoon chili flakes or a pinch of cayenne (more if you like it hot)")
                card.ingredients.append("Hot sauce, to serve")
                card.steps.append("Stir in the chili flakes with the other seasonings, taste, and add more if you want it hotter. Serve with hot sauce.")
                changes.append("chili flakes and hot sauce")
            }
        case "milder":
            let hot = #"\b(chili|chilli|chile|cayenne|jalapeno|jalapeño|hot sauce|sriracha|red pepper flakes|hot pepper)\b"#
            card.ingredients = card.ingredients.map { line in
                guard Rx.matches(hot, line) else { return line }
                changes.append("less heat")
                return line + " (use a tiny pinch, or leave it out)"
            }
        case "sweeter":
            var added = false
            card.ingredients = card.ingredients.map { line in
                guard !added, Rx.matches(#"\b(sugar|honey|maple syrup)\b"#, line) else { return line }
                added = true
                changes.append("a bit more sweetness")
                return line + " (add about a quarter more)"
            }
            if !added {
                card.ingredients.append("1 to 2 tablespoons honey or maple syrup")
                card.steps.append("Stir in the honey or maple syrup, then taste.")
                changes.append("a little honey or maple syrup")
            }
        case "less sweet":
            card.ingredients = card.ingredients.map { line in
                guard Rx.matches(#"\b(sugar|honey|maple syrup|syrup)\b"#, line) else { return line }
                changes.append("about a third less sugar")
                return line + " (use about a third less)"
            }
        case "cheesier":
            card.ingredients.append("1/2 cup (50 g) extra shredded cheese, like cheddar or mozzarella")
            card.steps.append("Sprinkle or stir in the extra cheese at the end and let it melt.")
            changes.append("extra cheese")
        default:
            break
        }
        var seen = Set<String>()
        changes = changes.filter { seen.insert($0).inserted }
        if !changes.isEmpty { card.name = tagged(original.name, style) }
        return Result(card: card, changes: changes)
    }
}
