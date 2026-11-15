// @title Drawing Pad App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show DrawingPadAppView() in ContentView's body. Draw with your finger or Apple Pencil.
// @keywords swiftui drawing pad, swiftui finger paint, swiftui draggesture path, swiftui undo strokes
// @about A finger painting app with colors, brush sizes, undo and clear, drawn with Canvas and DragGesture.

import SwiftUI

struct PaintStroke {
    var points: [CGPoint] = []
    var color: Color
    var width: CGFloat
}

struct DrawingPadAppView: View {
    @State private var strokes: [PaintStroke] = []
    @State private var current = PaintStroke(color: .black, width: 6)
    @State private var color = Color.black
    @State private var brushSize = 6.0

    let palette: [Color] = [.black, .red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        VStack {
            Canvas { context, _ in
                // Draw every finished stroke, then the one being drawn now
                for stroke in strokes + [current] {
                    var path = Path()
                    path.addLines(stroke.points)
                    context.stroke(path, with: .color(stroke.color),
                                   style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
                }
            }
            .background(Color.white)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        current.points.append(value.location)
                    }
                    .onEnded { _ in
                        strokes.append(current)
                        current = PaintStroke(color: color, width: CGFloat(brushSize))
                    }
            )

            HStack {
                ForEach(palette, id: \.self) { swatch in
                    Circle()
                        .fill(swatch)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.gray, lineWidth: swatch == color ? 4 : 0))
                        .onTapGesture {
                            color = swatch
                            current.color = swatch
                        }
                }
            }
            HStack {
                Text("Brush")
                Slider(value: $brushSize, in: 2...40)
                    .onChange(of: brushSize) { current.width = CGFloat(brushSize) }
                Button("Undo") { _ = strokes.popLast() }
                    .disabled(strokes.isEmpty)
                Button("Clear", role: .destructive) { strokes.removeAll() }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}
