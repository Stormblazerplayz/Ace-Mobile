// @title Color Mixer App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ColorMixerAppView() in ContentView's body.
// @keywords swiftui color mixer, swiftui rgb sliders, swiftui hex color, swiftui saved swatches
// @about Mixes red, green and blue with sliders, shows the hex code, and saves your favorite colors as swatches.

import SwiftUI

struct ColorMixerAppView: View {
    @State private var red = 0.4
    @State private var green = 0.7
    @State private var blue = 0.9
    @State private var swatches: [Color] = []

    var mixed: Color { Color(red: red, green: green, blue: blue) }

    // Web colors are written like #66B3E6 (two hex digits each for red, green, blue)
    var hexCode: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 30)
                .fill(mixed)
                .frame(height: 220)
                .overlay {
                    Text(hexCode)
                        .font(.system(.largeTitle, design: .monospaced).bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                }

            ColorSliderRow(name: "Red", value: $red, tint: .red)
            ColorSliderRow(name: "Green", value: $green, tint: .green)
            ColorSliderRow(name: "Blue", value: $blue, tint: .blue)

            HStack {
                Button("Random") {
                    red = Double.random(in: 0...1)
                    green = Double.random(in: 0...1)
                    blue = Double.random(in: 0...1)
                }
                Button("Save swatch") { swatches.append(mixed) }
            }
            .buttonStyle(.bordered)

            ScrollView(.horizontal) {
                HStack {
                    ForEach(swatches.indices, id: \.self) { index in
                        Circle().fill(swatches[index]).frame(width: 50, height: 50)
                    }
                }
            }
        }
        .padding()
        .animation(.default, value: hexCode)
    }
}

// One labeled slider; @Binding lets it change the parent's value
struct ColorSliderRow: View {
    let name: String
    @Binding var value: Double
    let tint: Color

    var body: some View {
        HStack {
            Text(name).frame(width: 60, alignment: .leading)
            Slider(value: $value, in: 0...1).tint(tint)
            Text("\(Int(value * 255))").monospacedDigit().frame(width: 40)
        }
    }
}
