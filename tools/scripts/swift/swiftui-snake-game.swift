// @title Snake Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SnakeGameView() in ContentView's body. Swipe to steer.
// @keywords swiftui snake game, swiftui swipe controls, swiftui game loop, swiftui grid game
// @about The classic snake game: swipe to steer, eat the red apples to grow, and don't hit the walls or yourself.

import Combine
import SwiftUI

struct GridPoint: Equatable {
    var x: Int
    var y: Int
}

enum SnakeDirection {
    case up, down, left, right
}

struct SnakeGameView: View {
    let columns = 20
    let rows = 20

    @State private var snake = [GridPoint(x: 10, y: 10), GridPoint(x: 9, y: 10)]
    @State private var direction = SnakeDirection.right
    @State private var lastMoved = SnakeDirection.right
    @State private var food = GridPoint(x: 15, y: 5)
    @State private var alive = true
    @State private var score = 0

    // The game loop: move the snake every 0.15 seconds
    let tick = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text(alive ? "Score: \(score)" : "Game over! Score: \(score)").font(.title.bold())

            GeometryReader { geo in
                let cell = min(geo.size.width / CGFloat(columns), geo.size.height / CGFloat(rows))
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: cell * CGFloat(columns), height: cell * CGFloat(rows))
                    ForEach(snake.indices, id: \.self) { index in
                        Rectangle()
                            .fill(index == 0 ? Color.green : Color.mint)
                            .frame(width: cell - 1, height: cell - 1)
                            .offset(x: CGFloat(snake[index].x) * cell, y: CGFloat(snake[index].y) * cell)
                    }
                    Circle()
                        .fill(Color.red)
                        .frame(width: cell, height: cell)
                        .offset(x: CGFloat(food.x) * cell, y: CGFloat(food.y) * cell)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .gesture(
                DragGesture(minimumDistance: 20).onEnded { value in
                    let move = value.translation
                    if abs(move.width) > abs(move.height) {
                        turn(move.width > 0 ? .right : .left)
                    } else {
                        turn(move.height > 0 ? .down : .up)
                    }
                }
            )

            if !alive {
                Button("Play again") { restart() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onReceive(tick) { _ in step() }
    }

    func turn(_ newDirection: SnakeDirection) {
        // The snake can't turn straight back into itself
        switch (lastMoved, newDirection) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            direction = newDirection
        }
    }

    func step() {
        guard alive, let head = snake.first else { return }
        var next = head
        switch direction {
        case .up: next.y -= 1
        case .down: next.y += 1
        case .left: next.x -= 1
        case .right: next.x += 1
        }
        lastMoved = direction

        let hitWall = next.x < 0 || next.x >= columns || next.y < 0 || next.y >= rows
        if hitWall || snake.contains(next) {
            alive = false
            return
        }
        snake.insert(next, at: 0)
        if next == food {
            score += 1
            placeFood()   // grow: we keep the tail this time
        } else {
            snake.removeLast()
        }
    }

    func placeFood() {
        repeat {
            food = GridPoint(x: Int.random(in: 0..<columns), y: Int.random(in: 0..<rows))
        } while snake.contains(food)
    }

    func restart() {
        snake = [GridPoint(x: 10, y: 10), GridPoint(x: 9, y: 10)]
        direction = .right
        lastMoved = .right
        score = 0
        alive = true
        placeFood()
    }
}
