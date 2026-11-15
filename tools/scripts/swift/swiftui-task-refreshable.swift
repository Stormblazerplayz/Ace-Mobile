// @title Loading with .task and Pull to Refresh
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TaskRefreshView() in ContentView's body.
// @keywords swiftui task modifier, swiftui refreshable, swiftui pull to refresh, swiftui async loading
// @about Pretends to download jokes with async code, loading when the screen appears and again when you pull down.

import SwiftUI

struct TaskRefreshView: View {
    @State private var jokes: [String] = []
    @State private var isLoading = false
    @State private var loadCount = 0

    let allJokes = [
        "Why do programmers prefer dark mode? Because light attracts bugs.",
        "Why did the computer go to the doctor? It had a virus.",
        "What is a computer's favorite snack? Microchips.",
        "Why was the math book sad? It had too many problems.",
        "How do robots eat salsa? With computer chips.",
        "Why did the developer go broke? Because they used up all their cache.",
    ]

    // async means this function can pause (wait) without freezing the app
    func loadJokes() async {
        isLoading = true
        try? await Task.sleep(for: .seconds(1.5))  // pretend the internet is slow
        jokes = Array(allJokes.shuffled().prefix(3))
        loadCount += 1
        isLoading = false
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Loaded \(loadCount) times") {
                    if isLoading && jokes.isEmpty {
                        ProgressView("Fetching jokes...")
                    }
                    ForEach(jokes, id: \.self) { joke in
                        Text(joke)
                    }
                }
            }
            .navigationTitle("Joke Feed")
            // .task runs when the view appears and is cancelled if it goes away
            .task {
                await loadJokes()
            }
            // Pull the list down to run this
            .refreshable {
                await loadJokes()
            }
        }
    }
}
