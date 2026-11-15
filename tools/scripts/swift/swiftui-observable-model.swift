// @title @Observable Model
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ObservableDemoView() in ContentView's body.
// @keywords swiftui observable, swiftui @observable macro, swiftui bindable, swiftui shared model, swiftui environment object
// @about Keeps game data in an @Observable class that several views share, so they all update together.

import Observation
import SwiftUI

// @Observable makes SwiftUI watch every property of this class
@Observable
final class PlayerStats {
    var name = "Storm"
    var coins = 0
    var level = 1

    var coinsToNextLevel: Int { level * 50 - coins }

    func collect(_ amount: Int) {
        coins += amount
        if coins >= level * 50 {
            level += 1
        }
    }
}

struct ObservableDemoView: View {
    // @State owns the model so it lives as long as this view
    @State private var stats = PlayerStats()

    var body: some View {
        VStack(spacing: 20) {
            StatsHeader(stats: stats)
            CoinButtons(stats: stats)
            NameEditor(stats: stats)
        }
        .padding()
    }
}

struct StatsHeader: View {
    let stats: PlayerStats  // just reading, so a plain property is enough

    var body: some View {
        VStack {
            Text(stats.name).font(.largeTitle.bold())
            Text("Level \(stats.level)  |  \(stats.coins) coins")
            Text("\(stats.coinsToNextLevel) coins to the next level")
                .foregroundStyle(.secondary)
        }
    }
}

struct CoinButtons: View {
    let stats: PlayerStats

    var body: some View {
        HStack {
            ForEach([1, 5, 25], id: \.self) { amount in
                Button("+\(amount)") { stats.collect(amount) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct NameEditor: View {
    // @Bindable lets us make $bindings to an @Observable object's properties
    @Bindable var stats: PlayerStats

    var body: some View {
        TextField("Player name", text: $stats.name)
            .textFieldStyle(.roundedBorder)
    }
}
