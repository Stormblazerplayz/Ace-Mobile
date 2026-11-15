// @title Tip Calculator App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TipCalculatorAppView() in ContentView's body.
// @keywords swiftui tip calculator, swiftui split bill, swiftui currency format, swiftui decimal keyboard
// @about Works out the tip, the total and how much each person pays when you split a restaurant bill.

import SwiftUI

struct TipCalculatorAppView: View {
    @State private var bill = 0.0
    @State private var tipPercent = 15
    @State private var people = 2
    @FocusState private var billFocused: Bool

    let tipChoices = [0, 10, 15, 18, 20, 25]
    // Use the money type for wherever the iPad is set up (dollars, euros, pounds...)
    let currency = Locale.current.currency?.identifier ?? "USD"

    var tipAmount: Double { bill * Double(tipPercent) / 100 }
    var total: Double { bill + tipAmount }
    var perPerson: Double { total / Double(people) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bill") {
                    TextField("Amount", value: $bill, format: .currency(code: currency))
                        .keyboardType(.decimalPad)
                        .focused($billFocused)
                    Stepper("Split between \(people) people", value: $people, in: 1...20)
                }
                Section("Tip") {
                    Picker("Tip", selection: $tipPercent) {
                        ForEach(tipChoices, id: \.self) { choice in
                            Text("\(choice)%").tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Results") {
                    LabeledContent("Tip", value: tipAmount, format: .currency(code: currency))
                    LabeledContent("Total", value: total, format: .currency(code: currency))
                    LabeledContent("Each person pays", value: perPerson, format: .currency(code: currency))
                        .font(.headline)
                        .foregroundStyle(tipPercent == 0 ? Color.red : Color.primary)
                }
            }
            .navigationTitle("Tip Calculator")
            .toolbar {
                // A Done button on top of the keyboard to hide it
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { billFocused = false }
                }
            }
        }
    }
}
