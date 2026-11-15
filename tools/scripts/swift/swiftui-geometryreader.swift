// @title GeometryReader
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show GeometryDemoView() in ContentView's body.
// @keywords swiftui geometryreader, swiftui screen size, swiftui relative sizing, swiftui proxy size
// @about Uses GeometryReader to learn how much space there is and size things as a fraction of the screen.

import SwiftUI

struct GeometryDemoView: View {
    let values: [CGFloat] = [0.3, 0.8, 0.55, 1.0, 0.45]

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
                Text("This space is \(Int(proxy.size.width)) x \(Int(proxy.size.height)) points")
                    .font(.headline)

                // Bars sized as a fraction of the available width
                ForEach(values.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.teal)
                        .frame(width: proxy.size.width * values[index], height: 28)
                        .overlay(alignment: .trailing) {
                            Text("\(Int(values[index] * 100))%")
                                .font(.caption.bold())
                                .padding(.trailing, 6)
                        }
                }

                // A square that is always one third of the width
                Rectangle()
                    .fill(.orange)
                    .frame(width: proxy.size.width / 3, height: proxy.size.width / 3)
                    .overlay { Text("1/3 wide") }

                Text(proxy.size.width > proxy.size.height ? "Landscape (wide)" : "Portrait (tall)")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
