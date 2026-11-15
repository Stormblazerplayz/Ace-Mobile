// @title ProgressView and Gauge
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ProgressGaugeView() in ContentView's body.
// @keywords swiftui progressview, swiftui gauge, swiftui loading bar, swiftui spinner, swiftui circular progress
// @about Shows spinners, progress bars and gauges, with buttons to fill them up.

import SwiftUI

struct ProgressGaugeView: View {
    @State private var progress = 0.25
    @State private var speed = 40.0

    var body: some View {
        VStack(spacing: 28) {
            // A spinner (it has no value, it just spins)
            ProgressView("Loading levels...")

            // A bar that fills up
            ProgressView(value: progress) {
                Text("Download")
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
            }

            HStack {
                Button("+10%") { withAnimation { progress = min(1, progress + 0.1) } }
                Button("Reset") { withAnimation { progress = 0 } }
            }
            .buttonStyle(.bordered)

            // A round gauge, like a speedometer
            Gauge(value: speed, in: 0...120) {
                Text("km/h")
            } currentValueLabel: {
                Text("\(Int(speed))")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [.green, .yellow, .red]))
            .scaleEffect(1.8)
            .padding()

            Slider(value: $speed, in: 0...120)

            // A linear gauge with a capacity look
            Gauge(value: progress) {
                Text("Battery")
            }
            .gaugeStyle(.linearCapacity)
        }
        .padding()
    }
}
