// @title Menus and Context Menus
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MenusDemoView() in ContentView's body.
// @keywords swiftui menu, swiftui context menu, swiftui long press menu, swiftui toolbar menu
// @about A pull-down Menu button and a long-press context menu, both changing a card on screen.

import SwiftUI

struct MenusDemoView: View {
    @State private var color = Color.blue
    @State private var symbol = "star.fill"
    @State private var isFavorite = false

    var body: some View {
        VStack(spacing: 30) {
            // A Menu shows a list of buttons when tapped
            Menu {
                Button("Blue") { color = .blue }
                Button("Green") { color = .green }
                Button("Orange") { color = .orange }
                Menu("More colors") {  // menus can be nested
                    Button("Pink") { color = .pink }
                    Button("Purple") { color = .purple }
                }
            } label: {
                Label("Pick a color", systemImage: "paintpalette")
            }
            .buttonStyle(.bordered)

            // A context menu appears when you press and hold
            VStack {
                Image(systemName: symbol)
                    .font(.system(size: 70))
                Text(isFavorite ? "Favorite!" : "Press and hold me")
            }
            .foregroundStyle(.white)
            .frame(width: 220, height: 180)
            .background(color, in: RoundedRectangle(cornerRadius: 24))
            .contextMenu {
                Button {
                    isFavorite.toggle()
                } label: {
                    Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "heart.slash" : "heart")
                }
                Button("Star") { symbol = "star.fill" }
                Button("Bolt") { symbol = "bolt.fill" }
                Button("Rocket") { symbol = "paperplane.fill" }
                Divider()
                Button("Reset", role: .destructive) {
                    color = .blue
                    symbol = "star.fill"
                    isFavorite = false
                }
            }
        }
        .padding()
    }
}
