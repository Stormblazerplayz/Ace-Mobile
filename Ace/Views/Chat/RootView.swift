import PhotosUI
import SwiftUI
import UIKit

/// The main screen: Ace's orb island at the top, the chat in the middle, and the message box at the bottom.
struct RootView: View {
    @EnvironmentObject var core: AceCore
    @ObservedObject private var voice = VoiceIn.shared
    @EnvironmentObject var settings: SettingsStore
    @State private var draft = ""
    @State private var showCalendar = false
    @State private var showChecks = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    /// Counts orb taps and sends, so the orb and the send arrow can boing each time.
    @State private var orbTaps = 0
    @State private var sends = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The animation for a kind of move here, from the Bouncy animations setting and Reduce Motion.
    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: settings.bouncyMotion, reduceMotion: reduceMotion)
    }

    /// The messages the chat shows. Empty Ace messages (older chats could have them) are skipped,
    /// so no "How I got this" row floats alone.
    private var visibleMessages: [ChatMessage] {
        core.messages.filter { $0.speaker == .user || !$0.text.isEmpty || !$0.cards.isEmpty }
    }

    /// How many replies Ace has given, so the orb hops when a new one lands.
    private var aceReplies: Int {
        core.messages.reduce(0) { $0 + ($1.speaker == .ace ? 1 : 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AceTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    KitchenTimersStrip()
                        .padding(.horizontal, 16)
                    chat
                    inputBar
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(AceTheme.ace)
        }
        .preferredColorScheme(.dark)
        // The voice call screen covers everything while a call is on.
        .modifier(CallCover(call: core.call, core: core, settings: settings))
        .sheet(isPresented: $showCalendar) { CalendarView() }
        .sheet(isPresented: $showChecks) { ChecksView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $core.webPage) { page in
            SafariView(url: page.url).ignoresSafeArea()
        }
        .fullScreenCover(item: $core.breatheScreen) { screen in
            BreatheView(start: screen.pattern)
        }
        .onChange(of: inputFocused) { _, focused in
            core.setTyping(focused && !draft.isEmpty)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    sendPicture(image)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in sendPicture(image) }
                .ignoresSafeArea()
        }
    }

    private func sendPicture(_ image: UIImage) {
        guard !core.busy, let data = ImageAnalyzer.jpeg(image), let file = Persistence.saveImage(data) else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        core.setTyping(false)
        core.send(text, imageFile: file)
    }

    // MARK: Chat list

    /// The top row: Ace's orb right at the top in the middle (tap it for Settings), buttons on each side.
    /// While the orb stretches out to look around, the buttons step aside.
    private var header: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 4) {
                    headerButton("calendar", label: "Nimbus calendar") { showCalendar = true }
                    Spacer()
                    headerButton("wind", label: "Breathe") { _ = core.showBreathe(nil) }
                    headerButton("phone.fill", label: "Call Ace") { core.startCall() }
                    headerButton("waveform.path.ecg", label: "Checks") { showChecks = true }
                }
                .opacity(core.mood.expands ? 0 : 1)
                .scaleEffect(core.mood.expands && AceMotion.moves(bouncy: settings.bouncyMotion, reduceMotion: reduceMotion) ? 0.85 : 1)
                .allowsHitTesting(!core.mood.expands)
                OrbIsland(
                    mood: core.mood,
                    look: core.look,
                    eyeOpen: core.eyeOpen,
                    status: core.statusLine,
                    maxExpandedWidth: geo.size.width,
                    level: voice.level,
                    outfit: settings.orbOutfits ? OrbOutfit.forDate(Date()) : nil,
                    onTap: {
                        // Tapping the orb opens Settings (there's no gear button any more).
                        // With the bounce on, the orb boings first so you see it react.
                        guard AceMotion.moves(bouncy: settings.bouncyMotion, reduceMotion: reduceMotion) else {
                            showSettings = true
                            return
                        }
                        orbTaps += 1
                        Task {
                            try? await Task.sleep(for: .milliseconds(140))
                            showSettings = true
                        }
                    },
                    onHold: { down in core.holdToTalk(down) }
                )
                .boing(on: orbTaps, scale: 1.12)
                .boing(on: aceReplies, scale: 1.06)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(motion(.bouncy), value: core.mood.expands)
        }
        .frame(height: 64)
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    /// A header button that squishes when pressed and whose symbol jumps when tapped.
    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        BouncyIconButton(symbol: symbol, label: label, action: action)
    }

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if core.messages.isEmpty {
                        EmptyChatView { text in send(text) }
                            .padding(.top, 40)
                    }
                    // New bubbles pop in: yours from the bottom right, Ace's from the top left.
                    ForEach(visibleMessages) { m in
                        MessageRow(message: m)
                            .id(m.id)
                            .transition(.chatBubble(fromUser: m.speaker == .user))
                    }
                    if core.busy && !core.liveThoughts.isEmpty && settings.showThinking {
                        LiveThoughtsView(thoughts: core.liveThoughts)
                            .id("thoughts")
                    }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .animation(motion(.bouncy), value: visibleMessages.count)
                .animation(motion(.snappy), value: core.busy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            // Fade the top edge so a half-scrolled message never looks cut off.
            .mask(
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.035),
                                       .init(color: .black, location: 1)], startPoint: .top, endPoint: .bottom)
            )
            .onChange(of: core.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: core.liveThoughts.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }

    // MARK: Input

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Menu {
                Button { showPhotoPicker = true } label: { Label("Photo library", systemImage: "photo.on.rectangle") }
                if CameraPicker.isAvailable {
                    Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AceTheme.card))
                    .foregroundStyle(AceTheme.ace)
            }
            .disabled(core.busy)
            .accessibilityLabel("Add a picture")
            TextField("Talk to Ace", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { send(draft) }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AceTheme.card))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(AceTheme.cardBorder, lineWidth: 1))
                .foregroundStyle(AceTheme.fg)
                .onChange(of: draft) { old, new in
                    if new.count > old.count { core.typedKey() }
                    core.setTyping(!new.isEmpty)
                }
            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .symbolEffect(.bounce.up, value: sends)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canSend ? AceTheme.ace : AceTheme.soft))
                    .foregroundStyle(canSend ? Color.black : AceTheme.muted)
                    .scaleEffect(canSend || !AceMotion.moves(bouncy: settings.bouncyMotion, reduceMotion: reduceMotion) ? 1 : 0.88)
                    .animation(motion(.pop), value: canSend)
            }
            .buttonStyle(BouncyButtonStyle(depth: 0.8))
            .disabled(!canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .background(AceTheme.bg.opacity(0.85).ignoresSafeArea(edges: .bottom))
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !core.busy
    }

    private func send(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !core.busy else { return }
        draft = ""
        core.setTyping(false)
        if AceMotion.moves(bouncy: settings.bouncyMotion, reduceMotion: reduceMotion) { sends += 1 }
        Haptics.shared.play(.tick)
        core.send(t)
    }
}

/// What shows before the first message: a hello and a few things to try.
struct EmptyChatView: View {
    var onPick: (String) -> Void
    @EnvironmentObject var settings: SettingsStore
    /// Turns true when the hello shows, so the ideas cascade in one after another.
    @State private var shown = false

    private let ideas = [
        "What's on my calendar today?",
        "Add soccer practice tomorrow at 5pm",
        "How do I make pancakes?",
        "What's the weather?",
        "Set a timer for 10 minutes",
        "Check on my iPad",
    ]

    var body: some View {
        VStack(spacing: 14) {
            Text(settings.userName.isEmpty ? "Hi, I'm Ace." : "Hi \(settings.userName), I'm Ace.")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(AceTheme.fg)
                .bounceReveal(shown, order: 0)
            Text("Ask me anything, or try one of these.")
                .foregroundStyle(AceTheme.muted)
                .bounceReveal(shown, order: 1)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                ForEach(Array(ideas.enumerated()), id: \.element) { i, idea in
                    Button { onPick(idea) } label: {
                        Text(idea)
                            .font(.subheadline)
                            .foregroundStyle(AceTheme.fg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.card))
                            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.aceBouncy)
                    .bounceReveal(shown, order: i + 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { shown = true }
    }
}

/// Ace's thinking steps, shown live while it works.
struct LiveThoughtsView: View {
    let thoughts: [String]
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(thoughts.suffix(6).enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 8) {
                    // The dotted circle turns into a tick when Ace moves on to the next step.
                    Image(systemName: i == thoughts.suffix(6).count - 1 ? "circle.dotted" : "checkmark")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.caption)
                        .foregroundStyle(AceTheme.amber)
                        .frame(width: 14)
                    Text(step)
                        .font(.caption)
                        .foregroundStyle(AceTheme.muted)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AceTheme.amber.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        .animation(AceMotion.animation(.snappy, bouncy: bouncy, reduceMotion: reduceMotion), value: thoughts.count)
        .transition(.scale(scale: 0.92, anchor: .topLeading).combined(with: .opacity))
    }
}
