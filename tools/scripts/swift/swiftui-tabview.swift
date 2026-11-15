// @title TabView
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TabsDemoView() in ContentView's body.
// @keywords swiftui tabview, swiftui tab bar, swiftui tabitem, swiftui badge, swiftui page style
// @about Makes an app with a tab bar at the bottom, plus a swipeable page view inside one tab.

import SwiftUI

struct TabsDemoView: View {
    @State private var selectedTab = 0
    @State private var inboxCount = 3

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack(spacing: 16) {
                Image(systemName: "house.fill").font(.system(size: 60))
                Text("Home").font(.largeTitle)
                Button("Go to Inbox") { selectedTab = 1 }
                    .buttonStyle(.borderedProminent)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)

            VStack(spacing: 16) {
                Text("\(inboxCount) new messages").font(.title)
                Button("Read one") { inboxCount = max(0, inboxCount - 1) }
                    .buttonStyle(.bordered)
            }
            .tabItem { Label("Inbox", systemImage: "tray") }
            .badge(inboxCount)  // the little red number on the tab
            .tag(1)

            // A TabView with the page style swipes left and right
            TabView {
                ForEach(["sun.max.fill", "cloud.rain.fill", "snowflake"], id: \.self) { name in
                    Image(systemName: name)
                        .font(.system(size: 120))
                        .foregroundStyle(.tint)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .tabItem { Label("Weather", systemImage: "cloud.sun") }
            .tag(2)
        }
    }
}
