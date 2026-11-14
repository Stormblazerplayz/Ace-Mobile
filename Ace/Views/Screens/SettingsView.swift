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
                    Toggle("Sound effects", isOn: $settings.soundsOn)
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(AceTheme.muted)
                        Slider(value: $settings.volume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(AceTheme.muted)
                    }
                    .disabled(!settings.soundsOn)
                    Toggle("Haptics", isOn: $settings.hapticsOn)
                    Button("Play a test sound") {
                        core.applySoundSettings()
                        SoundFX.shared.play(.greeting)
                        Haptics.shared.play(.success)
                    }
                } header: {
                    Text("Sounds")
                } footer: {
                    Text("Sound effects follow your silent switch.")
                }

                Section("Voice") {
                    Toggle("Read replies out loud", isOn: $settings.speakReplies)
                    Picker("Voice", selection: $settings.voiceID) {
                        Text("Default").tag("")
                        ForEach(voices, id: \.identifier) { v in
                            Text(v.name + " (" + v.language + ")").tag(v.identifier)
                        }
                    }
                    Button("Hear it") {
                        VoiceOut.shared.speak("Hi! I'm Ace.", voiceID: settings.voiceID) { _ in }
                    }
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

                AIModelSection()

                Section("Coming next") {
                    Label("PC Sync with Nimbus", systemImage: "desktopcomputer")
                    Label("Pictures straight into LFM3 Omni", systemImage: "photo.badge.plus")
                    Label("Screenshot and file search", systemImage: "doc.text.magnifyingglass")
                    Label("Hands-free voice", systemImage: "mic")
                }
                .foregroundStyle(AceTheme.muted)

                Section {
                    Button("Clear chat", role: .destructive) { confirmClear = true }
                }

                Section {
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

/// The facts Ace remembers, with swipe to forget.
struct MemorySection: View {
    @ObservedObject var memory: MemoryStore
    let bank: QABank

    var body: some View {
        Section {
            if memory.facts.isEmpty {
                Text("Nothing yet. Say \"remember that...\" and I'll keep it here.")
                    .foregroundStyle(AceTheme.muted)
            }
            ForEach(memory.facts) { fact in
                Text(fact.text)
            }
            .onDelete { offsets in
                let list = offsets.map { memory.facts[$0] }
                for f in list { memory.remove(f) }
            }
            LabeledContent("Answers I know", value: "\(bank.entries.count)")
            LabeledContent("Answers I learned", value: "\(max(0, bank.entries.count - bank.builtinCount))")
        } header: {
            Text("What Ace remembers")
        } footer: {
            Text("Swipe a memory to forget it.")
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
