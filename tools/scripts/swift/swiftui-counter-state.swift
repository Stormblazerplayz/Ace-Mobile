// @title Counter with @State
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show CounterView() in ContentView's body.
// @keywords swiftui counter, swiftui @state, swiftui state variable, swiftui plus minus buttons
// @about A counter with plus, minus and reset buttons that shows how @State makes the screen update.

import SwiftUI

struct CounterView: View {
    // @State tells SwiftUI: "redraw the screen whenever this changes"
    @State private var count = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("\(count)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(count < 0 ? Color.red : Color.primary)
                .contentTransition(.numericText())  // numbers roll when they change

            HStack(spacing: 24) {
                Button {
                    withAnimation { count -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 60))
                }

                Button {
                    withAnimation { count += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                }
            }

            Button("Reset") {
                withAnimation { count = 0 }
            }
            .buttonStyle(.bordered)
            .disabled(count == 0)

            Text(count >= 10 ? "Double digits!" : "Keep tapping")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
