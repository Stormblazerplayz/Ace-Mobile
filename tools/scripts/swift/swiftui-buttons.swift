// @title Buttons
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ButtonsDemoView() in ContentView's body.
// @keywords swiftui button, swiftui button style, swiftui borderedprominent, swiftui button role, swiftui tap action
// @about Shows different kinds of buttons and what happens when you tap them.

import SwiftUI

struct ButtonsDemoView: View {
    @State private var message = "Tap a button!"
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 18) {
            Text(message)
                .font(.title2)
                .multilineTextAlignment(.center)
            Text("Total taps: \(taps)")
                .foregroundStyle(.secondary)

            // The simplest button: a title and an action
            Button("Plain button") {
                tapped("plain")
            }

            Button("Bordered") { tapped("bordered") }
                .buttonStyle(.bordered)

            Button("Prominent") { tapped("prominent") }
                .buttonStyle(.borderedProminent)

            Button("Big and green") { tapped("big green") }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)

            // A button with an icon and text
            Button {
                tapped("icon")
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.bordered)

            // A destructive role makes it red
            Button("Reset", role: .destructive) {
                taps = 0
                message = "Everything was reset."
            }
            .buttonStyle(.bordered)

            Button("Can't tap me") {}
                .disabled(true)
        }
        .padding()
    }

    func tapped(_ name: String) {
        taps += 1
        message = "You tapped the \(name) button!"
    }
}
