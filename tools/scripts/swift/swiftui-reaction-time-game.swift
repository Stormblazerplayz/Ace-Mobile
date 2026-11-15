// @title Reaction Time Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ReactionTimeGameView() in ContentView's body.
// @keywords swiftui reaction time, swiftui reflex test, swiftui milliseconds, swiftui cancel task
// @about Wait for the screen to turn green, then tap as fast as you can to see your reaction time in milliseconds.

import SwiftUI

enum ReactionPhase {
    case idle, waiting, go, result, tooSoon
}

struct ReactionTimeGameView: View {
    @State private var phase = ReactionPhase.idle
    @State private var goTime = Date.now
    @State private var lastMs = 0
    @State private var bestMs: Int? = nil
    @State private var waitTask: Task<Void, Never>? = nil

    var screenColor: Color {
        switch phase {
        case .idle, .result: return .blue
        case .waiting: return .red
        case .go: return .green
        case .tooSoon: return .orange
        }
    }

    var message: String {
        switch phase {
        case .idle: return "Tap to start"
        case .waiting: return "Wait for green..."
        case .go: return "TAP NOW!"
        case .result: return "\(lastMs) ms\nTap to try again"
        case .tooSoon: return "Too soon!\nTap to try again"
        }
    }

    var body: some View {
        ZStack {
            screenColor.ignoresSafeArea()
            VStack(spacing: 20) {
                Text(message)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                if let bestMs {
                    Text("Best: \(bestMs) ms").font(.title2)
                }
            }
            .foregroundStyle(.white)
        }
        .contentShape(Rectangle())
        .onTapGesture { tapped() }
    }

    func tapped() {
        switch phase {
        case .idle, .result, .tooSoon:
            startWaiting()
        case .waiting:
            waitTask?.cancel()   // you tapped before green!
            phase = .tooSoon
        case .go:
            lastMs = Int(Date.now.timeIntervalSince(goTime) * 1000)
            bestMs = min(bestMs ?? lastMs, lastMs)
            phase = .result
        }
    }

    func startWaiting() {
        phase = .waiting
        // Wait a random time so you can't guess when it turns green
        waitTask = Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 1.5...4)))
            if !Task.isCancelled && phase == .waiting {
                goTime = .now
                phase = .go
            }
        }
    }
}
