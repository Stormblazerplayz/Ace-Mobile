// @title Phase and Keyframe Animations
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PhaseAnimatorDemoView() in ContentView's body.
// @keywords swiftui phaseanimator, swiftui keyframeanimator, swiftui looping animation, swiftui multi step animation
// @about Uses iOS 17 phaseAnimator to loop a pulsing heart and keyframeAnimator to make a ball jump when tapped.

import SwiftUI

// The values the jumping ball animates between
struct JumpValues {
    var height: CGFloat = 0
    var squash: CGFloat = 1
}

struct PhaseAnimatorDemoView: View {
    @State private var jumps = 0

    var body: some View {
        VStack(spacing: 60) {
            // phaseAnimator loops through the phases forever: small, big, small...
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
                .phaseAnimator([false, true]) { content, isBig in
                    content.scaleEffect(isBig ? 1.3 : 1.0)
                } animation: { _ in
                    .easeInOut(duration: 0.6)
                }

            // keyframeAnimator plays a list of steps each time "jumps" changes
            Circle()
                .fill(Color.orange)
                .frame(width: 70, height: 70)
                .keyframeAnimator(initialValue: JumpValues(), trigger: jumps) { content, value in
                    content
                        .scaleEffect(x: 1 / value.squash, y: value.squash, anchor: .bottom)
                        .offset(y: -value.height)
                } keyframes: { _ in
                    KeyframeTrack(\.height) {
                        SpringKeyframe(0, duration: 0.1)
                        CubicKeyframe(150, duration: 0.35)
                        CubicKeyframe(0, duration: 0.35)
                    }
                    KeyframeTrack(\.squash) {
                        CubicKeyframe(0.7, duration: 0.1)
                        CubicKeyframe(1.2, duration: 0.2)
                        CubicKeyframe(1.0, duration: 0.5)
                    }
                }

            Button("Jump!") { jumps += 1 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
