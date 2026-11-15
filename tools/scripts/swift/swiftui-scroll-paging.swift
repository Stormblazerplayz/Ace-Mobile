// @title Paging Scroll View
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PagingCardsView() in ContentView's body.
// @keywords swiftui paging scroll, swiftui scrolltargetbehavior, swiftui carousel, swiftui scrollposition
// @about A sideways carousel of cards that snaps to each one, and shows which card you are on.

import SwiftUI

struct PagingCardsView: View {
    @State private var currentCard: Int? = 0

    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    let names = ["Fire", "Sunset", "Sun", "Forest", "Ocean", "Galaxy"]

    var body: some View {
        VStack(spacing: 20) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(colors.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 30)
                            .fill(colors[index].gradient)
                            .overlay {
                                Text(names[index])
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                            }
                            .padding(20)
                            .containerRelativeFrame(.horizontal)  // each card is one screen wide
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)  // snap to whole cards
            .scrollPosition(id: $currentCard)  // keeps currentCard up to date
            .frame(height: 320)

            // Little dots that show which page you are on
            HStack {
                ForEach(colors.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentCard ? Color.primary : Color.gray.opacity(0.4))
                        .frame(width: 10, height: 10)
                }
            }

            Button("Back to the first card") {
                withAnimation { currentCard = 0 }
            }
        }
    }
}
