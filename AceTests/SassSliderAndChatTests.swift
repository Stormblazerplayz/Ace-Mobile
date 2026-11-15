import XCTest
@testable import Ace

/// The sass slider (Mild, Spicy, Extra), and chat that must never turn into a web search:
/// banter like "roast me", "search it" with nothing to search, and goodbyes like "I'm gonna leave".
@MainActor
final class SassSliderAndChatTests: XCTestCase {
    var pack: SassPack { .shared }

    // MARK: The slider

    func testSliderSettings() {
        XCTAssertEqual(SassLevel(setting: "mild"), .mild)
        XCTAssertEqual(SassLevel(setting: "spicy"), .spicy)
        XCTAssertEqual(SassLevel(setting: "extra"), .extra)
        XCTAssertEqual(SassLevel(setting: ""), .extra, "Extra is the default")
        XCTAssertEqual(SassLevel(setting: "nonsense"), .extra)
        for level in SassLevel.allCases {
            XCTAssertEqual(SassLevel(setting: level.setting), level)
        }
        XCTAssertEqual(SassLevel.allCases.map(\.title), ["Mild", "Spicy", "Extra"])
        XCTAssertLessThan(SassLevel.mild, SassLevel.extra)
    }

    func testEveryLineIsTagged() {
        for (key, lines) in pack.lines {
            let levels = pack.levels[key] ?? []
            XCTAssertEqual(levels.count, lines.count, key)
            XCTAssertTrue(levels.allSatisfy { (1...3).contains($0) }, key)
            guard !key.hasPrefix("level.") else { continue }
            for level in SassLevel.allCases {
                let mine = zip(lines, levels).filter { level.pool.contains($0.1) }
                XCTAssertGreaterThanOrEqual(mine.count, 3, "\(key) needs lines for \(level.title)")
            }
        }
        for e in pack.answers {
            XCTAssertEqual(e.lv?.count, e.a.count, e.id)
        }
    }

    func testMildLinesAreLight() {
        for key in pack.lines.keys where !key.hasPrefix("level.") {
            for line in pack.linesFor(key, level: .mild) {
                XCTAssertFalse(line.contains("*"), "No stage directions at Mild: \(line)")
                XCTAssertFalse(Sass.hasBannedWord(line), line)
                let shouting = line.split(whereSeparator: { !$0.isLetter }).contains { $0.count >= 3 && $0.allSatisfy(\.isUppercase) }
                XCTAssertFalse(shouting, "No shouting at Mild: \(line)")
            }
        }
    }

    func testEachStopPicksItsOwnLines() {
        let mild = Set(pack.linesFor("answer.open", level: .mild))
        let spicy = Set(pack.linesFor("answer.open", level: .spicy))
        let extra = Set(pack.linesFor("answer.open", level: .extra))
        XCTAssertTrue(mild.isDisjoint(with: spicy))
        XCTAssertTrue(mild.isDisjoint(with: extra), "Extra is the full attitude, no mild lines")
        XCTAssertTrue(spicy.isSubset(of: extra))
        XCTAssertGreaterThan(extra.count, spicy.count)
        XCTAssertTrue(extra.contains("Oh, you need help AGAIN? Shocking."))
        XCTAssertFalse(spicy.contains("Oh, you need help AGAIN? Shocking."), "Shouting is Extra only")
        XCTAssertTrue(mild.contains("Easy one."))
        for _ in 0..<20 {
            XCTAssertTrue(mild.contains(pack.line("answer.open", level: .mild)))
            XCTAssertTrue(spicy.contains(pack.line("answer.open", level: .spicy)))
            XCTAssertTrue(extra.contains(pack.line("answer.open", level: .extra)))
        }
    }

    func testMildIsALightQuipOnSomeReplies() {
        let answer = "The capital of Spain is Madrid."
        let skipped = Sass.dress(answer, category: "answer", repeats: 0, hour: 14, level: .mild, chance: { 0.9 })
        XCTAssertEqual(skipped.text, answer, "Mild lets most replies go by")
        XCTAssertEqual(skipped.eyes, Sass.Eyes.none, "No eye-roll without a quip")
        let quip = Sass.dress(answer, category: "answer", repeats: 0, hour: 14, level: .mild, chance: { 0.2 })
        XCTAssertTrue(pack.linesFor("answer.open", level: .mild).contains(quip.before))
        XCTAssertTrue(quip.after.isEmpty, "No extra line after at Mild")
        XCTAssertTrue(quip.text.contains(answer))
        XCTAssertNotEqual(quip.eyes, .roll, "No big eye-rolls at Mild")
        let again = Sass.dress(answer, category: "answer", repeats: 2, hour: 14, level: .mild, chance: { 0.9 })
        XCTAssertTrue(pack.linesFor("repeat.2", level: .mild).contains(again.before))
        XCTAssertEqual(again.eyes, .side)
    }

    func testSpicyIsMostReplies() {
        let answer = "The capital of Spain is Madrid."
        let line = Sass.dress(answer, category: "answer", repeats: 0, hour: 14, level: .spicy, chance: { 0.5 })
        XCTAssertTrue(pack.linesFor("answer.open", level: .spicy).contains(line.before))
        XCTAssertTrue(line.text.contains(answer))
        let skipped = Sass.dress(answer, category: "answer", repeats: 0, hour: 14, level: .spicy, chance: { 0.95 })
        XCTAssertEqual(skipped.text, answer)
        XCTAssertGreaterThan(Sass.often(.spicy), Sass.often(.mild))
        XCTAssertGreaterThan(Sass.often(.extra), Sass.often(.spicy))
        XCTAssertEqual(Sass.closeOften(.mild), 0)
    }

    func testExtraIsEveryReply() {
        let answer = "The capital of Spain is Madrid."
        for c in [0.0, 0.5, 0.99] {
            let d = Sass.dress(answer, category: "answer", repeats: 0, hour: 14, level: .extra, chance: { c })
            XCTAssertFalse(d.before.isEmpty, "Every reply at Extra")
            XCTAssertTrue(d.text.contains(answer))
        }
        let again = Sass.dress(answer, category: "answer", repeats: 1, hour: 14, level: .extra, chance: { 0.9 })
        XCTAssertEqual(again.eyes, .roll, "Big eye-roll for a repeat")
    }

    func testOrbAndVoiceDramaFollowTheSlider() {
        let mild = Sass.EyeDrama(level: .mild), spicy = Sass.EyeDrama(level: .spicy), extra = Sass.EyeDrama(level: .extra)
        XCTAssertLessThan(mild.size, spicy.size)
        XCTAssertLessThan(spicy.size, extra.size)
        XCTAssertLessThan(mild.hold, extra.hold)
        XCTAssertLessThan(mild.sideHold, extra.sideHold)
        XCTAssertGreaterThan(mild.squint, extra.squint, "A stronger squint at Extra")
        let top = { (d: Sass.EyeDrama) in d.rollPath.map { abs($0.y) }.max() ?? 0 }
        XCTAssertEqual(top(extra), 1.5, accuracy: 0.001, "Extra keeps the full eye-roll")
        XCTAssertLessThan(top(mild), top(extra))
        let quiet = VoiceOut.sassyStyle(drama: 1), loud = VoiceOut.sassyStyle(drama: 3)
        XCTAssertLessThan(quiet.pitch, VoiceOut.sassyStyle(drama: 2).pitch)
        XCTAssertLessThan(VoiceOut.sassyStyle(drama: 2).pitch, loud.pitch)
        XCTAssertGreaterThan(quiet.rate, loud.rate, "Extra drags it out more")
        XCTAssertLessThan(quiet.pause, loud.pause)
        XCTAssertEqual(SpokenPart(text: "Sigh.", language: nil, sassy: true).drama, 3, "Extra by default")
    }

    func testSassySetAnswersFollowTheSlider() async throws {
        let entry = try XCTUnwrap(pack.match("what is the capital of france"))
        let mild = entry.answers(for: .mild)
        XCTAssertEqual(mild.count, 1)
        XCTAssertTrue(mild[0].contains("The capital of France is Paris."))
        XCTAssertFalse(mild[0].contains("*"))
        for a in entry.answers(for: .spicy) + entry.answers(for: .extra) { XCTAssertTrue(a.contains("Paris"), a) }
        XCTAssertTrue(Set(entry.answers(for: .extra)).isDisjoint(with: mild))

        let brain = Brain()
        brain.sassyOverride = true
        brain.sassLevelOverride = .mild
        let r = await brain.respond(to: "what is the capital of France", onThought: { _ in })
        XCTAssertEqual(r.source, "Ace's sassy set")
        XCTAssertEqual(r.text, mild[0])
        // Small talk with no mild version goes to the normal answers at Mild, not an Extra line.
        let whoEntry = try XCTUnwrap(pack.match("who are you"))
        XCTAssertTrue(whoEntry.answers(for: .mild).isEmpty)
        let who = await brain.respond(to: "who are you", onThought: { _ in })
        XCTAssertFalse(whoEntry.a.contains(who.text), who.text)
    }

    func testMildGreetingsAndWhatsNew() {
        let lines = Sass.greetingLines(hour: 9, name: "Storm", level: .mild)
        XCTAssertGreaterThanOrEqual(lines.count, 5)
        for l in lines {
            XCTAssertFalse(l.contains("{"), l)
            XCTAssertFalse(l.contains("*"), l)
        }
        XCTAssertTrue(WhatsNew.intro(build: 53, sassy: true, level: .mild).contains("53"))
        for level in SassLevel.allCases {
            XCTAssertFalse(pack.line("level." + level.setting, level: level).isEmpty, level.title)
        }
    }

    func testChangelogHasBuild53() throws {
        let b53 = try XCTUnwrap(WhatsNew.load().first { $0.build == 53 })
        XCTAssertTrue(b53.items.contains { $0.contains("Sass slider") })
        XCTAssertTrue(b53.items.contains { $0.contains("roast me") })
    }

    func testWhatsNewShowsTheBiggerBrain() throws {
        let releases = WhatsNew.load()
        let brain = try XCTUnwrap(releases.first { $0.build == 55 })
        XCTAssertTrue(brain.items.contains { $0.contains("60,000") })
        XCTAssertEqual(WhatsNew.due(currentBuild: 55, lastShown: 53, releases: releases)?.build, 55)
        XCTAssertNil(WhatsNew.due(currentBuild: 55, lastShown: 55, releases: releases))
        XCTAssertEqual(WhatsNew.due(currentBuild: 56, lastShown: 55, releases: releases)?.build, 56)
        XCTAssertEqual(releases.first?.build, 56, "Newest first")
    }

    func testWhatsNewShowsNewWordings() throws {
        let release = try XCTUnwrap(WhatsNew.load().first { $0.build == 56 })
        XCTAssertTrue(release.items.contains { $0.contains("your own words") })
        XCTAssertTrue(release.items.contains { $0.contains("typos") })
    }

    // MARK: Banter is conversation, never a web search

    static let banter: [(String, Chat.Kind)] = [
        ("Whatever it's not like you can roast me", .roast),
        ("roast me", .roast),
        ("can you roast me", .roast),
        ("roast me ace", .roast),
        ("you can't roast me", .roast),
        ("you're dumb", .insult),
        ("ur stupid", .insult),
        ("you are so annoying lol", .insult),
        ("u suck", .insult),
        ("i hate you", .insult),
        ("nobody asked", .insult),
        ("bet you can't", .dare),
        ("i bet you can't answer this", .dare),
        ("prove it", .dare),
        ("it's not like you know", .dare),
        ("I'm bored", .bored),
        ("im so bored", .bored),
        ("this is boring", .bored),
        ("lol", .laugh),
        ("lmao", .laugh),
        ("hahaha", .laugh),
        ("whatever", .whatever),
        ("bruh", .whatever),
        ("meh", .whatever),
        ("ok cool", .whatever),
        ("who cares", .whatever),
    ]

    func testBanterIsChat() {
        for (text, kind) in Self.banter {
            XCTAssertEqual(Chat.kind(text), kind, text)
            XCTAssertEqual(IntentRouter.parse(text), .chat(kind), text)
            XCTAssertFalse(Chat.isInfoQuestion(text), "Never searched: \(text)")
            XCTAssertFalse(Chat.isGoodbye(text), text)
        }
    }

    func testRealQuestionsAreNotBanter() {
        for text in ["roast a chicken", "how do I roast marshmallows", "what is a pot roast", "how long to roast potatoes",
                     "what is the capital of france", "set a timer for 5 minutes", "tell me a joke",
                     "who is the best soccer player", "what is a bet", "is it boring to study math"] {
            XCTAssertNil(Chat.kind(text), text)
        }
    }

    func testOnlyClearQuestionsGoToTheWeb() {
        for text in ["what is photosynthesis", "how do volcanoes work?", "who invented the telephone",
                     "capital of peru", "tell me about black holes", "why is the sky blue"] {
            XCTAssertTrue(Chat.isInfoQuestion(text), text)
        }
        for text in ["photosynthesis", "it", "the", "it is", "this", "lol", "I'm gonna leave",
                     "I'm going to the store", "you are cool", "Whatever it's not like you can roast me", "ok", ""] {
            XCTAssertFalse(Chat.isInfoQuestion(text), text)
        }
    }

    func testBanterRepliesInNormalMode() async {
        let brain = Brain()
        brain.sassyOverride = false
        for (text, kind) in [("roast me", Chat.Kind.roast), ("you're dumb", .insult), ("I'm bored", .bored), ("lol", .laugh)] {
            let r = await brain.respond(to: text, onThought: { _ in })
            XCTAssertEqual(r.kind, "chat", text)
            XCTAssertTrue(r.chat, text)
            XCTAssertTrue(Chat.lines(kind).contains(r.text), "\(text): \(r.text)")
            XCTAssertTrue(r.cards.isEmpty, "No search card: \(text)")
            XCTAssertNotEqual(r.source, "web")
        }
    }

    func testBanterRepliesInSassyMode() async {
        let brain = Brain()
        brain.sassyOverride = true
        let r = await brain.respond(to: "Whatever it's not like you can roast me", onThought: { _ in })
        XCTAssertEqual(r.source, "Ace's sassy set")
        XCTAssertEqual(r.kind, "sassy")
        XCTAssertTrue(r.cards.isEmpty, "Not a Google search")
        XCTAssertTrue(pack.linesFor("banter.roast", level: .extra).contains(r.text), r.text)
        XCTAssertFalse(Sass.hasBannedWord(r.text), r.text)
        for line in pack.lines["banter.roast", default: []] + pack.lines["banter.insult", default: []] {
            XCTAssertFalse(Sass.hasBannedWord(line), "Roast the situation, not the person: \(line)")
        }
        brain.sassLevelOverride = .mild
        let mild = await brain.respond(to: "it's not like you can roast me", onThought: { _ in })
        XCTAssertTrue(pack.linesFor("banter.roast", level: .mild).contains(mild.text), mild.text)
    }

    func testChatNeverPutsSassOnTop() {
        XCTAssertEqual(Sass.category(kind: "chat", source: "rules", mood: .happy, cards: []), "sassy")
        XCTAssertEqual(Sass.category(kind: "goodbye", source: "rules", mood: .sleeping, cards: []), "bye")
    }

    func testSadThingsDontGetBanter() async {
        let brain = Brain()
        brain.sassyOverride = true
        let r = await brain.respond(to: "nobody likes me", onThought: { _ in })
        XCTAssertNotEqual(r.kind, "chat")
        XCTAssertFalse(pack.lines["banter.whatever", default: []].contains(r.text), r.text)
    }

    // MARK: "Search it"

    func testSearchItUsesTheLastQuestion() {
        XCTAssertEqual(IntentRouter.parse("Search it"), .searchTab(query: "it", site: nil))
        XCTAssertEqual(IntentRouter.parse("look it up"), .searchTab(query: "it", site: nil))
        XCTAssertEqual(IntentRouter.parse("google that"), .searchTab(query: "that", site: nil))
        XCTAssertEqual(IntentRouter.parse("search that up"), .searchTab(query: "that", site: nil))
        XCTAssertEqual(Chat.resolve("it", lastQuestion: "what is photosynthesis"), "what is photosynthesis")
        XCTAssertEqual(Chat.resolve("that", lastQuestion: "who painted the starry night"), "who painted the starry night")
        XCTAssertNil(Chat.resolve("it", lastQuestion: nil), "Nothing to search: ask \"Search what?\"")
        XCTAssertNil(Chat.resolve("it", lastQuestion: ""))
        XCTAssertNil(Chat.resolve("this", lastQuestion: "it"))
        XCTAssertEqual(Chat.resolve("minecraft seeds", lastQuestion: "what is photosynthesis"), "minecraft seeds")
    }

    func testChatDoesntCountAsTheLastQuestion() async {
        let brain = Brain()
        _ = await brain.respond(to: "who painted the starry night", onThought: { _ in })
        XCTAssertEqual(brain.lastInfoQuestion, "who painted the starry night")
        _ = await brain.respond(to: "lol", onThought: { _ in })
        _ = await brain.respond(to: "Whatever it's not like you can roast me", onThought: { _ in })
        _ = await brain.respond(to: "thanks", onThought: { _ in })
        XCTAssertEqual(brain.lastInfoQuestion, "who painted the starry night", "\"Search it\" still means the painting")
        brain.resetConversation()
        XCTAssertEqual(brain.lastInfoQuestion, "")
    }

    // MARK: Goodbyes

    static let goodbyes = [
        "I'm gonna leave", "im gonna leave", "I'm going", "I'm leaving", "I'm leaving now", "gtg", "g2g", "gotta go",
        "I have to go", "I need to go", "bye", "bye ace", "ok bye", "see ya", "see you later", "goodnight",
        "good night ace", "night night", "I'm off to bed", "I'm going to sleep", "peace out", "talk to you later",
        "ttyl", "I'm heading out", "I'm out", "later", "catch you later", "i will be going now", "brb", "ok bye for now",
    ]

    func testGoodbyes() {
        for text in Self.goodbyes {
            XCTAssertTrue(Chat.isGoodbye(text), text)
            XCTAssertEqual(IntentRouter.parse(text), .goodbye, text)
            XCTAssertFalse(Chat.isInfoQuestion(text), "Never searched: \(text)")
        }
        for text in ["I'm going to the store", "how do I leave a discord server", "what does gtg mean",
                     "leave a review", "when is good night moon from", "I'm going to build a house in minecraft"] {
            XCTAssertFalse(Chat.isGoodbye(text), text)
        }
    }

    func testGoodbyeSaysByeAndSleeps() async {
        for sassy in [false, true] {
            let brain = Brain()
            brain.sassyOverride = sassy
            let r = await brain.respond(to: "I'm gonna leave", onThought: { _ in })
            XCTAssertEqual(r.kind, "goodbye")
            XCTAssertEqual(r.mood, .sleeping, "The orb goes to sleep")
            XCTAssertEqual(r.source, "rules")
            XCTAssertTrue(r.cards.isEmpty)
            XCTAssertFalse(r.text.lowercased().contains("desertion"))
        }
        // Sassy mode puts a sassy bye line on it.
        let d = Sass.dress("Bye!", category: "bye", repeats: 0, hour: 14, level: .extra, chance: { 0.5 })
        XCTAssertTrue(pack.linesFor("bye", level: .extra).contains(d.before))
    }
}
