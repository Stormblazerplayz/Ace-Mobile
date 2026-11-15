// @title Temperature Converter Table
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Temperatures.swift and run in Terminal: swiftc -parse-as-library Temperatures.swift -o temps && ./temps
// @keywords swift temperature converter, swift celsius fahrenheit, swift measurement, swift string format table
// @about Converts temperatures between Celsius, Fahrenheit and Kelvin and prints a neat table.

import Foundation

enum TempUnit: String, CaseIterable {
    case celsius = "C", fahrenheit = "F", kelvin = "K"
}

@main
struct TemperatureConverterProgram {
    static func convert(_ value: Double, from: TempUnit, to: TempUnit) -> Double {
        // Change to Celsius first, then to the target unit
        let c: Double
        switch from {
        case .celsius: c = value
        case .fahrenheit: c = (value - 32) * 5 / 9
        case .kelvin: c = value - 273.15
        }
        switch to {
        case .celsius: return c
        case .fahrenheit: return c * 9 / 5 + 32
        case .kelvin: return c + 273.15
        }
    }

    static func main() {
        print("     C        F        K")
        for c in stride(from: -40.0, through: 100.0, by: 20.0) {
            let f = convert(c, from: .celsius, to: .fahrenheit)
            let k = convert(c, from: .celsius, to: .kelvin)
            print(String(format: "%6.1f %8.1f %8.2f", c, f, k))
        }

        // Apple's Measurement type can convert for you too
        let bodyTemp = Measurement(value: 98.6, unit: UnitTemperature.fahrenheit)
        print("98.6 F is \(String(format: "%.1f", bodyTemp.converted(to: .celsius).value)) C")
        print("Fun fact: -40 is the same in C and F: \(convert(-40, from: .celsius, to: .fahrenheit))")
    }
}
