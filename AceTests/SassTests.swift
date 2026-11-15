import XCTest
@testable import Ace

/// Sassy mode: its own data set first, then Ace's normal answers with a sassy line, then the web.
/// Lots of attitude, but kid-friendly, and the answer itself never changes.
@MainActor
final class SassTests: XCTestCase {
    var pack: SassPack { .shared }

    // MARK: The sassy data set

    func testSassySetIsAboutTwoThousandStrong() {
        print("SASSY SET: \(pack.size) lines and answers, \(pack.answers.count) questions")
        XCTAssertGreaterThanOrEqual(pack.size, 2000)
        XCTAssertGreaterThanOrEqual(pack.answers.count, 600)
        // Plenty of lines for the things that come up a lot, so they don't repeat.
        for key in ["answer.open", "answer.close", "unknown", "timer", "game", "error", "recipe", "weather", "greeting"] {
            XCTAssertGreaterThanOrEqual(pack.lines[key]?.count ?? 0, 14, key)
        }
        for key in ["repeat.1", "repeat.2", "repeat.3", "hello", "thanks", "math", "script", "homework", "translate",
                    "calendar", "memory", "device", "home", "web", "settings", "bye", "clarify", "correction",
                    "bedtime", "latenight", "whatsnew", "sassy.on", "sassy.off"] {
            XCTAssertGreaterThanOrEqual(pack.lines[key]?.count ?? 0, 3, key)
        }
    }

    func testKidFriendlyNoInsultsOrSwears() {
        var bad: [String] = []
        for (key, lines) in pack.lines {
            for line in lines where Sass.hasBannedWord(line) { bad.append("\(key): \(line)") }
        }
        for e in pack.answers {
            let wrote = ["about", "talk", "joke"].contains(e.topic)
            for a in e.a where Sass.hasBannedWord(a, grimToo: wrote) { bad.append("\(e.id): \(a)") }
        }
        XCTAssertTrue(bad.isEmpty, bad.joined(separator: "\n"))
    }

    func testEveryQuestionFindsItsOwnAnswer() {
        var wrong: [String] = []
        for e in pack.answers {
            for q in e.q where pack.match(q)?.id != e.id {
                wrong.append("\"\(q)\" -> \(pack.match(q)?.id ?? "nothing"), wanted \(e.id)")
            }
        }
        XCTAssertTrue(wrong.isEmpty, wrong.prefix(30).joined(separator: "\n"))
    }

    func testSmallTalkOnlyMatchesItsOwnWording() {
        XCTAssertEqual(pack.match("Hey Ace, how are you?")?.topic, "talk")
        XCTAssertEqual(pack.match("who are you")?.topic, "about")
        XCTAssertEqual(pack.match("tell me a joke")?.topic, "joke")
        XCTAssertNil(pack.match("what is my name"), "Not the answer to \"what is your name\"")
        XCTAssertNil(pack.match("tell me a joke about dogs"))
        XCTAssertNil(pack.match("set a timer for 5 minutes"))
        XCTAssertNil(pack.match("what is the capital of france in 1800"))
    }

    func testSassyFactsAreRight() throws {
        let cases: [(String, String)] = [
            ("what is the capital of France?", "Paris"),
            ("capital of australia", "Canberra"),
            ("whats the capital of canada", "Ottawa"),
            ("what continent is brazil in", "South America"),
            ("how many legs does a spider have", "8 legs"),
            ("how many planets are in the solar system", "8 planets"),
            ("what is the biggest planet", "Jupiter"),
            ("what is a baby kangaroo called", "joey"),
            ("how many sides does a hexagon have", "6 sides"),
            ("what is the chemical symbol for gold", "Au"),
            ("what is the boiling point of water", "100 °C"),
            ("who was the first person on the moon", "Neil Armstrong"),
        ]
        for (q, want) in cases {
            let e = try XCTUnwrap(pack.match(q), q)
            for a in e.a { XCTAssertTrue(a.contains(want), "\(q): \(a)") }
        }
    }

    // MARK: Lookup order: sassy set, then normal answers with a sassy line, then the web

    func testSassySetAnswersFirstInSassyMode() async {
        let brain = Brain()
        brain.sassyOverride = true
        let r = await brain.respond(to: "who are you", onThought: { _ in })
        XCTAssertEqual(r.source, "Ace's sassy set")
        XCTAssertEqual(r.kind, "sassy")
        XCTAssertTrue(pack.match("who are you")?.a.contains(r.text) == true, r.text)
        let capital = await brain.respond(to: "Hello Ace, what is the capital of France?", onThought: { _ in })
        XCTAssertEqual(capital.source, "Ace's sassy set")
        XCTAssertTrue(capital.text.contains("Paris"), capital.text)
    }

    func testNormalModeNeverUsesTheSassySet() async {
        let brain = Brain()
        brain.sassyOverride = false
        let r = await brain.respond(to: "who are you", onThought: { _ in })
        XCTAssertNotEqual(r.source, "Ace's sassy set")
        let capital = await brain.respond(to: "what is the capital of France", onThought: { _ in })
        XCTAssertNotEqual(capital.source, "Ace's sassy set")
        XCTAssertTrue(capital.text.contains("Paris"), capital.text)
    }

    func testFallsBackToNormalAnswersWhenTheSassySetDoesntKnow() async throws {
        let q = "who painted the starry night"
        XCTAssertNil(pack.match(q), "The sassy set doesn't have this one")
        let normal = Brain()
        normal.sassyOverride = false
        let sassy = Brain()
        sassy.sassyOverride = true
        let plain = await normal.respond(to: q, onThought: { _ in })
        let fallback = await sassy.respond(to: q, onThought: { _ in })
        // Same normal answer, from the same normal data set.
        XCTAssertEqual(fallback.source, plain.source)
        XCTAssertTrue(fallback.text.contains("Vincent van Gogh"), fallback.text)
        // Then Sassy mode wraps it, and the answer is still all there.
        let category = Sass.category(kind: fallback.kind, source: fallback.source, mood: fallback.mood, cards: fallback.cards)
        XCTAssertEqual(category, "answer")
        let dressed = Sass.dress(fallback.text, category: category, repeats: 0, hour: 14, chance: { 0 })
        XCTAssertTrue(dressed.text.contains(fallback.text))
        XCTAssertFalse(dressed.before.isEmpty)
        XCTAssertTrue(pack.lines["answer.open"]!.contains(dressed.before))
    }

    func testFollowUpsGoToTheNormalAnswers() {
        XCTAssertTrue(Brain.soundsLikeFollowUp("what continent is it in"))
        XCTAssertFalse(Brain.soundsLikeFollowUp("what continent is brazil in"))
        // Small talk with "it" still counts, because it has to be said word for word.
        XCTAssertEqual(pack.match("how is it going")?.exact, true)
    }

    func testDontKnowGetsAStumpedLine() {
        // What the brain sends back when it's out of ideas.
        let r = BrainReply(text: "I don't know that one yet.", source: "rules", mood: .idle, kind: "dontKnow")
        XCTAssertEqual(Sass.category(kind: r.kind, source: r.source, mood: r.mood, cards: r.cards), "unknown")
        let dressed = Sass.dress(r.text, category: "unknown", repeats: 0, hour: 14, chance: { 0.5 })
        XCTAssertTrue(pack.lines["unknown"]!.contains(dressed.before))
        XCTAssertTrue(dressed.text.hasSuffix(r.text))
        XCTAssertEqual(dressed.eyes, .side)
        XCTAssertFalse(Sass.countsRepeats("unknown"), "No \"didn't I tell you\" after an \"I don't know\"")
    }

    func testJobsSkipTheSassySet() {
        XCTAssertFalse(Brain.sassyFirst(.rule(.timer(seconds: 60, label: "Timer"))))
        XCTAssertFalse(Brain.sassyFirst(.rule(.weather(place: nil))))
        XCTAssertTrue(Brain.sassyFirst(.rule(.greeting)))
        XCTAssertTrue(Brain.sassyFirst(.rule(.thanks)))
        XCTAssertTrue(Brain.sassyFirst(.none))
    }

    // MARK: Sassy lines around answers

    func testDressKeepsTheWholeAnswer() {
        let answer = "The capital of Spain is Madrid."
        for category in ["answer", "unknown", "error", "recipe", "weather", "math", "game", "hello", "device", "home"] {
            let d = Sass.dress(answer, category: category, repeats: 0, hour: 14, chance: { 0.2 })
            XCTAssertTrue(d.text.contains(answer), category)
            XCTAssertFalse(d.before.isEmpty, "\(category) gets a sassy line")
        }
        // Timers get theirs after: "Timer set. Don't burn it this time."
        let timer = Sass.dress("Your 5 minute timer is set.", category: "timer", repeats: 0, hour: 14, chance: { 0.9 })
        XCTAssertTrue(timer.text.hasPrefix("Your 5 minute timer is set."))
        XCTAssertTrue(pack.lines["timer"]!.contains(timer.after))
        // The sassy set's own answers already have attitude.
        let own = Sass.dress("Ugh, fine. It's Paris.", category: "sassy", repeats: 0, hour: 14, chance: { 0.9 })
        XCTAssertEqual(own.text, "Ugh, fine. It's Paris.")
        // Late at night, sometimes a late-night line instead.
        let late = Sass.dress(answer, category: "answer", repeats: 0, hour: 23, chance: { 0.1 })
        XCTAssertTrue(pack.lines["latenight"]!.contains(late.before))
    }

    func testRepeatsGetSassierEachTime() {
        let answer = "The capital of France is Paris."
        let second = Sass.dress(answer, category: "answer", repeats: 1, hour: 14, chance: { 0.9 })
        let third = Sass.dress(answer, category: "answer", repeats: 2, hour: 14, chance: { 0.9 })
        let tenth = Sass.dress(answer, category: "answer", repeats: 9, hour: 14, chance: { 0.9 })
        XCTAssertTrue(pack.lines["repeat.1"]!.contains(second.before))
        XCTAssertTrue(pack.lines["repeat.2"]!.contains(third.before))
        XCTAssertTrue(pack.lines["repeat.3"]!.contains(tenth.before))
        for d in [second, third, tenth] {
            XCTAssertTrue(d.text.contains(answer), "Still the full answer")
            XCTAssertEqual(d.eyes, .roll, "Big eye-roll for a repeat")
        }
    }

    func testRepeatTrackerSpotsTheSameQuestion() {
        var t = RepeatTracker()
        let start = Date()
        XCTAssertEqual(t.note("What's the capital of France?", at: start), 0)
        XCTAssertEqual(t.note("capital of france", at: start.addingTimeInterval(60)), 1)
        XCTAssertEqual(t.note("what is the capital of france", at: start.addingTimeInterval(120)), 2)
        XCTAssertEqual(t.note("what is the capital of spain", at: start.addingTimeInterval(180)), 0)
        XCTAssertEqual(t.note("how are you", at: start.addingTimeInterval(200)), 0)
        XCTAssertEqual(t.note("how are you", at: start.addingTimeInterval(210)), 1)
        // After 30 minutes, it's a fresh question again.
        XCTAssertEqual(t.note("capital of france", at: start.addingTimeInterval(40 * 60)), 0)
        // Games and timers don't count ("yes" twice in 20 questions is normal).
        XCTAssertFalse(Sass.countsRepeats("game"))
        XCTAssertFalse(Sass.countsRepeats("timer"))
        XCTAssertTrue(Sass.countsRepeats("answer"))
        XCTAssertTrue(Sass.countsRepeats("sassy"))
    }

    func testSeriousThingsGetNoSass() {
        XCTAssertTrue(Sass.isSerious("I'm sad today"))
        XCTAssertTrue(Sass.isSerious("I am being bullied at school"))
        XCTAssertTrue(Sass.isSerious("my pet died"))
        XCTAssertTrue(Sass.isSerious("I feel scared"))
        XCTAssertFalse(Sass.isSerious("what is the capital of france"))
        XCTAssertFalse(Sass.isSerious("give me a kill brick script"))
        XCTAssertFalse(Sass.isSerious("set a timer for 5 minutes"))
    }

    func testCategories() {
        XCTAssertEqual(Sass.category(kind: "timer", source: "rules", mood: .happy, cards: []), "timer")
        XCTAssertEqual(Sass.category(kind: "dontKnow", source: "rules", mood: .idle, cards: []), "unknown")
        XCTAssertEqual(Sass.category(kind: "weather", source: "rules", mood: .alert, cards: []), "error")
        XCTAssertEqual(Sass.category(kind: "", source: "trivia", mood: .happy, cards: []), "game")
        XCTAssertEqual(Sass.category(kind: "", source: "answer bank", mood: .happy, cards: []), "answer")
        XCTAssertEqual(Sass.category(kind: "sassy", source: "Ace's sassy set", mood: .happy, cards: []), "sassy")
        XCTAssertEqual(Sass.category(kind: "greeting", source: "rules", mood: .happy, cards: []), "hello")
        XCTAssertEqual(Sass.category(kind: "leader", source: "Wikidata", mood: .happy, cards: []), "answer")
    }

    // MARK: Voice and hello

    func testSpokenLines() {
        XCTAssertEqual(Sass.spoken("*sigh* Fine."), "Sigh. Fine.")
        XCTAssertEqual(Sass.spoken("*hair flip* Of course."), "Of course.")
        XCTAssertEqual(Sass.spoken("Ugh, okay."), "Ugh, okay.")
        XCTAssertEqual(Sass.spoken("2 * 3 * 4 is 24."), "2 * 3 * 4 is 24.", "Math stays")
        for (_, lines) in pack.lines {
            for line in lines { XCTAssertFalse(Sass.spoken(line).contains("*"), line) }
        }
    }

    func testSassySpokenPartsKeepTheirStyle() {
        let part = SpokenPart(text: "Sigh. Fine.", language: nil, sassy: true)
        XCTAssertTrue(part.sassy)
        XCTAssertFalse(SpokenPart(text: "Hi", language: nil).sassy, "Normal lines stay normal")
    }

    func testSassyGreetingLines() {
        let lines = Sass.greetingLines(hour: 9, name: "Storm")
        XCTAssertGreaterThanOrEqual(lines.count, 10)
        for l in lines {
            XCTAssertFalse(l.contains("{"), l)
            XCTAssertFalse(Sass.hasBannedWord(l), l)
        }
        XCTAssertTrue(lines.contains { $0.contains("Good morning") })
        XCTAssertTrue(lines.contains { $0.contains("Storm") })
        XCTAssertGreaterThan(Sass.greetingLines(hour: 23, name: "").count, lines.count, "Late-night extras")
    }

    // MARK: What's new

    func testChangelogHasThisBuild() throws {
        let releases = WhatsNew.load()
        let b52 = try XCTUnwrap(releases.first { $0.build == 52 })
        XCTAssertGreaterThanOrEqual(b52.items.count, 4)
        XCTAssertTrue(b52.items.contains { $0.contains("Sassy mode") })
        XCTAssertTrue(b52.items.contains { $0.contains("What's new") })
        XCTAssertEqual(releases.map(\.build), releases.map(\.build).sorted(by: >), "Newest first")
    }

    func testWhatsNewShowsOncePerBuild() {
        let releases = [WhatsNew.Release(build: 52, date: "2026-11-15", items: ["Sassy mode"]),
                        WhatsNew.Release(build: 51, date: "2026-11-15", items: ["Greeting"])]
        XCTAssertEqual(WhatsNew.due(currentBuild: 52, lastShown: 0, releases: releases)?.build, 52, "First open of the update")
        XCTAssertEqual(WhatsNew.due(currentBuild: 52, lastShown: 51, releases: releases)?.build, 52)
        XCTAssertNil(WhatsNew.due(currentBuild: 52, lastShown: 52, releases: releases), "Only once")
        XCTAssertNil(WhatsNew.due(currentBuild: 53, lastShown: 52, releases: releases), "No new notes, no card")
        XCTAssertNil(WhatsNew.due(currentBuild: 1, lastShown: 0, releases: releases), "Test builds have no notes")
        XCTAssertEqual(WhatsNew.release(forBuild: 60, in: releases)?.build, 52)
    }

    func testWhatsNewWording() {
        XCTAssertEqual(WhatsNew.intro(build: 52, sassy: false), "Here's what's new in build 52.")
        let sassy = WhatsNew.intro(build: 52, sassy: true)
        XCTAssertTrue(sassy.contains("52"), sassy)
        XCTAssertNotEqual(sassy, "Here's what's new in build 52.")
    }

    func testWhatsNewCardSavesWithTheChat() throws {
        let card = AceCard.whatsNew(WhatsNewCard(build: 52, date: "2026-11-15", items: ["Sassy mode"]))
        let data = try JSONEncoder().encode([card])
        XCTAssertEqual(try JSONDecoder().decode([AceCard].self, from: data), [card])
    }
}
