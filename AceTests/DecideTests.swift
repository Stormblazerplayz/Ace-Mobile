import XCTest
@testable import Ace

/// A random number generator that gives the same numbers every time, so tests are repeatable.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@MainActor
final class DecideTests: XCTestCase {
    func testWinnerIsTheSliceUnderThePointer() {
        // Four slices of 90 degrees. Unturned, slice 0 is under the pointer.
        XCTAssertEqual(DecideMath.winner(rotation: 0, count: 4), 0)
        // Turning the wheel clockwise brings the slices from the left (the end of the list) to the top.
        XCTAssertEqual(DecideMath.winner(rotation: 45, count: 4), 3)
        XCTAssertEqual(DecideMath.winner(rotation: 135, count: 4), 2)
        XCTAssertEqual(DecideMath.winner(rotation: 225, count: 4), 1)
        XCTAssertEqual(DecideMath.winner(rotation: 315, count: 4), 0)
        // Full turns don't change the winner.
        XCTAssertEqual(DecideMath.winner(rotation: 45 + 360 * 7, count: 4), 3)
        XCTAssertEqual(DecideMath.winner(rotation: -45, count: 4), 0)
        XCTAssertEqual(DecideMath.winner(rotation: 10, count: 0), 0)
    }

    func testSpinAlwaysLandsOnItsWinner() {
        var rng = SeededRNG(state: 42)
        var rotation = 0.0
        var seen = Set<Int>()
        for count in 2...16 {
            for _ in 0..<40 {
                let spin = DecideMath.spin(from: rotation, count: count, turns: 5, using: &rng)
                XCTAssertTrue((0..<count).contains(spin.winner))
                XCTAssertEqual(DecideMath.winner(rotation: spin.rotation, count: count), spin.winner,
                               "A \(count)-slice wheel should stop on the slice it picked")
                // Always at least five full turns forward, and less than six.
                let travel = spin.rotation - rotation
                XCTAssertGreaterThanOrEqual(travel, 5 * 360)
                XCTAssertLessThan(travel, 6 * 360)
                // Never right on a line between two slices.
                let slice = 360 / Double(count)
                let into = DecideMath.positive(-spin.rotation).truncatingRemainder(dividingBy: slice) / slice
                XCTAssertGreaterThan(into, 0.1)
                XCTAssertLessThan(into, 0.9)
                if count == 6 { seen.insert(spin.winner) }
                rotation = spin.rotation
            }
        }
        XCTAssertEqual(seen.count, 6, "Every slice can win")
    }

    func testSpinWithNoChoicesStaysPut() {
        var rng = SeededRNG(state: 1)
        let spin = DecideMath.spin(from: 30, count: 0, using: &rng)
        XCTAssertEqual(spin.rotation, 30)
        XCTAssertEqual(spin.winner, 0)
    }

    func testDiceRollOneToSix() {
        var rng = SeededRNG(state: 7)
        let rolls = DecideMath.roll(600, using: &rng)
        XCTAssertEqual(rolls.count, 600)
        XCTAssertTrue(rolls.allSatisfy { (1...6).contains($0) })
        XCTAssertEqual(Set(rolls), Set(1...6), "Every face comes up")
        XCTAssertEqual(DecideMath.roll(0, using: &rng), [])
        XCTAssertEqual(DecideMath.roll(-3, using: &rng), [])
    }

    func testDieFacesHaveTheRightNumberOfDots() {
        for value in 1...6 {
            XCTAssertEqual(DecideDie.spots(value).count, value)
            XCTAssertTrue(DecideDie.spots(value).allSatisfy { (0...8).contains($0) })
        }
        XCTAssertEqual(DecideDie.spots(0), [])
    }

    func testCoinShowsTheRightSide() {
        XCTAssertTrue(DecideSpinningCoin.showsHeads(0))
        XCTAssertFalse(DecideSpinningCoin.showsHeads(180))
        XCTAssertTrue(DecideSpinningCoin.showsHeads(1440))
        XCTAssertFalse(DecideSpinningCoin.showsHeads(1440 + 180))
        XCTAssertTrue(DecideSpinningCoin.showsHeads(80))
        XCTAssertFalse(DecideSpinningCoin.showsHeads(100))
    }

    func testTeamsAreEvenAndKeepEveryone() {
        var rng = SeededRNG(state: 99)
        let names = ["Ava", "Ben", "Cam", "Dev", "Eli", "Fay", "Gus"]
        let teams = DecideMath.teams(names, into: 3, using: &rng)
        XCTAssertEqual(teams.count, 3)
        XCTAssertEqual(teams.map(\.count).sorted(), [2, 2, 3])
        XCTAssertEqual(teams.flatMap { $0 }.sorted(), names.sorted())
    }

    func testTeamsCleanUpNames() {
        var rng = SeededRNG(state: 5)
        let teams = DecideMath.teams(["  Ava ", "ava", "", "Ben", "   "], into: 4, using: &rng)
        // Two real people, so at most two teams of one.
        XCTAssertEqual(teams.count, 2)
        XCTAssertEqual(teams.flatMap { $0 }.sorted(), ["Ava", "Ben"])
        XCTAssertEqual(DecideMath.teams([], into: 3, using: &rng), [[]])
    }

    func testTeamsAreShuffled() {
        var rng = SeededRNG(state: 2026)
        let names = (1...12).map { "Player \($0)" }
        var firsts = Set<String>()
        for _ in 0..<20 { firsts.insert(DecideMath.teams(names, into: 2, using: &rng)[0][0]) }
        XCTAssertGreaterThan(firsts.count, 3, "Teams shouldn't come out the same every time")
    }

    func testCleanNames() {
        let long = String(repeating: "x", count: 50)
        XCTAssertEqual(DecideMath.cleanNames([" Pizza ", "pizza", "", "Tacos", long]),
                       ["Pizza", "Tacos", String(repeating: "x", count: DecideStore.maxOption)])
    }

    func testStoreStartsWithStarterWheels() {
        let store = DecideStore(fileName: nil)
        XCTAssertEqual(store.wheels.map(\.title), DecideStore.starters.map { $0.title })
        XCTAssertTrue(store.wheels.allSatisfy { $0.options.count >= 2 })
        XCTAssertTrue(store.history.isEmpty)
    }

    func testAddingAWheelNeedsTwoChoices() {
        let store = DecideStore(fileName: nil)
        XCTAssertNil(store.add(title: "Lonely", options: ["Only one", " only one "]))
        let made = store.add(title: "   ", options: ["Red", "Blue", "", "red"])
        XCTAssertEqual(made?.title, "My wheel")
        XCTAssertEqual(made?.options, ["Red", "Blue"])
        XCTAssertEqual(store.wheels.last?.id, made?.id)

        let many = store.add(title: "Big", options: (1...30).map { "Choice \($0)" })
        XCTAssertEqual(many?.options.count, DecideStore.maxOptions)
    }

    func testEditingAndDeletingWheels() throws {
        let store = DecideStore(fileName: nil)
        let wheel = try XCTUnwrap(store.add(title: "Snacks", options: ["Chips", "Fruit"]))
        XCTAssertFalse(store.setOptions(wheel.id, ["Just one"]))
        XCTAssertEqual(store.wheel(wheel.id)?.options, ["Chips", "Fruit"])
        XCTAssertTrue(store.setOptions(wheel.id, ["Popcorn", "Pretzels", "Grapes"]))
        XCTAssertEqual(store.wheel(wheel.id)?.options, ["Popcorn", "Pretzels", "Grapes"])

        store.rename(wheel.id, to: "  ")
        XCTAssertEqual(store.wheel(wheel.id)?.title, "Snacks", "A blank name is ignored")
        store.rename(wheel.id, to: "After school snacks")
        XCTAssertEqual(store.wheel(wheel.id)?.title, "After school snacks")

        store.delete(wheel.id)
        XCTAssertNil(store.wheel(wheel.id))
        XCTAssertFalse(store.setOptions(wheel.id, ["A", "B"]))
    }

    func testHistoryKeepsTheNewestTwelve() {
        let store = DecideStore(fileName: nil)
        store.remember("   ")
        XCTAssertTrue(store.history.isEmpty)
        for i in 1...15 { store.remember("Pick \(i)") }
        XCTAssertEqual(store.history.count, DecideStore.maxHistory)
        XCTAssertEqual(store.history.first, "Pick 15")
        XCTAssertEqual(store.history.last, "Pick 4")
        store.clearHistory()
        XCTAssertTrue(store.history.isEmpty)
    }

    func testWheelsAreSaved() throws {
        let name = "decide-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let first = DecideStore(fileName: name)
        let wheel = try XCTUnwrap(first.add(title: "Weekend", options: ["Park", "Pool"]))
        first.remember("Weekend: Pool")

        let again = DecideStore(fileName: name)
        XCTAssertEqual(again.wheel(wheel.id)?.options, ["Park", "Pool"])
        XCTAssertEqual(again.history, ["Weekend: Pool"])
    }

    func testWhatsNewMentionsPickForMe() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 60 }) else {
            return XCTFail("Build 60 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Pick for me") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
