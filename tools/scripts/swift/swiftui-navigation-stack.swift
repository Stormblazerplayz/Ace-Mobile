// @title NavigationStack and NavigationLink
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show GameLibraryView() in ContentView's body.
// @keywords swiftui navigationstack, swiftui navigationlink, swiftui detail view, swiftui navigationdestination, swiftui push screen
// @about A list of games where tapping one slides in a detail screen, using NavigationStack.

import SwiftUI

struct LibraryGame: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let genre: String
    let rating: Int
    let symbol: String
}

struct GameLibraryView: View {
    let games = [
        LibraryGame(title: "Minecraft", genre: "Sandbox", rating: 5, symbol: "cube.fill"),
        LibraryGame(title: "Rocket League", genre: "Sports", rating: 4, symbol: "car.fill"),
        LibraryGame(title: "Terraria", genre: "Adventure", rating: 5, symbol: "tree.fill"),
        LibraryGame(title: "Tetris", genre: "Puzzle", rating: 4, symbol: "square.grid.3x3.fill"),
    ]

    var body: some View {
        NavigationStack {
            List(games) { game in
                // Tapping this row pushes the value; navigationDestination decides what to show
                NavigationLink(value: game) {
                    Label(game.title, systemImage: game.symbol)
                }
            }
            .navigationTitle("My Games")
            .navigationDestination(for: LibraryGame.self) { game in
                GameDetailView(game: game)
            }
        }
    }
}

struct GameDetailView: View {
    let game: LibraryGame

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: game.symbol)
                .font(.system(size: 100))
                .foregroundStyle(.tint)
            Text(game.title)
                .font(.largeTitle.bold())
            Text(game.genre)
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= game.rating ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
            .font(.title)
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
