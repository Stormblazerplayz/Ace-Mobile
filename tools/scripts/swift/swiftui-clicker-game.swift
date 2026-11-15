// @title Cookie Clicker Style Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ClickerGameView() in ContentView's body.
// @keywords swiftui clicker game, swiftui idle game, swiftui upgrades shop, swiftui saved progress
// @about Tap the big gem to earn coins, buy upgrades that earn coins for you, and your progress is saved.

import Combine
import SwiftUI

struct ClickerGameView: View {
    // @AppStorage keeps these numbers even after you close the app
    @AppStorage("clickerCoins") private var coins = 0
    @AppStorage("clickerPerTap") private var perTap = 1
    @AppStorage("clickerMiners") private var miners = 0
    @State private var bounce = false

    let incomeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Things get more expensive the more you own
    var tapUpgradeCost: Int { perTap * perTap * 15 }
    var minerCost: Int { 25 + miners * miners * 10 }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(coins) coins")
                .font(.system(size: 50, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("\(perTap) per tap  |  \(miners) per second").foregroundStyle(.secondary)

            Image(systemName: "diamond.fill")
                .font(.system(size: 150))
                .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                .scaleEffect(bounce ? 0.9 : 1)
                .onTapGesture {
                    coins += perTap
                    bounce = true
                    withAnimation(.spring(duration: 0.2)) { bounce = false }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: coins)

            VStack(spacing: 12) {
                Button("Stronger taps (+1 per tap): \(tapUpgradeCost) coins") {
                    coins -= tapUpgradeCost
                    perTap += 1
                }
                .disabled(coins < tapUpgradeCost)

                Button("Hire a miner (+1 per second): \(minerCost) coins") {
                    coins -= minerCost
                    miners += 1
                }
                .disabled(coins < minerCost)

                Button("Start over", role: .destructive) {
                    coins = 0
                    perTap = 1
                    miners = 0
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onReceive(incomeTimer) { _ in
            // Miners earn coins all by themselves
            withAnimation { coins += miners }
        }
    }
}
