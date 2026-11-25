import XCTest
@testable import Ace

/// Ace Graphs: reading formulas, working out what a graph does, asking for a graph,
/// moving and zooming the paper, and the graph screen's list of lines.
@MainActor
final class GraphTests: XCTestCase {
    private func value(_ text: String, at x: Double) -> Double? {
        GraphParse.parse(text)?.value(x)
    }

    // MARK: Reading formulas

    func testReadsTypedFormulas() {
        let cases: [(String, Double, Double)] = [
            ("x^2", 3, 9), ("y = x^2 + 1", 2, 5), ("2x+1", 4, 9), ("3(x+1)", 1, 6), ("-x^2", 2, -4),
            ("2sin(x)", .pi / 2, 2), ("sin 2x", .pi / 4, 1), ("x sin x", .pi / 2, .pi / 2), ("√x", 9, 3),
            ("|x - 3|", 1, 2), ("f(x) = 3x − 2", 1, 1), ("x²", 5, 25), ("2^x", 3, 8), ("(-2)^3", 0, -8),
            ("x^-1", 4, 0.25), ("e^x", 1, M_E), ("pi x", 1, .pi), ("ln x", M_E, 1), ("log(100)", 0, 2),
            ("x^3 - 3x", 2, 2), ("1/(x+1)", 1, 0.5),
        ]
        for (text, x, want) in cases {
            guard let got = value(text, at: x) else { XCTFail("Couldn't read \(text)"); continue }
            XCTAssertEqual(got, want, accuracy: 1e-9, text)
        }
    }

    func testReadsSpokenFormulas() {
        XCTAssertEqual(value("x squared minus 3", at: 2), 1)
        XCTAssertEqual(value("2 x cubed plus x", at: 2), 18)
        XCTAssertEqual(value("x times x", at: 3), 9)
        XCTAssertEqual(value("half of x", at: 8), 4)
        XCTAssertEqual(value("y equals the square root of x", at: 16), 4)
        XCTAssertEqual(value("absolute value of x", at: -5), 5)
        XCTAssertEqual(GraphParse.clean("y equals x squared plus 1"), "x^2 + 1")
        XCTAssertEqual(GraphParse.pretty("x^2 - 3x"), "x² − 3x")
        XCTAssertEqual(GraphParse.pretty("x^20"), "x^20")
        XCTAssertEqual(GraphParse.pretty("sqrt x"), "√x")
    }

    func testRejectsNonsense() {
        for text in ["cat", "x +", "(x", "", "hello x", "x ^", "|x", "2 % x", "the dog"] {
            XCTAssertNil(GraphParse.parse(text), text)
        }
        XCTAssertFalse(GraphParse.parse("5")!.usesX)
        XCTAssertTrue(GraphParse.parse("5x")!.usesX)
    }

    func testNoValueWhereThereIsNone() {
        XCTAssertTrue(value("1/x", at: 0)!.isNaN)
        XCTAssertTrue(value("sqrt(x)", at: -1)!.isNaN)
        XCTAssertTrue(value("ln x", at: 0)!.isNaN)
        XCTAssertTrue(value("x^0.5", at: -4)!.isNaN)
    }

    // MARK: Facts

    func testRoots() {
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("x^2 - 4")!), [-2, 2])
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("2x + 1")!), [-0.5])
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("x^2 + 1")!), [])
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("1/x")!), [], "1/x jumps across 0 but never touches it")
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("sin x")!).count, 7)
        let cubic = GraphFacts.roots(GraphParse.parse("x^3 - 3x")!)
        XCTAssertEqual(cubic.count, 3)
        XCTAssertEqual(cubic[0], -3.0.squareRoot(), accuracy: 1e-6)
        XCTAssertEqual(GraphFacts.roots(GraphParse.parse("(x - 3)^2")!), [3], "Touching the axis counts")
    }

    func testLinesAndParabolas() {
        let line = GraphFacts.line(GraphParse.parse("-3x + 6")!)
        XCTAssertEqual(line?.slope, -3)
        XCTAssertEqual(line?.intercept, 6)
        XCTAssertNil(GraphFacts.line(GraphParse.parse("x^2")!))
        let top = GraphFacts.turningPoint(GraphParse.parse("-(x - 1)^2 + 3")!)
        XCTAssertEqual(top?.x, 1)
        XCTAssertEqual(top?.y, 3)
        XCTAssertEqual(top?.lowest, false)
        XCTAssertNil(GraphFacts.turningPoint(GraphParse.parse("x^3")!))
        XCTAssertNil(GraphFacts.turningPoint(GraphParse.parse("2x")!))
    }

    func testDescriptions() {
        XCTAssertEqual(GraphFacts.describe(GraphParse.parse("2x + 1")!),
                       "It's a straight line that goes up 2 for every 1 step right, and crosses the y axis at 1. It crosses the x axis at x = -0.5.")
        XCTAssertEqual(GraphFacts.describe(GraphParse.parse("x^2 - 4")!),
                       "It's a U-shaped curve (a parabola) with its lowest point at (0, -4). It crosses the x axis at x = -2, 2.")
        XCTAssertEqual(GraphFacts.describe(GraphParse.parse("5")!), "It's a flat line at y = 5.")
        XCTAssertTrue(GraphFacts.describe(GraphParse.parse("1/x")!).contains("doesn't cross the x axis"))
        XCTAssertEqual(GraphFacts.say(2), "2")
        XCTAssertEqual(GraphFacts.say(-1.5), "-1.5")
        XCTAssertEqual(GraphFacts.say(1.7320508), "1.73")
    }

    // MARK: Asking

    private func graphAsk(_ text: String) -> String? {
        if case .graph(let ask)? = IntentRouter.parse(text) { return ask }
        return nil
    }

    func testGraphAsksRoute() {
        let cases: [(String, String)] = [
            ("graph y = x^2", "plot:x^2"),
            ("Graph y = x^2 + 1", "plot:x^2 + 1"),
            ("plot sin x", "plot:sin x"),
            ("draw the graph of 2x+1", "plot:2x+1"),
            ("sketch the line y = 3x - 2", "plot:3x - 2"),
            ("graph x squared minus 4", "plot:x^2 - 4"),
            ("can you graph y equals 2x plus 3", "plot:2x + 3"),
            ("y = 2x + 3", "plot:2x + 3"),
            ("f(x) = x^2 - 4", "plot:x^2 - 4"),
            ("show me the graph of x cubed", "plot:x^3"),
            ("open the graphing calculator", "open"),
            ("graphing calculator", "open"),
            ("graph", "open"),
            ("graph something", "open"),
        ]
        for (text, want) in cases {
            XCTAssertEqual(graphAsk(text), want, text)
        }
    }

    func testOtherAsksAreNotGraphs() {
        for text in ["graph of y equals sin x", "what does a sine wave look like", "draw a cat", "plot twist",
                     "show me the solar system", "draw me a picture of a dog", "graph the sales", "show me e",
                     "what is 2+2", "solve 2x + 3 = 11", "2x + 3 = 11", "solve y = 2x + 3 for x"] {
            XCTAssertNil(graphAsk(text), text)
        }
        if case .homework? = IntentRouter.parse("solve 2x + 3 = 11") {} else { XCTFail("Homework still solves equations") }
    }

    func testGraphStartsFromAsks() {
        XCTAssertEqual(GraphStart(ask: "open"), .blank)
        XCTAssertEqual(GraphStart(ask: "plot:x^2 + 1"), .plot("x^2 + 1"))
        XCTAssertNil(GraphStart(ask: "plot:the dog"))
        XCTAssertNil(GraphStart(ask: "nope"))
    }

    // MARK: The paper

    func testScreenAndPlaneRoundTrip() {
        let size = CGSize(width: 1000, height: 700)
        let v = GraphViewport.fitting(width: 1000)
        XCTAssertEqual(v.screen(0, 0, size: size), CGPoint(x: 500, y: 350))
        XCTAssertEqual(v.plane(CGPoint(x: 1000, y: 350), size: size).x, 11, accuracy: 1e-9)
        let p = v.plane(v.screen(3.5, -2, size: size), size: size)
        XCTAssertEqual(p.x, 3.5, accuracy: 1e-9)
        XCTAssertEqual(p.y, -2, accuracy: 1e-9)
        XCTAssertLessThan(v.screen(0, 1, size: size).y, 350, "Up is positive y")
    }

    func testZoomKeepsTheFingerStill() {
        let size = CGSize(width: 1000, height: 700)
        var v = GraphViewport.fitting(width: 1000)
        let finger = CGPoint(x: 750, y: 200)
        let before = v.plane(finger, size: size)
        v.zoom(by: 2, around: finger, size: size)
        let after = v.plane(finger, size: size)
        XCTAssertEqual(before.x, after.x, accuracy: 1e-9)
        XCTAssertEqual(before.y, after.y, accuracy: 1e-9)
        XCTAssertEqual(v.unitsPerPoint, 0.011, accuracy: 1e-12)
        v.zoom(by: 1e9, around: finger, size: size)
        XCTAssertEqual(v.unitsPerPoint, GraphViewport.minUnits)
        v.pan(by: CGSize(width: 100, height: -50))
        XCTAssertLessThan(v.centerX, before.x)
    }

    func testGridSteps() {
        for units in [0.0005, 0.003, 0.02, 0.04, 0.2, 1, 7, 50] {
            let step = GraphViewport(unitsPerPoint: units).gridStep()
            XCTAssertGreaterThanOrEqual(step / units, 70 - 1e-6)
            XCTAssertLessThanOrEqual(step / units, 70 * 2.5 + 1e-6)
            let lead = step / Foundation.pow(10, floor(log10(step)))
            XCTAssertTrue([1, 2, 5].contains { abs($0 - lead) < 1e-9 }, "\(step)")
        }
        XCTAssertEqual(GraphCanvas.number(0.30000000004, step: 0.1), "0.3")
        XCTAssertEqual(GraphCanvas.number(20, step: 5), "20")
    }

    // MARK: The screen's lines

    func testAddingRemovingAndLimits() {
        let model = GraphModel()
        XCTAssertTrue(model.add("x^2"))
        XCTAssertFalse(model.add("x²"), "The same formula twice")
        XCTAssertNotNil(model.problem)
        XCTAssertFalse(model.add("the dog"))
        XCTAssertTrue(model.add("2x + 1"))
        XCTAssertTrue(model.add("sin x"))
        XCTAssertTrue(model.add("5"), "A flat line is fine")
        XCTAssertFalse(model.add("x^3"), "Only 4 lines fit")
        XCTAssertEqual(Set(model.lines.map(\.color)).count, 4, "Each line gets its own color")
        XCTAssertEqual(model.pickedLine?.text, "5")
        let first = model.lines[0].id
        model.remove(first)
        XCTAssertEqual(model.lines.count, 3)
        XCTAssertTrue(model.add("x^3"))
        XCTAssertEqual(model.lines.last?.color, GraphModel.colors[0], "A freed color is reused")
        model.picked = model.lines[0].id
        model.traceX = 2
        XCTAssertEqual(model.tracePoint?.y ?? .nan, 5, accuracy: 1e-9)
        model.toggle(model.lines[0].id)
        XCTAssertNil(model.tracePoint, "No trace on a hidden line")
        model.clearAll()
        XCTAssertTrue(model.lines.isEmpty)
        XCTAssertNil(model.traceX)
    }

    func testExamplesAllDraw() {
        for e in GraphModel.examples {
            XCTAssertTrue(GraphParse.parse(e)?.usesX == true, e)
        }
    }

    func testChangelogHasGraphs() {
        let releases = WhatsNew.load()
        XCTAssertEqual(releases.first?.build, 72)
        XCTAssertTrue(releases.first?.items.contains { $0.contains("Ace Graphs") } == true)
    }
}
