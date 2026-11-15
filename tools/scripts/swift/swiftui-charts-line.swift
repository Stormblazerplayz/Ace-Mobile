// @title Line Chart with Swift Charts
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show LineChartDemoView() in ContentView's body.
// @keywords swiftui line chart, swiftui linemark, swiftui pointmark, swiftui temperature graph
// @about A line chart of temperatures over a week, with dots on each point and a button to make new data.

import Charts
import SwiftUI

struct TempReading: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let celsius: Double
}

struct LineChartDemoView: View {
    @State private var readings: [TempReading] = LineChartDemoView.makeReadings()

    // static means this belongs to the type, so we can use it to set the starting value
    static func makeReadings() -> [TempReading] {
        var list: [TempReading] = []
        var temp = 15.0
        for day in 1...14 {
            temp += Double.random(in: -3...3)
            list.append(TempReading(dayNumber: day, celsius: temp))
        }
        return list
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Two weeks of temperatures").font(.headline)

            Chart(readings) { reading in
                LineMark(
                    x: .value("Day", reading.dayNumber),
                    y: .value("Temperature", reading.celsius)
                )
                .interpolationMethod(.catmullRom)  // smooth curvy line

                PointMark(
                    x: .value("Day", reading.dayNumber),
                    y: .value("Temperature", reading.celsius)
                )
                .foregroundStyle(reading.celsius > 15 ? Color.red : Color.blue)
            }
            .chartXAxisLabel("Day")
            .chartYAxisLabel("Degrees C")
            .frame(height: 300)

            Button("New weather") {
                withAnimation { readings = LineChartDemoView.makeReadings() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
