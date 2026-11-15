import XCTest
@testable import Ace

/// Memory names ("my lamp is called Sunny"), day words, real follow-ups and recipe changes.
@MainActor
final class MemoryFollowUpTests: XCTestCase {
    // MARK: Names you give things

    func testNamesComeFromFacts() {
        let names = MemoryStore.aliases(in: [
            "my vacuum is called Mova", "my lamp is named Sunny", "my dog's name is Max", "Bolt is my bike",
            "my robot vacuum is called Robo",
            // Not names:
            "blue is my favorite color", "it is my birthday", "my favorite color is blue", "Jake is my best friend",
        ])
        XCTAssertEqual(names["mova"], "vacuum")
        XCTAssertEqual(names["sunny"], "lamp")
        XCTAssertEqual(names["max"], "dog")
        XCTAssertEqual(names["bolt"], "bike")
        XCTAssertEqual(names["robo"], "vacuum")
        XCTAssertNil(names["blue"])
        XCTAssertNil(names["it"])
        XCTAssertNil(names["jake"])
        XCTAssertEqual(names.count, 5)
    }

    func testNamesAreSwappedIn() {
        let names = ["sunny": "lamp", "max": "dog"]
        XCTAssertEqual(Brain.withAliases("Turn on Sunny", names), "turn on the lamp")
        XCTAssertEqual(Brain.withAliases("turn off the sunny", names), "turn off the lamp")
        XCTAssertNil(Brain.withAliases("turn on the sunshine lamp", ["sun": "lamp"]))
        XCTAssertNil(Brain.withAliases("what time is it", names))
        if case .home(let h)? = IntentRouter.parse(Brain.withAliases("turn on sunny", names) ?? "") {
            XCTAssertEqual(h.name, "home.on")
            XCTAssertTrue(h.target.contains("lamp"), h.target)
        } else {
            XCTFail("\"turn on the lamp\" should be a home command")
        }
    }

    func testOriginalCapitalsAreKept() {
        XCTAssertEqual(Brain.originalCase("my vacuum is called mova", in: "Remember my vacuum is called Mova"), "my vacuum is called Mova")
        XCTAssertEqual(Brain.originalCase("not here", in: "Something else"), "not here")
    }

    func testMemoryWordsStillWork() {
        XCTAssertEqual(IntentRouter.parse("my vacuum is called Mova")?.kind, "remember")
        XCTAssertEqual(IntentRouter.parse("what's my vacuum called")?.kind, "recall")
        XCTAssertEqual(IntentRouter.parse("forget my vacuum")?.kind, "forget")
    }

    // MARK: Day words

    private func saturday() -> (Date, Calendar) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 12))!   // a Saturday
        return (date, cal)
    }

    func testDayWords() {
        let (today, cal) = saturday()
        func find(_ s: String) -> DayWords.Found? { DayWords.find(in: s, today: today, calendar: cal) }
        XCTAssertEqual(find("what is the weather tomorrow")?.offset, 1)
        XCTAssertEqual(find("what is the weather tomorrow")?.rest, "what is the weather")
        XCTAssertEqual(find("weather in paris on monday")?.offset, 2)
        XCTAssertEqual(find("weather in paris on monday")?.label, "Monday")
        XCTAssertEqual(find("weather in paris on monday")?.rest, "weather in paris")
        XCTAssertEqual(find("on saturday")?.offset, 0)
        XCTAssertEqual(find("next saturday")?.offset, 7)
        XCTAssertEqual(find("this weekend")?.offset, 0)
        XCTAssertEqual(find("this weekend")?.length, 2)
        XCTAssertEqual(find("the day after tomorrow")?.offset, 2)
        XCTAssertNil(find("how is the weather"))
        XCTAssertNil(find("weather in todaytown"))
        XCTAssertTrue(DayWords.isOnlyDay("tomorrow"))
        XCTAssertTrue(DayWords.isOnlyDay("on friday"))
        XCTAssertFalse(DayWords.isOnlyDay("tomorrow in paris"))
    }

    func testWeatherKnowsTheDay() {
        XCTAssertEqual(IntentRouter.parse("what's the weather tomorrow"), .weather(place: nil, day: "tomorrow"))
        XCTAssertEqual(IntentRouter.parse("weather in paris on friday"), .weather(place: "paris", day: "friday"))
        XCTAssertEqual(IntentRouter.parse("what's the weather like in london"), .weather(place: "london", day: nil))
        XCTAssertEqual(IntentRouter.parse("what's the weather today"), .weather(place: nil, day: nil))
        XCTAssertEqual(IntentRouter.parse("will it rain tomorrow in tokyo"), .weather(place: "tokyo", day: "tomorrow"))
    }

    // MARK: Follow-ups

    func testWeatherFollowUps() {
        let brain = Brain()
        brain.noteTurn("what's the weather in paris")
        XCTAssertEqual(brain.understand("what about tomorrow"), .skill("weather"))
        brain.noteTurn("what's the weather")
        XCTAssertEqual(brain.understand("and on saturday?"), .skill("weather"))
        brain.noteTurn("what's the weather tomorrow")
        XCTAssertEqual(brain.understand("how about in london"), .skill("weather"))
    }

    func testCalendarFollowUps() {
        let brain = Brain()
        brain.noteTurn("what do I have tomorrow")
        XCTAssertEqual(brain.understand("what about friday"), .skill("calendarList"))
        brain.noteTurn("what's on my calendar today")
        XCTAssertEqual(brain.understand("and tomorrow?"), .skill("calendarList"))
    }

    func testOldFollowUpsStillWork() {
        let brain = Brain()
        brain.noteTurn("what is the capital of france")
        XCTAssertEqual(brain.understand("what about germany"), .bank("geo.capital.what-is-the-capital-of-germany"))
    }

    // MARK: Changing recipes

    func testRecipeChangeWords() {
        let cases: [(String, RecipeTweaks.Change)] = [
            ("make it spicier", .style("spicier")), ("can you make it more spicy", .style("spicier")),
            ("make it vegetarian", .style("vegetarian")), ("make a vegan version", .style("vegan")),
            ("is there a gluten-free version", .style("gluten free")), ("without meat", .style("vegetarian")),
            ("no dairy", .style("dairy free")), ("make it healthier please", .style("healthier")),
            ("make it less sweet", .style("less sweet")), ("make it kid friendly", .style("milder")),
            ("make it cheesier", .style("cheesier")),
            ("make it for 8 people", .people(8)), ("what about for 10 people", .people(10)),
            ("make it for twelve people", .people(12)), ("i need to feed 6 kids", .people(6)),
            ("double it", .scale(2)), ("halve the recipe", .scale(0.5)), ("cut it in half", .scale(0.5)),
            ("make twice as much", .scale(2)), ("triple it", .scale(3)),
        ]
        for (text, want) in cases {
            XCTAssertEqual(RecipeTweaks.parse(text), want, text)
            XCTAssertEqual(IntentRouter.parse(text)?.kind, "recipeTweak", text)
        }
        for text in ["make it brighter", "make it warmer", "make it hotter", "double click", "how many people live in france",
                     "i have 3 kids", "make it rain", "turn it on", "make it louder", "what about tomorrow", "for real"] {
            XCTAssertNil(RecipeTweaks.parse(text), text)
        }
    }

    func testAmountsScale() {
        XCTAssertEqual(RecipeTweaks.scaleLine("1 1/2 cups (190 g) all-purpose flour", by: 2), "3 cups (380 g) all-purpose flour")
        XCTAssertEqual(RecipeTweaks.scaleLine("1 1/4 cups (300 ml) milk", by: 0.5), "2/3 cup (150 ml) milk")
        XCTAssertEqual(RecipeTweaks.scaleLine("2 tablespoons sugar", by: 0.5), "1 tablespoon sugar")
        XCTAssertEqual(RecipeTweaks.scaleLine("1/2 teaspoon salt", by: 2), "1 teaspoon salt")
        XCTAssertEqual(RecipeTweaks.scaleLine("1 large egg", by: 0.5), "1 large egg")
        XCTAssertEqual(RecipeTweaks.scaleLine("1 large egg", by: 3), "3 large eggs")
        XCTAssertEqual(RecipeTweaks.scaleLine("2 to 3 bananas", by: 2), "4 to 6 bananas")
        XCTAssertEqual(RecipeTweaks.scaleLine("Salt and pepper", by: 2), "Salt and pepper")
        XCTAssertEqual(RecipeTweaks.fraction(1.5), "1 1/2")
        XCTAssertEqual(RecipeTweaks.fraction(0.25), "1/4")
        XCTAssertEqual(RecipeTweaks.fraction(2.99), "3")
    }

    private func card(_ id: String) -> RecipeCard {
        guard let e = RecipeBook.all.first(where: { $0.id == id }) else {
            XCTFail("No recipe \(id)")
            return RecipeCard(name: "", ingredients: [], steps: [])
        }
        return e.card
    }

    func testForMorePeople() {
        let pancakes = card("pancakes")
        XCTAssertEqual(pancakes.servings, 4)
        let r = RecipeTweaks.apply(.people(8), to: pancakes)
        XCTAssertEqual(r.card.servings, 8)
        XCTAssertFalse(r.guessedServings)
        XCTAssertEqual(r.card.ingredients.first, "3 cups (380 g) all-purpose flour")
        XCTAssertEqual(r.card.steps, pancakes.steps, "Steps and times don't change")
        let half = RecipeTweaks.apply(.scale(0.5), to: pancakes)
        XCTAssertEqual(half.card.servings, 2)
        XCTAssertTrue(half.card.name.contains("half batch"))
    }

    func testVegetarianSwapsTheMeat() {
        let stirFry = card("chicken-stir-fry")
        let r = RecipeTweaks.apply(.style("vegetarian"), to: stirFry)
        XCTAssertFalse(r.changes.isEmpty)
        XCTAssertTrue(r.card.name.hasSuffix("(vegetarian)"), r.card.name)
        for line in r.card.ingredients {
            let before = line.components(separatedBy: "(instead of:").first ?? line
            XCTAssertFalse(before.lowercased().contains("chicken"), line)
        }
        XCTAssertFalse(r.card.steps.joined(separator: " ").lowercased().contains("chicken"))
        // Pancakes have no meat, so nothing changes.
        XCTAssertTrue(RecipeTweaks.apply(.style("vegetarian"), to: card("pancakes")).changes.isEmpty)
    }

    func testSpicierFitsTheDish() {
        let sweet = RecipeTweaks.apply(.style("spicier"), to: card("chocolate-chip-cookies"))
        XCTAssertTrue(sweet.card.ingredients.joined().contains("cinnamon"))
        XCTAssertTrue(RecipeTweaks.isSweet(card("pancakes")))
        XCTAssertFalse(RecipeTweaks.isSweet(card("chicken-stir-fry")))
        let savory = RecipeTweaks.apply(.style("spicier"), to: card("chicken-stir-fry"))
        XCTAssertTrue(savory.card.ingredients.joined().contains("chili"))
    }

    func testChangesStack() {
        XCTAssertEqual(RecipeTweaks.tagged("Tacos", "vegetarian"), "Tacos (vegetarian)")
        XCTAssertEqual(RecipeTweaks.tagged("Tacos (vegetarian)", "spicier"), "Tacos (vegetarian, spicier)")
        XCTAssertEqual(RecipeTweaks.tagged("Tacos (vegetarian)", "vegetarian"), "Tacos (vegetarian)")
    }

    func testRecipeChangeNeedsARecipe() {
        let brain = Brain()
        brain.noteRecipe(nil)
        XCTAssertEqual(brain.understand("make it spicier"), .skill("recipeTweak"))
    }
}
