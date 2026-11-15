// @title Custom Button Styles
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ButtonStylesDemoView() in ContentView's body.
// @keywords swiftui buttonstyle, swiftui custom button, swiftui ispressed, swiftui bouncy button, swiftui arcade button
// @about Builds your own button looks with ButtonStyle, including one that squishes when pressed.

import SwiftUI

// A button that shrinks a little while your finger is on it
struct BouncyButtonStyle: ButtonStyle {
    var color: Color = .pink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .background(color, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// A chunky retro arcade button with a "3D" bottom edge
struct ArcadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.system(.title3, design: .rounded).bold())
            .foregroundStyle(.black)
            .frame(width: 120, height: 120)
            .background(Circle().fill(Color.yellow))
            .background(Circle().fill(Color.orange).offset(y: pressed ? 0 : 8))
            .offset(y: pressed ? 8 : 0)
    }
}

struct ButtonStylesDemoView: View {
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 40) {
            Text("Taps: \(taps)").font(.largeTitle)

            Button("Bouncy!") { taps += 1 }
                .buttonStyle(BouncyButtonStyle())

            Button("Green bounce") { taps += 1 }
                .buttonStyle(BouncyButtonStyle(color: .green))

            Button("PUSH") { taps += 5 }
                .buttonStyle(ArcadeButtonStyle())
        }
        .padding()
    }
}
