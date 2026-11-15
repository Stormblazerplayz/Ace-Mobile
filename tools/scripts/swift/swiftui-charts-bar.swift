// @title Bar Chart with Swift Charts
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show BarChartDemoView() in ContentView's body.
// @keywords swiftui charts, swiftui bar chart, swiftui barmark, swiftui chart colors
// @about Draws a colorful bar chart of minutes spent coding each day using the Charts framework.

import Charts
import SwiftUI

struct CodingDay: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
    let language: String
}

struct BarChartDemoView: View {
    @State private var showAverage = true

    let days = [
        CodingDay(day: "Mon", minutes: 30, language: "Python"),
        CodingDay(day: "Tue", minutes: 45, language: "Swift"),
        CodingDay(day: "Wed", minutes: 20, language: "Python"),
        CodingDay(day: "Thu", minutes: 60, language: "Swift"),
        CodingDay(day: "Fri", minutes: 15, language: "Python"),
        CodingDay(day: "Sat", minutes: 90, language: "Swift"),
        CodingDay(day: "Sun", minutes: 50, language: "Python"),
    ]

    var average: Double {
        let total = days.reduce(0) { $0 + $1.minutes }
        return Double(total) / Double(days.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Minutes of coding this week").font(.headline)

            Chart {
                ForEach(days) { item in
                    // One bar per day; color depends on the language
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(by: .value("Language", item.language))
                }
                if showAverage {
                    // A dashed line across the chart at the average
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.gray)
                }
            }
            .frame(height: 300)

            Toggle("Show average line", isOn: $showAverage)
            Text("Average: \(Int(average)) minutes a day").foregroundStyle(.secondary)
        }
        .padding()
    }
}
