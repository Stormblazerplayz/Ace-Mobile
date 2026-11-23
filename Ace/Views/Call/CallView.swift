import SwiftUI

/// The voice call screen: a big orb that reacts while you talk, Ace thinks and Ace talks,
/// the call timer, live captions, and the call buttons (mute, speaker, captions, end).
struct CallView: View {
    @ObservedObject var call: CallController
    @EnvironmentObject var core: AceCore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Captions on or off (Ace remembers your choice).
    @AppStorage("callCaptions") private var showCaptions = true
    @State private var start = Date()

    private var mood: OrbMood { CallLogic.orbMood(call.phase, ace: core.mood) }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                top
                    .padding(.top, 24)
                Spacer(minLength: 12)
                orb
                Spacer(minLength: 12)
                if showCaptions {
                    captions
                        .frame(maxHeight: 260)
                        .padding(.horizontal, 20)
                }
                controls
                    .padding(.top, 18)
                    .padding(.bottom, 28)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
        .accessibilityAction(.magicTap) {
            // Two-finger double tap: stop Ace talking, or end the call.
            if call.phase == .speaking { call.interrupt() } else { call.hangUp() }
        }
    }

    // MARK: Parts

    private var background: some View {
        ZStack {
            AceTheme.background
            RadialGradient(colors: [mood.tint.opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: 520)
                .animation(.easeInOut(duration: 0.6), value: mood)
        }
        .ignoresSafeArea()
    }

    private var top: some View {
        VStack(spacing: 6) {
            Text("Ace")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AceTheme.fg)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(timerText(at: context.date))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(AceTheme.muted)
                    .accessibilityLabel(timerLabel(at: context.date))
            }
            HStack(spacing: 6) {
                if call.muted {
                    Image(systemName: "mic.slash.fill")
                        .foregroundStyle(AceTheme.bad)
                }
                Text(call.muted && call.phase.isLive ? "Muted" : call.phase.label)
                    .contentTransition(.opacity)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(call.phase == .ended ? AceTheme.bad : mood.tint)
            .animation(.easeInOut(duration: 0.2), value: call.phase)
        }
        .accessibilityElement(children: .combine)
    }

    private func timerText(at date: Date) -> String {
        guard let began = call.startedAt else { return call.phase == .ended ? "0:00" : "Calling…" }
        return CallLogic.clock((call.endedAt ?? date).timeIntervalSince(began))
    }

    private func timerLabel(at date: Date) -> String {
        guard let began = call.startedAt else { return "Calling" }
        return "Call time " + CallLogic.lengthInWords((call.endedAt ?? date).timeIntervalSince(began))
    }

    /// The big orb. Rings grow with your voice, bars bounce while Ace talks. Tap it to stop Ace talking.
    private var orb: some View {
        TimelineView(.animation(minimumInterval: call.phase == .ended ? 1.0 / 15.0 : nil)) { context in
            let t = context.date.timeIntervalSince(start) * (reduceMotion ? 0.35 : 1)
            let speed: Double = mood == .talking ? 7 : mood == .thinking ? 3.2 : mood == .sleeping ? 0.8 : 1.4
            let breathe = (sin(t * speed) + 1) / 2
            let size: CGFloat = sizeClass == .compact ? 170 : 230
            ZStack {
                if mood == .listening || call.phase == .listening {
                    ForEach(0..<3, id: \.self) { i in
                        let p = (t * (mood == .listening ? 0.9 : 0.4) + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                        Circle()
                            .stroke(mood.tint.opacity((mood == .listening ? 0.6 : 0.25) * (1 - p)), lineWidth: 2.5)
                            .scaleEffect(1 + p * (0.55 + call.level * 0.9))
                    }
                }
                if mood == .thinking {
                    ThinkingLayer(part: .back, time: t, reduceMotion: reduceMotion, orbSize: size, tint: mood.tint)
                }
                OrbBody(
                    tint: mood.tint,
                    tint2: mood.tint2,
                    glow: mood == .sleeping ? 0.3 : min(1, 0.5 + 0.35 * breathe + 0.2 * mood.energy + 0.3 * call.level),
                    pulse: breathe,
                    time: t,
                    energy: reduceMotion ? mood.energy * 0.4 : mood.energy
                )
                .frame(width: size, height: size)
                if mood == .thinking {
                    ThinkingLayer(part: .front, time: t, reduceMotion: reduceMotion, orbSize: size, tint: mood.tint)
                }
                if mood.showsEyes {
                    OrbEyes(look: core.look, open: core.eyeOpen, happy: mood == .happy)
                        .frame(width: size * 0.42, height: size * 0.42)
                } else if mood == .sleeping {
                    OrbEyes(look: .zero, open: 0.1)
                        .frame(width: size * 0.42, height: size * 0.42)
                } else if mood == .talking {
                    HStack(spacing: 7) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(Color.white.opacity(0.88))
                                .frame(width: 8, height: 14 + 38 * abs(sin(t * 8 + Double(i) * 1.25)))
                        }
                    }
                }
            }
            .frame(width: size * 1.9, height: size * 1.9)
        }
        .contentShape(Circle())
        .onTapGesture {
            if call.phase == .speaking { call.interrupt() }
        }
        .accessibilityElement()
        .accessibilityLabel("Ace")
        .accessibilityValue(call.phase.label)
        .accessibilityHint(call.phase == .speaking ? "Double tap to stop Ace talking." : "")
        .accessibilityAddTraits(call.phase == .speaking ? .isButton : [])
    }

    private var captions: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(call.captions) { line in
                        CaptionRow(line: line)
                            .id(line.id)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    Color.clear.frame(height: 1).id("end")
                }
                .padding(.vertical, 8)
                .animation(.easeOut(duration: 0.2), value: call.captions)
            }
            .mask(
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                                       .init(color: .black, location: 1)], startPoint: .top, endPoint: .bottom)
            )
            .onChange(of: call.captions) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("end", anchor: .bottom) }
            }
            .onAppear { proxy.scrollTo("end", anchor: .bottom) }
        }
    }

    private var controls: some View {
        HStack(alignment: .top, spacing: 26) {
            CallButton(symbol: call.muted ? "mic.slash.fill" : "mic.fill",
                       label: call.muted ? "Unmute" : "Mute",
                       on: call.muted) { call.toggleMute() }
            CallButton(symbol: call.speakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                       label: "Speaker",
                       on: call.speakerOn) { call.toggleSpeaker() }
            CallButton(symbol: showCaptions ? "captions.bubble.fill" : "captions.bubble",
                       label: "Captions",
                       on: showCaptions) { withAnimation(.easeInOut(duration: 0.2)) { showCaptions.toggle() } }
            CallButton(symbol: "phone.down.fill",
                       label: call.phase == .ended ? "Close" : "End",
                       on: false,
                       tint: AceTheme.bad) {
                if call.phase == .ended { call.dismissEnded() } else { call.hangUp() }
            }
        }
        .disabled(call.phase == .off)
    }
}

/// One line of the captions: what you said on the right, what Ace said on the left.
private struct CaptionRow: View {
    let line: CallLogic.Caption

    private var isYou: Bool { line.who == .you }

    var body: some View {
        HStack {
            if isYou { Spacer(minLength: 50) }
            VStack(alignment: isYou ? .trailing : .leading, spacing: 3) {
                Text(isYou ? "You" : "Ace")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isYou ? AceTheme.ace : AceTheme.accent)
                Text(line.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AceTheme.fg.opacity(line.live ? 0.65 : 1))
                    .multilineTextAlignment(isYou ? .trailing : .leading)
                    .italic(line.live)
            }
            if !isYou { Spacer(minLength: 50) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A round call button with its name under it, like the phone app.
private struct CallButton: View {
    let symbol: String
    let label: String
    var on: Bool
    var tint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(fill))
                    .foregroundStyle(tint != nil || !on ? Color.white : Color.black)
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(AceTheme.muted)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on && tint == nil ? .isSelected : [])
    }

    private var fill: Color {
        if let tint { return tint }
        return on ? Color.white.opacity(0.92) : Color.white.opacity(0.14)
    }
}

/// Shows the call screen over everything while a call is on.
struct CallCover: ViewModifier {
    @ObservedObject var call: CallController
    let core: AceCore
    let settings: SettingsStore

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding(
            get: { call.phase != .off },
            set: { shown in if !shown { call.dismissEnded() } }
        )) {
            CallView(call: call)
                .environmentObject(core)
                .environmentObject(settings)
        }
    }
}
