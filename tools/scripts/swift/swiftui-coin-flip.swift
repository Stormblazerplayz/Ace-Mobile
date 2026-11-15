// @title Coin Flip App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show CoinFlipAppView() in ContentView's body.
// @keywords swiftui coin flip, swiftui heads or tails, swiftui flip animation, swiftui probability counter
// @about Flips a coin with a spinning 3D animation and keeps count of heads and tails.

import SwiftUI

struct CoinFlipAppView: View {
    @State private var isHeads = true
    @State private var rotation = 0.0
    @State private var heads = 0
    @State private var tails = 0
    @State private var flipping = false

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .frame(width: 220, height: 220)
                    .shadow(radius: 8)
                Text(flipping ? "?" : (isHeads ? "HEADS" : "TAILS"))
                    .font(.title.bold())
                    .foregroundStyle(.brown)
            }
            .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0))

            Button("Flip!") { flip() }
                .font(.title)
                .buttonStyle(.borderedProminent)
                .disabled(flipping)

            HStack(spacing: 40) {
                VStack { Text("\(heads)").font(.largeTitle.bold()); Text("Heads") }
                VStack { Text("\(tails)").font(.largeTitle.bold()); Text("Tails") }
            }

            let flips = heads + tails
            if flips > 0 {
                Text("Heads came up \(heads * 100 / flips)% of the time")
                    .foregroundStyle(.secondary)
            }
            Button("Reset") { heads = 0; tails = 0 }
        }
        .padding()
    }

    func flip() {
        flipping = true
        withAnimation(.easeOut(duration: 1)) {
            rotation += 360 * 5  // spin around five times
        }
        Task {
            try? await Task.sleep(for: .seconds(1))
            isHeads = Bool.random()
            if isHeads { heads += 1 } else { tails += 1 }
            flipping = false
        }
    }
}
