// @title Protocols
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Protocols.swift and run in Terminal: swiftc -parse-as-library Protocols.swift -o protocols && ./protocols
// @keywords swift protocol, swift conform to protocol, swift protocol extension, swift polymorphism
// @about Uses a protocol as a promise: any shape that conforms must be able to tell its area and name.

import Foundation

// A protocol is a list of things a type promises to have
protocol AreaShape {
    var shapeName: String { get }
    func area() -> Double
}

// A protocol extension gives every conforming type a free method
extension AreaShape {
    func summary() -> String {
        "\(shapeName) with area \(String(format: "%.2f", area()))"
    }
}

struct CircleShape: AreaShape {
    let radius: Double
    var shapeName: String { "Circle" }
    func area() -> Double { Double.pi * radius * radius }
}

struct RectangleShape: AreaShape {
    let width: Double
    let height: Double
    var shapeName: String { width == height ? "Square" : "Rectangle" }
    func area() -> Double { width * height }
}

struct TriangleShape: AreaShape {
    let base: Double
    let height: Double
    var shapeName: String { "Triangle" }
    func area() -> Double { base * height / 2 }
}

@main
struct ProtocolsProgram {
    static func main() {
        // Different types in one array, because they all conform to AreaShape
        let shapes: [any AreaShape] = [
            CircleShape(radius: 2),
            RectangleShape(width: 3, height: 4),
            RectangleShape(width: 5, height: 5),
            TriangleShape(base: 6, height: 2),
        ]
        for shape in shapes {
            print(shape.summary())
        }
        let biggest = shapes.max { $0.area() < $1.area() }
        print("Biggest: \(biggest?.shapeName ?? "none")")
        let total = shapes.reduce(0.0) { $0 + $1.area() }
        print("Total area: \(String(format: "%.1f", total))")
    }
}
