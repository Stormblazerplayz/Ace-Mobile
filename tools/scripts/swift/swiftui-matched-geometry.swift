// @title Matched Geometry Effect
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show MatchedGeometryView() in ContentView's body.
// @keywords swiftui matchedgeometryeffect, swiftui namespace, swiftui hero animation, swiftui expand card
// @about Tap a small card and it smoothly grows into a big card, using matchedGeometryEffect.

import SwiftUI

struct MatchedGeometryView: View {
    @Namespace private var cardSpace  // a shared name space for matching views
    @State private var isExpanded = false

    var body: some View {
        VStack {
            if isExpanded {
                // The big version
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 80))
                        .matchedGeometryEffect(id: "icon", in: cardSpace)
                    Text("Planet Earth")
                        .font(.largeTitle.bold())
                        .matchedGeometryEffect(id: "title", in: cardSpace)
                    Text("Home sweet home. 71 percent of it is covered in water. Tap to close.")
                }
                .foregroundStyle(.white)
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.blue)
                        .matchedGeometryEffect(id: "background", in: cardSpace)
                )
            } else {
                // The small version
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 40))
                        .matchedGeometryEffect(id: "icon", in: cardSpace)
                    Text("Planet Earth")
                        .font(.headline)
                        .matchedGeometryEffect(id: "title", in: cardSpace)
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .matchedGeometryEffect(id: "background", in: cardSpace)
                )
                Spacer()
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.5)) { isExpanded.toggle() }
        }
    }
}
