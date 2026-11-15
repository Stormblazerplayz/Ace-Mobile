// @title Weather from JSON
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show WeatherJSONView() in ContentView's body.
// @keywords swiftui weather app, swiftui decode json, swiftui codable forecast, swiftui jsondecoder
// @about Reads a weather forecast written in JSON text, decodes it with Codable and shows it as a nice list.

import SwiftUI

// These structs match the shape of the JSON below
struct ForecastDay: Codable, Identifiable {
    var id: String { day }   // computed, so it isn't in the JSON
    let day: String
    let high: Int
    let low: Int
    let condition: String
}

struct WeatherReport: Codable {
    let city: String
    let days: [ForecastDay]
}

// In a real app this text would come from a weather website
let sampleWeatherJSON = """
{
  "city": "Seattle",
  "days": [
    {"day": "Monday", "high": 14, "low": 8, "condition": "rain"},
    {"day": "Tuesday", "high": 17, "low": 9, "condition": "cloudy"},
    {"day": "Wednesday", "high": 21, "low": 11, "condition": "sunny"},
    {"day": "Thursday", "high": 19, "low": 10, "condition": "partly"},
    {"day": "Friday", "high": 12, "low": 6, "condition": "storm"}
  ]
}
"""

struct WeatherJSONView: View {
    @State private var report: WeatherReport? = nil
    @State private var errorText = ""

    func symbol(for condition: String) -> String {
        switch condition {
        case "sunny": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "partly": return "cloud.sun.fill"
        case "rain": return "cloud.rain.fill"
        case "storm": return "cloud.bolt.rain.fill"
        default: return "questionmark"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let report {
                    ForEach(report.days) { day in
                        HStack {
                            Image(systemName: symbol(for: day.condition))
                                .symbolRenderingMode(.multicolor)
                                .font(.title)
                                .frame(width: 50)
                            Text(day.day).font(.headline)
                            Spacer()
                            Text("\(day.low)  /  \(day.high) C").monospacedDigit()
                        }
                    }
                } else {
                    Text(errorText.isEmpty ? "Loading..." : errorText).foregroundStyle(.red)
                }
            }
            .navigationTitle(report?.city ?? "Weather")
            .onAppear(perform: decode)
        }
    }

    func decode() {
        let data = Data(sampleWeatherJSON.utf8)
        do {
            report = try JSONDecoder().decode(WeatherReport.self, from: data)
        } catch {
            errorText = "Could not read the JSON: \(error.localizedDescription)"
        }
    }
}
