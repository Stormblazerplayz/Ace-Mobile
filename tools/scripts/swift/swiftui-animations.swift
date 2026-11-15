// @title Animations
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show AnimationsDemoView() in ContentView's body.
// @keywords swiftui animation, swiftui withanimation, swiftui spring animation, swiftui repeatforever, swiftui rotation effect
// @about Shows SwiftUI animations: springs, easing, rotating, scaling and a forever-pulsing heart.

import SwiftUI

struct AnimationsDemoView: View {
    @State private var moved = false
    @State private var spin = 0.0
    @State private var big = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 36) {
            // 1. Move with a bouncy spring
            Circle()
                .fill(.blue)
                .frame(width: 60, height: 60)
                .offset(x: moved ? 120 : -120)
                .animation(.spring(response: 0.5, dampingFraction: 0.4), value: moved)
            Button("Bounce") { moved.toggle() }

            // 2. Spin with withAnimation
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .rotationEffect(.degrees(spin))
            Button("Spin") {
                withAnimation(.easeInOut(duration: 1)) { spin += 360 }
            }

            // 3. Grow and change color
            RoundedRectangle(cornerRadius: big ? 40 : 8)
                .fill(big ? Color.orange : Color.green)
                .frame(width: big ? 200 : 80, height: 80)
                .onTapGesture {
                    withAnimation(.easeInOut) { big.toggle() }
                }
            Text("Tap the box").font(.caption)

            // 4. Pulse forever, starting as soon as it appears
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }
        }
        .buttonStyle(.bordered)
        .padding()
    }
}
