// @title Grid Layout
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show GridLayoutView() in ContentView's body.
// @keywords swiftui grid, swiftui gridrow, swiftui table layout, swiftui gridcellcolumns
// @about Lines things up in rows and columns with Grid, like a scoreboard table.

import SwiftUI

struct GridLayoutView: View {
    let players: [(String, Int, Int)] = [("Storm", 1200, 8), ("Ace", 980, 6), ("Pixel", 850, 5), ("Nova", 610, 3)]

    var totalPoints: Int {
        var total = 0
        for player in players { total += player.1 }
        return total
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Scoreboard").font(.largeTitle.bold())

            // Grid makes every column as wide as its widest cell
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    Text("Player").bold()
                    Text("Score").bold()
                    Text("Wins").bold()
                }
                Divider()
                ForEach(players.indices, id: \.self) { index in
                    let player = players[index]
                    GridRow {
                        Text("\(index + 1). \(player.0)")
                        Text("\(player.1)")
                            .gridColumnAlignment(.trailing)
                        Text(String(repeating: "*", count: player.2))
                            .foregroundStyle(.orange)
                    }
                }
                GridRow {
                    // This cell stretches across all 3 columns
                    Text("Total points: \(totalPoints)")
                        .gridCellColumns(3)
                        .padding(.top)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding()
    }
}
