import XCTest
@testable import Ace

/// Everyday chat gets a reply that fits what was said: "yo what up" gets a what's-up line,
/// never the "whatever" line, in Normal and Sassy mode alike.
@MainActor
final class ChatMatchTests: XCTestCase {
    let pack = SassPack.shared

    static let lines: [(String, Chat.Kind)] = [
        // What's up
        ("Yo what up", .whatsUp),
        ("what up", .whatsUp),
        ("yo what's up bro", .whatsUp),
        ("wassup", .whatsUp),
        ("whats good", .whatsUp),
        ("wyd", .whatsUp),
        ("what are you doing", .whatsUp),
        ("what are you up to", .whatsUp),
        ("what's new", .whatsUp),
        ("sup bro", .whatsUp),
        // How are you
        ("how are you", .howAreYou),
        ("how are you doing", .howAreYou),
        ("how's it going", .howAreYou),
        ("hows your day", .howAreYou),
        ("you good?", .howAreYou),
        ("are you okay", .howAreYou),
        ("how have you been", .howAreYou),
        ("how was your day", .howAreYou),
        // Hello
        ("heyy", .hello),
        ("hiii", .hello),
        ("yo yo", .hello),
        ("heya", .hello),
        ("I'm back", .hello),
        ("long time no see", .hello),
        ("nice to meet you", .hello),
        ("hey bro", .hello),
        ("hello friend", .hello),
        // Compliments
        ("you're awesome", .compliment),
        ("you're really cool", .compliment),
        ("you are so smart", .compliment),
        ("ur the goat", .compliment),
        ("good job", .compliment),
        ("nice work", .compliment),
        ("you rock", .compliment),
        ("i love you", .compliment),
        ("well done", .compliment),
        ("you are funny", .compliment),
        // Sorry
        ("sorry", .sorry),
        ("my bad", .sorry),
        ("oops", .sorry),
        ("i'm sorry", .sorry),
        ("sorry about that", .sorry),
        // Laughing
        ("lol", .laugh),
        ("lmao", .laugh),
        ("hahaha", .laugh),
        // Whatever
        ("whatever", .whatever),
        ("bruh", .whatever),
        ("meh", .whatever),
        ("ok cool", .whatever),
        // Roasts, insults, dares, bored
        ("roast me", .roast),
        ("you're dumb", .insult),
        ("bet you can't", .dare),
        ("I'm bored", .bored),
    ]

    /// Sassy-set answers that fit each kind of chat (said word for word, like "how are you").
    static let fittingSassyAnswers: [Chat.Kind: Set<String>] = [
        .whatsUp: ["talk-25"],
        .howAreYou: ["talk-24"],
        .compliment: ["about-20", "about-21", "about-23"],
        .sorry: ["talk-31"],
        .laugh: ["about-23"],
        .roast: ["talk-35"],
        .insult: ["about-22"],
        .bored: ["talk-26"],
    ]

    func testThereAreAtLeast40Lines() {
        XCTAssertGreaterThanOrEqual(Self.lines.count, 40)
    }

    func testEachLineIsTheRightKindOfChat() {
        for (text, kind) in Self.lines {
            let plain = IntentRouter.withoutGreeting(text)
            XCTAssertEqual(Chat.kind(plain), kind, text)
            XCTAssertEqual(IntentRouter.parse(plain), .chat(kind), text)
            XCTAssertFalse(Chat.isInfoQuestion(text), "Never searched: \(text)")
            XCTAssertFalse(Chat.isGoodbye(text), text)
        }
    }

    func testYoWhatUpIsNotWhatever() {
        XCTAssertEqual(Chat.kind("Yo what up"), .whatsUp)
        XCTAssertNotEqual(Chat.kind("yo what up"), .whatever)
        XCTAssertEqual(Chat.kind("whatever"), .whatever, "\"whatever\" itself still gets the whatever line")
    }

    func testRealQuestionsStayQuestions() {
        for text in ["how are you made", "what's up with the weather", "what is good for a cold", "sorry in spanish",
                     "how are you in french", "what is new in ios 18", "is it good to sleep late", "your homework is due",
                     "what does wyd mean", "how was the pyramid built", "what are you doing to the bank"] {
            XCTAssertNil(Chat.kind(text), text)
        }
    }

    func testEveryKindHasItsOwnLines() {
        for kind in Chat.Kind.allCases {
            XCTAssertGreaterThanOrEqual(Chat.lines(kind).count, 3, kind.rawValue)
            for level in SassLevel.allCases {
                let lines = pack.linesFor("banter." + kind.rawValue, level: level)
                XCTAssertGreaterThanOrEqual(lines.count, 3, "\(kind.rawValue) at \(level.title)")
                for line in lines {
                    XCTAssertFalse(Sass.hasBannedWord(line), line)
                }
            }
        }
        // The what's-up lines are about what's up, and the whatever lines stay apart from them.
        let whatsUp = Set(pack.lines["banter.whatsup", default: []])
        XCTAssertTrue(whatsUp.contains("Not much, just being smarter than you. What's up with YOU?"))
        XCTAssertTrue(whatsUp.isDisjoint(with: pack.lines["banter.whatever", default: []]))
    }

    func testEverydayChatFitsInSassyMode() async {
        let brain = Brain()
        brain.sassyOverride = true
        for (text, kind) in Self.lines {
            brain.resetConversation()
            let plain = IntentRouter.withoutGreeting(text)
            var fits = Set(pack.lines["banter." + kind.rawValue, default: []])
            if let entry = pack.match(plain) {
                XCTAssertTrue(Self.fittingSassyAnswers[kind, default: []].contains(entry.id),
                              "\"\(text)\" matched the sassy answer \(entry.id), which isn't about \(kind.rawValue)")
                fits.formUnion(entry.a)
            }
            let r = await brain.respond(to: text, onThought: { _ in })
            XCTAssertTrue(fits.contains(r.text), "\"\(text)\" (\(kind.rawValue)) got: \(r.text)")
            XCTAssertEqual(r.kind, "sassy", text)
            XCTAssertTrue(r.cards.isEmpty, "No search card: \(text)")
            XCTAssertNotEqual(r.source, "web", text)
            if kind != .whatever {
                XCTAssertFalse(pack.lines["banter.whatever", default: []].contains(r.text), "\"\(text)\" got a whatever line")
            }
        }
    }

    func testYoWhatUpGetsASassyWhatsUp() async {
        let brain = Brain()
        brain.sassyOverride = true
        for level in SassLevel.allCases {
            brain.sassLevelOverride = level
            let r = await brain.respond(to: "Yo what up", onThought: { _ in })
            XCTAssertTrue(pack.linesFor("banter.whatsup", level: level).contains(r.text), "\(level.title): \(r.text)")
            XCTAssertFalse(r.text.contains("WHATEVER"), r.text)
        }
    }

    func testEverydayChatFitsInNormalMode() async {
        let brain = Brain()
        brain.sassyOverride = false
        for (text, kind) in Self.lines {
            brain.resetConversation()
            // A few, like "you're awesome", keep their hand-made answer from the bank.
            if case .bank(let id) = brain.understand(text) {
                XCTAssertTrue(id.hasPrefix("feelings."), "\"\(text)\" got the bank answer \(id)")
                continue
            }
            let r = await brain.respond(to: text, onThought: { _ in })
            XCTAssertTrue(Chat.lines(kind).contains(r.text), "\"\(text)\" (\(kind.rawValue)) got: \(r.text)")
            XCTAssertEqual(r.kind, "chat", text)
            XCTAssertTrue(r.cards.isEmpty, "No search card: \(text)")
        }
    }

    func testSmallTalkNeverGetsAWrongBankAnswer() {
        let brain = Brain()
        brain.bank.loadKnowledgeNow()
        for text in ["Yo what up", "how are you", "what are you doing", "sorry", "i'm sorry", "nice to meet you", "yo yo"] {
            brain.resetConversation()
            XCTAssertEqual(brain.understand(text), .skill("chat"), "\(text): not a yo-yo or \"how old are you\"")
        }
        XCTAssertEqual(brain.understand("you're really cool"), .bank("feelings.you-re-awesome"))
        XCTAssertEqual(brain.understand("i love you"), .bank("feelings.i-love-you"))
    }

    func testGreetingsThanksAndGoodbyes() {
        for text in ["hi", "hello", "hey", "hey there", "hi there", "howdy there", "good morning"] {
            XCTAssertEqual(IntentRouter.parse(text), .greeting, text)
        }
        for text in ["thanks", "thank you", "thank you so much", "thanks a lot ace", "ty", "thx", "thanks for the help",
                     "much appreciated", "thank you ace"] {
            XCTAssertEqual(IntentRouter.parse(text), .thanks, text)
        }
        for text in ["bye", "gtg", "see ya", "goodnight", "I'm gonna leave"] {
            XCTAssertEqual(IntentRouter.parse(text), .goodbye, text)
        }
    }

    // MARK: The Apple Home message only comes from asking about home or lights

    func testSassyModeIsNotAHomeScene() {
        XCTAssertEqual(IntentRouter.parse("turn on sassy mode"), .personality(true))
        XCTAssertEqual(IntentRouter.parse("start sassy mode"), .personality(true))
        XCTAssertEqual(IntentRouter.parse("sassy mode on"), .personality(true))
        XCTAssertEqual(IntentRouter.parse("turn off sassy mode"), .personality(false))
        XCTAssertEqual(IntentRouter.parse("go back to normal mode"), .personality(false))
        XCTAssertEqual(IntentRouter.parse("be normal"), .personality(false))
        // Real scenes still go to Apple Home.
        for text in ["movie mode", "run the goodnight scene"] {
            guard case .home(let h)? = IntentRouter.parse(text), case .scene = h.action else {
                return XCTFail("\(text) should still be an Apple Home scene")
            }
        }
    }

    func testChatNeverAsksAppleHome() {
        let chat = Self.lines.map(\.0) + ["hi", "thanks", "bye", "turn on sassy mode", "turn off sassy mode",
                                          "turn on hands free mode", "sassy mode", "be sassy"]
        for text in chat {
            let kind = IntentRouter.parse(IntentRouter.withoutGreeting(text))?.kind ?? ""
            XCTAssertFalse(kind.hasPrefix("home"), "\"\(text)\" went to Apple Home")
        }
    }
}
