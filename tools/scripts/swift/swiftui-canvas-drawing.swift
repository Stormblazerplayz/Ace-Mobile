// @title Canvas Drawing
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show CanvasArtView() in ContentView's body.
// @keywords swiftui canvas, swiftui graphicscontext, swiftui draw with code, swiftui generative art
// @about Draws a sunset scene with code using Canvas, and makes new random stars every time you tap.

import SwiftUI

struct CanvasArtView: View {
    @State private var seed = 0  // changing this redraws with new stars

    var body: some View {
        Canvas { context, size in
            // Sky
            let sky = Path(CGRect(origin: .zero, size: size))
            context.fill(sky, with: .linearGradient(Gradient(colors: [.indigo, .purple, .orange]),
                                                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

            // Stars: a seeded random generator so they only change when seed changes
            var generator = SeededGenerator(seed: UInt64(seed + 1))
            for _ in 0..<60 {
                let x = Double.random(in: 0...Double(size.width), using: &generator)
                let y = Double.random(in: 0...(Double(size.height) * 0.5), using: &generator)
                let r = Double.random(in: 1...3, using: &generator)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white))
            }

            // Sun
            let sunRect = CGRect(x: size.width / 2 - 60, y: size.height * 0.55, width: 120, height: 120)
            context.fill(Path(ellipseIn: sunRect), with: .color(.yellow))

            // Hills
            var hills = Path()
            hills.move(to: CGPoint(x: 0, y: size.height))
            hills.addLine(to: CGPoint(x: 0, y: size.height * 0.7))
            hills.addQuadCurve(to: CGPoint(x: size.width, y: size.height * 0.72),
                               control: CGPoint(x: size.width / 2, y: size.height * 0.55))
            hills.addLine(to: CGPoint(x: size.width, y: size.height))
            hills.closeSubpath()
            context.fill(hills, with: .color(.black.opacity(0.85)))

            // Text can be drawn too
            context.draw(Text("Tap for new stars").foregroundColor(.white), at: CGPoint(x: size.width / 2, y: size.height - 30))
        }
        .ignoresSafeArea()
        .onTapGesture { seed += 1 }
    }
}

// A tiny random number generator that gives the same numbers for the same seed
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
