// @title Jump Around with ScrollViewReader
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ScrollJumpView() in ContentView's body.
// @keywords swiftui scrollviewreader, swiftui scrollto, swiftui scroll to bottom, swiftui jump to item
// @about A long list of numbered rows with buttons that scroll straight to the top, the bottom or a random row.

import SwiftUI

struct ScrollJumpView: View {
    @State private var target = 50

    var body: some View {
        // The proxy lets us tell the scroll view where to go
        ScrollViewReader { proxy in
            VStack {
                HStack {
                    Button("Top") {
                        withAnimation { proxy.scrollTo(1, anchor: .top) }
                    }
                    Button("Random") {
                        target = Int.random(in: 1...100)
                        withAnimation { proxy.scrollTo(target, anchor: .center) }
                    }
                    Button("Bottom") {
                        withAnimation { proxy.scrollTo(100, anchor: .bottom) }
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(1...100, id: \.self) { number in
                            Text("Row \(number)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(number == target ? Color.yellow : Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .id(number)  // the id is what scrollTo looks for
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
