import SwiftUI
import UIKit

/// Secret codes: hide a message or read one with a code wheel, Morse code or the mirror code.
/// The code wheel turns, the Morse lamp flashes, and answers scramble into place.
struct SecretCodesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("secretCodes.shift") private var savedShift = 3

    @Namespace private var tabs
    @State private var code: SecretCode = .caesar
    /// True to turn a message into code, false to read a code.
    @State private var hiding = true
    @State private var message = ""
    @State private var spin = 3
    @State private var shown = false
    @State private var copied = false
    @State private var crackNote: String?

    // Morse playback.
    @State private var lampOn = false
    @State private var lit: Int?
    @State private var playing: Task<Void, Never>?
    @State private var fast = false

    private var moves: Bool { AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) }

    private func motion(_ kind: AceMotion.Kind) -> Animation? {
        AceMotion.animation(kind, bouncy: bouncy, reduceMotion: reduceMotion)
    }

    private var result: String {
        SecretCodes.run(code, text: message, hiding: hiding, shift: spin)
    }

    /// The Morse code to flash: the answer when hiding, or what you typed when reading.
    private var morseToPlay: String {
        hiding ? result : message
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 760
            ZStack {
                AceTheme.background.ignoresSafeArea()
                backdrop
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                            .bounceReveal(shown, order: 0, rise: 24)
                        tabPicker
                            .bounceReveal(shown, order: 1)
                        if wide {
                            HStack(alignment: .top, spacing: 18) {
                                VStack(spacing: 16) {
                                    messageCard
                                    answerCard
                                }
                                .frame(maxWidth: .infinity)
                                .bounceReveal(shown, order: 2)
                                toolCard
                                    .frame(width: min(420, geo.size.width * 0.42))
                                    .bounceReveal(shown, order: 3)
                            }
                        } else {
                            messageCard.bounceReveal(shown, order: 2)
                            answerCard.bounceReveal(shown, order: 3)
                            toolCard.bounceReveal(shown, order: 4)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            spin = Caesar.normalize(savedShift)
            withAnimation(motion(.bouncy)) { shown = true }
        }
        .onDisappear { stopMorse() }
        .onChange(of: spin) { _, new in
            savedShift = Caesar.normalize(new)
        }
        .onChange(of: code) { _, _ in
            stopMorse()
            crackNote = nil
        }
        .onChange(of: hiding) { _, _ in
            stopMorse()
            crackNote = nil
        }
        .onChange(of: message) { _, _ in
            stopMorse()
            copied = false
        }
    }

    // MARK: Pieces

    /// Two soft glows in the code's colors that drift slowly.
    private var backdrop: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !moves)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(Color(hex: code.hexes.0).opacity(0.28))
                    .frame(width: 520, height: 520)
                    .blur(radius: 120)
                    .offset(x: -220 + 50 * sin(t / 5), y: -260 + 40 * cos(t / 6))
                Circle()
                    .fill(Color(hex: code.hexes.1).opacity(0.22))
                    .frame(width: 480, height: 480)
                    .blur(radius: 120)
                    .offset(x: 240 + 50 * cos(t / 7), y: 280 + 40 * sin(t / 4))
            }
            .animation(.easeInOut(duration: 0.8), value: code)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BouncyIconButton(symbol: "xmark", label: "Close") { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Secret codes")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                Text("Hide a message, or crack one")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
    }

    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(SecretCode.allCases) { item in
                let on = item == code
                Button {
                    Haptics.shared.play(.tick)
                    withAnimation(motion(.snappy)) { code = item }
                } label: {
                    Label(item.title, systemImage: item.symbol)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(on ? Color.black : AceTheme.fg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background {
                            if on {
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: item.hexes.0), Color(hex: item.hexes.1)], startPoint: .leading, endPoint: .trailing))
                                    .matchedGeometryEffect(id: "tab", in: tabs)
                            }
                        }
                }
                .buttonStyle(.aceBouncy)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(5)
        .background(Capsule().fill(AceTheme.card))
        .overlay(Capsule().stroke(AceTheme.cardBorder, lineWidth: 1))
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Hide or read", selection: $hiding) {
                    Text("Hide a message").tag(true)
                    Text("Read a code").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                Spacer(minLength: 0)
                if !message.isEmpty {
                    Button("Clear") {
                        Haptics.shared.play(.tick)
                        message = ""
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AceTheme.ace)
                }
            }
            Text(code.howItWorks)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            TextField(placeholder, text: Binding(
                get: { message },
                set: { message = String($0.prefix(SecretCodes.maxLength)) }
            ), axis: .vertical)
            .lineLimit(3...6)
            .font(.system(size: 20, weight: .semibold, design: code == .morse && !hiding ? .monospaced : .rounded))
            .foregroundStyle(AceTheme.fg)
            .autocorrectionDisabled(!hiding)
            .textInputAutocapitalization(.never)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AceTheme.soft))
            if code == .morse && !hiding {
                morseKeys
            }
            if !hiding && code == .morse && !message.isEmpty && !Morse.looksLikeMorse(message) {
                Label("Morse code is only dots, dashes, spaces and /. Switch to Hide a message to turn words into Morse.", systemImage: "info.circle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.warn)
            }
        }
        .aceCard(padding: 18)
    }

    private var placeholder: String {
        switch (code, hiding) {
        case (.morse, false): return "Type dots and dashes, like ... --- ..."
        case (_, true): return "Type a secret message"
        case (_, false): return "Type or paste the code to read"
        }
    }

    /// Big keys for typing Morse code.
    private var morseKeys: some View {
        HStack(spacing: 8) {
            morseKey("•", insert: ".", label: "Dot")
            morseKey("—", insert: "-", label: "Dash")
            morseKey("space", insert: " ", label: "Next letter")
            morseKey("/", insert: " / ", label: "Next word")
            morseKey("⌫", insert: nil, label: "Delete")
        }
    }

    private func morseKey(_ title: String, insert: String?, label: String) -> some View {
        Button {
            Haptics.shared.play(insert == "-" ? .pop : .tick)
            if let insert {
                message = String((message + insert).prefix(SecretCodes.maxLength))
            } else if !message.isEmpty {
                message.removeLast()
            }
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: 0xFFB020).opacity(0.22)))
        }
        .buttonStyle(.aceBouncy)
        .accessibilityLabel(label)
    }

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(hiding ? "Your secret code" : "The message", systemImage: hiding ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: code.hexes.1))
                Spacer()
                Button {
                    UIPasteboard.general.string = result
                    Haptics.shared.play(.success)
                    withAnimation(motion(.pop)) { copied = true }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(copied ? AceTheme.good : AceTheme.ace)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.aceBouncy)
                .disabled(result.isEmpty)
            }
            if message.isEmpty {
                Text(hiding ? "Your code shows up here as you type." : "The message shows up here as you type.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AceTheme.muted)
            } else {
                ScrambleText(text: result.isEmpty ? "No letters I can use yet" : result, moves: moves,
                             font: .system(size: code == .morse && hiding ? 20 : 24, weight: .bold, design: .monospaced))
            }
            if let crackNote {
                Label(crackNote, systemImage: "sparkles")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.good)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .aceCard(padding: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LinearGradient(colors: [Color(hex: code.hexes.0), Color(hex: code.hexes.1)], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(message.isEmpty ? 0.2 : 0.7), lineWidth: 2)
        )
        .shadow(color: Color(hex: code.hexes.1).opacity(message.isEmpty ? 0 : 0.25), radius: 18)
    }

    @ViewBuilder
    private var toolCard: some View {
        switch code {
        case .caesar: wheelCard
        case .morse: lampCard
        case .mirror: mirrorCard
        }
    }

    private var wheelCard: some View {
        VStack(spacing: 14) {
            CipherWheel(spin: $spin, moves: moves)
                .frame(maxWidth: 380)
                .padding(.top, 10)
            Text("Turn the wheel. The letter under the arrow is what A becomes.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                BouncyIconButton(symbol: "minus", label: "Smaller shift") { spin -= 1 }
                Text("A → \(String(Caesar.shifted("A", by: spin)))")
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundStyle(AceTheme.fg)
                    .frame(minWidth: 90)
                    .contentTransition(.numericText())
                BouncyIconButton(symbol: "plus", label: "Bigger shift") { spin += 1 }
            }
            if !hiding {
                Button {
                    crack()
                } label: {
                    Label("Crack it for me", systemImage: "wand.and.stars")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0x2BD9C5), Color(hex: 0x7C5CFF)], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.aceBouncy)
                .disabled(Caesar.letterCount(message) < 3)
            }
        }
        .frame(maxWidth: .infinity)
        .aceCard(padding: 18)
    }

    /// Tries every shift and turns the wheel to the one that reads most like English.
    private func crack() {
        guard let found = Caesar.crack(message) else { return }
        Haptics.shared.play(.success)
        // Turn the short way round to the answer.
        var delta = Caesar.normalize(found.shift - Caesar.normalize(spin))
        if delta > 13 { delta -= 26 }
        withAnimation(motion(.bouncy)) {
            spin += delta
            crackNote = Caesar.letterCount(message) < 12
                ? "My best guess is shift \(found.shift). Short messages are hard to be sure about."
                : "Cracked it: it looks like shift \(found.shift)."
        }
    }

    private var lampCard: some View {
        VStack(spacing: 14) {
            MorseLamp(on: lampOn)
                .frame(maxWidth: 240)
            MorseTape(code: morseToPlay, lit: lit)
                .frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.3)))
            HStack(spacing: 12) {
                Button {
                    if playing == nil { playMorse() } else { stopMorse() }
                } label: {
                    Label(playing == nil ? "Flash it" : "Stop", systemImage: playing == nil ? "play.fill" : "stop.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color(hex: 0xFFB020)))
                }
                .buttonStyle(.aceBouncy)
                .disabled(Morse.signals(morseToPlay).isEmpty)
                Toggle("Fast", isOn: $fast)
                    .toggleStyle(.button)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            Text("Each dot and dash buzzes too, so you can feel the message.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aceCard(padding: 18)
    }

    private func playMorse() {
        let signals = Morse.signals(morseToPlay)
        guard !signals.isEmpty else { return }
        let beat: UInt64 = fast ? 90_000_000 : 160_000_000
        playing = Task { @MainActor in
            for signal in signals {
                if Task.isCancelled { break }
                if signal.on {
                    lampOn = true
                    lit = signal.symbol
                    Haptics.shared.play(signal.units == 1 ? .tick : .pop)
                } else {
                    lampOn = false
                }
                try? await Task.sleep(nanoseconds: beat * UInt64(signal.units))
                lampOn = false
            }
            lampOn = false
            playing = nil
        }
    }

    private func stopMorse() {
        playing?.cancel()
        playing = nil
        lampOn = false
        lit = nil
    }

    private var mirrorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("The flipped alphabet", systemImage: "arrow.left.arrow.right")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            MirrorStrip(message: message)
            Text("Mirror code works both ways: code it twice and you get your message back.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AceTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .aceCard(padding: 18)
    }
}
