// @title Lists with ForEach
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PlanetListView() in ContentView's body.
// @keywords swiftui list, swiftui foreach, swiftui identifiable, swiftui ondelete, swiftui sections
// @about A list of planets in sections, built with ForEach, where you can delete and reorder rows.

import SwiftUI

struct PlanetRow: Identifiable {
    let id = UUID()
    let name: String
    let moons: Int
    let isGiant: Bool
}

struct PlanetListView: View {
    @State private var planets = [
        PlanetRow(name: "Mercury", moons: 0, isGiant: false),
        PlanetRow(name: "Venus", moons: 0, isGiant: false),
        PlanetRow(name: "Earth", moons: 1, isGiant: false),
        PlanetRow(name: "Mars", moons: 2, isGiant: false),
        PlanetRow(name: "Jupiter", moons: 95, isGiant: true),
        PlanetRow(name: "Saturn", moons: 146, isGiant: true),
        PlanetRow(name: "Uranus", moons: 28, isGiant: true),
        PlanetRow(name: "Neptune", moons: 16, isGiant: true),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("All planets") {
                    // ForEach makes one row for each item. Identifiable lets it tell them apart.
                    ForEach(planets) { planet in
                        HStack {
                            Image(systemName: planet.isGiant ? "circle.circle.fill" : "circle.fill")
                                .foregroundStyle(planet.isGiant ? Color.orange : Color.blue)
                            Text(planet.name)
                            Spacer()
                            Text("\(planet.moons) moons")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in planets.remove(atOffsets: offsets) }
                    .onMove { from, to in planets.move(fromOffsets: from, toOffset: to) }
                }

                Section("Stats") {
                    Text("Planets in the list: \(planets.count)")
                    Text("Total moons: \(planets.reduce(0) { $0 + $1.moons })")
                }
            }
            .navigationTitle("Planets")
            .toolbar { EditButton() }  // Edit lets you drag rows around
        }
    }
}
