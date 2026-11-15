// @title Saving Settings with @AppStorage
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show AppStorageSettingsView() in ContentView's body.
// @keywords swiftui appstorage, swiftui save settings, swiftui userdefaults, swiftui remember value
// @about A settings screen whose choices are saved automatically and are still there after you close the app.

import SwiftUI

struct AppStorageSettingsView: View {
    // @AppStorage saves to UserDefaults using the key in quotes
    @AppStorage("playerName") private var playerName = "Player"
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("difficulty") private var difficulty = 1
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("accentHue") private var accentHue = 0.6

    let levels = ["Easy", "Normal", "Hard"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $playerName)
                    Toggle("Sound effects", isOn: $soundOn)
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(levels.indices, id: \.self) { index in
                            Text(levels[index]).tag(index)
                        }
                    }
                }
                Section("Theme color") {
                    Slider(value: $accentHue, in: 0...1)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hue: accentHue, saturation: 0.8, brightness: 0.9))
                        .frame(height: 40)
                }
                Section {
                    Text("Hi \(playerName)! You've opened this screen \(launchCount) times.")
                    Button("Reset everything", role: .destructive) {
                        playerName = "Player"
                        soundOn = true
                        difficulty = 1
                        accentHue = 0.6
                        launchCount = 0
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { launchCount += 1 }
        }
    }
}
