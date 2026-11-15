// @title Searchable List
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SearchableListView() in ContentView's body.
// @keywords swiftui searchable, swiftui search bar, swiftui filter list, swiftui search suggestions
// @about A list of animals with a search bar that filters as you type.

import SwiftUI

struct SearchableListView: View {
    @State private var query = ""

    let animals = ["Axolotl", "Bear", "Cheetah", "Dolphin", "Eagle", "Fox", "Giraffe",
                   "Hedgehog", "Iguana", "Jaguar", "Koala", "Lemur", "Meerkat", "Narwhal",
                   "Octopus", "Penguin", "Quokka", "Raccoon", "Sloth", "Tiger"]

    // Only the animals whose name contains what you typed
    var results: [String] {
        if query.isEmpty {
            return animals
        }
        return animals.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.self) { animal in
                    Label(animal, systemImage: "pawprint")
                }
                if results.isEmpty {
                    Text("No animal called \"\(query)\"")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Animals")
            // This adds the search bar at the top of the list
            .searchable(text: $query, prompt: "Find an animal")
            .searchSuggestions {
                if query.isEmpty {
                    Text("Penguin").searchCompletion("Penguin")
                    Text("Sloth").searchCompletion("Sloth")
                }
            }
        }
    }
}
