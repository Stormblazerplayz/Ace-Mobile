// @title Flashcards App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show FlashcardsAppView() in ContentView's body.
// @keywords swiftui flashcards, swiftui flip card, swiftui 3d rotation, swiftui study app
// @about Study flashcards that flip over in 3D when you tap them, with buttons to mark if you knew the answer.

import SwiftUI

struct StudyCard {
    let front: String
    let back: String
}

struct FlashcardsAppView: View {
    let cards = [
        StudyCard(front: "7 x 8", back: "56"),
        StudyCard(front: "Capital of Japan", back: "Tokyo"),
        StudyCard(front: "Hola", back: "Hello (Spanish)"),
        StudyCard(front: "Swift keyword for a constant", back: "let"),
        StudyCard(front: "Fastest land animal", back: "Cheetah"),
        StudyCard(front: "12 squared", back: "144"),
    ]

    @State private var index = 0
    @State private var flipped = false
    @State private var known = 0
    @State private var practice = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("Card \(index + 1) of \(cards.count)").foregroundStyle(.secondary)

            ZStack {
                CardFace(text: cards[index].front, color: .indigo)
                    .opacity(flipped ? 0 : 1)
                CardFace(text: cards[index].back, color: .orange)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))  // so the back isn't mirrored
                    .opacity(flipped ? 1 : 0)
            }
            .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .onTapGesture {
                withAnimation(.spring(duration: 0.5)) { flipped.toggle() }
            }

            Text("Tap the card to flip it").font(.caption)

            HStack(spacing: 20) {
                Button("Need practice") { practice += 1; next() }
                    .buttonStyle(.bordered)
                    .tint(.red)
                Button("I knew it!") { known += 1; next() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }

            Text("Knew: \(known)   Practice: \(practice)")
        }
        .padding()
    }

    func next() {
        flipped = false
        index = (index + 1) % cards.count  // go back to the start after the last card
    }
}

struct CardFace: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding()
            .frame(width: 320, height: 220)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 6)
    }
}
