// @title @Binding: Sharing State with a Child View
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show BindingDemoView() in ContentView's body.
// @keywords swiftui binding, swiftui @binding, swiftui pass state to child, swiftui dollar sign
// @about Shows how a parent view can share a value with a child view so the child can change it.

import SwiftUI

struct BindingDemoView: View {
    @State private var volume = 5
    @State private var isMuted = false

    var body: some View {
        VStack(spacing: 24) {
            Text(isMuted ? "Muted" : "Volume: \(volume)")
                .font(.largeTitle.bold())

            // The $ makes a Binding: a two-way connection to the @State
            VolumeKnob(level: $volume)
            MuteSwitch(isOn: $isMuted)

            Text("Both controls change values that live in the parent view.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// The child doesn't own the value, it just borrows it with @Binding
struct VolumeKnob: View {
    @Binding var level: Int

    var body: some View {
        HStack {
            Button("Quieter") { level = max(0, level - 1) }
            ProgressView(value: Double(level), total: 10)
            Button("Louder") { level = min(10, level + 1) }
        }
        .buttonStyle(.bordered)
    }
}

struct MuteSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("Mute", isOn: $isOn)
            .padding()
            .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
