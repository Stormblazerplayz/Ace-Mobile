// @title ColorPicker
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ColorPickerDemoView() in ContentView's body.
// @keywords swiftui colorpicker, swiftui pick color, swiftui color well, swiftui gradient from colors
// @about Pick two colors with the system color picker and see them blended in a gradient.

import SwiftUI

struct ColorPickerDemoView: View {
    @State private var topColor = Color.orange
    @State private var bottomColor = Color.purple
    @State private var useGradient = true

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 24)
                .fill(useGradient
                      ? AnyShapeStyle(LinearGradient(colors: [topColor, bottomColor], startPoint: .top, endPoint: .bottom))
                      : AnyShapeStyle(topColor))
                .frame(height: 300)
                .overlay {
                    Text("My Colors")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }

            ColorPicker("Top color", selection: $topColor)
            ColorPicker("Bottom color", selection: $bottomColor, supportsOpacity: false)
            Toggle("Blend into a gradient", isOn: $useGradient)

            Button("Swap colors") {
                let old = topColor
                topColor = bottomColor
                bottomColor = old
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
