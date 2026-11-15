// @title Pocket Money Tracker
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show ExpenseTrackerAppView() in ContentView's body.
// @keywords swiftui expense tracker, swiftui pocket money, swiftui pie chart, swiftui sectormark
// @about Records what you spend your pocket money on and shows it as a donut chart by category.

import Charts
import SwiftUI

struct Purchase: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let amount: Double
}

struct CategoryTotal: Identifiable {
    var id: String { name }
    let name: String
    let total: Double
}

struct ExpenseTrackerAppView: View {
    @State private var purchases = [
        Purchase(name: "Comic book", category: "Fun", amount: 6),
        Purchase(name: "Pizza slice", category: "Food", amount: 3.5),
        Purchase(name: "Game skin", category: "Games", amount: 10),
    ]
    @State private var newName = ""
    @State private var newAmount = 0.0
    @State private var newCategory = "Food"

    let categories = ["Food", "Fun", "Games", "Saving"]

    // Add up the money in each category for the chart
    var totals: [CategoryTotal] {
        categories.map { category in
            let sum = purchases.filter { $0.category == category }.reduce(0.0) { $0 + $1.amount }
            return CategoryTotal(name: category, total: sum)
        }
        .filter { $0.total > 0 }
    }

    var grandTotal: Double { purchases.reduce(0.0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Where did it go?") {
                    Chart(totals) { item in
                        SectorMark(angle: .value("Amount", item.total), innerRadius: .ratio(0.55), angularInset: 2)
                            .foregroundStyle(by: .value("Category", item.name))
                    }
                    .frame(height: 220)
                    Text("Total spent: \(grandTotal, format: .number.precision(.fractionLength(2)))")
                        .font(.headline)
                }
                Section("Add a purchase") {
                    TextField("What did you buy?", text: $newName)
                    TextField("How much?", value: $newAmount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $newCategory) {
                        ForEach(categories, id: \.self) { item in Text(item).tag(item) }
                    }
                    Button("Add") {
                        purchases.append(Purchase(name: newName, category: newCategory, amount: newAmount))
                        newName = ""
                        newAmount = 0
                    }
                    .disabled(newName.isEmpty || newAmount <= 0)
                }
                Section("History") {
                    ForEach(purchases) { item in
                        LabeledContent(item.name, value: item.amount, format: .number.precision(.fractionLength(2)))
                    }
                    .onDelete { offsets in purchases.remove(atOffsets: offsets) }
                }
            }
            .navigationTitle("Pocket Money")
        }
    }
}
