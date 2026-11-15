// @title Transitions
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TransitionsDemoView() in ContentView's body.
// @keywords swiftui transition, swiftui show hide view, swiftui slide in, swiftui asymmetric transition, swiftui if view animation
// @about Shows how views can slide, fade, scale and move in and out when they appear and disappear.

import SwiftUI

struct TransitionsDemoView: View {
    @State private var showBanner = false
    @State private var showCard = false
    @State private var showBadge = false

    var body: some View {
        VStack(spacing: 24) {
            Button("Toggle all") {
                withAnimation(.spring) {
                    showBanner.toggle()
                    showCard.toggle()
                    showBadge.toggle()
                }
            }
            .buttonStyle(.borderedProminent)

            ZStack {
                if showBanner {
                    Text("Slides in from the top")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(height: 60)

            ZStack {
                if showCard {
                    Text("Comes in from the left, leaves to the right")
                        .padding()
                        .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                }
            }
            .frame(height: 60)

            ZStack {
                if showBadge {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 100)
        }
        .padding()
    }
}
