// @title Custom View Modifiers
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ModifierDemoView() in ContentView's body.
// @keywords swiftui viewmodifier, swiftui custom modifier, swiftui reusable style, swiftui view extension
// @about Makes your own reusable styles with ViewModifier so you don't repeat the same modifiers everywhere.

import SwiftUI

// A ViewModifier bundles several modifiers into one
struct GameCardStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4, y: 3)
    }
}

// A modifier that takes a setting and can change how a view looks
struct GlowingTitle: ViewModifier {
    var isOn: Bool

    func body(content: Content) -> some View {
        content
            .font(.largeTitle.bold())
            .shadow(color: isOn ? Color.yellow : Color.clear, radius: 12)
    }
}

// Extensions give our modifiers short, easy names
extension View {
    func gameCard(_ color: Color = .indigo) -> some View {
        modifier(GameCardStyle(color: color))
    }

    func glowingTitle(_ isOn: Bool) -> some View {
        modifier(GlowingTitle(isOn: isOn))
    }
}

struct ModifierDemoView: View {
    @State private var glow = true

    var body: some View {
        VStack(spacing: 16) {
            Text("My Games").glowingTitle(glow)
            Text("Space Blaster").gameCard()
            Text("Dragon Quest").gameCard(.red)
            Text("Puzzle Land").gameCard(.green)
            Toggle("Glow", isOn: $glow)
        }
        .padding()
    }
}
