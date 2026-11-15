import XCTest
@testable import Ace

/// Siri and Shortcuts hand Ace plain words, so those words must do the right thing.
@MainActor
final class ShortcutsTests: XCTestCase {
    private func homeName(_ text: String) -> String? {
        if case .home(let cmd) = IntentRouter.parse(text) { return cmd.name }
        return nil
    }

    func testShortcutWordsAreUnderstood() {
        XCTAssertEqual(homeName("start the vacuum"), "home.vacuumStart")
        XCTAssertEqual(homeName("run the goodnight scene"), "home.scene")
        for scene in AceScene.allCases {
            XCTAssertEqual(homeName(scene.command), "home.scene", "\"\(scene.command)\" isn't a scene")
        }
    }

    func testInboxPassesWordsOn() {
        var got: [String] = []
        let inbox = IntentInbox.shared
        inbox.connect { got.append($0) }
        inbox.post("  hello there  ")
        inbox.post("   ")
        inbox.post("start the vacuum")
        XCTAssertEqual(got, ["hello there", "start the vacuum"])
    }
}
