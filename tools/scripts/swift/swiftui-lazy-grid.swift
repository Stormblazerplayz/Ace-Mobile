// @title Grids with LazyVGrid
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show EmojiGridView() in ContentView's body.
// @keywords swiftui lazyvgrid, swiftui grid layout, swiftui griditem adaptive, swiftui scrollview grid
// @about A scrolling grid of colorful tiles that adjusts how many columns fit, and highlights the one you tap.

import SwiftUI

struct EmojiGridView: View {
    let items = ["🐶", "🐱", "🦊", "🐼", "🐸", "🐵", "🦄", "🐙", "🦖", "🐢", "🦁", "🐧",
                 "🐝", "🦋", "🐳", "🦉", "🐯", "🐨", "🐷", "🐮"]
    @State private var picked: String?
    @State private var columnCount = 4.0

    var body: some View {
        VStack {
            Text(picked.map { "You picked \($0)" } ?? "Tap an animal")
                .font(.title2)
            Stepper("Columns: \(Int(columnCount))", value: $columnCount, in: 2...6)
                .padding(.horizontal)

            ScrollView {
                // Each GridItem is one column. .flexible() shares the space equally.
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: Int(columnCount)), spacing: 12) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 40))
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(picked == item ? Color.yellow : Color.gray.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .onTapGesture {
                                withAnimation { picked = item }
                            }
                    }
                }
                .padding()
            }
        }
    }
}
