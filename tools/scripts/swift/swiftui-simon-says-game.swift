// @title Simon Says Memory Game
// @category Games
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SimonSaysGameView() in ContentView's body.
// @keywords swiftui simon says, swiftui color sequence, swiftui memory pattern, swiftui async playback
// @about Watch the colored pads light up in order, then tap them back in the same order; the pattern grows each round.

import SwiftUI

struct SimonSaysGameView: View {
    let padColors: [Color] = [.green, .red, .yellow, .blue]

    @State private var sequence: [Int] = []
    @State private var playerStep = 0
    @State private var litPad: Int? = nil
    @State private var playingBack = false
    @State private var message = "Press Start"
    @State private var best = 0

    var body: some View {
        VStack(spacing: 24) {
            Text(message).font(.title.bold())
            Text("Round: \(sequence.count)   Best: \(best)")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<4, id: \.self) { pad in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(padColors[pad])
                        .opacity(litPad == pad ? 1 : 0.35)
                        .frame(height: 160)
                        .scaleEffect(litPad == pad ? 1.05 : 1)
                        .animation(.easeOut(duration: 0.15), value: litPad)
                        .onTapGesture { tapped(pad) }
                }
            }

            Button("Start") { start() }
                .buttonStyle(.borderedProminent)
                .disabled(playingBack)
        }
        .padding()
    }

    func start() {
        sequence = []
        addAndPlay()
    }

    func addAndPlay() {
        sequence.append(Int.random(in: 0..<4))
        playerStep = 0
        Task { await playBack() }
    }

    // Light up each pad in the sequence, one after another
    func playBack() async {
        playingBack = true
        message = "Watch..."
        try? await Task.sleep(for: .seconds(0.8))
        for pad in sequence {
            litPad = pad
            try? await Task.sleep(for: .seconds(0.5))
            litPad = nil
            try? await Task.sleep(for: .seconds(0.2))
        }
        playingBack = false
        message = "Your turn!"
    }

    func tapped(_ pad: Int) {
        guard !playingBack, !sequence.isEmpty else { return }
        flash(pad)
        if pad == sequence[playerStep] {
            playerStep += 1
            if playerStep == sequence.count {
                best = max(best, sequence.count)
                addAndPlay()   // you got them all, so the pattern gets longer
            }
        } else {
            message = "Oops! You remembered \(sequence.count - 1)"
            sequence = []
        }
    }

    func flash(_ pad: Int) {
        litPad = pad
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            if litPad == pad { litPad = nil }
        }
    }
}
