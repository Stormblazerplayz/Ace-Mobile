import PencilKit
import XCTest
@testable import Ace

/// The sketchbook: papers, challenges, saving sketches, the streak, undo and redo, and pictures.
@MainActor
final class SketchTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private var now: Date { day(2026, 11, 25, hour: 18) }

    private func store() -> SketchStore {
        SketchStore(indexFile: nil, folder: nil, calendar: cal)
    }

    /// A drawing with one red pen stroke going right and a little down.
    private func drawing(strokes count: Int = 1) -> PKDrawing {
        var strokes: [PKStroke] = []
        for n in 0..<count {
            let points = (0..<20).map { i in
                PKStrokePoint(location: CGPoint(x: 100 + CGFloat(i) * 10, y: 200 + CGFloat(i) * 3 + CGFloat(n) * 40),
                              timeOffset: TimeInterval(i) * 0.01,
                              size: CGSize(width: 6, height: 6),
                              opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
            }
            let path = PKStrokePath(controlPoints: points, creationDate: Date())
            strokes.append(PKStroke(ink: PKInk(.pen, color: .red), path: path, transform: .identity, mask: nil))
        }
        return PKDrawing(strokes: strokes)
    }

    // MARK: Papers, challenges and colors

    func testEveryPaperLooksDifferent() {
        XCTAssertEqual(SketchPaper.allCases.count, 5)
        XCTAssertEqual(Set(SketchPaper.allCases.map(\.hex)).count, 5)
        XCTAssertEqual(SketchPaper.midnight.pattern, .plain)
        XCTAssertEqual(SketchPaper.paper.pattern, .lines)
        XCTAssertEqual(SketchPaper.grid.pattern, .grid)
        XCTAssertEqual(SketchPaper.dots.pattern, .dots)
        for paper in SketchPaper.allCases {
            XCTAssertEqual(paper.startInk, paper.isDark ? 0xFFFFFF : 0x1B1830, "\(paper.label) needs ink you can see")
            XCTAssertTrue(SketchInk.palette.contains(paper.startInk), "The starting ink is one of the swatches")
        }
    }

    func testTimersAreMinutes() {
        XCTAssertEqual(SketchChallenge.allCases.map(\.seconds), [0, 60, 180, 300])
        XCTAssertEqual(SketchChallenge.threeMinutes.label, "3 min")
    }

    func testTheColorsAllHaveNames() {
        XCTAssertEqual(SketchInk.palette.count, 12)
        XCTAssertEqual(Set(SketchInk.palette).count, 12)
        XCTAssertEqual(Set(SketchInk.palette.map(SketchInk.name)).count, 12)
        XCTAssertFalse(SketchInk.palette.map(SketchInk.name).contains("Color"))
    }

    func testEveryToolMakesAPencilKitTool() throws {
        XCTAssertEqual(Set(SketchTool.allCases.map(\.symbol)).count, SketchTool.allCases.count)
        let red = SketchInk.uiColor(0xFF5A4E)
        let pen = try XCTUnwrap(SketchTool.pen.pkTool(color: red, size: .medium) as? PKInkingTool)
        XCTAssertEqual(pen.inkType, .pen)
        XCTAssertEqual(try XCTUnwrap(SketchTool.crayon.pkTool(color: red, size: .small) as? PKInkingTool).inkType, .crayon)
        XCTAssertEqual(try XCTUnwrap(SketchTool.watercolor.pkTool(color: red, size: .large) as? PKInkingTool).inkType, .watercolor)
        XCTAssertTrue(SketchTool.eraser.pkTool(color: red, size: .medium) is PKEraserTool)
        XCTAssertTrue(SketchTool.lasso.pkTool(color: red, size: .medium) is PKLassoTool)
        XCTAssertFalse(SketchTool.eraser.usesColor)
        XCTAssertTrue(SketchTool.marker.usesColor)
        XCTAssertLessThan(SketchSize.small.width, SketchSize.large.width)
    }

    // MARK: Challenges

    func testThereAreLotsOfDifferentChallenges() {
        XCTAssertGreaterThanOrEqual(SketchPrompts.all.count, 50)
        XCTAssertEqual(Set(SketchPrompts.all).count, SketchPrompts.all.count, "No repeats")
        for p in SketchPrompts.all {
            XCTAssertFalse(p.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertLessThanOrEqual(p.count, 60)
        }
    }

    func testTodaysChallengeLastsAllDay() {
        let morning = SketchPrompts.daily(for: day(2026, 11, 25, hour: 1), calendar: cal)
        let night = SketchPrompts.daily(for: day(2026, 11, 25, hour: 23), calendar: cal)
        let tomorrow = SketchPrompts.daily(for: day(2026, 11, 26, hour: 9), calendar: cal)
        XCTAssertEqual(morning, night)
        XCTAssertNotEqual(morning, tomorrow, "A new one each day")
        XCTAssertTrue(SketchPrompts.all.contains(morning))
    }

    func testTheDiceAlwaysGiveANewChallenge() {
        let current = SketchPrompts.all[3]
        for _ in 0..<50 {
            XCTAssertNotEqual(SketchPrompts.random(excluding: current), current)
        }
    }

    // MARK: The sketchbook

    func testNewSketchesAreNumbered() {
        let s = store()
        XCTAssertEqual(s.create(paper: .midnight, now: now).title, "Sketch 1")
        let second = s.create(paper: .grid, now: now)
        XCTAssertEqual(second.title, "Sketch 2")
        XCTAssertEqual(second.paper, .grid)
        XCTAssertNil(second.prompt)
        s.delete(s.sketches.last!.id)
        XCTAssertEqual(s.create(paper: .paper, now: now).title, "Sketch 3", "Numbers aren't reused")
        XCTAssertEqual(s.sketches.count, 2)
    }

    func testAChallengeSketchIsNamedAfterIt() {
        let s = store()
        let sketch = s.create(paper: .paper, prompt: "  A robot walking its dog  ", now: now)
        XCTAssertEqual(sketch.title, "A robot walking its dog")
        XCTAssertEqual(sketch.prompt, "A robot walking its dog")
        let long = s.create(paper: .paper, prompt: String(repeating: "dragon ", count: 20), now: now)
        XCTAssertLessThanOrEqual(long.title.count, SketchStore.maxTitle)
        XCTAssertEqual(s.create(paper: .paper, prompt: "   ", now: now).title, "Sketch 1", "A blank challenge is a blank page")
    }

    func testSavingADrawingKeepsItsStrokesAndMovesItToTheTop() throws {
        let s = store()
        let first = s.create(paper: .midnight, now: day(2026, 11, 20))
        let second = s.create(paper: .midnight, now: day(2026, 11, 21))
        XCTAssertEqual(s.sketches.map(\.id), [second.id, first.id])

        let d = drawing(strokes: 3)
        s.saveDrawing(first.id, data: d.dataRepresentation(), strokes: d.strokes.count, thumbnail: Data([1, 2, 3]), now: now)
        XCTAssertEqual(s.sketches.map(\.id), [first.id, second.id], "Drawing on it moves it to the top")
        XCTAssertEqual(s.sketch(first.id)?.strokes, 3)
        XCTAssertEqual(s.sketch(first.id)?.updated, now)
        XCTAssertEqual(s.thumbnailData(first.id), Data([1, 2, 3]))
        let back = try PKDrawing(data: try XCTUnwrap(s.drawingData(first.id)))
        XCTAssertEqual(back.strokes.count, 3)
        XCTAssertEqual(s.totalStrokes, 3)

        s.saveDrawing(first.id, data: PKDrawing().dataRepresentation(), strokes: 0, thumbnail: nil, now: now)
        XCTAssertNil(s.thumbnailData(first.id), "An empty page has no picture")
        XCTAssertEqual(s.totalStrokes, 0)
    }

    func testRenamingIgnoresBlankNamesAndCutsLongOnes() {
        let s = store()
        let sketch = s.create(paper: .dots, now: now)
        s.rename(sketch.id, to: "  Space whale  ")
        XCTAssertEqual(s.sketch(sketch.id)?.title, "Space whale")
        s.rename(sketch.id, to: "   ")
        XCTAssertEqual(s.sketch(sketch.id)?.title, "Space whale")
        s.rename(sketch.id, to: String(repeating: "x", count: 100))
        XCTAssertEqual(s.sketch(sketch.id)?.title.count, SketchStore.maxTitle)
    }

    func testChangingThePaper() {
        let s = store()
        let sketch = s.create(paper: .midnight, now: day(2026, 11, 20))
        s.setPaper(sketch.id, to: .blueprint, now: now)
        XCTAssertEqual(s.sketch(sketch.id)?.paper, .blueprint)
        XCTAssertEqual(s.sketch(sketch.id)?.updated, now)
    }

    func testACopyHasTheSameDrawing() throws {
        let s = store()
        let sketch = s.create(paper: .grid, now: now)
        s.rename(sketch.id, to: "Castle")
        let d = drawing(strokes: 2)
        s.saveDrawing(sketch.id, data: d.dataRepresentation(), strokes: 2, thumbnail: Data([9]), now: now)

        let copy = try XCTUnwrap(s.duplicate(sketch.id, now: now))
        XCTAssertNotEqual(copy.id, sketch.id)
        XCTAssertEqual(copy.title, "Castle copy")
        XCTAssertEqual(copy.paper, .grid)
        XCTAssertEqual(copy.strokes, 2)
        XCTAssertEqual(s.drawingData(copy.id), s.drawingData(sketch.id))
        XCTAssertEqual(s.thumbnailData(copy.id), Data([9]))
        XCTAssertEqual(s.sketches.count, 2)

        s.delete(sketch.id)
        XCTAssertNil(s.sketch(sketch.id))
        XCTAssertNil(s.drawingData(sketch.id))
        XCTAssertNotNil(s.drawingData(copy.id), "Deleting the first leaves the copy alone")
    }

    func testTheStreakCountsDaysYouDrew() {
        let s = store()
        let sketch = s.create(paper: .midnight, now: day(2026, 11, 20))
        let data = drawing().dataRepresentation()
        XCTAssertEqual(s.streak(now: now), 0)
        for d in [21, 23, 24] {
            s.saveDrawing(sketch.id, data: data, strokes: 1, thumbnail: nil, now: day(2026, 11, d))
        }
        XCTAssertEqual(s.streak(now: now), 2, "Today isn't over yet, so the 23rd and 24th count")
        s.saveDrawing(sketch.id, data: data, strokes: 1, thumbnail: nil, now: now)
        XCTAssertEqual(s.streak(now: now), 3)
        XCTAssertEqual(s.streak(now: day(2026, 11, 27)), 0, "A whole day missed ends it")

        let empty = store()
        let blank = empty.create(paper: .paper, now: now)
        empty.saveDrawing(blank.id, data: PKDrawing().dataRepresentation(), strokes: 0, thumbnail: nil, now: now)
        XCTAssertEqual(empty.streak(now: now), 0, "An empty page doesn't count")
    }

    func testTheSketchbookIsSavedForNextTime() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("sketch-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let index = "sketches-test-\(UUID().uuidString).json"
        defer {
            try? FileManager.default.removeItem(at: folder)
            try? FileManager.default.removeItem(at: Persistence.url(index))
        }
        let saveTime = Date(timeIntervalSince1970: now.timeIntervalSince1970.rounded(.down))
        let first = SketchStore(indexFile: index, folder: folder, calendar: cal)
        let sketch = first.create(paper: .dots, prompt: "A fox reading a book", now: saveTime)
        let d = drawing(strokes: 2)
        first.saveDrawing(sketch.id, data: d.dataRepresentation(), strokes: 2, thumbnail: Data([7, 7]), now: saveTime)

        let again = SketchStore(indexFile: index, folder: folder, calendar: cal)
        XCTAssertEqual(again.sketches, first.sketches)
        XCTAssertEqual(again.drawDays, ["2026-11-25"])
        XCTAssertEqual(again.thumbnailData(sketch.id), Data([7, 7]))
        let back = try PKDrawing(data: try XCTUnwrap(again.drawingData(sketch.id)))
        XCTAssertEqual(back.strokes.count, 2)

        again.delete(sketch.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("\(sketch.id.uuidString).drawing").path))
        XCTAssertTrue(SketchStore(indexFile: index, folder: folder, calendar: cal).sketches.isEmpty)
    }

    // MARK: Undo and redo

    func testUndoAndRedo() {
        let m = SketchCanvasModel()
        m.load(drawing(strokes: 2))
        XCTAssertEqual(m.strokes, 2)
        XCTAssertFalse(m.canUndo, "Nothing to undo right after opening")
        XCTAssertEqual(m.changes, 0)

        m.clear()
        XCTAssertEqual(m.strokes, 0)
        XCTAssertTrue(m.canUndo)
        XCTAssertFalse(m.canRedo)

        m.undo()
        XCTAssertEqual(m.strokes, 2, "Undo brings the page back")
        XCTAssertTrue(m.canRedo)

        m.redo()
        XCTAssertEqual(m.strokes, 0)
        XCTAssertFalse(m.canRedo)
        XCTAssertEqual(m.changes, 3)
    }

    func testDrawingAStrokeCanBeUndone() {
        let m = SketchCanvasModel()
        m.load(drawing(strokes: 1))
        draw(m, drawing(strokes: 3))
        XCTAssertEqual(m.strokes, 3)
        XCTAssertTrue(m.canUndo)
        m.undo()
        XCTAssertEqual(m.strokes, 1)
        XCTAssertEqual(m.canvas.drawing.strokes.count, 1, "The canvas shows the undone page too")
    }

    /// Draws on the canvas the way a finger would, so the model hears about it.
    private func draw(_ m: SketchCanvasModel, _ d: PKDrawing) {
        let before = m.changes
        m.canvas.drawing = d
        if m.changes == before { m.drawingChanged(m.canvas) }
    }

    func testUndoForgetsVeryOldSteps() {
        let m = SketchCanvasModel()
        m.load(PKDrawing())
        for i in 0..<(SketchCanvasModel.historyLimit + 10) {
            draw(m, drawing(strokes: 1 + i % 3))
        }
        var undos = 0
        while m.canUndo && undos < 500 {
            m.undo()
            undos += 1
        }
        XCTAssertEqual(undos, SketchCanvasModel.historyLimit)
    }

    // MARK: Pictures

    func testThePictureFramesTheDrawing() throws {
        let d = drawing()
        let frame = try XCTUnwrap(SketchRender.frame(for: d))
        XCTAssertEqual(frame.width / frame.height, 4.0 / 3.0, accuracy: 0.001)
        XCTAssertTrue(frame.contains(d.bounds), "The whole drawing is in the picture")
        XCTAssertNil(SketchRender.frame(for: PKDrawing()), "An empty page has no picture")
    }

    func testThePictureIsTheRightSize() throws {
        for paper in SketchPaper.allCases {
            let image = try XCTUnwrap(SketchRender.image(drawing(), paper: paper, width: 480, scale: 1))
            XCTAssertEqual(image.size.width, 480, accuracy: 0.5)
            XCTAssertEqual(image.size.height, 360, accuracy: 0.5)
            XCTAssertNotNil(image.pngData())
        }
        XCTAssertNil(SketchRender.image(PKDrawing(), paper: .paper, width: 480))
    }

    // MARK: What's new

    func testTheNewsMentionsTheSketchbook() {
        let release = WhatsNew.load().first { $0.build == 60 }
        XCTAssertNotNil(release, "Build 60 should have notes")
        XCTAssertTrue(release?.items.contains { $0.contains("Sketchbook") } ?? false)
    }
}
