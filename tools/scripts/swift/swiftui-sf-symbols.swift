// @title Images and SF Symbols
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SymbolsGalleryView() in ContentView's body.
// @keywords swiftui sf symbols, swiftui image systemname, swiftui symbol rendering, swiftui icons, swiftui label
// @about Shows Apple's built-in SF Symbols icons in different sizes, colors and rendering modes.

import SwiftUI

struct SymbolsGalleryView: View {
    let symbols = ["bolt.fill", "star.fill", "heart.fill", "gamecontroller.fill", "cpu", "paperplane.fill",
                   "flame.fill", "leaf.fill", "moon.stars.fill", "trophy.fill", "printer.fill", "hammer.fill"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // A symbol is an Image with a systemName
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)

                // Symbols can have more than one color
                HStack(spacing: 30) {
                    Image(systemName: "cloud.sun.rain.fill")
                        .symbolRenderingMode(.multicolor)
                    Image(systemName: "person.3.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                    Image(systemName: "speaker.wave.3.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.purple, .orange)
                }
                .font(.system(size: 44))

                // Label puts an icon and text together
                Label("Downloads", systemImage: "arrow.down.circle.fill")
                    .font(.title2)

                // A grid of symbols
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 20) {
                    ForEach(symbols, id: \.self) { name in
                        VStack {
                            Image(systemName: name)
                                .font(.largeTitle)
                                .foregroundStyle(.tint)
                            Text(name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
