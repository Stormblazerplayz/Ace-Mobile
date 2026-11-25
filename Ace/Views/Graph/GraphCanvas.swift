import SwiftUI

/// The graph paper: grid, axes with numbers, each formula drawing itself in from left to right
/// with a soft glow, dots where it crosses the axes, and the trace with its (x, y) bubble.
struct GraphCanvas: View {
    @ObservedObject var model: GraphModel
    let moves: Bool
    /// Move drags the paper; Trace slides the dot along the line.
    let tracing: Bool

    /// How long a new line takes to draw itself in.
    static let drawIn = 0.9

    @State private var dragStart: GraphViewport?
    @State private var pinchStart: GraphViewport?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation(minimumInterval: 1 / 60, paused: !moves)) { timeline in
                Canvas { ctx, size in
                    let now = timeline.date
                    drawGrid(size, in: ctx)
                    for line in model.lines where line.shown {
                        drawLine(line, size: size, now: now, in: ctx)
                    }
                    drawTrace(size, now: now, in: ctx)
                }
            }
            .contentShape(Rectangle())
            .gesture(drag(size))
            .simultaneousGesture(pinch(size))
            .simultaneousGesture(SpatialTapGesture().onEnded { tap in
                setTrace(at: tap.location, size: size)
            })
            .onAppear { model.fit(width: size.width) }
            .onChange(of: size.width) { _, w in model.fit(width: w) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard !model.lines.isEmpty else { return "Empty graph. Type a formula below to draw it." }
        return "Graph of " + model.lines.map { $0.label + ". " + GraphFacts.describe($0.expr) }.joined(separator: " ")
    }

    // MARK: Gestures

    private func drag(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                // Two fingers are a pinch, not a drag.
                guard pinchStart == nil else { return }
                if tracing {
                    setTrace(at: value.location, size: size)
                    return
                }
                let start = dragStart ?? model.viewport
                dragStart = start
                var v = start
                v.pan(by: value.translation)
                model.viewport = v
            }
            .onEnded { _ in dragStart = nil }
    }

    private func pinch(_ size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? model.viewport
                pinchStart = start
                var v = start
                let anchor = CGPoint(x: value.startAnchor.x * size.width, y: value.startAnchor.y * size.height)
                v.zoom(by: Double(value.magnification), around: anchor, size: size)
                model.viewport = v
            }
            .onEnded { _ in pinchStart = nil }
    }

    private func setTrace(at point: CGPoint, size: CGSize) {
        guard !model.lines.isEmpty else { return }
        let p = model.viewport.plane(point, size: size)
        // In Move mode a tap picks the line nearest the finger.
        if !tracing {
            let near = model.lines.filter(\.shown).min { a, b in
                abs(gap(a, p, size)) < abs(gap(b, p, size))
            }
            if let near { model.picked = near.id }
        }
        model.traceX = snap(p.x)
    }

    /// How far (in screen points) the line is above or below a plane point.
    private func gap(_ line: GraphLine, _ p: (x: Double, y: Double), _ size: CGSize) -> Double {
        let y = line.expr.value(p.x)
        return y.isFinite ? (y - p.y) / model.viewport.unitsPerPoint : .infinity
    }

    /// Lands on a crossing when the finger is close to one, so the bubble shows the exact answer.
    private func snap(_ x: Double) -> Double {
        let reach = 14 * model.viewport.unitsPerPoint
        if let line = model.pickedLine, let r = line.roots.min(by: { abs($0 - x) < abs($1 - x) }), abs(r - x) < reach { return r }
        if abs(x) < reach { return 0 }
        return x
    }

    // MARK: Drawing

    private func drawGrid(_ size: CGSize, in ctx: GraphicsContext) {
        let v = model.viewport
        let step = v.gridStep()
        let minor = step / 5
        let left = v.plane(.zero, size: size).x, right = v.plane(CGPoint(x: size.width, y: 0), size: size).x
        let top = v.plane(.zero, size: size).y, bottom = v.plane(CGPoint(x: 0, y: size.height), size: size).y

        var small = Path(), big = Path()
        var x = (left / minor).rounded(.down) * minor
        while x <= right {
            let sx = v.screen(x, 0, size: size).x
            let onBig = abs((x / step).rounded() * step - x) < minor / 10
            if onBig { big.addVerticalLine(sx, size.height) } else { small.addVerticalLine(sx, size.height) }
            x += minor
        }
        var y = (bottom / minor).rounded(.down) * minor
        while y <= top {
            let sy = v.screen(0, y, size: size).y
            let onBig = abs((y / step).rounded() * step - y) < minor / 10
            if onBig { big.addHorizontalLine(sy, size.width) } else { small.addHorizontalLine(sy, size.width) }
            y += minor
        }
        ctx.stroke(small, with: .color(.white.opacity(0.04)), lineWidth: 1)
        ctx.stroke(big, with: .color(.white.opacity(0.11)), lineWidth: 1)

        // The axes, kept on screen at the edge when they're out of view, so the numbers stay readable.
        let origin = v.screen(0, 0, size: size)
        let axisX = min(max(origin.x, 0), size.width), axisY = min(max(origin.y, 0), size.height)
        var axes = Path()
        axes.addVerticalLine(origin.x, size.height)
        axes.addHorizontalLine(origin.y, size.width)
        ctx.stroke(axes, with: .color(.white.opacity(0.55)), lineWidth: 1.5)

        let font = Font.system(size: 11, weight: .semibold, design: .rounded)
        var n = (left / step).rounded(.up) * step
        while n <= right {
            if abs(n) > step / 100 {
                let sx = v.screen(n, 0, size: size).x
                let below = axisY + 13 > size.height - 6 ? axisY - 12 : axisY + 13
                ctx.draw(Text(GraphCanvas.number(n, step: step)).font(font).foregroundColor(.white.opacity(0.55)), at: CGPoint(x: sx, y: below))
            }
            n += step
        }
        n = (bottom / step).rounded(.up) * step
        while n <= top {
            if abs(n) > step / 100 {
                let sy = v.screen(0, n, size: size).y
                let side = axisX + 8 > size.width - 30 ? axisX - 8 : axisX + 8
                ctx.draw(Text(GraphCanvas.number(n, step: step)).font(font).foregroundColor(.white.opacity(0.55)),
                         at: CGPoint(x: side, y: sy), anchor: side < axisX ? .trailing : .leading)
            }
            n += step
        }
        ctx.draw(Text("0").font(font).foregroundColor(.white.opacity(0.45)), at: CGPoint(x: origin.x + 8, y: origin.y + 12))
    }

    /// A grid number without long tails: 0.30000000004 shows as 0.3.
    static func number(_ n: Double, step: Double) -> String {
        let places = max(0, Int(-floor(log10(step))))
        let s = String(format: "%.\(places)f", n)
        return s == "-0" ? "0" : s
    }

    private func drawLine(_ line: GraphLine, size: CGSize, now: Date, in ctx: GraphicsContext) {
        let v = model.viewport
        let age = now.timeIntervalSince(line.born)
        let t = moves ? min(1, max(0, age / GraphCanvas.drawIn)) : 1
        let eased = 1 - (1 - t) * (1 - t) * (1 - t)
        let reach = size.width * CGFloat(eased)
        let color = Color(hex: line.color)
        let picked = model.pickedLine?.id == line.id

        var path = Path()
        var pen = false
        var lastY: CGFloat = 0
        var sx: CGFloat = 0
        while sx <= reach {
            let x = v.plane(CGPoint(x: sx, y: 0), size: size).x
            let y = line.expr.value(x)
            if y.isFinite {
                let sy = CGFloat(max(-1e5, min(1e5, Double(v.screen(0, y, size: size).y))))
                // A huge jump (like 1/x crossing 0) is a gap, not a line straight up the screen.
                if pen, abs(sy - lastY) > size.height * 1.5 {
                    path.move(to: CGPoint(x: sx, y: sy))
                } else if pen {
                    path.addLine(to: CGPoint(x: sx, y: sy))
                } else {
                    path.move(to: CGPoint(x: sx, y: sy))
                }
                pen = true
                lastY = sy
            } else {
                pen = false
            }
            sx += 1.5
        }
        ctx.drawLayer { glow in
            glow.addFilter(.blur(radius: picked ? 9 : 6))
            glow.stroke(path, with: .color(color.opacity(picked ? 0.8 : 0.5)), style: StrokeStyle(lineWidth: picked ? 7 : 5, lineCap: .round, lineJoin: .round))
        }
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: picked ? 3.5 : 2.5, lineCap: .round, lineJoin: .round))

        // The pen tip while it draws.
        if t < 1, let tip = path.currentPoint {
            ctx.fill(Path(ellipseIn: CGRect(x: tip.x - 6, y: tip.y - 6, width: 12, height: 12)), with: .color(.white))
        }

        // Dots where it crosses the axes, popping in once the line is drawn.
        guard t >= 1 || !moves else { return }
        let pop = moves ? min(1, max(0, (age - GraphCanvas.drawIn) / 0.35)) : 1
        let bounce = moves ? CGFloat(1 + 0.4 * sin(pop * .pi)) : 1
        var points: [(Double, Double)] = line.roots.map { ($0, 0) }
        if let y0 = GraphFacts.yIntercept(line.expr) { points.append((0, y0)) }
        for (px, py) in points {
            let p = v.screen(px, py, size: size)
            guard p.x > -10, p.x < size.width + 10, p.y > -10, p.y < size.height + 10 else { continue }
            let r = 5.5 * CGFloat(pop) * bounce
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0x0C0A1C)))
            ctx.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(color), lineWidth: 2.5)
        }
    }

    private func drawTrace(_ size: CGSize, now: Date, in ctx: GraphicsContext) {
        guard let p = model.tracePoint, let line = model.pickedLine else { return }
        let v = model.viewport
        let at = v.screen(p.x, p.y, size: size)
        let color = Color(hex: line.color)
        var guide = Path()
        guide.addVerticalLine(at.x, size.height)
        ctx.stroke(guide, with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))

        let pulse = moves ? CGFloat(1 + 0.25 * sin(now.timeIntervalSinceReferenceDate * 5)) : 1
        let halo = 16 * pulse
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - halo, y: at.y - halo, width: halo * 2, height: halo * 2)), with: .color(color.opacity(0.25)))
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - 7, y: at.y - 7, width: 14, height: 14)), with: .color(.white))
        ctx.fill(Path(ellipseIn: CGRect(x: at.x - 4.5, y: at.y - 4.5, width: 9, height: 9)), with: .color(color))

        let text = Text("(\(GraphFacts.say(p.x)), \(GraphFacts.say(p.y)))")
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
        let resolved = ctx.resolve(text)
        let box = resolved.measure(in: size)
        let above = at.y - 30 > 20
        var center = CGPoint(x: at.x, y: above ? at.y - 30 : at.y + 30)
        center.x = min(max(center.x, box.width / 2 + 14), size.width - box.width / 2 - 14)
        let bubble = CGRect(x: center.x - box.width / 2 - 10, y: center.y - box.height / 2 - 6, width: box.width + 20, height: box.height + 12)
        ctx.fill(Path(roundedRect: bubble, cornerRadius: bubble.height / 2), with: .color(color.opacity(0.9)))
        ctx.draw(resolved, at: center)
    }
}

private extension Path {
    mutating func addVerticalLine(_ x: CGFloat, _ height: CGFloat) {
        move(to: CGPoint(x: x, y: 0))
        addLine(to: CGPoint(x: x, y: height))
    }

    mutating func addHorizontalLine(_ y: CGFloat, _ width: CGFloat) {
        move(to: CGPoint(x: 0, y: y))
        addLine(to: CGPoint(x: width, y: y))
    }
}
