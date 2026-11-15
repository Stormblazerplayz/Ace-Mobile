// @title Tap the Target Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TapTargetGameView() in ContentView's body.
// @keywords swiftui tap target game, swiftui moving target, swiftui 30 second game, swiftui position modifier
// @about Tap the red target as many times as you can in 30 seconds; it jumps around and gets smaller each hit.

import Combine
import SwiftUI

struct TapTargetGameView: View {
    // The target's spot is stored as fractions (0 to 1) of the play area
    @State private var target = CGPoint(x: 0.5, y: 0.5)
    @State private var targetSize: CGFloat = 90
    @State private var score = 0
    @State private var misses = 0
    @State private var timeLeft = 30
    @State private var playing = false

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            HStack {
                Text("Score: \(score)")
                Spacer()
                Text("Misses: \(misses)")
                Spacer()
                Text("Time: \(timeLeft)")
            }
            .font(.title2.bold())
            .padding()

            GeometryReader { geo in
                ZStack {
                    Color.gray.opacity(0.1)
                    if playing {
                        Circle()
                            .fill(Color.red)
                            .overlay(Circle().fill(Color.white).padding(targetSize / 4))
                            .frame(width: targetSize, height: targetSize)
                            .position(x: target.x * geo.size.width, y: target.y * geo.size.height)
                            .onTapGesture { hit() }
                    } else {
                        Button(timeLeft == 0 ? "Play again" : "Start") { start() }
                            .font(.largeTitle)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .contentShape(Rectangle())
                // Tapping the background (not the target) counts as a miss
                .onTapGesture { if playing { misses += 1 } }
            }
        }
        .onReceive(clock) { _ in
            guard playing else { return }
            timeLeft -= 1
            if timeLeft <= 0 { playing = false }
        }
    }

    func start() {
        score = 0
        misses = 0
        timeLeft = 30
        targetSize = 90
        playing = true
    }

    func hit() {
        score += 1
        targetSize = max(30, targetSize - 3)
        withAnimation(.spring(duration: 0.25)) {
            target = CGPoint(x: CGFloat.random(in: 0.1...0.9), y: CGFloat.random(in: 0.1...0.9))
        }
    }
}
