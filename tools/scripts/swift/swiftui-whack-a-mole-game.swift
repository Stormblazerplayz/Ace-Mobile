// @title Whack-a-Mole Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show WhackAMoleGameView() in ContentView's body.
// @keywords swiftui whack a mole, swiftui popping moles, swiftui two timers, swiftui arcade tapping
// @about Moles pop up out of nine holes; whack as many as you can before the 30 seconds run out.

import Combine
import SwiftUI

struct WhackAMoleGameView: View {
    @State private var moleHole: Int? = nil
    @State private var score = 0
    @State private var misses = 0
    @State private var timeLeft = 30
    @State private var playing = false

    // One timer moves the mole, the other counts down the seconds
    let moleTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    let secondTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Whack-a-Mole").font(.largeTitle.bold())
            Text("Score: \(score)   Misses: \(misses)   Time: \(timeLeft)")
                .font(.title3)
                .monospacedDigit()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(0..<9, id: \.self) { hole in
                    ZStack(alignment: .bottom) {
                        Ellipse()
                            .fill(Color.brown)
                            .frame(height: 40)
                        if moleHole == hole {
                            Image(systemName: "hare.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                                .padding(.bottom, 10)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(height: 110)
                    .contentShape(Rectangle())
                    .onTapGesture { whack(hole) }
                }
            }
            .animation(.spring(duration: 0.2), value: moleHole)

            Button(playing ? "Playing..." : "Start") {
                score = 0
                misses = 0
                timeLeft = 30
                playing = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(playing)
        }
        .padding()
        .onReceive(moleTimer) { _ in
            guard playing else { return }
            moleHole = Int.random(in: 0..<9)
        }
        .onReceive(secondTimer) { _ in
            guard playing else { return }
            timeLeft -= 1
            if timeLeft <= 0 {
                playing = false
                moleHole = nil
            }
        }
    }

    func whack(_ hole: Int) {
        guard playing else { return }
        if hole == moleHole {
            score += 1
            moleHole = nil   // the mole hides after being hit
        } else {
            misses += 1
        }
    }
}
