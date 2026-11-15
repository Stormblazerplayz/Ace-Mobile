// @title Empty Screens with ContentUnavailableView
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show EmptyStateDemoView() in ContentView's body.
// @keywords swiftui contentunavailableview, swiftui empty state, swiftui no results, swiftui placeholder screen
// @about Shows a friendly message when a list is empty, using the iOS 17 ContentUnavailableView.

import SwiftUI

struct EmptyStateDemoView: View {
    @State private var pets: [String] = []
    @State private var search = ""

    let petNames = ["Biscuit", "Pixel", "Nugget", "Ziggy", "Mochi", "Rocket"]

    var filtered: [String] {
        search.isEmpty ? pets : pets.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    // The built-in empty screen: a title, an icon, a description and actions
                    ContentUnavailableView {
                        Label("No Pets Yet", systemImage: "pawprint")
                    } description: {
                        Text("Tap the button to adopt your first pet.")
                    } actions: {
                        Button("Adopt a pet") { addPet() }
                            .buttonStyle(.borderedProminent)
                    }
                } else if filtered.isEmpty {
                    // A ready-made "no search results" screen
                    ContentUnavailableView.search(text: search)
                } else {
                    List(filtered, id: \.self) { pet in
                        Label(pet, systemImage: "pawprint.fill")
                    }
                }
            }
            .navigationTitle("My Pets")
            .searchable(text: $search)
            .toolbar {
                Button("Add", systemImage: "plus") { addPet() }
                Button("Clear", systemImage: "trash") { pets.removeAll() }
            }
        }
    }

    func addPet() {
        pets.append(petNames.randomElement() ?? "Buddy")
    }
}
