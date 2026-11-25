import SwiftUI
import UIKit

/// How Ace moves: one set of springs for the whole app, so buttons, switches, chat bubbles and
/// screens all bounce the same way. "Bouncy animations" in Settings swaps the bounce for a quick,
/// calm ease, and Reduce Motion (in the iPad's own Settings) keeps everything still.
enum AceMotion {
    /// The UserDefaults key behind Settings > Look and feel > Bouncy animations.
    static let settingKey = "bouncyMotion"

    enum Kind: CaseIterable {
        /// Big, playful moves: rows and bubbles springing in.
        case bouncy
        /// Quick moves that settle fast: pressing a button down.
        case snappy
        /// Soft moves for big things: a whole screen settling into place.
        case gentle
        /// A short boing with lots of overshoot: letting go of a button, a switch flipping.
        case pop
    }

    /// How long the calm ease takes when Bouncy animations is off.
    static let calmDuration = 0.2

    /// Response (in seconds) and damping for each spring. Damping under 1 overshoots, and lower is bouncier.
    static func spring(_ kind: Kind) -> (response: Double, damping: Double) {
        switch kind {
        case .bouncy: return (0.5, 0.62)
        case .snappy: return (0.28, 0.78)
        case .gentle: return (0.6, 0.8)
        case .pop: return (0.36, 0.5)
        }
    }

    /// The animation for a kind of move. With the bounce off it's a short ease, and with
    /// Reduce Motion on it's nil, so views go straight to where they end up.
    static func animation(_ kind: Kind, bouncy: Bool, reduceMotion: Bool) -> Animation? {
        if reduceMotion { return nil }
        guard bouncy else { return .easeInOut(duration: calmDuration) }
        let s = spring(kind)
        return .spring(response: s.response, dampingFraction: s.damping)
    }

    /// True when things should really move around (the bounce is on and Reduce Motion is off).
    static func moves(bouncy: Bool, reduceMotion: Bool) -> Bool {
        bouncy && !reduceMotion
    }

    /// How long row `index` waits before it springs in, so a list cascades down.
    /// It stops growing after a few rows, so a long list never makes you wait.
    static func stagger(_ index: Int, step: Double = 0.04, cap: Double = 0.48) -> Double {
        min(cap, Double(max(0, index)) * step)
    }

    /// How big something is while it's pressed (1 is normal size).
    static func pressScale(pressed: Bool, moving: Bool, depth: CGFloat = 0.92) -> CGFloat {
        pressed && moving ? depth : 1
    }

    /// The Bouncy animations setting, for code that isn't a view.
    static var isOn: Bool {
        UserDefaults.standard.object(forKey: settingKey) as? Bool ?? true
    }

    /// The animation for a kind of move right now, from the setting and Reduce Motion.
    @MainActor
    static func now(_ kind: Kind) -> Animation? {
        animation(kind, bouncy: isOn, reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }
}

// MARK: Springing in

/// Springs a view in when `shown` turns true: up from a little lower, from a little smaller,
/// and from see-through. Give each row its own `order` and they cascade in one after another.
struct BounceReveal: ViewModifier {
    var shown: Bool
    var order: Int = 0
    var rise: CGFloat = 18
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        // With Reduce Motion on, things are simply there.
        let hidden = !shown && !reduceMotion
        content
            .opacity(hidden ? 0 : 1)
            .scaleEffect(hidden && moving ? 0.94 : 1, anchor: .top)
            .offset(y: hidden && moving ? rise : 0)
            .animation(AceMotion.animation(.bouncy, bouncy: bouncy, reduceMotion: reduceMotion)?.delay(AceMotion.stagger(order)),
                       value: shown)
    }
}

/// A quick boing (grow, then spring back) every time `trigger` changes.
struct Boing<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    var scale: CGFloat = 1.12
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(up ? scale : 1)
            .onChange(of: trigger) { _, _ in
                guard AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) else { return }
                withAnimation(.spring(response: 0.16, dampingFraction: 0.7)) {
                    up = true
                } completion: {
                    withAnimation(AceMotion.animation(.pop, bouncy: true, reduceMotion: false)) { up = false }
                }
            }
    }
}

extension View {
    /// Springs in when `shown` turns true. Rows with a higher `order` come in a little later.
    func bounceReveal(_ shown: Bool, order: Int = 0, rise: CGFloat = 18) -> some View {
        modifier(BounceReveal(shown: shown, order: order, rise: rise))
    }

    /// A quick boing every time `trigger` changes.
    func boing<Trigger: Equatable>(on trigger: Trigger, scale: CGFloat = 1.12) -> some View {
        modifier(Boing(trigger: trigger, scale: scale))
    }
}

extension AnyTransition {
    /// A chat bubble popping in: yours from the bottom right, Ace's from the top left (where the orb is).
    static func chatBubble(fromUser: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8, anchor: fromUser ? .bottomTrailing : .topLeading)
                .combined(with: .opacity)
                .combined(with: .offset(y: 14)),
            removal: .opacity
        )
    }
}

// MARK: Buttons

/// Shrinks a little while pressed and boings back when you let go.
struct BouncyPress<Label: View>: View {
    let label: Label
    let pressed: Bool
    var depth: CGFloat = 0.92
    var anchor: UnitPoint = .center
    var dimsWhenDisabled = false
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let moving = AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion)
        label
            .scaleEffect(AceMotion.pressScale(pressed: pressed, moving: moving, depth: depth), anchor: anchor)
            .opacity((pressed ? 0.8 : 1) * (dimsWhenDisabled && !isEnabled ? 0.4 : 1))
            .animation(AceMotion.animation(pressed ? .snappy : .pop, bouncy: bouncy, reduceMotion: reduceMotion), value: pressed)
    }
}

/// A button that squishes when you press it and boings back when you let go.
struct BouncyButtonStyle: ButtonStyle {
    var depth: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        BouncyPress(label: configuration.label, pressed: configuration.isPressed, depth: depth)
    }
}

/// A row button in Settings: tinted like a normal row button (red for destructive ones),
/// tappable across the whole row, and springy when pressed.
struct BouncyRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BouncyPress(label: configuration.label, pressed: configuration.isPressed, depth: 0.95, anchor: .leading, dimsWhenDisabled: true)
            .foregroundStyle(configuration.role == .destructive ? AceTheme.bad : AceTheme.ace)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == BouncyButtonStyle {
    /// Squishes when pressed and boings back.
    static var aceBouncy: BouncyButtonStyle { BouncyButtonStyle() }
}

extension ButtonStyle where Self == BouncyRowButtonStyle {
    /// A springy row button for Settings and lists.
    static var aceBouncyRow: BouncyRowButtonStyle { BouncyRowButtonStyle() }
}

/// A round header button whose symbol jumps when you tap it.
struct BouncyIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0

    var body: some View {
        Button {
            if AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) { taps += 1 }
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .symbolEffect(.bounce, value: taps)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(BouncyButtonStyle(depth: 0.82))
        .accessibilityLabel(label)
    }
}

// MARK: Switches

/// Ace's own switch: the knob springs across with a little overshoot, squashes as it goes,
/// and the track glows when it's on. Tap anywhere on the row to flip it.
struct BouncyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        BouncyToggleRow(configuration: configuration)
    }
}

extension ToggleStyle where Self == BouncyToggleStyle {
    /// Ace's springy switch.
    static var aceBouncy: BouncyToggleStyle { BouncyToggleStyle() }
}

struct BouncyToggleRow: View {
    let configuration: ToggleStyleConfiguration
    @AppStorage(AceMotion.settingKey) private var bouncy = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var squish = false

    var body: some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            BouncySwitch(isOn: configuration.isOn, squish: squish)
        }
        .contentShape(Rectangle())
        .onTapGesture { flip() }
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityAction { flip() }
    }

    private func flip() {
        guard isEnabled else { return }
        withAnimation(AceMotion.animation(.pop, bouncy: bouncy, reduceMotion: reduceMotion)) {
            configuration.isOn.toggle()
        }
        Haptics.shared.play(.tick)
        guard AceMotion.moves(bouncy: bouncy, reduceMotion: reduceMotion) else { return }
        // The knob squashes wide while it travels, then springs back round.
        withAnimation(.spring(response: 0.14, dampingFraction: 0.7)) {
            squish = true
        } completion: {
            withAnimation(AceMotion.animation(.pop, bouncy: true, reduceMotion: false)) { squish = false }
        }
    }
}

/// The switch itself (the track and the knob).
struct BouncySwitch: View {
    var isOn: Bool
    var squish = false

    static let size = CGSize(width: 51, height: 31)
    private let knob: CGFloat = 27

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule(style: .continuous)
                .fill(isOn ? AceTheme.ace : Color.white.opacity(0.16))
            Capsule(style: .continuous)
                .fill(Color.white)
                .frame(width: knob + (squish ? 7 : 0), height: knob - (squish ? 2 : 0))
                .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
                .padding(2)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .shadow(color: AceTheme.ace.opacity(isOn ? 0.45 : 0), radius: 6)
        .accessibilityHidden(true)
    }
}
