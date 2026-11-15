// @title Unit Converter App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show UnitConverterAppView() in ContentView's body.
// @keywords swiftui unit converter, swiftui measurement, swiftui unitlength, swiftui convert units
// @about Converts lengths, temperatures and weights using Apple's Measurement type.

import SwiftUI

struct UnitConverterAppView: View {
    @State private var amount = 1.0
    @State private var kind = 0
    @State private var fromIndex = 0
    @State private var toIndex = 1

    let kinds = ["Length", "Temperature", "Weight"]
    // Each kind has its own list of units. Dimension is the parent class of all of them.
    let units: [[Dimension]] = [
        [UnitLength.meters, UnitLength.feet, UnitLength.inches, UnitLength.kilometers, UnitLength.miles],
        [UnitTemperature.celsius, UnitTemperature.fahrenheit, UnitTemperature.kelvin],
        [UnitMass.kilograms, UnitMass.pounds, UnitMass.grams, UnitMass.ounces],
    ]

    var currentUnits: [Dimension] { units[kind] }

    var resultText: String {
        // min() keeps the index safe for a moment after switching to a shorter list
        let fromUnit = currentUnits[min(fromIndex, currentUnits.count - 1)]
        let toUnit = currentUnits[min(toIndex, currentUnits.count - 1)]
        let from = Measurement(value: amount, unit: fromUnit)
        let converted = from.converted(to: toUnit)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit  // keep the unit we picked
        formatter.numberFormatter.maximumFractionDigits = 3
        return formatter.string(from: converted)
    }

    func name(of unit: Dimension) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        return formatter.string(from: unit).capitalized
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(kinds.indices, id: \.self) { index in
                        Text(kinds[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: kind) {
                    fromIndex = 0
                    toIndex = 1
                }

                Section("Convert") {
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("From", selection: $fromIndex) {
                        ForEach(currentUnits.indices, id: \.self) { index in
                            Text(name(of: currentUnits[index])).tag(index)
                        }
                    }
                    Picker("To", selection: $toIndex) {
                        ForEach(currentUnits.indices, id: \.self) { index in
                            Text(name(of: currentUnits[index])).tag(index)
                        }
                    }
                }

                Section("Answer") {
                    Text(resultText).font(.title2.bold())
                }
            }
            .navigationTitle("Converter")
        }
    }
}
