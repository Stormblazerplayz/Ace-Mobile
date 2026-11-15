import XCTest
@testable import Ace

/// "Hey Ace" has to be found in what speech recognition hears, and only as its own words.
final class VoiceTests: XCTestCase {
    private func command(_ text: String) -> String? {
        guard let end = VoiceIn.wakeWordEnd(in: text) else { return nil }
        return VoiceIn.command(after: text, from: end)
    }

    func testWakeWord() {
        XCTAssertEqual(command("Hey Ace turn on the lights"), "turn on the lights")
        XCTAssertEqual(command("so hey ace, what's the time"), "what's the time")
        XCTAssertEqual(command("Hey Ace"), "")
        XCTAssertEqual(command("hey ase start the vacuum"), "start the vacuum")
        XCTAssertNil(command("hey aces are high"))
        XCTAssertNil(command("hello there"))
        XCTAssertNil(command("ace is cool"))
    }

    func testHandsFreeWords() {
        if case .handsFree(let on) = IntentRouter.parse("turn on hands free mode") { XCTAssertTrue(on) } else { XCTFail("hands free on") }
        if case .handsFree(let on) = IntentRouter.parse("stop listening") { XCTAssertFalse(on) } else { XCTFail("stop listening") }
    }
}
