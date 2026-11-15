import XCTest
@testable import Ace

/// Recipes: Ace's own recipe book, recipe questions, and the timer buttons on recipe steps.
@MainActor
final class RecipeTests: XCTestCase {
    // MARK: Timer times read from recipe steps

    func testStepTimes() {
        let cases: [(String, Int?)] = [
            ("Bake for 25 to 30 minutes.", 1800),
            ("Bake for 10-12 minutes, until the edges are golden.", 720),
            ("Chill for 1 hour 15 minutes.", 4500),
            ("Let rise for 1 hour and 30 minutes.", 5400),
            ("Refrigerate overnight.", 8 * 3600),
            ("Bake until golden.", nil),
            ("Cook until done.", nil),
            ("Microwave for 90 seconds.", 90),
            ("Let cool for 10 minutes.", 600),
            ("Simmer for 1 1/2 hours.", 5400),
            ("Simmer for 1.5 hours.", 5400),
            ("Chill for an hour.", 3600),
            ("Let it rest for half an hour.", 1800),
            ("Boil for 8 to 10 minutes.", 600),
            ("Bake 20 min.", 1200),
            ("Heat the oven to 350°F (175°C).", nil),
            ("Cut into 12 squares.", nil),
            ("Mix the flour and sugar in a pan.", nil),
            ("Cook 2 to 3 minutes per side.", 180),
            ("Let rise for 45 minutes.", 2700),
        ]
        var misses: [String] = []
        for (step, want) in cases {
            let got = StepTimer.find(in: step)?.seconds
            if got != want { misses.append("\"\(step)\" -> \(got.map(String.init) ?? "no timer"), wanted \(want.map(String.init) ?? "no timer")") }
        }
        print("STEP TIMERS: \(cases.count - misses.count)/\(cases.count)")
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testTimerLabels() {
        XCTAssertEqual(StepTimer.find(in: "Bake for 12 minutes.")?.activity, "baking")
        XCTAssertEqual(StepTimer.find(in: "Let cool for 10 minutes.")?.activity, "cooling")
        XCTAssertEqual(StepTimer.find(in: "Refrigerate overnight.")?.activity, "chilling")
        XCTAssertEqual(StepTimer.find(in: "Let the dough rise for 1 hour.")?.activity, "rising")
        XCTAssertEqual(StepTimer.label(recipe: "Chocolate chip cookies", activity: "baking"), "Chocolate chip cookies baking")
        XCTAssertEqual(StepTimer.label(recipe: "Fluffy pancakes", activity: "resting"), "Pancakes resting")
        XCTAssertEqual(KitchenTimers.words(30 * 60), "30 min")
        XCTAssertEqual(KitchenTimers.words(4500), "1 hr 15 min")
        XCTAssertEqual(KitchenTimers.words(8 * 3600), "8 hr")
        XCTAssertEqual(KitchenTimers.words(90), "90 sec")
        XCTAssertEqual(KitchenTimers.clock(75), "1:15")
        XCTAssertEqual(KitchenTimers.clock(3725), "1:02:05")
    }

    // MARK: The recipe book

    func testRecipeBookIsGood() {
        let all = RecipeBook.all
        XCTAssertGreaterThanOrEqual(all.count, 1000, "recipes.json should have at least 1000 recipes")
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "Two recipes share an id")
        for r in all {
            XCTAssertFalse(r.ingredients.isEmpty, "\(r.id) has no ingredients")
            XCTAssertGreaterThanOrEqual(r.steps.count, 3, "\(r.id) has too few steps")
            XCTAssertFalse(r.main.isEmpty, "\(r.id) has no main ingredients")
            for s in r.steps where Rx.matches(#"\b(bake|chill|refrigerate|let cool|let rise|simmer)\b.*\bfor\b"#, s) {
                XCTAssertNotNil(StepTimer.find(in: s), "\(r.id): no timer read from \"\(s)\"")
            }
        }
    }

    // MARK: Recipe questions

    private func recipeAsk(_ text: String) -> String? {
        if case .recipe(let dish) = IntentRouter.parse(text) { return dish }
        return nil
    }

    func testRecipeQuestions() {
        // (question, the recipe Ace's book should find, or "with"/"idea" for ideas)
        let cases: [(String, String)] = [
            ("recipe for pancakes", "pancakes"),
            ("give me a recipe for chocolate chip cookies", "chocolate-chip-cookies"),
            ("how do I make pancakes", "pancakes"),
            ("how do you make mac and cheese", "mac-and-cheese"),
            ("how to make guacamole", "guacamole"),
            ("brownie recipe", "brownies"),
            ("how do I bake banana bread", "banana-bread"),
            ("I want to make tacos", "tacos"),
            ("teach me how to make french toast", "french-toast"),
            ("show me a pizza recipe", "homemade-pizza"),
            ("how to cook fried rice", "fried-rice"),
            ("how do i make a grilled cheese", "grilled-cheese"),
            ("lemonade recipe", "lemonade"),
            ("how do I make scrambled eggs", "scrambled-eggs"),
            ("what can I make with eggs and cheese", "with"),
            ("what can we cook with chicken and rice", "with"),
            ("I have bananas and flour what can I make", "with"),
            ("what should I make for dinner", "idea"),
            ("give me a dessert recipe", "idea"),
            ("any dinner ideas", "idea"),
        ]
        var misses: [String] = []
        for (q, want) in cases {
            guard let dish = recipeAsk(q) else { misses.append("\"\(q)\" -> not a recipe"); continue }
            switch want {
            case "with":
                if !dish.hasPrefix("with ") || RecipeBook.ideas(with: RecipeBook.splitItems(String(dish.dropFirst(5)))).isEmpty {
                    misses.append("\"\(q)\" -> no ideas (\(dish))")
                }
            case "idea":
                if !dish.hasPrefix("idea") { misses.append("\"\(q)\" -> \(dish), wanted an idea") }
            default:
                let found = RecipeBook.find(dish)?.id
                if !(found ?? "").hasPrefix(want) && found != want { misses.append("\"\(q)\" -> \(found ?? "nothing in the book") (\(dish))") }
            }
        }
        print("RECIPE SCORE: \(cases.count - misses.count)/\(cases.count)")
        for m in misses { print("RECIPE MISS \(m)") }
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testNotRecipes() {
        for q in ["how do I make a crafting table", "how do i make my password strong", "how do you make a nether portal",
                  "how do I make friends", "how do I make a website", "what is a recipe"] {
            XCTAssertNil(recipeAsk(q), "\"\(q)\" shouldn't be a recipe question")
        }
    }

    func testIdeasUseWhatYouHave() {
        let ideas = RecipeBook.ideas(with: ["eggs", "cheese"])
        XCTAssertFalse(ideas.isEmpty)
        XCTAssertEqual(RecipeBook.splitItems("some eggs, cheese and bread"), ["eggs", "cheese", "bread"])
    }
}
