import SwiftUI
import AVFoundation

/// Everything you can change about Ace.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var core: AceCore
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var calendar = CalendarService.shared
    @State private var confirmClear = false
    @State private var voices: [AVSpeechSynthesisVoice] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    TextField("Your name", text: $settings.userName)
                        .textContentType(.givenName)
                }

                Section {
                    Picker("Personality", selection: $settings.personality) {
                        Text("Normal").tag("normal")
                        Text("Sassy").tag("sassy")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Personality")
                } footer: {
                    Text(settings.personality == "sassy"
                         ? "Sassy Ace has a LOT of attitude, rolls its eyes, and still gives the right answer."
                         : "Switch to Sassy for an Ace with a lot of attitude. Same right answers.")
                }

                Section {
                    Toggle("Sound effects", isOn: $settings.soundsOn)
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(AceTheme.muted)
                        Slider(value: $settings.volume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(AceTheme.muted)
                    }
                    .disabled(!settings.soundsOn)
                    Toggle("Haptics", isOn: $settings.hapticsOn)
                    Toggle("Mood sounds", isOn: $settings.moodSounds)
                        .disabled(!settings.soundsOn)
                    Button("Play a test sound") {
                        core.applySoundSettings()
                        SoundFX.shared.play(.greeting)
                        Haptics.shared.play(.success)
                    }
                } header: {
                    Text("Sounds")
                } footer: {
                    Text("Sound effects follow your silent switch. Mood sounds are quiet blips when the orb changes mood.")
                }

                Section {
                    Toggle("Seasonal orb outfits", isOn: $settings.orbOutfits)
                    NavigationLink("Preview outfits") { OutfitPreviewView() }
                } header: {
                    Text("Orb")
                } footer: {
                    Text("Ace wears a Santa hat in December, a pumpkin at Halloween, and more on special days.")
                }

                Section {
                    Toggle("Read replies out loud", isOn: $settings.speakReplies)
                    Toggle("Say hello out loud when Ace opens", isOn: $settings.speakGreeting)
                    Toggle("Listen for \"Hey Ace\"", isOn: Binding(
                        get: { settings.heyAce },
                        set: { on in _ = core.setHandsFree(on) }
                    ))
                    Picker("Voice", selection: $settings.voiceID) {
                        Text("Default").tag("")
                        ForEach(voices, id: \.identifier) { v in
                            Text(v.name + " (" + v.language + ")").tag(v.identifier)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Talking speed")
                            Spacer()
                            Text(settings.voiceSpeed == 1 ? "Normal" : String(format: "%.2fx", settings.voiceSpeed))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.voiceSpeed, in: SettingsStore.slowestVoice...SettingsStore.fastestVoice, step: 0.05) {
                            Text("Talking speed")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise.fill")
                        } maximumValueLabel: {
                            Image(systemName: "hare.fill")
                        }
                    }
                    Button("Hear it") {
                        VoiceOut.shared.speak("Hi! I'm Ace.", voiceID: settings.voiceID) { _ in }
                    }
                } header: {
                    Text("Voice")
                } footer: {
                    Text("You can also say \"talk slower\" or \"talk faster\". Hold the orb to talk, and let go when you're done. With \"Hey Ace\" on, Ace listens while the app is open. Tap the orb for Settings.")
                }

                Section {
                    Toggle("Wake up and check things", isOn: $settings.wakeChecks)
                    Toggle("Alerts when Ace is closed", isOn: $settings.backgroundAlerts)
                    Toggle("Bedtime tips", isOn: $settings.bedtimeTips)
                    Button("Allow notifications") {
                        Task { _ = await Notifier.requestPermission() }
                    }
                } header: {
                    Text("Checks")
                } footer: {
                    Text("While Ace is open it wakes up every 15 to 30 minutes. When it's closed, iPadOS decides when Ace can check, so it may be less often.")
                }

                Section("Thinking and the web") {
                    Toggle("Show how Ace thinks", isOn: $settings.showThinking)
                    Toggle("Look things up on the web", isOn: $settings.webAnswers)
                    Picker("Search with", selection: $settings.searchEngine) {
                        Text("Google").tag("google")
                        Text("DuckDuckGo").tag("duckduckgo")
                        Text("Bing").tag("bing")
                    }
                    Picker("Open links in", selection: $settings.openLinksIn) {
                        Text("Ace").tag("ace")
                        Text("Safari").tag("safari")
                    }
                    Picker("Temperature", selection: $settings.temperatureUnit) {
                        Text("Automatic").tag("auto")
                        Text("°C").tag("c")
                        Text("°F").tag("f")
                    }
                }

                Section("Calendar and reminders") {
                    LabeledContent("Calendar", value: calendar.eventAccess ? "Allowed" : "Not allowed")
                    if !calendar.eventAccess {
                        Button("Allow calendar") { Task { await calendar.requestEventAccess() } }
                    }
                    LabeledContent("Reminders", value: calendar.reminderAccess ? "Allowed" : "Not allowed")
                    if !calendar.reminderAccess {
                        Button("Allow reminders") { Task { await calendar.requestReminderAccess() } }
                    }
                }

                MemorySection(memory: core.memory, bank: core.brain.bank)

                HomeSection()
                WiFiLightsSection()

                AIModelSection()

                Section("Coming next") {
                    Label("PC Sync with Nimbus", systemImage: "desktopcomputer")
                    Label("Pictures straight into LFM3 Omni", systemImage: "photo.badge.plus")
                    Label("Screenshot and file search", systemImage: "doc.text.magnifyingglass")
                }
                .foregroundStyle(AceTheme.muted)

                Section {
                    Button("Clear chat", role: .destructive) { confirmClear = true }
                }

                Section {
                    NavigationLink("What's new") { WhatsNewView() }
                    LabeledContent("Ace", value: Self.version)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Clear the whole chat?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear chat", role: .destructive) { core.clearChat() }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                if voices.isEmpty { voices = VoiceOut.englishVoices() }
            }
            .onChange(of: settings.soundsOn) { _, _ in core.applySoundSettings() }
            .onChange(of: settings.volume) { _, _ in core.applySoundSettings() }
            .onChange(of: settings.hapticsOn) { _, _ in core.applySoundSettings() }
            .onChange(of: settings.wakeChecks) { _, _ in core.scheduleWake() }
            .onChange(of: settings.personality) { _, new in core.personalityChanged(to: new) }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }

    static var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "4.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "V\(v) (\(b))"
    }
}

/// What Ace remembers: a short summary here, and the full Memory page one tap away.
struct MemorySection: View {
    @ObservedObject var memory: MemoryStore
    let bank: QABank

    var body: some View {
        Section {
            NavigationLink {
                MemoryView(memory: memory)
            } label: {
                LabeledContent {
                    Text("\(memory.facts.count)")
                } label: {
                    Label("Memories", systemImage: "brain.head.profile")
                }
            }
            NavigationLink {
                ScriptsView()
            } label: {
                LabeledContent {
                    Text("\(ScriptLibrary.all.count)")
                } label: {
                    Label("Scripts", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            LabeledContent("Answers I know", value: "\(bank.entries.count)")
            LabeledContent("Answers I learned", value: "\(max(0, bank.entries.count - bank.builtinCount))")
        } header: {
            Text("What Ace remembers")
        } footer: {
            Text("Open Memories to see, search, add or forget things. Scripts has Ace's built-in Roblox Lua and C++ code.")
        }
    }
}

/// Pick the brain (Normal Ace or LFM3 Omni), the LFM3 Omni fallback, Apple's model,
/// and download or delete LFM3 Omni.
struct AIModelSection: View {
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var local = LocalModel.shared
    @State private var confirmDownload = false
    @State private var confirmDelete = false

    /// The model has to be on this iPad for the picked setting to work.
    private var needsModel: Bool { settings.lfmAllowed }

    var body: some View {
        Section {
            Picker("Brain", selection: $settings.brain) {
                Text("Normal Ace").tag("ace")
                Text("LFM3 Omni").tag("model")
            }
            .pickerStyle(.segmented)

            Text(settings.modelBrain
                 ? "LFM3 Omni answers your questions. Ace still does timers, checks, the calendar and other things it does itself."
                 : "Ace answers with its own brain: rules, its answer bank and the web.")
                .font(.caption)
                .foregroundStyle(AceTheme.muted)

            if !settings.modelBrain {
                Toggle("Fall back to LFM3 Omni when Ace doesn't know", isOn: $settings.useLocalModel)
            }

            if needsModel {
                if !LocalModel.engineIncluded {
                    Text("This build doesn't have the model engine yet. It comes with the next update.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.warn)
                } else if !local.filesPresent, !isDownloading {
                    Text("LFM3 Omni isn't on this iPad yet. Download it so it can answer.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.warn)
                }
                LabeledContent("LFM3 Omni", value: local.statusText)
                switch local.state {
                case .notDownloaded, .failed:
                    Button("Download LFM3 Omni (\(SystemMonitor.bytes(LocalModel.totalBytes)))") { confirmDownload = true }
                case .downloading(let p):
                    ProgressView(value: p)
                    Button("Stop download", role: .destructive) { local.cancelDownload() }
                case .downloaded, .ready, .loading:
                    Button("Delete the model", role: .destructive) { confirmDelete = true }
                }
            }
        } header: {
            Text("Brain")
        } footer: {
            Text("Ace starts with Normal Ace. With the fallback on, LFM3 Omni only answers when Ace isn't sure. \"How I got this\" shows which one answered. Everything stays on your iPad.")
        }
        .confirmationDialog("Download LFM3 Omni?", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("Download \(SystemMonitor.bytes(LocalModel.totalBytes))") { local.download() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It's a big download, so use Wi-Fi and keep Ace open until it's done.")
        }
        .confirmationDialog("Delete LFM3 Omni from this iPad?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { local.deleteFiles() }
            Button("Cancel", role: .cancel) {}
        }

        Section {
            Toggle("Apple's model on this iPad", isOn: $settings.useAppleModel)
            if settings.useAppleModel {
                Text(AppleModel.statusText).font(.caption).foregroundStyle(AceTheme.muted)
            }
        } header: {
            Text("Apple's model")
        } footer: {
            Text("Off unless you turn it on. Normal Ace asks it only when it isn't sure.")
        }
    }

    private var isDownloading: Bool {
        if case .downloading = local.state { return true }
        return false
    }
}

/// Apple Home: connect, see your devices by room, and flip them on or off.
struct HomeSection: View {
    @ObservedObject private var home = HomeService.shared

    var body: some View {
        Section {
            switch home.access {
            case .notConnected:
                Button {
                    home.connect()
                } label: {
                    Label("Connect Apple Home", systemImage: "house.fill")
                }
            case .waiting:
                HStack {
                    ProgressView()
                    Text("Connecting to Apple Home...").foregroundStyle(AceTheme.muted)
                }
            case .denied:
                Text("Ace doesn't have Home access yet. Turn it on in the Settings app, under Ace.")
                    .font(.callout)
                    .foregroundStyle(AceTheme.warn)
            case .noHome:
                Text("There's no home in Apple Home yet. Set one up in the Home app first.")
                    .font(.callout)
                    .foregroundStyle(AceTheme.muted)
            case .allowed:
                if home.devices.isEmpty {
                    Text("No lights, plugs or other devices in \(home.homeName) yet.")
                        .foregroundStyle(AceTheme.muted)
                }
                ForEach(home.devices) { d in
                    HStack(spacing: 12) {
                        Image(systemName: d.icon)
                            .foregroundStyle(d.isOn == true ? AceTheme.accent : AceTheme.muted)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.name)
                            if !d.room.isEmpty || d.level != nil {
                                Text([d.room, d.level.map { "\($0)%" } ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(AceTheme.muted)
                            }
                        }
                        Spacer()
                        if let on = d.isOn {
                            Toggle(d.name, isOn: Binding(
                                get: { on },
                                set: { v in Task { await home.setPower(d.id, v) } }
                            ))
                            .labelsHidden()
                        }
                    }
                }
                if !home.scenes.isEmpty {
                    LabeledContent("Scenes", value: home.scenes.joined(separator: ", "))
                }
                if !home.devices.contains(where: { $0.kind == .vacuum }) {
                    Label("To control your MOVA vacuum, open the MOVA app and add it to Apple Home with Matter.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
                Button("Refresh") { Task { await home.refresh() } }
            }
        } header: {
            Text("Apple Home")
        } footer: {
            Text("Try \"start the vacuum\", \"turn off the kitchen lights\", \"set the thermostat to 70\" or \"run goodnight scene\". Ace won't touch locks, garage doors or alarms.")
        }
        .onAppear {
            if home.wasConnected { home.connect() }
            Task { await home.refresh() }
        }
    }
}

/// Govee and Twinkly lights found on your Wi-Fi (no account needed).
struct WiFiLightsSection: View {
    @ObservedObject private var lan = LanLights.shared
    @State private var renaming: LanLights.Light?
    @State private var newName = ""
    @State private var scannedOnce = false

    var body: some View {
        Section {
            Toggle("Find Govee and Twinkly lights", isOn: $lan.enabled)
            if lan.enabled {
                if lan.scanning {
                    HStack {
                        ProgressView()
                        Text("Looking on your Wi-Fi...").foregroundStyle(AceTheme.muted)
                    }
                } else {
                    Button {
                        Task { await lan.scan(); scannedOnce = true }
                    } label: {
                        Label("Scan for lights", systemImage: "wifi")
                    }
                }
                if lan.lights.isEmpty && scannedOnce && !lan.scanning {
                    Text("No lights found. In the Govee Home app, open each light's settings and turn on LAN Control, then scan again.")
                        .font(.callout)
                        .foregroundStyle(AceTheme.muted)
                }
                ForEach(lan.lights) { l in
                    HStack(spacing: 12) {
                        Image(systemName: l.brand == .govee ? "lightbulb.led.fill" : "sparkles")
                            .foregroundStyle(l.isOn == true ? AceTheme.accent : AceTheme.muted)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.label)
                            Text(l.brand == .govee ? "Govee · \(l.model)" : "Twinkly")
                                .font(.caption)
                                .foregroundStyle(AceTheme.muted)
                        }
                        Spacer()
                        Toggle(l.label, isOn: Binding(
                            get: { l.isOn ?? false },
                            set: { v in Task { _ = await lan.setPower(l, v) } }
                        ))
                        .labelsHidden()
                    }
                    .contextMenu {
                        Button("Rename") { newName = l.name; renaming = l }
                        Button("Forget", role: .destructive) { lan.forget(l.id) }
                    }
                }
            }
        } header: {
            Text("Wi-Fi lights")
        } footer: {
            Text(lan.enabled
                 ? "Long-press a light to rename it. Try \"turn the govee lights blue\", \"dim the lights to 20%\" or \"movie mode\"."
                 : "Ace can control Govee and Twinkly lights straight over your Wi-Fi. For Govee, turn on LAN Control in the Govee Home app.")
        }
        .alert("Rename light", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newName)
            Button("Save") { if let r = renaming { lan.rename(r.id, to: newName) }; renaming = nil }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .task {
            if lan.enabled && !lan.lights.isEmpty { await lan.refresh() }
        }
    }
}
