// @title Loading Images from the Internet
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show AsyncImageDemoView() in ContentView's body. Needs internet.
// @keywords swiftui asyncimage, swiftui load image url, swiftui image from internet, swiftui image placeholder
// @about Downloads pictures from the web with AsyncImage, showing a spinner while loading and an icon if it fails.

import SwiftUI

struct AsyncImageDemoView: View {
    @State private var photoNumber = 10

    // picsum.photos gives a different free photo for each number
    var url: URL? { URL(string: "https://picsum.photos/id/\(photoNumber)/600/400") }

    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView("Loading...")  // still downloading
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Text("Photo #\(photoNumber)")
            HStack {
                Button("Previous") { photoNumber = max(0, photoNumber - 1) }
                Button("Random") { photoNumber = Int.random(in: 0...200) }
                Button("Next") { photoNumber += 1 }
            }
            .buttonStyle(.bordered)

            // The short version, when you just want the picture
            AsyncImage(url: URL(string: "https://picsum.photos/id/237/200/200")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        }
        .padding()
    }
}
