// @title VStack, HStack and ZStack
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show StacksLayoutView() in ContentView's body.
// @keywords swiftui vstack, swiftui hstack, swiftui zstack, swiftui spacer, swiftui padding layout
// @about Explains the three stacks that arrange views: down (VStack), across (HStack) and on top (ZStack).

import SwiftUI

struct StacksLayoutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // VStack: one on top of the other
            VStack(spacing: 4) {
                Text("VStack")
                    .font(.headline)
                box(.red)
                box(.orange)
                box(.yellow)
            }

            // HStack: side by side. Spacer() pushes things apart.
            HStack {
                Text("HStack")
                    .font(.headline)
                Spacer()
                box(.green)
                box(.teal)
                box(.blue)
            }
            .padding()
            .background(.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            // ZStack: stacked on top of each other, like layers
            ZStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(.pink)
                    .frame(width: 90, height: 90)
                Text("ZStack")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Alignment lines things up
            VStack(alignment: .leading) {
                Text("Leading alignment")
                Text("lines up on the left")
                Text("side")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .border(.gray)
        }
        .padding()
    }

    // A helper that makes a little colored square
    func box(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(width: 40, height: 40)
    }
}
