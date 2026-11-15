// @title Links and Sharing
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show LinksShareView() in ContentView's body.
// @keywords swiftui link, swiftui sharelink, swiftui share sheet, swiftui open url
// @about Opens web pages with Link and shares text or a web address with the iPad share sheet using ShareLink.

import SwiftUI

struct LinksShareView: View {
    @State private var highScore = 1200
    @Environment(\.openURL) private var openURL  // a way to open links from code

    let swiftSite = URL(string: "https://www.swift.org")
    let docsSite = URL(string: "https://developer.apple.com/tutorials/swiftui")

    var body: some View {
        VStack(spacing: 24) {
            // A Link looks like a button and opens Safari
            if let swiftSite {
                Link("Visit swift.org", destination: swiftSite)
                    .font(.title3)
            }

            // Opening a link from your own button
            Button("Open SwiftUI tutorials") {
                if let docsSite { openURL(docsSite) }
            }
            .buttonStyle(.bordered)

            Divider()

            Stepper("High score: \(highScore)", value: $highScore, step: 100)

            // ShareLink pops up the share sheet (Messages, AirDrop, Notes...)
            ShareLink(item: "I just scored \(highScore) points in my game!") {
                Label("Share my score", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)

            if let swiftSite {
                ShareLink(item: swiftSite, subject: Text("Learn Swift"), message: Text("Check out this site!"))
            }
        }
        .padding()
    }
}
