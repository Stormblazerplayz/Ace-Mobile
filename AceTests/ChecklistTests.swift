import XCTest
@testable import Ace

@MainActor
final class ChecklistTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeStore() -> ChecklistStore {
        ChecklistStore(fileName: nil)
    }

    private func texts(_ store: ChecklistStore, _ id: UUID) -> [String] {
        store.list(id)?.items.map(\.text) ?? []
    }

    func testBlankNamesAreNumbered() {
        let store = makeStore()
        XCTAssertEqual(store.create(title: "  ", symbol: "checklist", tint: .blue).title, "List 1")
        XCTAssertEqual(store.create(title: "", symbol: "checklist", tint: .blue).title, "List 2")
        store.create(title: "List 7", symbol: "checklist", tint: .blue)
        XCTAssertEqual(store.nextTitle(), "List 8")
        let long = store.create(title: String(repeating: "z", count: 90), symbol: "nope", tint: .red)
        XCTAssertEqual(long.title.count, ChecklistStore.maxTitle)
        XCTAssertEqual(long.symbol, ChecklistStore.symbols[0])
    }

    func testPastingAListMakesOneItemPerLine() {
        let store = makeStore()
        let list = store.create(title: "Trip", symbol: "airplane", tint: .blue)
        let added = store.add("- Passport\n• Charger\n\n   \n* Snacks\n[ ] Hoodie\nBook", to: list.id)
        XCTAssertEqual(added, 5)
        XCTAssertEqual(texts(store, list.id), ["Passport", "Charger", "Snacks", "Hoodie", "Book"])
        XCTAssertEqual(store.add("   \n  ", to: list.id), 0)
        XCTAssertEqual(store.add("x", to: UUID()), 0)
    }

    func testTickedThingsSinkAndUntickedOnesRise() {
        let store = makeStore()
        let list = store.create(title: "Bag", symbol: "backpack.fill", tint: .green, items: ["A", "B", "C"])
        let a = store.list(list.id)!.items[0].id
        store.toggle(a, in: list.id)
        XCTAssertEqual(texts(store, list.id), ["B", "C", "A"])
        XCTAssertEqual(store.list(list.id)?.doneCount, 1)
        // New things go above the ticked ones.
        store.add("D", to: list.id)
        XCTAssertEqual(texts(store, list.id), ["B", "C", "D", "A"])
        store.toggle(a, in: list.id)
        XCTAssertEqual(texts(store, list.id), ["B", "C", "D", "A"])
        XCTAssertEqual(store.list(list.id)?.doneCount, 0)
    }

    func testProgressAndComplete() {
        let store = makeStore()
        let list = store.create(title: "Morning", symbol: "sunrise.fill", tint: .pink, items: ["Bed", "Teeth"])
        XCTAssertEqual(store.list(list.id)?.progress, 0)
        XCTAssertFalse(store.list(list.id)!.isComplete)
        for item in store.list(list.id)!.items { store.toggle(item.id, in: list.id) }
        XCTAssertEqual(store.list(list.id)?.progress, 1)
        XCTAssertTrue(store.list(list.id)!.isComplete)
        let empty = store.create(title: "Empty", symbol: "checklist", tint: .blue)
        XCTAssertFalse(empty.isComplete, "An empty list isn't done")
        XCTAssertEqual(empty.progress, 0)
    }

    func testResetAndClearDone() {
        let store = makeStore()
        let list = store.create(title: "Beach", symbol: "sun.max.fill", tint: .orange, items: ["Towel", "Hat", "Sunscreen"])
        let first = store.list(list.id)!.items[0].id
        store.toggle(first, in: list.id)
        store.reset(list.id)
        XCTAssertEqual(store.list(list.id)?.doneCount, 0)
        XCTAssertEqual(store.list(list.id)?.items.count, 3)
        store.toggle(first, in: list.id)
        store.clearDone(list.id)
        XCTAssertEqual(texts(store, list.id), ["Hat", "Sunscreen"])
    }

    func testRenameRemoveAndMove() {
        let store = makeStore()
        let list = store.create(title: "Room", symbol: "house.fill", tint: .red, items: ["One", "Two", "Three"])
        let ids = store.list(list.id)!.items.map(\.id)
        store.rename(ids[0], in: list.id, to: "  First  ")
        XCTAssertEqual(texts(store, list.id).first, "First")
        store.rename(ids[1], in: list.id, to: "   ")
        XCTAssertEqual(texts(store, list.id), ["First", "Three"], "Blank words delete it")
        store.move(in: list.id, from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(texts(store, list.id), ["Three", "First"])
        store.remove(ids[0], from: list.id)
        XCTAssertEqual(texts(store, list.id), ["Three"])
    }

    func testChangesMoveAListToTheTop() {
        let store = makeStore()
        let old = store.create(title: "Old", symbol: "checklist", tint: .blue, now: t0)
        let new = store.create(title: "New", symbol: "checklist", tint: .blue, now: t0.addingTimeInterval(60))
        XCTAssertEqual(store.sorted.map(\.id), [new.id, old.id])
        store.add("Milk", to: old.id, now: t0.addingTimeInterval(120))
        XCTAssertEqual(store.sorted.map(\.id), [old.id, new.id])
        // Nothing changing doesn't move it.
        store.reset(new.id, now: t0.addingTimeInterval(500))
        XCTAssertEqual(store.list(new.id)?.updated, t0.addingTimeInterval(60))
    }

    func testEditKeepsNameWhenBlank() {
        let store = makeStore()
        let list = store.create(title: "Camp", symbol: "tent.fill", tint: .green)
        store.edit(list.id, title: " ", symbol: "star.fill", tint: .purple)
        XCTAssertEqual(store.list(list.id)?.title, "Camp")
        XCTAssertEqual(store.list(list.id)?.symbol, "star.fill")
        XCTAssertEqual(store.list(list.id)?.tint, .purple)
        store.edit(list.id, title: "Camping", symbol: "bad.symbol", tint: .purple)
        XCTAssertEqual(store.list(list.id)?.title, "Camping")
        XCTAssertEqual(store.list(list.id)?.symbol, "star.fill")
    }

    func testDuplicateStartsUnticked() {
        let store = makeStore()
        let list = store.create(title: "Sleepover", symbol: "moon.stars.fill", tint: .purple, items: ["PJs", "Pillow"])
        store.toggle(store.list(list.id)!.items[0].id, in: list.id)
        let copy = store.duplicate(list.id)!
        XCTAssertEqual(copy.title, "Sleepover copy")
        XCTAssertEqual(copy.items.map(\.text), ["Pillow", "PJs"])
        XCTAssertEqual(copy.doneCount, 0)
        XCTAssertNil(store.duplicate(UUID()))
        store.delete(list.id)
        XCTAssertEqual(store.lists.map(\.id), [copy.id])
    }

    func testListsHaveALimit() {
        let store = makeStore()
        let list = store.create(title: "Big", symbol: "checklist", tint: .blue)
        let many = (1...250).map { "Thing \($0)" }.joined(separator: "\n")
        XCTAssertEqual(store.add(many, to: list.id), ChecklistStore.maxItems)
        XCTAssertEqual(store.add("One more", to: list.id), 0)
        let longItem = String(repeating: "w", count: 120)
        let other = store.create(title: "Long", symbol: "checklist", tint: .blue)
        store.add(longItem, to: other.id)
        XCTAssertEqual(store.list(other.id)?.items.first?.text.count, ChecklistStore.maxItem)
    }

    func testTemplates() {
        let store = makeStore()
        XCTAssertEqual(Set(ChecklistTemplate.all.map(\.title)).count, ChecklistTemplate.all.count)
        for template in ChecklistTemplate.all {
            XCTAssertTrue(ChecklistStore.symbols.contains(template.symbol), template.title)
            XCTAssertFalse(template.items.isEmpty)
            XCTAssertEqual(Set(template.items).count, template.items.count, template.title)
        }
        let bag = store.create(from: ChecklistTemplate.all[0])
        XCTAssertEqual(bag.title, "School bag")
        XCTAssertEqual(bag.items.count, ChecklistTemplate.all[0].items.count)
        XCTAssertEqual(Set(ChecklistStore.symbols).count, ChecklistStore.symbols.count)
    }

    func testListsAreSaved() {
        let name = "checklists-test-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(at: Persistence.url(name)) }
        let store = ChecklistStore(fileName: name)
        let list = store.create(title: "Groceries", symbol: "cart.fill", tint: .orange, items: ["Eggs", "Bread"])
        store.toggle(store.list(list.id)!.items[0].id, in: list.id)
        let again = ChecklistStore(fileName: name)
        XCTAssertEqual(again.lists.count, 1)
        XCTAssertEqual(again.lists[0].title, "Groceries")
        XCTAssertEqual(again.lists[0].items.map(\.text), ["Bread", "Eggs"])
        XCTAssertEqual(again.lists[0].doneCount, 1)
        XCTAssertEqual(again.lists[0].tint, .orange)
    }

    func testTheNewsMentionsLists() {
        let releases = WhatsNew.load()
        guard let notes = releases.first(where: { $0.build == 68 }) else {
            return XCTFail("Build 68 should have notes")
        }
        XCTAssertTrue(notes.items.contains { $0.contains("Lists") })
        XCTAssertEqual(releases.first?.build, releases.map(\.build).max())
    }
}
