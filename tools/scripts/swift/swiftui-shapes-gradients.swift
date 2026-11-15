// @title Shapes and Gradients
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ShapesGradientsView() in ContentView's body.
// @keywords swiftui shapes, swiftui gradient, swiftui custom shape path, swiftui stroke fill, swiftui angular gradient
// @about Shows SwiftUI's built-in shapes, three kinds of gradients, and a custom star shape made with Path.

import SwiftUI

// A custom shape: you describe its outline with a Path
struct StarShape: Shape {
    var points = 5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        var path = Path()
        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct ShapesGradientsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Circle().fill(.red)
                    Rectangle().fill(.orange)
                    RoundedRectangle(cornerRadius: 16).fill(.yellow)
                    Capsule().fill(.green)
                    Ellipse().stroke(.blue, lineWidth: 4)
                }
                .frame(height: 60)

                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 100)
                    .overlay(Text("Linear").foregroundStyle(.white).bold())

                Circle()
                    .fill(RadialGradient(colors: [.yellow, .orange, .red], center: .center, startRadius: 5, endRadius: 90))
                    .frame(width: 180, height: 180)
                    .overlay(Text("Radial").bold())

                Circle()
                    .strokeBorder(AngularGradient(colors: [.red, .yellow, .green, .blue, .purple, .red], center: .center), lineWidth: 24)
                    .frame(width: 180, height: 180)
                    .overlay(Text("Angular").bold())

                StarShape(points: 5)
                    .fill(.yellow)
                    .overlay(StarShape(points: 5).stroke(.orange, lineWidth: 4))
                    .frame(width: 200, height: 200)
            }
            .padding()
        }
    }
}
