// @title Dodge the Blocks Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show DodgeGameView() in ContentView's body. Drag your finger to move.
// @keywords swiftui dodge game, swiftui falling blocks, swiftui collision detection, swiftui drag to move
// @about Drag the blue player left and right to dodge falling blocks; the game speeds up as your score grows.

import Combine
import SwiftUI

struct FallingBlock: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let speed: CGFloat
}

struct DodgeGameView: View {
    @State private var playerX: CGFloat = 200
    @State private var blocks: [FallingBlock] = []
    @State private var score = 0
    @State private var gameOver = false
    @State private var area = CGSize(width: 400, height: 700)

    let playerWidth: CGFloat = 70
    let playerHeight: CGFloat = 26
    // About 30 frames every second
    let frameTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var playerY: CGFloat { area.height - 60 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                ForEach(blocks) { block in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange)
                        .frame(width: block.size, height: block.size)
                        .position(x: block.x, y: block.y)
                }
                Capsule()
                    .fill(Color.cyan)
                    .frame(width: playerWidth, height: playerHeight)
                    .position(x: playerX, y: playerY)
                VStack {
                    Text("Score: \(score)").font(.title.bold()).foregroundStyle(.white)
                    Spacer()
                }
                if gameOver {
                    VStack(spacing: 20) {
                        Text("Crash!").font(.largeTitle.bold()).foregroundStyle(.white)
                        Button("Play again") { restart() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    playerX = min(max(value.location.x, playerWidth / 2), area.width - playerWidth / 2)
                }
            )
            .onAppear { area = geo.size; playerX = geo.size.width / 2 }
            .onChange(of: geo.size) { area = geo.size }
        }
        .onReceive(frameTimer) { _ in step() }
    }

    func step() {
        guard !gameOver else { return }
        // Move every block down
        for index in blocks.indices {
            blocks[index].y += blocks[index].speed
        }
        // Blocks that fell off the bottom give you a point
        let before = blocks.count
        blocks.removeAll { $0.y > area.height + 50 }
        score += before - blocks.count

        // Sometimes add a new block; more often when your score is high
        let chance = 0.04 + Double(score) * 0.002
        if Double.random(in: 0...1) < chance {
            let size = CGFloat.random(in: 25...60)
            let speed = CGFloat.random(in: 4...8) + CGFloat(score) * 0.05
            blocks.append(FallingBlock(x: CGFloat.random(in: 0...area.width), y: -size, size: size, speed: speed))
        }

        // Check if any block touches the player
        for block in blocks {
            let closeX = abs(block.x - playerX) < (block.size + playerWidth) / 2
            let closeY = abs(block.y - playerY) < (block.size + playerHeight) / 2
            if closeX && closeY {
                gameOver = true
            }
        }
    }

    func restart() {
        blocks.removeAll()
        score = 0
        playerX = area.width / 2
        gameOver = false
    }
}
