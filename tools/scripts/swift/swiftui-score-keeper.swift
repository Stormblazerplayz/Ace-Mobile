// @title Score Keeper App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ScoreKeeperAppView() in ContentView's body.
// @keywords swiftui score keeper, swiftui board game scores, swiftui leader highlight, swiftui add players
// @about Keeps score for a board game night, with plus and minus buttons and a crown on whoever is winning.

import SwiftUI

struct ScorePlayer: Identifiable {
    let id = UUID()
    var name: String
    var score = 0
}

struct ScoreKeeperAppView: View {
    @State private var players = [ScorePlayer(name: "Storm"), ScorePlayer(name: "Player 2")]
    @State private var newName = ""

    var topScore: Int { players.map(\.score).max() ?? 0 }

    var body: some View {
        NavigationStack {
            List {
                ForEach($players) { $player in
                    HStack {
                        if player.score == topScore && topScore > 0 {
                            Image(systemName: "crown.fill").foregroundStyle(.yellow)
                        }
                        TextField("Name", text: $player.name)
                            .font(.headline)
                        Text("\(player.score)")
                            .font(.title.bold())
                            .monospacedDigit()
                            .frame(minWidth: 50)
                        Button {
                            player.score -= 1
                        } label: {
                            Image(systemName: "minus.circle.fill").font(.title)
                        }
                        .buttonStyle(.borderless)
                        .tint(.red)
                        Button {
                            player.score += 1
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.title)
                        }
                        .buttonStyle(.borderless)
                        .tint(.green)
                    }
                }
                .onDelete { offsets in players.remove(atOffsets: offsets) }

                HStack {
                    TextField("New player", text: $newName)
                    Button("Add") {
                        players.append(ScorePlayer(name: newName))
                        newName = ""
                    }
                    .disabled(newName.isEmpty)
                }
            }
            .navigationTitle("Scores")
            .toolbar {
                Button("Reset scores") {
                    for index in players.indices { players[index].score = 0 }
                }
            }
        }
    }
}
