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

/// Turn on Apple's model or LFM3 Omni, and download or delete LFM3 Omni.
struct AIModelSection: View {
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var local = LocalModel.shared
    @State private var confirmDownload = false
    @State private var confirmDelete = false

    var body: some View {
        Section {
            Toggle("Apple Intelligence wording", isOn: $settings.useAppleModel)
            if settings.useAppleModel {
                Text(AppleModel.statusText).font(.caption).foregroundStyle(AceTheme.muted)
            }
            Toggle("LFM3 Omni on this iPad", isOn: $settings.useLocalModel)
            if settings.useLocalModel {
                if !LocalModel.engineIncluded {
                    Text("This build doesn't have the model engine yet. It comes with the next update.")
                        .font(.caption)
                        .foregroundStyle(AceTheme.warn)
                }
                LabeledContent("Model", value: local.statusText)
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
            Text("On-device AI")
        } footer: {
            Text("Both are off unless you turn them on. Ace's own brain still answers first. The model helps with wording, questions Ace doesn't know, and questions about pictures. Everything stays on your iPad.")
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
    }
}
