// @title Text and Fonts
// @category SwiftUI basics
// @kind SwiftUI view
// @where In Xcode or Swift Playgrounds, add a new Swift file to your iOS 17 app, paste this in, then put TextStylesView() inside ContentView's body.
// @keywords swiftui text, swiftui font, swiftui bold italic, swiftui foregroundstyle, swiftui text styles
// @about Shows the many ways to style text in SwiftUI: sizes, weights, colors, designs and markdown.

import SwiftUI

struct TextStylesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Large Title").font(.largeTitle)
                Text("Title").font(.title)
                Text("Headline").font(.headline)
                Text("Body text is the normal size.").font(.body)
                Text("Caption is tiny.").font(.caption)

                Divider()

                Text("Bold").bold()
                Text("Italic").italic()
                Text("Underlined").underline()
                Text("Crossed out").strikethrough()
                Text("Heavy and rounded").font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("Monospaced like code").font(.system(.body, design: .monospaced))

                Divider()

                Text("Blue text").foregroundStyle(.blue)
                Text("Gradient text")
                    .font(.title.bold())
                    .foregroundStyle(LinearGradient(colors: [.orange, .pink, .purple], startPoint: .leading, endPoint: .trailing))
                Text("Text with a background")
                    .padding(8)
                    .background(.yellow, in: RoundedRectangle(cornerRadius: 8))

                // Markdown works inside Text!
                Text("You can use **bold**, *italic* and `code` with markdown.")

                // Long text can be limited to a number of lines
                Text("This is a very long sentence that keeps going and going so it will be cut off after two lines with three dots at the end.")
                    .lineLimit(2)

                // Mixing styles in one line with string interpolation
                Text("Score: \(Text("9001").bold().foregroundColor(.green)) points")
            }
            .padding()
        }
    }
}
