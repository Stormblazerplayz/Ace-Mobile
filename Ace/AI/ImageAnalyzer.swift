import ImageIO
import UIKit
import Vision

/// Looks at a picture on the iPad with Apple's Vision: what's in it, any text, QR codes and faces.
enum ImageAnalyzer {
    static func analyze(_ image: UIImage) async -> ImageReport {
        guard let cg = image.cgImage else {
            return ImageReport(labels: [], text: nil, codes: [], faces: 0, summary: "I couldn't read that picture.")
        }
        let orientation = Self.orientation(image.imageOrientation)
        return await Task.detached(priority: .userInitiated) {
            Self.run(cg, orientation: orientation)
        }.value
    }

    private static func run(_ cg: CGImage, orientation: CGImagePropertyOrientation) -> ImageReport {
        let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])
        let classify = VNClassifyImageRequest()
        let text = VNRecognizeTextRequest()
        text.recognitionLevel = .accurate
        text.usesLanguageCorrection = true
        let codes = VNDetectBarcodesRequest()
        let faces = VNDetectFaceRectanglesRequest()
        try? handler.perform([classify, text, codes, faces])

        let labels: [String] = (classify.results ?? [])
            .filter { $0.confidence > 0.25 }
            .prefix(6)
            .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
        let lines: [String] = (text.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let found: [String] = (codes.results ?? []).compactMap { $0.payloadStringValue }
        let faceCount = faces.results?.count ?? 0
        let joined = lines.joined(separator: "\n")

        var parts: [String] = []
        if let first = labels.first {
            let rest = labels.dropFirst().prefix(2)
            parts.append(rest.isEmpty ? "It looks like \(first)." : "It looks like \(first), with \(rest.joined(separator: " and ")).")
        }
        if faceCount > 0 { parts.append(faceCount == 1 ? "I see 1 face." : "I see \(faceCount) faces.") }
        if !lines.isEmpty {
            let preview = lines.prefix(2).joined(separator: " ")
            parts.append(lines.count > 2 ? "It has text that starts \"\(preview)\"." : "It says \"\(preview)\".")
        }
        if let code = found.first { parts.append("There's a code: \(code)") }
        if parts.isEmpty { parts.append("I can't tell what's in this one. Try a clearer or brighter picture.") }

        return ImageReport(labels: labels, text: joined.isEmpty ? nil : joined, codes: found, faces: faceCount,
                           summary: parts.joined(separator: " "))
    }

    private static func orientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch o {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    /// Shrinks a picture so it's quick to save and read, then returns JPEG data.
    static func jpeg(_ image: UIImage, maxSide: CGFloat = 2048) -> Data? {
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height, 1))
        let target = CGSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.85)
    }
}
