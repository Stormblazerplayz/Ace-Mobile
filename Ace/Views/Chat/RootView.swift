import PhotosUI
import SwiftUI
import UIKit

/// The main screen: Ace's orb island at the top, the chat in the middle, and the message box at the bottom.
struct RootView: View {
    @EnvironmentObject var core: AceCore
    @EnvironmentObject var settings: SettingsStore
    @State private var draft = ""
    @State private var showCalendar = false
    @State private var showChecks = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                AceTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    chat
                    inputBar
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(AceTheme.ace)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCalendar) { CalendarView() }
        .sheet(isPresented: $showChecks) { ChecksView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $core.webPage) { page in
            SafariView(url: page.url).ignoresSafeArea()
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

    /// The top row: Ace's orb right at the top in the middle, buttons on each side.
    /// While the orb stretches out to look around, the buttons step aside.
    private var header: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 4) {
                    headerButton("calendar", label: "Nimbus calendar") { showCalendar = true }
                    Spacer()
                    headerButton("waveform.path.ecg", label: "Checks") { showChecks = true }
                    headerButton("gearshape", label: "Settings") { showSettings = true }
                }
                .opacity(core.mood.expands ? 0 : 1)
                .allowsHitTesting(!core.mood.expands)
                OrbIsland(
                    mood: core.mood,
                    look: core.look,
                    eyeOpen: core.eyeOpen,
                    status: core.statusLine,
                    maxExpandedWidth: geo.size.width
                ) {
                    Task { await core.wakeUp(reason: .manual) }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeInOut(duration: 0.25), value: core.mood.expands)
        }
        .frame(height: 64)
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if core.messages.isEmpty {
                        EmptyChatView { text in send(text) }
                            .padding(.top, 40)
                    }
                    ForEach(core.messages) { m in
                        MessageRow(message: m)
                            .id(m.id)
                    }
                    if core.busy && !core.liveThoughts.isEmpty && settings.showThinking {
                        LiveThoughtsView(thoughts: core.liveThoughts)
                            .id("thoughts")
                    }
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
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
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canSend ? AceTheme.ace : AceTheme.soft))
                    .foregroundStyle(canSend ? Color.black : AceTheme.muted)
            }
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
        core.send(t)
    }
}

/// What shows before the first message: a hello and a few things to try.
struct EmptyChatView: View {
    var onPick: (String) -> Void
    @EnvironmentObject var settings: SettingsStore

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
            Text("Ask me anything, or try one of these.")
                .foregroundStyle(AceTheme.muted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                ForEach(ideas, id: \.self) { idea in
                    Button { onPick(idea) } label: {
                        Text(idea)
                            .font(.subheadline)
                            .foregroundStyle(AceTheme.fg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AceTheme.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Ace's thinking steps, shown live while it works.
struct LiveThoughtsView: View {
    let thoughts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(thoughts.suffix(6).enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: i == thoughts.suffix(6).count - 1 ? "circle.dotted" : "checkmark")
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
        .transition(.opacity)
    }
}
