// @title Pickers
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show PickerDemoView() in ContentView's body.
// @keywords swiftui picker, swiftui segmented control, swiftui wheel picker, swiftui menu picker, swiftui enum picker
// @about Shows the picker styles (menu, segmented and wheel) and how to pick from an enum.

import SwiftUI

enum PizzaTopping: String, CaseIterable, Identifiable {
    case cheese, pepperoni, mushroom, pineapple
    var id: Self { self }
}

struct PickerDemoView: View {
    @State private var topping = PizzaTopping.cheese
    @State private var size = "Medium"
    @State private var slices = 8

    let sizes = ["Small", "Medium", "Large"]

    var body: some View {
        VStack(spacing: 24) {
            Text("A \(size.lowercased()) \(topping.rawValue) pizza cut into \(slices) slices")
                .font(.headline)
                .multilineTextAlignment(.center)

            // Menu style (the default in most places)
            Picker("Topping", selection: $topping) {
                ForEach(PizzaTopping.allCases) { item in
                    Text(item.rawValue.capitalized).tag(item)
                }
            }
            .pickerStyle(.menu)

            // Segmented style looks like a row of buttons
            Picker("Size", selection: $size) {
                ForEach(sizes, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)

            // Wheel style spins like a slot machine
            Picker("Slices", selection: $slices) {
                ForEach([4, 6, 8, 10, 12], id: \.self) { number in
                    Text("\(number) slices").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .padding()
    }
}
