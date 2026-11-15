import XCTest
@testable import Ace

/// The fixes from Storm's screenshots: "Who is the current president of the UK" (got a page about Germany),
/// "Hello Ace what is the capital of the UK" (got a page about Sanrio) and "chocolate cake" (got the mug cake).
/// Also the hello when the app opens, favorites and mood sounds.
@MainActor
final class AnswerFixTests: XCTestCase {
    // MARK: Leaders

    func testUKPresidentScreenshot() throws {
        let ask = try XCTUnwrap(Leaders.parse("Who is the current president of the UK"))
        XCTAssertEqual(ask.role, .president)
        XCTAssertEqual(ask.country, "Q145")
        let text = Leaders.answer(ask, fresh: nil)
        XCTAssertTrue(text.contains("doesn't have a president"), text)
        XCTAssertTrue(text.contains("King Charles III"), text)
        XCTAssertTrue(text.contains("Prime Minister Keir Starmer"), text)
        XCTAssertTrue(text.contains(Leaders.checked), "Built-in names say how old they are: \(text)")
        // Fresh names from the web replace the built-in ones, and then there's no date warning.
        let fresh = Leaders.answer(ask, fresh: (state: "Charles III", government: "Keir Starmer"))
        XCTAssertFalse(fresh.contains(Leaders.checked), fresh)
        XCTAssertTrue(fresh.contains("Keir Starmer"), fresh)
        // The router sends it to the leader skill, not the web.
        if case .leader(let routed)? = IntentRouter.parse("Who is the current president of the UK") {
            XCTAssertEqual(routed, ask)
        } else {
            XCTFail("Not routed to the leader skill")
        }
    }

    func testLeaderQuestions() {
        let cases: [(String, String, String)] = [
            // (question, country id, words the answer must have)
            ("who is the prime minister of the uk", "Q145", "Keir Starmer"),
            ("who's the king of england right now", "Q145", "Charles III"),
            ("who is the queen of the uk", "Q145", "not a queen"),
            ("who is the president of the usa", "Q30", "Donald Trump"),
            ("who is the president of america", "Q30", "Donald Trump"),
            ("who is the president of germany", "Q183", "Steinmeier"),
            ("who is the chancellor of germany", "Q183", "Merz"),
            ("who is the king of japan", "Q17", "Emperor Naruhito"),
            ("uk prime minister", "Q145", "Keir Starmer"),
            ("who leads canada", "Q16", "Canada"),
            ("does the uk have a president", "Q145", "No."),
            ("who is the uk's prime minister", "Q145", "Keir Starmer"),
        ]
        var misses: [String] = []
        for (q, id, want) in cases {
            guard let ask = Leaders.parse(q) else { misses.append("\"\(q)\" -> not a leader question"); continue }
            if ask.country != id { misses.append("\"\(q)\" -> \(ask.country), wanted \(id)"); continue }
            let text = Leaders.answer(ask, fresh: nil)
            if !text.contains(want) { misses.append("\"\(q)\" -> \"\(text)\", wanted \"\(want)\"") }
        }
        print("LEADER SCORE: \(cases.count - misses.count)/\(cases.count)")
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testNotLeaderQuestions() {
        for q in ["who was the first president of the united states", "who was the very first us president",
                  "who is the president of the chess club", "what is a president", "who is the president",
                  "who is the leader of the band", "the king"] {
            XCTAssertNil(Leaders.parse(q), "\"\(q)\" isn't about who leads a country now")
        }
    }

    func testTimeSensitive() {
        XCTAssertTrue(Leaders.isTimeSensitive("who is the current president of the uk"))
        XCTAssertTrue(Leaders.isTimeSensitive("what is the latest iphone"))
        XCTAssertTrue(Leaders.isTimeSensitive("who is winning right now"))
        XCTAssertFalse(Leaders.isTimeSensitive("what is the capital of france"))
        XCTAssertFalse(Leaders.isTimeSensitive("how tall is mount everest"))
    }

    // MARK: Web results about the wrong thing

    func testWebRejectsWrongPages() {
        // The two screenshots.
        XCTAssertFalse(WebService.fits(title: "Sanrio",
                                       text: "Sanrio is a Japanese entertainment company that designs and sells Hello Kitty products.",
                                       query: "Hello Ace what is the capital of the UK"))
        XCTAssertFalse(WebService.fits(title: "Minister-president",
                                       text: "A minister-president is the head of government of a state in Germany or Austria.",
                                       query: "Who is the current president of the UK"))
        // Right pages still fit.
        XCTAssertTrue(WebService.fits(title: "London",
                                      text: "London is the capital and largest city of England and the United Kingdom.",
                                      query: "Hello Ace what is the capital of the UK"))
        XCTAssertTrue(WebService.fits(title: "Volcano",
                                      text: "A volcano is a rupture in the crust of a planet that lets hot lava, ash and gases escape.",
                                      query: "how do volcanoes work"))
        // A page about something else entirely.
        XCTAssertFalse(WebService.fits(title: "Hello Kitty",
                                       text: "Hello Kitty is a fictional character created by Yuko Shimizu.",
                                       query: "how do volcanoes work"))
    }

    func testMainWordsSkipGreetingsAndPlaces() {
        let words = WebService.mainWords("Hello Ace what is the capital of the UK")
        XCTAssertEqual(words, ["capital"])
    }

    // MARK: "Hello Ace" in front of a question

    func testGreetingIsTakenOff() {
        let cases: [(String, String)] = [
            ("Hello Ace what is the capital of the UK", "what is the capital of the UK"),
            ("Hey Ace, what's 2 + 2", "what's 2 + 2"),
            ("Ace, tell me a joke", "tell me a joke"),
            ("hi, who made you", "who made you"),
            ("Good morning Ace. What's the weather", "What's the weather"),
            ("okay what time is it", "what time is it"),
            // Left alone: just a greeting, or "hello" is part of the question.
            ("Hello Ace", "Hello Ace"),
            ("hello", "hello"),
            ("hey ace!!", "hey ace!!"),
            ("hello world in python", "hello world in python"),
            ("ace of spades", "ace of spades"),
            ("ok google", "ok google"),
        ]
        for (said, want) in cases {
            XCTAssertEqual(IntentRouter.withoutGreeting(said), want, "\"\(said)\"")
        }
    }

    func testCapitalWithGreetingUsesTheBank() throws {
        let brain = Brain()
        let cases: [(String, String)] = [
            ("Hello Ace what is the capital of the UK", "London"),
            ("hey ace whats the capital of the united kingdom", "London"),
            ("Hi Ace, what is the capital of Britain?", "London"),
            ("what is the capital of the UK", "London"),
            ("capital of the uk", "London"),
            ("Hello Ace what is the capital of the USA", "Washington"),
            ("hey ace what's the capital of the US", "Washington"),
            ("capital of america", "Washington"),
            ("Ace, what is the capital of France?", "Paris"),
            ("hello ace what is the capital of japan", "Tokyo"),
        ]
        var misses: [String] = []
        for (q, want) in cases {
            brain.resetConversation()
            guard case .bank(let id) = brain.understand(q), let e = brain.bank.entry(id: id) else {
                misses.append("\"\(q)\" -> \(brain.understand(q))"); continue
            }
            if !e.a.contains(where: { $0.contains(want) }) { misses.append("\"\(q)\" -> \(id), wanted \(want)") }
        }
        print("CAPITAL SCORE: \(cases.count - misses.count)/\(cases.count)")
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    // MARK: Chocolate cake

    func testChocolateCakeIsTheFullCake() throws {
        let cake = try XCTUnwrap(RecipeBook.find("chocolate cake"))
        XCTAssertEqual(cake.id, "chocolate-cake")
        let steps = cake.steps.joined(separator: " ")
        XCTAssertTrue(steps.contains("350°F"), "Oven temperature")
        XCTAssertTrue(steps.contains("9 inch"), "Pan size")
        XCTAssertTrue(steps.contains("Bake for 30 to 35 minutes"), "Bake time")
        XCTAssertTrue(steps.contains("cool completely"), "Cooling")
        XCTAssertEqual(StepTimer.find(in: cake.steps.first { $0.hasPrefix("Bake") } ?? "")?.seconds, 35 * 60)
        XCTAssertEqual(RecipeBook.quickOffer(for: cake), "Want a quick 5-minute mug version instead?")
        XCTAssertEqual(RecipeBook.quickVersion(of: cake)?.id, "chocolate-mug-cake")
    }

    func testCakeWordings() {
        let cases: [(String, String)] = [
            ("chocolate cake", "chocolate-cake"),
            ("a chocolate cake", "chocolate-cake"),
            ("choc cake", "chocolate-cake"),
            ("cake", "chocolate-cake"),
            ("birthday cake", "chocolate-cake"),
            ("quick chocolate cake", "chocolate-mug-cake"),
            ("mug cake", "chocolate-mug-cake"),
            ("chocolate mug cake", "chocolate-mug-cake"),
            ("microwave chocolate cake", "chocolate-mug-cake"),
            ("5 minute chocolate cake", "chocolate-mug-cake"),
            ("single serving chocolate cake", "chocolate-mug-cake"),
            ("banana cake", "banana-bread"),
            ("cheesecake", "no-bake-cheesecake"),
        ]
        var misses: [String] = []
        for (dish, want) in cases where RecipeBook.find(dish)?.id != want {
            misses.append("\"\(dish)\" -> \(RecipeBook.find(dish)?.id ?? "nothing"), wanted \(want)")
        }
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testPlainDishesStillWin() {
        let cases: [(String, String)] = [
            ("how do I make a chocolate cake", "chocolate-cake"),
            ("chocolate cake recipe", "chocolate-cake"),
            ("how do I make a mug cake", "chocolate-mug-cake"),
            ("cookies", "chocolate-chip-cookies"),
            ("how do I make cookies", "chocolate-chip-cookies"),
            ("quick cookies", "chocolate-chip-cookies"),
            ("sugar cookies", "sugar-cookies"),
            ("pancakes", "pancakes"),
            ("quick pancakes", "pancakes"),
            ("pizza recipe", "homemade-pizza"),
            ("how do I make pizza", "homemade-pizza"),
            ("brownies", "brownies"),
            ("chocolate brownies", "brownies"),
            ("how to make brownies", "brownies"),
        ]
        var misses: [String] = []
        for (q, want) in cases {
            var dish = q
            if case .recipe(let d)? = IntentRouter.parse(q) { dish = d }
            let got = RecipeBook.find(dish)?.id
            if got != want { misses.append("\"\(q)\" -> \(got ?? "nothing") (\(dish)), wanted \(want)") }
        }
        XCTAssertTrue(misses.isEmpty, misses.joined(separator: "\n"))
    }

    func testOnlyTheCakeOffersAQuickVersion() {
        for e in RecipeBook.all where e.id != "chocolate-cake" {
            XCTAssertNil(RecipeBook.quickOffer(for: e), e.id)
        }
        // The mug cake button sends this, and it finds the mug cake.
        if case .recipe(let d)? = IntentRouter.parse("Chocolate mug cake recipe") {
            XCTAssertEqual(RecipeBook.find(d)?.id, "chocolate-mug-cake")
        } else {
            XCTFail("The mug cake button isn't a recipe question")
        }
    }

    func testSayingYesToTheMugVersion() {
        for yes in ["yes", "yes please", "sure", "yeah the mug one", "the quick one", "mug version", "quick"] {
            XCTAssertTrue(Brain.acceptsQuickOffer(yes), yes)
        }
        for no in ["no", "no thanks", "ok", "what is the capital of france", "how long does it bake"] {
            XCTAssertFalse(Brain.acceptsQuickOffer(no), no)
        }
    }

    // MARK: Hello when the app opens

    func testGreeterTiming() {
        let now = Date()
        // A fresh start greets.
        XCTAssertTrue(Greeter.shouldGreet(now: now, lastGreeting: nil, awaySince: nil, firstOpen: true))
        XCTAssertTrue(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-3600), awaySince: nil, firstOpen: true))
        // Never twice within 5 minutes, even after closing and opening again.
        XCTAssertFalse(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-120), awaySince: nil, firstOpen: true))
        XCTAssertFalse(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-120), awaySince: now.addingTimeInterval(-600), firstOpen: false))
        // Back after 10 minutes away: hello again. Back after 1 minute: no.
        XCTAssertTrue(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-3600), awaySince: now.addingTimeInterval(-600), firstOpen: false))
        XCTAssertFalse(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-3600), awaySince: now.addingTimeInterval(-60), firstOpen: false))
        // Pulling down Control Center isn't leaving the app.
        XCTAssertFalse(Greeter.shouldGreet(now: now, lastGreeting: now.addingTimeInterval(-3600), awaySince: nil, firstOpen: false))
    }

    func testGreeterWording() {
        XCTAssertEqual(Greeter.partOfDay(hour: 8), "Good morning")
        XCTAssertEqual(Greeter.partOfDay(hour: 13), "Good afternoon")
        XCTAssertEqual(Greeter.partOfDay(hour: 20), "Good evening")
        XCTAssertEqual(Greeter.partOfDay(hour: 2), "Good evening")
        for hour in [2, 8, 13, 20, 23] {
            let lines = Greeter.lines(hour: hour, name: "Storm")
            XCTAssertGreaterThanOrEqual(lines.count, 8, "Enough different ways to say hi")
            XCTAssertEqual(Set(lines).count, lines.count, "The same hello twice at \(hour)")
            XCTAssertTrue(lines.allSatisfy { $0.contains("Storm") }, "Every hello uses your name")
        }
        let noName = Greeter.lines(hour: 9, name: "")
        XCTAssertFalse(noName.contains { $0.contains(", !") || $0.contains(" ,") || $0.contains("  ") }, noName.joined(separator: " / "))
    }

    // MARK: Favorites

    func testReadingFavorites() {
        XCTAssertEqual(Favorites.read("my favorite food is pizza"), Favorites.Item(thing: "food", value: "pizza"))
        XCTAssertEqual(Favorites.read("My favourite colour is blue."), Favorites.Item(thing: "color", value: "blue"))
        XCTAssertEqual(Favorites.read("my favorite game is Minecraft"), Favorites.Item(thing: "game", value: "Minecraft"))
        XCTAssertEqual(Favorites.read("my fav animal is a fox"), Favorites.Item(thing: "animal", value: "fox"))
        XCTAssertEqual(Favorites.read("Minecraft is my favorite game"), Favorites.Item(thing: "game", value: "Minecraft"))
        XCTAssertNil(Favorites.read("my dog is called Max"))
        XCTAssertNil(Favorites.read("I like pizza"))
    }

    func testFavoritesComeUpWhereTheyFit() {
        let items = Favorites.all(["my favorite animal is a fox", "my favorite color is blue", "my dog is called Max"])
        XCTAssertEqual(items.count, 2)
        let fox = Favorites.touched(by: "tell me about foxes", items: items)
        XCTAssertEqual(fox?.item.thing, "animal")
        XCTAssertEqual(fox?.valueSaid, true)
        XCTAssertEqual(Favorites.aside(fox!.item, valueSaid: true), "That's your favorite animal, too!")
        let color = Favorites.touched(by: "what are the primary colors", items: items)
        XCTAssertEqual(color?.item.value, "blue")
        XCTAssertEqual(Favorites.aside(color!.item, valueSaid: false), "Your favorite color is blue, by the way.")
        XCTAssertNil(Favorites.touched(by: "how tall is mount everest", items: items))
    }

    func testFavoritesArentOverdone() {
        let now = Date()
        XCTAssertTrue(Favorites.mayMention(now: now, lastAny: nil, lastThis: nil))
        XCTAssertFalse(Favorites.mayMention(now: now, lastAny: now.addingTimeInterval(-3600), lastThis: nil), "One an hour ago")
        XCTAssertFalse(Favorites.mayMention(now: now, lastAny: now.addingTimeInterval(-86_400), lastThis: now.addingTimeInterval(-86_400)), "Same one yesterday")
        XCTAssertTrue(Favorites.mayMention(now: now, lastAny: now.addingTimeInterval(-86_400), lastThis: now.addingTimeInterval(-5 * 86_400)))
    }

    func testFavoriteFoodsAndGreetings() {
        let items = Favorites.all(["my favorite food is pizza", "my favorite dessert is brownies", "my favorite game is Minecraft"])
        XCTAssertEqual(Favorites.recipe(for: "dinner", items: items)?.id, "homemade-pizza")
        XCTAssertEqual(Favorites.recipe(for: "dessert", items: items)?.id, "brownies")
        XCTAssertNil(Favorites.recipe(for: "breakfast", items: items))
        XCTAssertEqual(Favorites.greetingLine(Favorites.Item(thing: "game", value: "Minecraft")), "Up for some Minecraft today?")
        XCTAssertEqual(Favorites.greetingLine(Favorites.Item(thing: "food", value: "pizza")), "Maybe some pizza later?")
        XCTAssertNil(Favorites.greetingLine(Favorites.Item(thing: "color", value: "blue")))
    }

    // MARK: Mood sounds

    func testMoodSounds() {
        XCTAssertEqual(MoodSound.sfx(from: .idle, to: .listening), .moodListen)
        XCTAssertEqual(MoodSound.sfx(from: .listening, to: .thinking), .moodThink)
        XCTAssertEqual(MoodSound.sfx(from: .thinking, to: .happy), .moodHappy)
        XCTAssertEqual(MoodSound.sfx(from: .thinking, to: .alert), .moodConfused)
        XCTAssertEqual(MoodSound.sfx(from: .idle, to: .sleeping), .moodSleep)
        XCTAssertNil(MoodSound.sfx(from: .happy, to: .happy), "No sound when nothing changes")
        XCTAssertNil(MoodSound.sfx(from: .idle, to: .typing), "Typing is too often for a sound")
        XCTAssertNil(MoodSound.sfx(from: .happy, to: .idle))
        XCTAssertLessThanOrEqual(MoodSound.gain, 0.4, "Mood sounds stay quiet")
        for s in [Sfx.moodListen, .moodThink, .moodHappy, .moodConfused, .moodSleep] {
            XCTAssertNotNil(Bundle.main.url(forResource: s.rawValue, withExtension: "wav"), "\(s.rawValue).wav is missing")
        }
    }
}
