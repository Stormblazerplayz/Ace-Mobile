import AVFoundation
import XCTest
@testable import Ace

/// The homework helper, notes, the talking speed and the shopping list.
@MainActor
final class HelpersTests: XCTestCase {
    // MARK: Exact numbers

    func testRationals() throws {
        let third = try XCTUnwrap(Rational(1, 3))
        let sixth = try XCTUnwrap(Rational(1, 6))
        XCTAssertEqual((third + sixth)?.fractionText, "1/2")
        XCTAssertEqual(Rational(6, -8)?.fractionText, "-3/4")
        XCTAssertNil(Rational(1, 0))
        XCTAssertEqual(Rational(decimal: "2.5")?.fractionText, "5/2")
        XCTAssertEqual(Rational(7, 2)?.decimalText, "3.5")
        XCTAssertEqual(Rational(3, 4)?.decimalText, "0.75")
        XCTAssertEqual(Rational(1, 3)?.decimalText, "about 0.333")
        XCTAssertEqual(Rational(12)?.decimalText, "12")
        XCTAssertNil(Rational.one / Rational.zero)
    }

    // MARK: Solving

    private func solved(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Homework.Solution? {
        let s = Homework.solve(text)
        XCTAssertNotNil(s, "Couldn't solve \(text)", file: file, line: line)
        return s
    }

    func testOrderOfOperations() {
        let s = solved("12 + 7 × 3")
        XCTAssertEqual(s?.problem, "12 + 7 × 3")
        XCTAssertEqual(s?.steps, ["Times: 7 × 3 = 21. Now it's 12 + 21.", "Add: 12 + 21 = 33."])
        XCTAssertEqual(s?.answer, "33")
        XCTAssertEqual(solved("(2 + 3) × 4")?.steps, ["Add: 2 + 3 = 5. Now it's 5 × 4.", "Times: 5 × 4 = 20."])
        XCTAssertEqual(solved("10 - 2 - 3")?.answer, "5")
        XCTAssertEqual(solved("8 ÷ 4 ÷ 2")?.answer, "1")
        XCTAssertEqual(solved("12 ÷ 3 × 2")?.answer, "8")
        XCTAssertEqual(solved("2^3 + 1")?.steps.first, "Do the power first: 2^3 = 8. Now it's 8 + 1.")
        XCTAssertEqual(solved("5 squared")?.answer, "25")
        XCTAssertEqual(solved("7 / 2")?.answer, "3.5")
        XCTAssertEqual(solved("10 divided by 4")?.answer, "2.5")
        XCTAssertEqual(solved("0.5 + 0.25")?.answer, "0.75")
        XCTAssertEqual(solved("5 - -2")?.steps, ["Take away: 5 - (-2) = 7."])
        XCTAssertEqual(solved("12 + 7 x 3 =")?.answer, "33", "A worksheet line ending in = means work it out")
        XCTAssertNil(Homework.solve("8 ÷ 0"))
        XCTAssertNil(Homework.solve("hello there"))
    }

    func testFractions() {
        let add = solved("3/4 + 1/8")
        XCTAssertEqual(add?.problem, "3/4 + 1/8")
        XCTAssertEqual(add?.steps, ["Make the bottoms match: 3/4 = 6/8 and 1/8 = 1/8. Then 6/8 + 1/8 = 7/8."])
        XCTAssertEqual(add?.answer, "7/8")
        XCTAssertEqual(solved("1/3 + 1/6")?.steps.first, "Make the bottoms match: 1/3 = 2/6 and 1/6 = 1/6. Then 2/6 + 1/6 = 3/6. That simplifies to 1/2.")
        let times = solved("2/3 × 3/4")
        XCTAssertEqual(times?.problem, "2/3 × 3/4")
        XCTAssertEqual(times?.steps, ["Times the tops and the bottoms: 2/3 × 3/4 = 6/12. That simplifies to 1/2."])
        XCTAssertEqual(solved("1/2 ÷ 1/4")?.answer, "2")
        XCTAssertEqual(solved("12 ÷ 3/4")?.answer, "16", "÷ divides by the whole fraction")
        XCTAssertEqual(solved("-3/4 + 1")?.answer, "1/4")
        XCTAssertEqual(solved("(1/2)^2")?.steps, ["Do the power first: (1/2)^2 = 1/4."])
    }

    func testPercents() {
        let s = solved("15% of 80")
        XCTAssertEqual(s?.steps, ["15% means 15 out of 100, so it's 15 ÷ 100 = 0.15.", "Now times it by 80: 0.15 × 80 = 12."])
        XCTAssertEqual(s?.answer, "12")
        XCTAssertEqual(solved("50 percent of 30")?.answer, "15")
    }

    func testEquations() {
        let s = solved("2x + 3 = 11")
        XCTAssertEqual(s?.problem, "2x + 3 = 11")
        XCTAssertEqual(s?.steps, ["Take away 3 from both sides: 2x = 8.", "Divide both sides by 2: x = 4.",
                                  "Check: with x = 4, both sides come to 11."])
        XCTAssertEqual(s?.answer, "x = 4")
        XCTAssertEqual(solved("5x - 4 = 2x + 11")?.steps, ["Take away 2x from both sides: 3x - 4 = 11.", "Add 4 to both sides: 3x = 15.",
                                                           "Divide both sides by 3: x = 5.", "Check: with x = 5, both sides come to 21."])
        XCTAssertEqual(solved("3(x + 1) = 12")?.steps.first, "Tidy up each side: 3x + 3 = 12.")
        XCTAssertEqual(solved("3(x + 1) = 12")?.answer, "x = 3")
        XCTAssertEqual(solved("2(x - 3) = x + 4")?.answer, "x = 10")
        XCTAssertEqual(solved("x/2 = 5")?.answer, "x = 10")
        XCTAssertTrue(solved("x/2 = 5")?.steps.contains("Times both sides by 2: x = 10.") ?? false)
        XCTAssertEqual(solved("1/2x = 4")?.problem, "(1/2)x = 4")
        XCTAssertEqual(solved("-3x = 12")?.problem, "-3x = 12")
        XCTAssertEqual(solved("-3x = 12")?.answer, "x = -4")
        XCTAssertEqual(solved("x - 7 = -2")?.answer, "x = 5")
        XCTAssertEqual(solved("0.2x + 1 = 3")?.answer, "x = 10")
        XCTAssertEqual(solved("4y + 2 = 10")?.answer, "y = 2")
        XCTAssertEqual(solved("2x + 1 = 2x + 1")?.answer, "any number")
        XCTAssertEqual(solved("2x + 1 = 2x + 5")?.answer, "no answer")
        XCTAssertNil(Homework.solve("x^2 = 4"), "Squares aren't straight-line equations")
        XCTAssertNil(Homework.solve("2 + 2 = 4"), "Nothing to find")
        XCTAssertNil(Homework.solve("x + y = 4"), "Two unknowns")
        // Every step's answer checks out.
        for (q, x) in [("7x - 2 = 3x + 10", "3"), ("6 - x = 2", "4"), ("5(x - 1) = 2(x + 2)", "3")] {
            XCTAssertEqual(Homework.solve(q)?.answer, "x = \(x)", q)
        }
    }

    // MARK: Reading the ask

    func testProblemsInSentences() {
        let cases: [(String, String?)] = [
            ("solve 2x+3=11", "2x+3=11"),
            ("Can you show me the steps for 3/4 + 1/8?", "3/4 + 1/8"),
            ("what's 12 + 7 x 3 step by step", "12 + 7 x 3"),
            ("how do I solve 5x - 4 = 2x + 11", "5x - 4 = 2x + 11"),
            ("2x + 3 = 11, solve for x", "2x + 3 = 11"),
            ("solve for x: 3x - 7 = 8", "3x - 7 = 8"),
            ("help me with this equation: 4y + 2 = 10", "4y + 2 = 10"),
            ("what is the capital of france", nil),
            ("set a timer for 5 minutes", nil),
        ]
        for (text, want) in cases {
            XCTAssertEqual(Homework.problem(in: text), want, text)
        }
    }

    func testHomeworkRouting() {
        let yes: [(String, String)] = [
            ("solve 2x + 3 = 11", "2x + 3 = 11"),
            ("2x + 3 = 11", "2x + 3 = 11"),
            ("3/4 + 1/8", "3/4 + 1/8"),
            ("what is 3/4 + 1/8", "3/4 + 1/8"),
            ("what is 12 + 7 x 3 step by step", "12 + 7 x 3"),
            ("show me the steps for 15% of 80", "15% of 80"),
            ("help me with my math homework", ""),
            ("can you help me with my homework", ""),
            ("homework help", ""),
        ]
        for (text, problem) in yes {
            XCTAssertEqual(IntentRouter.parse(text), .homework(problem), text)
        }
        // Plain sums stay quick answers.
        XCTAssertEqual(IntentRouter.parse("what is 5 + 3")?.kind, "math")
        XCTAssertEqual(IntentRouter.parse("what's 15 times 4")?.kind, "math")
        XCTAssertEqual(IntentRouter.parse("what is 15% of 80")?.kind, "math")
        XCTAssertNotEqual(IntentRouter.parse("start a homework session")?.kind, "homework")
        // "solve" with something Ace can't do yet still goes to the homework helper, which says what it can do.
        XCTAssertEqual(IntentRouter.parse("solve x^2 = 4")?.kind, "homework")
    }

    func testPhotoMath() {
        let page = "Name: Storm\n1) 12 + 7 × 3 =\n2. 2x - 5 = 9\nPage 2\n2025-11-14"
        XCTAssertEqual(Homework.problems(inText: page, needEquals: true), ["12 + 7 × 3 =", "2x - 5 = 9"])
        let photo = AceCore.photoMath(page, question: "")
        XCTAssertEqual(photo?.cards.map(\.answer), ["33", "x = 7"])
        XCTAssertFalse(photo?.text.contains("{") ?? true)
        XCTAssertNil(AceCore.photoMath("Exit 5\nOpen 9 to 5", question: ""), "No sums in a sign")
        XCTAssertNil(AceCore.photoMath(page, question: "what dog is this"), "A question about something else isn't math")
        XCTAssertEqual(AceCore.photoMath("3/4 + 1/8", question: "can you solve this")?.cards.first?.answer, "7/8")
    }

    func testHomeworkReplies() {
        let brain = Brain()
        let help = brain.homeworkReply("")
        XCTAssertTrue(help.text.contains("2x + 3 = 11") || help.text.contains("3/4 + 1/8"), help.text)
        let r = brain.homeworkReply("2x + 3 = 11")
        XCTAssertTrue(r.text.contains("x = 4"), r.text)
        guard case .steps(let card)? = r.cards.first else { return XCTFail("No steps card") }
        XCTAssertEqual(card.steps.count, 3)
        let cant = brain.homeworkReply("solve x^2 = 4")
        XCTAssertTrue(cant.cards.isEmpty)
        XCTAssertTrue(cant.text.contains("fractions"), cant.text)
    }

    // MARK: Notes

    func testNoteAsks() {
        let cases: [(String, String, String)] = [
            ("take a note: Bring my PE kit tomorrow", "add", "Bring my PE kit tomorrow"),
            ("take a note that the game is at 5", "add", "the game is at 5"),
            ("note: call Grandma", "add", "call Grandma"),
            ("note to self buy batteries", "add", "buy batteries"),
            ("write down Mom said yes", "add", "Mom said yes"),
            ("add pizza night to my notes", "add", "pizza night"),
            ("what are my notes", "list", ""),
            ("read my notes", "list", ""),
            ("delete the note about PE kit", "delete", "pe kit"),
            ("clear my notes", "clear", ""),
            ("delete all my notes", "clear", ""),
        ]
        for (text, action, words) in cases {
            XCTAssertEqual(IntentRouter.parse(text), .note(action: action, text: words), text)
        }
        XCTAssertEqual(IntentRouter.parse("remember that my locker is 42")?.kind, "remember")
        XCTAssertEqual(IntentRouter.parse("remind me to buy milk")?.kind, "reminder")
    }

    func testNotesStore() {
        let store = NotesStore(key: "aceNotes.test")
        store.clearAll()
        defer { store.clearAll() }
        let brain = Brain()
        XCTAssertEqual(brain.notes("list", "", store: store).mood, .idle, "No notes yet")
        _ = brain.notes("add", "bring my PE kit", store: store)
        _ = brain.notes("add", "Call Grandma on Sunday", store: store)
        XCTAssertEqual(store.notes.map(\.text), ["Call Grandma on Sunday", "Bring my PE kit"])
        let list = brain.notes("list", "", store: store).text
        XCTAssertTrue(list.contains("Call Grandma on Sunday") && list.contains("Bring my PE kit"), list)
        XCTAssertEqual(NotesStore(key: "aceNotes.test").notes.count, 2, "Notes are saved")
        let gone = brain.notes("delete", "pe kit", store: store).text
        XCTAssertTrue(gone.contains("Bring my PE kit"), gone)
        XCTAssertEqual(store.notes.count, 1)
        XCTAssertTrue(brain.notes("delete", "homework", store: store).text.contains("homework"))
        let one = brain.notes("list", "", store: store).text
        XCTAssertFalse(one.contains("1 notes"), one)
        XCTAssertTrue(brain.notes("clear", "", store: store).text.contains("1"))
        XCTAssertTrue(store.notes.isEmpty)
    }

    // MARK: Talking speed

    func testVoiceSpeedAsks() {
        let cases: [(String, String)] = [
            ("talk slower", "slower"), ("can you talk a little slower please", "slower"), ("slow down", "slower"),
            ("you're talking too fast", "slower"), ("speak faster", "faster"), ("speed up", "faster"),
            ("talk at normal speed", "normal"), ("reset your voice speed", "normal"),
        ]
        for (text, how) in cases {
            XCTAssertEqual(IntentRouter.parse(text), .voiceSpeed(how), text)
        }
    }

    func testVoiceSpeedChanges() {
        let settings = SettingsStore()
        let saved = settings.voiceSpeed
        defer { settings.voiceSpeed = saved }
        let brain = Brain()
        settings.voiceSpeed = 1
        _ = brain.voiceSpeed("slower", settings: settings)
        XCTAssertEqual(settings.voiceSpeed, 0.85, accuracy: 0.001)
        for _ in 0..<5 { _ = brain.voiceSpeed("slower", settings: settings) }
        XCTAssertEqual(settings.voiceSpeed, SettingsStore.slowestVoice, accuracy: 0.001)
        let limit = brain.voiceSpeed("slower", settings: settings)
        XCTAssertTrue(limit.text.contains("slow"), limit.text)
        _ = brain.voiceSpeed("normal", settings: settings)
        XCTAssertEqual(settings.voiceSpeed, 1, accuracy: 0.001)
        for _ in 0..<10 { _ = brain.voiceSpeed("faster", settings: settings) }
        XCTAssertEqual(settings.voiceSpeed, SettingsStore.fastestVoice, accuracy: 0.001)
        XCTAssertEqual(SettingsStore.voiceSpeedNow, SettingsStore.fastestVoice, accuracy: 0.001)
        XCTAssertLessThanOrEqual(VoiceOut.rate(1.02), AVSpeechUtteranceMaximumSpeechRate)
        XCTAssertGreaterThan(VoiceOut.rate(1.02), AVSpeechUtteranceDefaultSpeechRate, "Fastest is faster than normal")
    }

    // MARK: Shopping list

    func testShoppingAsks() {
        let cases: [(String, String)] = [
            ("add the ingredients to my shopping list", "recipe"),
            ("put the recipe on my grocery list", "recipe"),
            ("make me a shopping list for this recipe", "recipe"),
            ("add milk and eggs to my shopping list", "add:milk and eggs"),
            ("put bread on the shopping list", "add:bread"),
            ("what's on my shopping list", "read"),
            ("read my shopping list", "read"),
        ]
        for (text, what) in cases {
            XCTAssertEqual(IntentRouter.parse(text), .shopping(what), text)
        }
        XCTAssertEqual(IntentRouter.parse("add a reminder to buy milk")?.kind, "reminder")
    }

    func testShoppingSkipsWhatsThere() {
        let r = ShoppingList.split(["2 eggs", "Milk", "the bread", "milk", " "], existing: ["milk", "Bread"])
        XCTAssertEqual(r.new, ["2 eggs"])
        XCTAssertEqual(r.skipped, ["Milk", "the bread", "milk"])
        XCTAssertEqual(Say.singular("You have 1 notes and 2 things"), "You have 1 note and 2 things")
        XCTAssertEqual(Say.singular("Added 11 ingredients"), "Added 11 ingredients")
    }

    // MARK: Replies

    func testNewRepliesFillEverySlot() {
        let slots: [ReplyKey: [String: String]] = [
            .homeworkSteps: ["problem": "2x + 3 = 11", "answer": "x = 4"], .homeworkHelp: ["examples": "3/4 + 1/8"],
            .homeworkCantSolve: ["kinds": "fractions"], .photoMathOne: ["problem": "1 + 1", "answer": "2"], .photoMathMany: ["count": "3"],
            .noteSaved: ["note": "x"], .noteList: ["count": "2", "notes": "x"], .noteListEmpty: [:], .noteDeleted: ["note": "x"],
            .noteNotFound: ["words": "x"], .notesCleared: ["count": "2"], .voiceSpeedSet: ["speed": "slower"],
            .voiceSpeedLimit: ["speed": "slow"], .shoppingAdded: ["count": "3", "recipe": "pancakes", "list": "Shopping"],
            .shoppingAddedItems: ["items": "milk", "list": "Shopping"], .shoppingSkipped: ["count": "2"], .shoppingNoRecipe: [:],
            .shoppingNoAccess: [:], .shoppingListRead: ["count": "2", "items": "milk and eggs"], .shoppingListEmpty: [:],
        ]
        for (key, fill) in slots {
            let all = Say.wordings(key)
            XCTAssertEqual(all.count, 20, key.rawValue)
            for w in all {
                let line = Say.fill(w, fill)
                XCTAssertFalse(line.contains("{"), "\(key.rawValue): \(line)")
            }
        }
    }
}
