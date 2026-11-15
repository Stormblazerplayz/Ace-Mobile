// @title Dice Roller App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show DiceRollerAppView() in ContentView's body.
// @keywords swiftui dice roller, swiftui die face symbols, swiftui roll animation, swiftui random numbers
// @about Rolls up to six dice with a spin animation, adds them up and remembers your last rolls.

import SwiftUI

struct DiceRollerAppView: View {
    @State private var diceCount = 2
    @State private var values: [Int] = [1, 1, 1, 1, 1, 1]
    @State private var spin = 0.0
    @State private var history: [Int] = []

    var total: Int { values.prefix(diceCount).reduce(0, +) }

    var body: some View {
        VStack(spacing: 24) {
            Text("Dice Roller").font(.largeTitle.bold())

            Stepper("Number of dice: \(diceCount)", value: $diceCount, in: 1...6)

            // Show one die picture for each die. SF Symbols has die.face.1 to die.face.6
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                ForEach(0..<diceCount, id: \.self) { index in
                    Image(systemName: "die.face.\(values[index]).fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(spin))
                }
            }

            Text("Total: \(total)").font(.title.bold())

            Button("Roll!") { roll() }
                .font(.title2)
                .buttonStyle(.borderedProminent)

            if !history.isEmpty {
                Text("Last rolls: " + history.map(String.init).joined(separator: ", "))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .sensoryFeedback(.impact, trigger: spin)
    }

    func roll() {
        for index in values.indices {
            values[index] = Int.random(in: 1...6)
        }
        withAnimation(.spring(duration: 0.6)) {
            spin += 360
        }
        history.insert(total, at: 0)   // newest first
        if history.count > 8 {
            history.removeLast()
        }
    }
}
