import SwiftUI

/// The space above the keys: falling notes for songs, sparkles where notes are hit,
/// and music notes that float up when you play.
struct PianoStage: View {
    @ObservedObject var model: PianoModel
    /// How many beats of the song fit between the top and the line.
    static let beatsShown = 6.0

    var body: some View {
        GeometryReader { geo in
            let layout = PianoLayout(low: model.range.lowerBound, high: model.range.upperBound,
                                     size: CGSize(width: geo.size.width, height: 1))
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let now = timeline.date
                    if let song = model.song {
                        drawNotes(song, now: now, layout: layout, size: size, in: ctx)
                    }
                    drawBursts(now: now, layout: layout, size: size, in: ctx)
                    drawFloaters(now: now, layout: layout, size: size, in: ctx)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func hitY(_ size: CGSize) -> CGFloat { size.height - 10 }

    private func drawNotes(_ song: PianoSong, now: Date, layout: PianoLayout, size: CGSize, in ctx: GraphicsContext) {
        let beat = model.beat(at: now)
        let line = hitY(size)
        let perBeat = line / CGFloat(PianoStage.beatsShown)
        let lesson = model.lesson
        // The line the notes fall onto.
        ctx.drawLayer { glow in
            glow.addFilter(.blur(radius: 6))
            glow.fill(Path(CGRect(x: 0, y: line - 2, width: size.width, height: 4)), with: .color(AceTheme.ace.opacity(0.8)))
        }
        ctx.fill(Path(CGRect(x: 0, y: line - 1, width: size.width, height: 2)), with: .color(.white.opacity(0.85)))
        // Faint lanes under each white key, so you can see where a note will land.
        for midi in layout.whiteKeys {
            guard let r = layout.rect(midi) else { continue }
            ctx.fill(Path(CGRect(x: r.minX, y: 0, width: 1, height: line)), with: .color(.white.opacity(0.04)))
        }
        for (i, note) in song.notes.enumerated() {
            let bottom = line - CGFloat(note.beat - beat) * perBeat
            let height = max(14, CGFloat(note.length) * perBeat - 4)
            let top = bottom - height
            guard top < size.height, bottom > -4, let key = layout.rect(note.midi) else { continue }
            let played = lesson.map { i < $0.index } ?? (note.beat + note.length <= beat)
            let next = lesson.map { i == $0.index } ?? false
            let width = key.width * (PianoTheory.isBlack(note.midi) ? 0.86 : 0.7)
            let rect = CGRect(x: key.midX - width / 2, y: top, width: width, height: height)
            let shape = Path(roundedRect: rect, cornerRadius: min(10, width / 2.4))
            let color = PianoTheory.color(note.midi)
            if played {
                // Played notes melt into the line.
                ctx.fill(shape, with: .color(color.opacity(0.18)))
                continue
            }
            ctx.drawLayer { glow in
                glow.addFilter(.blur(radius: next ? 12 : 7))
                glow.fill(shape, with: .color(color.opacity(next ? 0.95 : 0.6)))
            }
            ctx.fill(shape, with: .linearGradient(Gradient(colors: [color.opacity(0.75), color]),
                                                  startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
            ctx.stroke(shape, with: .color(.white.opacity(next ? 0.95 : 0.35)), lineWidth: next ? 2.5 : 1)
            if height > 26 {
                let label = Text(PianoTheory.letter(note.midi))
                    .font(.system(size: min(15, width * 0.42), weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                ctx.draw(label, at: CGPoint(x: rect.midX, y: rect.maxY - 13))
            }
        }
    }

    private func drawBursts(now: Date, layout: PianoLayout, size: CGSize, in ctx: GraphicsContext) {
        let line = hitY(size)
        for burst in model.bursts {
            let age = now.timeIntervalSince(burst.born)
            guard age < 0.8, let x = layout.centerX(burst.midi) else { continue }
            let t = CGFloat(age / 0.8)
            let fade = Double(1 - t)
            let color = burst.right ? PianoTheory.color(burst.midi) : AceTheme.bad
            // A ring that spreads out...
            let ring: CGFloat = 10 + 46 * t
            ctx.stroke(Path(ellipseIn: CGRect(x: x - ring, y: line - ring * 0.6, width: ring * 2, height: ring * 1.2)),
                       with: .color(color.opacity(0.8 * fade)), lineWidth: 3 * (1 - t) + 0.5)
            guard burst.right else { continue }
            // ...and sparks that fly up and out.
            for k in 0..<8 {
                let angle = CGFloat.pi * (1.05 + 0.9 * CGFloat(k) / 7)
                let dist: CGFloat = 18 + 70 * t
                let p = CGPoint(x: x + cos(angle) * dist, y: line + sin(angle) * dist + 40 * t * t)
                let r: CGFloat = 3.5 * (1 - t) + 0.5
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                         with: .color(k.isMultiple(of: 2) ? .white.opacity(fade) : color.opacity(fade)))
            }
        }
    }

    private func drawFloaters(now: Date, layout: PianoLayout, size: CGSize, in ctx: GraphicsContext) {
        let line = hitY(size)
        for f in model.floaters {
            let age = now.timeIntervalSince(f.born)
            let life = 2.0
            guard age < life, let x = layout.centerX(f.midi) else { continue }
            let t = age / life
            let y = line - 20 - CGFloat(t) * min(size.height * 0.8, 260)
            let wobble = CGFloat(sin(age * 5 + f.drift) * 8 + f.drift * t)
            var c = ctx
            c.opacity = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85
            let text = Text(f.symbol)
                .font(.system(size: CGFloat(30 + 10 * (1 - t)), weight: .bold))
                .foregroundColor(PianoTheory.color(f.midi))
            c.addFilter(.shadow(color: PianoTheory.color(f.midi).opacity(0.9), radius: 8))
            c.draw(text, at: CGPoint(x: x + wobble, y: y))
        }
    }
}

/// The soft colored light behind the piano. It takes the colors of the last notes played
/// and drifts slowly (it holds still with Reduce Motion or Bouncy animations off).
struct PianoGlow: View {
    let hues: [Double]
    let moves: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !moves)) { timeline in
            let t = moves ? timeline.date.timeIntervalSinceReferenceDate : 0
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let hue = hues.indices.contains(i) ? hues[i] : 0.6
                        Circle()
                            .fill(Color(hue: hue, saturation: 0.7, brightness: 0.9).opacity(i == 0 ? 0.42 : 0.28))
                            .frame(width: geo.size.width * (0.75 - CGFloat(i) * 0.12))
                            .offset(x: geo.size.width * (CGFloat(i) - 1) * 0.32 + CGFloat(sin(t * 0.21 + Double(i) * 2.1)) * 40,
                                    y: geo.size.height * 0.1 + CGFloat(cos(t * 0.17 + Double(i) * 1.3)) * 50)
                            .blur(radius: 80)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
