import XCTest
@testable import Ace

/// Ace's built-in Roblox Lua, C++, Python and Swift scripts: the library, finding the right one, and the colored code.
@MainActor
final class ScriptLibraryTests: XCTestCase {
    func testLibraryIsComplete() {
        let all = ScriptLibrary.all
        XCTAssertGreaterThanOrEqual(all.filter { $0.language == "Lua" }.count, 25)
        XCTAssertGreaterThanOrEqual(all.filter { $0.language == "C++" }.count, 20)
        XCTAssertGreaterThanOrEqual(all.filter { $0.language == "Python" }.count, 20)
        XCTAssertGreaterThanOrEqual(all.filter { $0.language == "Swift" }.count, 20)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "Two scripts share an id")
        for s in all {
            XCTAssertFalse(s.title.isEmpty, s.id)
            XCTAssertFalse(s.`where`.isEmpty, s.id)
            XCTAssertFalse(s.about.isEmpty, s.id)
            XCTAssertGreaterThanOrEqual(s.keywords.count, 3, s.id)
            XCTAssertGreaterThan(s.code.count, 40, s.id)
            XCTAssertTrue(ScriptLibrary.languages.contains(s.language), s.id)
        }
        for c in ["Arduino", "Basics", "Games", "Unreal Engine"] { XCTAssertTrue(ScriptLibrary.categories("C++").contains(c), c) }
        XCTAssertTrue(ScriptLibrary.categories("Python").contains("Games"))
        XCTAssertFalse(ScriptLibrary.categories("Swift").isEmpty)
        XCTAssertTrue(ScriptLibrary.categories("Lua").contains("Obstacles"))
        XCTAssertTrue(ScriptLibrary.script(id: "kill-brick")?.code.contains("humanoid.Health = 0") ?? false)
    }

    func testFindsTheRightScript() {
        let cases: [(String, String)] = [
            ("give me a kill brick script", "kill-brick"),
            ("C++ servo code", "arduino-servo-sweep"),
            ("lua script for a moving part", "moving-part"),
            ("can you write me a roblox script that makes a part spin", "spinning-part"),
            ("door script", "touch-door"),
            ("saving script", "leaderstats-saving"),
            ("arduino code to blink an led", "arduino-blink"),
            ("c++ tic tac toe code", "cpp-tic-tac-toe"),
            ("write a hangman game in c++", "cpp-hangman"),
            ("unreal engine jump pad code", "unreal-launch-pad"),
            ("give me a jump pad script", "jump-pad"),
            ("coin script", "coin-pickup"),
            ("script for a sword", "sword"),
            ("how do i make a leaderboard that saves in roblox", "leaderstats-saving"),
            ("roblox day and night cycle script", "day-night-cycle"),
            ("arduino ultrasonic sensor code", "arduino-ultrasonic-distance"),
            ("kill brick in unreal c++", "unreal-kill-volume"),
            ("script for teleporting", "teleporter"),
            ("make a timer script", "round-timer"),
            ("roblox script for a zombie that chases you", "follow-npc"),
            ("c++ number guessing game", "cpp-number-guessing"),
            ("i need a checkpoint script", "checkpoints"),
            ("lua double jump", "double-jump"),
            ("give me a conveyor belt script", "conveyor-belt"),
            ("arduino traffic light code", "arduino-traffic-light"),
            ("show me c++ code for a calculator", "cpp-calculator"),
            ("c++ rock paper scissors", "cpp-rock-paper-scissors"),
            ("script for a speed boost", "speed-pad"),
            ("rising lava script", "rising-lava"),
            ("neopixel rainbow arduino code", "arduino-neopixel-rainbow"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(ScriptLibrary.find(text)?.script.id, want, text)
            XCTAssertEqual(IntentRouter.parse(text)?.kind, "script", text)
        }
    }

    func testOtherQuestionsAreNotScripts() {
        for text in ["what is lua", "what is coding", "what is c++", "what is roblox studio", "what is a computer program",
                     "california postal code", "set a timer for 5 minutes", "turn on the lamp", "make it spicier",
                     "write me a python script", "give me code for a website", "what is the code for wifi", "how do i code"] {
            XCTAssertNotEqual(IntentRouter.parse(text)?.kind, "script", text)
        }
    }

    func testListAndWhichOne() {
        XCTAssertEqual(ScriptLibrary.listAsk("what scripts do you have"), "")
        XCTAssertEqual(ScriptLibrary.listAsk("show me your roblox scripts"), "Lua")
        XCTAssertEqual(ScriptLibrary.listAsk("do you have any arduino code"), "C++")
        XCTAssertNil(ScriptLibrary.listAsk("give me a kill brick script"))
        XCTAssertEqual(ScriptLibrary.needsOne("give me a script"), "")
        XCTAssertEqual(ScriptLibrary.needsOne("can you write me a roblox script"), "Lua")
        XCTAssertEqual(ScriptLibrary.needsOne("i need a c++ program"), "C++")
        XCTAssertNil(ScriptLibrary.needsOne("give me a jump pad script"))
        for text in ["what scripts do you have", "give me a script", "show me your c++ code"] {
            XCTAssertEqual(IntentRouter.parse(text)?.kind, "script", text)
        }
    }

    func testBrainKnowsScripts() {
        let brain = Brain()
        XCTAssertEqual(brain.understand("give me a kill brick script"), .skill("script"))
        XCTAssertEqual(brain.understand("C++ servo code"), .skill("script"))
    }

    func testSpokenNames() {
        XCTAssertEqual(ScriptLibrary.spokenName("Kill Volume (Kill Brick)"), "kill volume")
        XCTAssertEqual(ScriptLibrary.spokenName("Classes and Objects: a Pet"), "classes and objects")
        XCTAssertEqual(ScriptLibrary.spokenName("Blink an LED"), "blink an LED")
        XCTAssertEqual(ScriptLibrary.spokenName("NPC that follows players"), "NPC that follows players")
    }

    func testStems() {
        XCTAssertEqual(ScriptLibrary.stem("spinning"), ScriptLibrary.stem("spin"))
        XCTAssertEqual(ScriptLibrary.stem("spins"), ScriptLibrary.stem("spin"))
        XCTAssertEqual(ScriptLibrary.stem("moving"), ScriptLibrary.stem("move"))
        XCTAssertEqual(ScriptLibrary.stem("teleporting"), ScriptLibrary.stem("teleport"))
        XCTAssertEqual(ScriptLibrary.stem("saves"), ScriptLibrary.stem("saving"))
    }

    // MARK: Colors

    func testColoredPiecesGiveBackTheCode() {
        for s in ScriptLibrary.all {
            let pieces = CodeHighlighter.pieces(s.code, language: s.language)
            XCTAssertEqual(pieces.map(\.text).joined(), s.code, s.id)
        }
    }

    func testLuaColors() {
        let code = "local x = 5 -- five\nprint(\"hi\" .. x)\n"
        let p = CodeHighlighter.pieces(code, language: "Lua")
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "local", kind: .keyword)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "5", kind: .number)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "-- five", kind: .comment)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "\"hi\"", kind: .string)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "print", kind: .builtin)))
        XCTAssertEqual(p.map(\.text).joined(), code)
    }

    func testCppColors() {
        let code = "#include <iostream>\nint main() {\n    // say hi\n    std::cout << \"hi\" << 42;\n    return 0;\n}\n"
        let p = CodeHighlighter.pieces(code, language: "C++")
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "#include <iostream>", kind: .preprocessor)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "int", kind: .keyword)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "// say hi", kind: .comment)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "\"hi\"", kind: .string)))
        XCTAssertTrue(p.contains(CodeHighlighter.Piece(text: "42", kind: .number)))
        XCTAssertEqual(p.map(\.text).joined(), code)
    }
}
