// @title Download JSON from the Web
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PostsLoaderView() in ContentView's body. Needs internet.
// @keywords swiftui urlsession, swiftui fetch json, swiftui async network, swiftui api request, swiftui error message
// @about Downloads a list of sample posts from a free practice website with URLSession and shows them in a list.

import SwiftUI

// Matches one item from https://jsonplaceholder.typicode.com/posts
struct WebPost: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

struct PostsLoaderView: View {
    @State private var posts: [WebPost] = []
    @State private var errorMessage: String? = nil
    @State private var loading = false

    var body: some View {
        NavigationStack {
            List(posts) { post in
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.title.capitalized).font(.headline)
                    Text(post.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                    Text("Post \(post.id) by user \(post.userId)").font(.caption)
                }
            }
            .overlay {
                if loading {
                    ProgressView("Downloading...")
                } else if let errorMessage {
                    ContentUnavailableView("Couldn't load", systemImage: "wifi.slash", description: Text(errorMessage))
                }
            }
            .navigationTitle("Posts")
            .task { await loadPosts() }
            .refreshable { await loadPosts() }
        }
    }

    func loadPosts() async {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
        loading = posts.isEmpty
        errorMessage = nil
        do {
            // Wait for the download without freezing the screen
            let (data, _) = try await URLSession.shared.data(from: url)
            posts = try JSONDecoder().decode([WebPost].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}
