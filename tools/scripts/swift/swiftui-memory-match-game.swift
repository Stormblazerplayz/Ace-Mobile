// @title Memory Match Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MemoryMatchGameView() in ContentView's body.
// @keywords swiftui memory match, swiftui card matching, swiftui concentration game, swiftui flip pairs
// @about Flip cards two at a time to find all the matching pairs in as few moves as you can.

import SwiftUI

struct MemoryTile: Identifiable {
    let id = UUID()
    let symbol: String
    var faceUp = false
    var matched = false
}

struct MemoryMatchGameView: View {
    @State private var tiles: [MemoryTile] = MemoryMatchGameView.newDeck()
    @State private var firstPick: Int? = nil
    @State private var moves = 0
    @State private var busy = false   // true while two wrong cards are showing

    var allMatched: Bool { tiles.allSatisfy { $0.matched } }

    // Two of each picture, shuffled
    static func newDeck() -> [MemoryTile] {
        let symbols = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "moon.fill", "flame.fill", "cloud.fill", "gamecontroller.fill"]
        return (symbols + symbols).shuffled().map { MemoryTile(symbol: $0) }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(allMatched ? "You won in \(moves) moves!" : "Moves: \(moves)")
                .font(.title.bold())

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(tiles.indices, id: \.self) { index in
                    let tile = tiles[index]
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(tile.faceUp || tile.matched ? Color.white : Color.blue)
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue, lineWidth: 3)
                        if tile.faceUp || tile.matched {
                            Image(systemName: tile.symbol)
                                .font(.system(size: 40))
                                .foregroundStyle(tile.matched ? Color.green : Color.orange)
                        }
                    }
                    .frame(height: 100)
                    .rotation3DEffect(.degrees(tile.faceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .onTapGesture { tap(index) }
                }
            }

            Button("New game") {
                tiles = MemoryMatchGameView.newDeck()
                firstPick = nil
                moves = 0
                busy = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func tap(_ index: Int) {
        guard !busy, !tiles[index].faceUp, !tiles[index].matched else { return }
        withAnimation(.easeInOut(duration: 0.3)) { tiles[index].faceUp = true }

        guard let first = firstPick else {
            firstPick = index   // this was the first card of the pair
            return
        }
        moves += 1
        firstPick = nil
        if tiles[first].symbol == tiles[index].symbol {
            tiles[first].matched = true
            tiles[index].matched = true
        } else {
            // Not a match: wait a moment so you can see them, then flip both back
            busy = true
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                withAnimation(.easeInOut(duration: 0.3)) {
                    tiles[first].faceUp = false
                    tiles[index].faceUp = false
                }
                busy = false
            }
        }
    }
}
