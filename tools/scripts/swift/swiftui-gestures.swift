// @title Gestures: Tap, Drag and Long Press
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show GesturesDemoView() in ContentView's body.
// @keywords swiftui gestures, swiftui drag gesture, swiftui long press, swiftui double tap, swiftui magnify gesture
// @about Shows tap, double tap, long press, drag and pinch gestures, each changing a shape on screen.

import SwiftUI

struct GesturesDemoView: View {
    @State private var color = Color.blue
    @State private var offset = CGSize.zero
    @State private var saved = CGSize.zero
    @State private var scale = 1.0
    @State private var pressed = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Tap: color. Double tap: reset. Hold: shrink. Drag: move. Pinch: zoom.")
                .font(.footnote)
                .multilineTextAlignment(.center)

            Circle()
                .fill(color)
                .frame(width: 120, height: 120)
                .scaleEffect(pressed ? 0.7 * scale : scale)
                .offset(offset)
                .onTapGesture(count: 2) {
                    withAnimation(.spring) {
                        offset = .zero
                        saved = .zero
                        scale = 1
                    }
                }
                .onTapGesture {
                    color = [Color.red, .green, .orange, .purple, .blue].randomElement() ?? .blue
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    withAnimation { pressed.toggle() }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // translation is how far the finger moved since the drag started
                            offset = CGSize(width: saved.width + value.translation.width,
                                            height: saved.height + value.translation.height)
                        }
                        .onEnded { _ in saved = offset }
                )
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in scale = min(3, max(0.5, Double(value.magnification))) }
                )

            Spacer()
        }
        .padding()
    }
}
