import PencilKit
import SwiftUI
import UIKit

// The drawing surface: PencilKit's canvas, the tools you draw with, undo and redo,
// the paper behind it, and turning a drawing into a picture.

/// How thick the lines are.
enum SketchSize: Int, CaseIterable, Identifiable {
    case small, medium, large

    var id: Int { rawValue }

    /// The pen width in points (other tools scale it).
    var width: CGFloat {
        switch self {
        case .small: return 2.5
        case .medium: return 6
        case .large: return 12
        }
    }

    /// How big the dot is in the tool bar.
    var dot: CGFloat {
        switch self {
        case .small: return 7
        case .medium: return 12
        case .large: return 18
        }
    }

    var label: String {
        switch self {
        case .small: return "Thin"
        case .medium: return "Medium"
        case .large: return "Thick"
        }
    }
}

/// The tools in the sketchbook's tool bar.
enum SketchTool: String, CaseIterable, Identifiable {
    case pen, marker, pencil, crayon, watercolor, eraser, lasso

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pen: return "Pen"
        case .marker: return "Marker"
        case .pencil: return "Pencil"
        case .crayon: return "Crayon"
        case .watercolor: return "Watercolor"
        case .eraser: return "Eraser"
        case .lasso: return "Lasso"
        }
    }

    var symbol: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .pencil: return "pencil"
        case .crayon: return "scribble"
        case .watercolor: return "paintbrush.pointed.fill"
        case .eraser: return "eraser.fill"
        case .lasso: return "lasso"
        }
    }

    /// The eraser and the lasso don't use a color.
    var usesColor: Bool { self != .eraser && self != .lasso }

    /// The PencilKit tool for this, in a color and a size.
    func pkTool(color: UIColor, size: SketchSize) -> PKTool {
        let w = size.width
        switch self {
        case .pen: return PKInkingTool(.pen, color: color, width: w)
        case .marker: return PKInkingTool(.marker, color: color, width: w * 3)
        case .pencil: return PKInkingTool(.pencil, color: color, width: w * 1.5)
        case .crayon: return PKInkingTool(.crayon, color: color, width: w * 2.5)
        case .watercolor: return PKInkingTool(.watercolor, color: color, width: w * 3)
        case .eraser: return PKEraserTool(.bitmap, width: w * 5)
        case .lasso: return PKLassoTool()
        }
    }
}

/// The ink colors in the tool bar.
enum SketchInk {
    static let palette: [UInt32] = [
        0x1B1830, 0xFFFFFF, 0xFF5A4E, 0xFF8A3D, 0xFFCF3A, 0x45D483,
        0x1BC6FF, 0x5BB6FF, 0x8F7CFF, 0xFF5F8F, 0x8B5A2B, 0x9A97B2
    ]

    /// What VoiceOver calls each color.
    static func name(_ hex: UInt32) -> String {
        switch hex {
        case 0x1B1830: return "Black"
        case 0xFFFFFF: return "White"
        case 0xFF5A4E: return "Red"
        case 0xFF8A3D: return "Orange"
        case 0xFFCF3A: return "Yellow"
        case 0x45D483: return "Green"
        case 0x1BC6FF: return "Cyan"
        case 0x5BB6FF: return "Blue"
        case 0x8F7CFF: return "Purple"
        case 0xFF5F8F: return "Pink"
        case 0x8B5A2B: return "Brown"
        case 0x9A97B2: return "Gray"
        default: return "Color"
        }
    }

    static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}

/// Passes PencilKit's "the drawing changed" on to the canvas model.
final class SketchDrawingRelay: NSObject, PKCanvasViewDelegate {
    var onChange: (PKCanvasView) -> Void = { _ in }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        onChange(canvasView)
    }
}

/// Holds the PencilKit canvas and keeps its own undo and redo, so the buttons always work
/// (with a finger or an Apple Pencil, and even after clearing the page).
@MainActor
final class SketchCanvasModel: ObservableObject {
    let canvas: PKCanvasView
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published private(set) var strokes = 0
    /// Goes up every time the drawing changes, so the editor knows to save.
    @Published private(set) var changes = 0

    /// How many steps undo remembers.
    static let historyLimit = 60

    private let relay: SketchDrawingRelay
    private var past: [PKDrawing] = []
    private var future: [PKDrawing] = []
    private var current = PKDrawing()
    private var applying = false

    init() {
        canvas = PKCanvasView()
        relay = SketchDrawingRelay()
        canvas.delegate = relay
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        // Light, so PencilKit draws colors as they are instead of flipping them for dark mode.
        canvas.overrideUserInterfaceStyle = .light
        canvas.isScrollEnabled = false
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.tool = PKInkingTool(.pen, color: .black, width: SketchSize.medium.width)
        relay.onChange = { [weak self] view in
            self?.drawingChanged(view)
        }
    }

    var drawing: PKDrawing { current }

    /// Shows a saved drawing, with nothing to undo yet.
    func load(_ drawing: PKDrawing) {
        past.removeAll()
        future.removeAll()
        apply(drawing, counts: false)
    }

    func setTool(_ tool: PKTool) {
        canvas.tool = tool
    }

    func undo() {
        guard let before = past.popLast() else { return }
        future.append(current)
        apply(before, counts: true)
    }

    func redo() {
        guard let after = future.popLast() else { return }
        past.append(current)
        apply(after, counts: true)
    }

    /// Wipes the page. Undo brings it back.
    func clear() {
        guard !current.strokes.isEmpty else { return }
        remember(current)
        future.removeAll()
        apply(PKDrawing(), counts: true)
    }

    /// A stroke was drawn, erased or moved on the canvas.
    func drawingChanged(_ view: PKCanvasView) {
        guard !applying else { return }
        remember(current)
        future.removeAll()
        current = view.drawing
        refresh()
        changes += 1
    }

    private func remember(_ drawing: PKDrawing) {
        past.append(drawing)
        if past.count > Self.historyLimit { past.removeFirst(past.count - Self.historyLimit) }
    }

    private func apply(_ drawing: PKDrawing, counts: Bool) {
        applying = true
        canvas.drawing = drawing
        applying = false
        current = drawing
        refresh()
        if counts { changes += 1 }
    }

    private func refresh() {
        canUndo = !past.isEmpty
        canRedo = !future.isEmpty
        strokes = current.strokes.count
    }
}

/// The PencilKit canvas in SwiftUI.
struct SketchCanvas: UIViewRepresentable {
    let model: SketchCanvasModel

    func makeUIView(context: Context) -> PKCanvasView {
        model.canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

/// The paper behind the canvas: its color and its lines, squares or dots.
struct SketchPaperView: View {
    let paper: SketchPaper

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: paper.hex)))
            let step = paper.spacing
            let line = GraphicsContext.Shading.color(Color(hex: paper.lineHex))
            switch paper.pattern {
            case .plain:
                break
            case .lines:
                var y = step
                while y < size.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: line)
                    y += step
                }
            case .grid:
                var x = step
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: line)
                    x += step
                }
                var y = step
                while y < size.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: line)
                    y += step
                }
            case .dots:
                var y = step
                while y < size.height {
                    var x = step
                    while x < size.width {
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2)), with: line)
                        x += step
                    }
                    y += step
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Turns a drawing into a picture on its paper, for the sketchbook's cards and for sharing.
@MainActor
enum SketchRender {
    /// The part of the canvas worth showing: the drawing with a margin around it, widened to
    /// `aspect` (width over height). Nil for an empty drawing.
    static func frame(for drawing: PKDrawing, aspect: CGFloat = 4.0 / 3.0, margin: CGFloat = 36) -> CGRect? {
        let bounds = drawing.bounds
        guard !drawing.strokes.isEmpty, !bounds.isNull, !bounds.isInfinite, aspect > 0 else { return nil }
        var rect = bounds.insetBy(dx: -margin, dy: -margin)
        if rect.width / rect.height < aspect {
            let wide = rect.height * aspect
            rect = rect.insetBy(dx: -(wide - rect.width) / 2, dy: 0)
        } else {
            let tall = rect.width / aspect
            rect = rect.insetBy(dx: 0, dy: -(tall - rect.height) / 2)
        }
        return rect
    }

    /// The drawing on its paper, `width` points wide. Nil for an empty drawing.
    static func image(_ drawing: PKDrawing, paper: SketchPaper, width: CGFloat, scale: CGFloat = 2) -> UIImage? {
        guard width > 0, let rect = frame(for: drawing) else { return nil }
        let zoom = width / rect.width
        let size = CGSize(width: width, height: rect.height * zoom)
        var ink: UIImage?
        // Light, so the colors come out as they were drawn.
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            ink = drawing.image(from: rect, scale: zoom * scale)
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            SketchInk.uiColor(paper.hex).setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            drawPattern(paper, in: cg, area: rect, zoom: zoom)
            ink?.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Draws the paper's lines, squares or dots, lined up with the canvas.
    private static func drawPattern(_ paper: SketchPaper, in cg: CGContext, area: CGRect, zoom: CGFloat) {
        let step = paper.spacing
        guard paper.pattern != .plain, step > 0 else { return }
        SketchInk.uiColor(paper.lineHex).setFill()
        let thin = max(1, zoom)
        let firstX = (area.minX / step).rounded(.up) * step
        let firstY = (area.minY / step).rounded(.up) * step
        // Never more than a few hundred lines, however big the drawing is.
        let limit = 400
        switch paper.pattern {
        case .plain:
            return
        case .lines, .grid:
            var y = firstY
            var n = 0
            while y <= area.maxY && n < limit {
                cg.fill(CGRect(x: 0, y: (y - area.minY) * zoom, width: area.width * zoom, height: thin))
                y += step
                n += 1
            }
            guard paper.pattern == .grid else { return }
            var x = firstX
            n = 0
            while x <= area.maxX && n < limit {
                cg.fill(CGRect(x: (x - area.minX) * zoom, y: 0, width: thin, height: area.height * zoom))
                x += step
                n += 1
            }
        case .dots:
            let r = max(1, 1.6 * zoom)
            var y = firstY
            var rows = 0
            while y <= area.maxY && rows < limit {
                var x = firstX
                var cols = 0
                while x <= area.maxX && cols < limit {
                    cg.fillEllipse(in: CGRect(x: (x - area.minX) * zoom - r, y: (y - area.minY) * zoom - r, width: r * 2, height: r * 2))
                    x += step
                    cols += 1
                }
                y += step
                rows += 1
            }
        }
    }
}

/// The share sheet, for sending a sketch or saving it to Photos.
struct SketchShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
