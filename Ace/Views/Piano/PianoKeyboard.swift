import SwiftUI
import UIKit

/// The keys: drawn in one Canvas, with a touch layer on top so you can play chords and
/// slide a finger across the keys. Pressed keys light up in their own color and sink a little.
struct PianoKeyboard: View {
    @ObservedObject var model: PianoModel
    var labels: Bool
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let layout = PianoLayout(low: model.range.lowerBound, high: model.range.upperBound, size: geo.size)
            ZStack {
                TimelineView(.animation(minimumInterval: 1 / 30, paused: model.hintKey == nil || !AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion))) { timeline in
                    Canvas { ctx, _ in
                        let pulse = 0.5 + 0.5 * sin(timeline.date.timeIntervalSinceReferenceDate * 5)
                        draw(layout, pulse: pulse, in: ctx)
                    }
                }
                PianoTouchSurface(layout: layout,
                                  onDown: { midi, velocity in model.press(midi, velocity: velocity) },
                                  onUp: { midi in model.release(midi) })
            }
        }
    }

    private func state(_ midi: Int) -> (lit: Bool, wrong: Bool, hint: Bool) {
        (model.held.contains(midi) || model.aceHeld.contains(midi), model.wrongKey == midi, model.hintKey == midi)
    }

    private func draw(_ layout: PianoLayout, pulse: Double, in ctx: GraphicsContext) {
        // White keys first, then the black keys on top.
        for midi in layout.whiteKeys {
            guard let r = layout.rect(midi) else { continue }
            let s = state(midi)
            let key = r.insetBy(dx: 1, dy: 0)
            // A pressed key sinks: it gets a little shorter and darker at the top.
            let face = CGRect(x: key.minX, y: key.minY + (s.lit ? 3 : 0), width: key.width, height: key.height - (s.lit ? 3 : 0))
            let shape = Path(roundedRect: face, cornerRadii: .init(topLeading: 0, bottomLeading: 9, bottomTrailing: 9, topTrailing: 0))
            if s.wrong {
                ctx.fill(shape, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFB3AC), AceTheme.bad]),
                                                     startPoint: CGPoint(x: face.midX, y: face.minY), endPoint: CGPoint(x: face.midX, y: face.maxY)))
            } else if s.lit {
                ctx.fill(shape, with: .linearGradient(Gradient(colors: [PianoTheory.color(midi, saturation: 0.35), PianoTheory.color(midi)]),
                                                     startPoint: CGPoint(x: face.midX, y: face.minY), endPoint: CGPoint(x: face.midX, y: face.maxY)))
            } else {
                ctx.fill(shape, with: .linearGradient(Gradient(colors: [Color(hex: 0xD9D7E6), .white, Color(hex: 0xF4F3FA)]),
                                                     startPoint: CGPoint(x: face.midX, y: face.minY), endPoint: CGPoint(x: face.midX, y: face.maxY)))
            }
            if s.hint && !s.lit {
                let glow = PianoTheory.color(midi).opacity(0.45 + 0.4 * pulse)
                ctx.fill(shape, with: .color(glow))
                ctx.stroke(shape, with: .color(PianoTheory.color(midi, brightness: 0.85)), lineWidth: 3)
            }
            ctx.stroke(shape, with: .color(.black.opacity(0.35)), lineWidth: 1)
            // A bottom lip, like a real key.
            let lip = CGRect(x: face.minX + 2, y: face.maxY - 7, width: face.width - 4, height: 5)
            ctx.fill(Path(roundedRect: lip, cornerRadius: 2.5), with: .color(.black.opacity(s.lit ? 0.08 : 0.12)))
            if labels || s.hint {
                let text = Text(PianoTheory.letter(midi) + (midi % 12 == 0 ? String(midi / 12 - 1) : ""))
                    .font(.system(size: min(16, r.width * 0.32), weight: .heavy, design: .rounded))
                    .foregroundColor(s.lit || s.hint ? .white : Color(hex: 0x5A5772))
                ctx.draw(text, at: CGPoint(x: r.midX, y: r.maxY - 22))
            }
        }
        for midi in layout.blackKeys {
            guard let r = layout.rect(midi) else { continue }
            let s = state(midi)
            let face = CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - (s.lit ? 4 : 0))
            let shape = Path(roundedRect: face, cornerRadii: .init(topLeading: 0, bottomLeading: 6, bottomTrailing: 6, topTrailing: 0))
            // A shadow on the white keys below.
            ctx.fill(Path(roundedRect: face.offsetBy(dx: 2, dy: 3), cornerRadius: 6), with: .color(.black.opacity(0.25)))
            let top: Color, bottom: Color
            if s.wrong {
                top = Color(hex: 0xFF8077); bottom = AceTheme.bad
            } else if s.lit {
                top = PianoTheory.color(midi, brightness: 1); bottom = PianoTheory.color(midi, brightness: 0.6)
            } else {
                top = Color(hex: 0x3A3850); bottom = Color(hex: 0x121019)
            }
            ctx.fill(shape, with: .linearGradient(Gradient(colors: [top, bottom]),
                                                 startPoint: CGPoint(x: face.midX, y: face.minY), endPoint: CGPoint(x: face.midX, y: face.maxY)))
            if s.hint && !s.lit {
                ctx.fill(shape, with: .color(PianoTheory.color(midi).opacity(0.4 + 0.45 * pulse)))
                ctx.stroke(shape, with: .color(.white.opacity(0.9)), lineWidth: 2)
            }
            // A shine near the bottom.
            let shine = CGRect(x: face.minX + 3, y: face.maxY - 12, width: face.width - 6, height: 6)
            ctx.fill(Path(roundedRect: shine, cornerRadius: 3), with: .color(.white.opacity(s.lit ? 0.3 : 0.12)))
            if s.hint {
                let text = Text(PianoTheory.letter(midi))
                    .font(.system(size: min(13, r.width * 0.36), weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                ctx.draw(text, at: CGPoint(x: r.midX, y: r.maxY - 22))
            }
        }
    }
}

/// The touch layer over the keys. Every finger is tracked, so chords work, and sliding a finger
/// plays each key it moves onto. Pressing lower on a key plays it louder, like on a real piano.
struct PianoTouchSurface: UIViewRepresentable {
    let layout: PianoLayout
    let onDown: (Int, Float) -> Void
    let onUp: (Int) -> Void

    func makeUIView(context: Context) -> PianoTouchView {
        let v = PianoTouchView()
        v.isMultipleTouchEnabled = true
        v.backgroundColor = .clear
        v.isAccessibilityElement = true
        v.accessibilityLabel = "Piano keys"
        v.accessibilityHint = "Touch the keys to play notes."
        v.accessibilityTraits = [.allowsDirectInteraction, .playsSound]
        return v
    }

    func updateUIView(_ v: PianoTouchView, context: Context) {
        if v.layout != layout {
            // The keyboard changed (a new octave or a song): let go of every key first.
            v.releaseAll()
        }
        v.layout = layout
        v.onDown = onDown
        v.onUp = onUp
    }

    static func dismantleUIView(_ v: PianoTouchView, coordinator: ()) {
        v.releaseAll()
    }
}

final class PianoTouchView: UIView {
    var layout = PianoLayout(low: 60, high: 84, size: .zero)
    var onDown: (Int, Float) -> Void = { _, _ in }
    var onUp: (Int) -> Void = { _ in }
    private var touchKeys: [ObjectIdentifier: Int] = [:]

    private func velocity(_ touch: UITouch, key: Int) -> Float {
        if touch.type == .pencil, touch.maximumPossibleForce > 0 {
            return Float(max(0.3, min(1, touch.force / touch.maximumPossibleForce * 1.4)))
        }
        guard let r = layout.rect(key), r.height > 0 else { return 0.8 }
        let y = touch.location(in: self).y
        return Float(0.55 + 0.45 * min(1, max(0, (y - r.minY) / r.height)))
    }

    private func isHeldByAnother(_ key: Int, except id: ObjectIdentifier) -> Bool {
        touchKeys.contains { $0.key != id && $0.value == key }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let id = ObjectIdentifier(t)
            guard let key = layout.key(at: t.location(in: self)) else { continue }
            let alreadyDown = isHeldByAnother(key, except: id)
            touchKeys[id] = key
            if !alreadyDown { onDown(key, velocity(t, key: key)) }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let id = ObjectIdentifier(t)
            let now = layout.key(at: t.location(in: self))
            let was = touchKeys[id]
            guard now != was else { continue }
            touchKeys[id] = now
            if let was, !isHeldByAnother(was, except: id) { onUp(was) }
            if let now, !isHeldByAnother(now, except: id) { onDown(now, velocity(t, key: now)) }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lift(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lift(touches)
    }

    private func lift(_ touches: Set<UITouch>) {
        for t in touches {
            let id = ObjectIdentifier(t)
            guard let key = touchKeys.removeValue(forKey: id) else { continue }
            if !isHeldByAnother(key, except: id) { onUp(key) }
        }
    }

    func releaseAll() {
        let keys = Set(touchKeys.values)
        touchKeys = [:]
        for k in keys { onUp(k) }
    }
}
