// @title Toggle, Slider and Stepper
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ControlsDemoView() in ContentView's body.
// @keywords swiftui toggle, swiftui slider, swiftui stepper, swiftui controls, swiftui switch
// @about Three common controls: a Toggle switch, a Slider for picking a value and a Stepper for counting.

import SwiftUI

struct ControlsDemoView: View {
    @State private var lightsOn = true
    @State private var brightness = 0.7
    @State private var robots = 3

    var body: some View {
        VStack(spacing: 28) {
            // A preview that reacts to all three controls
            HStack {
                ForEach(0..<robots, id: \.self) { _ in
                    Image(systemName: "figure.wave")
                        .font(.largeTitle)
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(lightsOn ? Color.yellow.opacity(brightness) : Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Toggle: on or off
            Toggle("Lights", isOn: $lightsOn)

            // Slider: drag to pick a number between two values
            VStack(alignment: .leading) {
                Text("Brightness: \(Int(brightness * 100))%")
                Slider(value: $brightness, in: 0.1...1) {
                    Text("Brightness")
                } minimumValueLabel: {
                    Image(systemName: "sun.min")
                } maximumValueLabel: {
                    Image(systemName: "sun.max.fill")
                }
                .disabled(!lightsOn)
            }

            // Stepper: tap + or - to count
            Stepper("Robots: \(robots)", value: $robots, in: 1...6)
        }
        .padding()
    }
}
