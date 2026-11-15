// @title Sheets and Full Screen Covers
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SheetDemoView() in ContentView's body.
// @keywords swiftui sheet, swiftui modal, swiftui dismiss, swiftui fullscreencover, swiftui presentation detents
// @about Pops up a sheet from the bottom (with a half-height option) and a full screen cover, and closes them with dismiss.

import SwiftUI

struct SheetDemoView: View {
    @State private var showSettings = false
    @State private var showCover = false
    @State private var username = "Storm"

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, \(username)!")
                .font(.largeTitle)
            Button("Open settings sheet") { showSettings = true }
                .buttonStyle(.borderedProminent)
            Button("Open full screen") { showCover = true }
                .buttonStyle(.bordered)
        }
        // The sheet shows whenever showSettings becomes true
        .sheet(isPresented: $showSettings) {
            SettingsSheet(name: $username)
                .presentationDetents([.medium, .large])  // can be half height or full
        }
        .fullScreenCover(isPresented: $showCover) {
            CoverScreen()
        }
    }
}

struct SettingsSheet: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss  // lets this view close itself

    var body: some View {
        NavigationStack {
            Form {
                TextField("Your name", text: $name)
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct CoverScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.indigo.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Full screen!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.indigo)
            }
        }
    }
}
