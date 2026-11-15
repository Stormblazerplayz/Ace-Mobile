// @title Habit Tracker App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show HabitTrackerAppView() in ContentView's body.
// @keywords swiftui habit tracker, swiftui streak counter, swiftui daily goals, swiftui add sheet
// @about Track daily habits like reading or practicing piano, with a tap counter and a sheet to add new habits.

import SwiftUI

struct DailyHabit: Identifiable {
    let id = UUID()
    var name: String
    var symbol: String
    var count = 0
    var goal: Int
}

struct HabitTrackerAppView: View {
    @State private var habits = [
        DailyHabit(name: "Read", symbol: "book.fill", goal: 1),
        DailyHabit(name: "Drink water", symbol: "drop.fill", goal: 8),
        DailyHabit(name: "Code", symbol: "laptopcomputer", goal: 1),
    ]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach($habits) { $habit in
                    HStack {
                        Image(systemName: habit.symbol)
                            .frame(width: 30)
                            .foregroundStyle(habit.count >= habit.goal ? Color.green : Color.blue)
                        VStack(alignment: .leading) {
                            Text(habit.name).font(.headline)
                            ProgressView(value: Double(min(habit.count, habit.goal)), total: Double(habit.goal))
                        }
                        Text("\(habit.count)/\(habit.goal)").monospacedDigit()
                        Button {
                            habit.count += 1
                        } label: {
                            Image(systemName: "plus.circle.fill").font(.title)
                        }
                        .buttonStyle(.borderless)  // so only the button is tappable, not the row
                    }
                }
                .onDelete { offsets in habits.remove(atOffsets: offsets) }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New day") {
                        for index in habits.indices { habits[index].count = 0 }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") { showingAdd = true }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddHabitSheet { newHabit in habits.append(newHabit) }
            }
        }
    }
}

struct AddHabitSheet: View {
    var onSave: (DailyHabit) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var goal = 1
    @State private var symbol = "star.fill"

    let symbols = ["star.fill", "figure.run", "music.note", "bed.double.fill", "leaf.fill", "pencil"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit name", text: $name)
                Stepper("Times a day: \(goal)", value: $goal, in: 1...20)
                Picker("Icon", selection: $symbol) {
                    ForEach(symbols, id: \.self) { item in
                        Image(systemName: item).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(DailyHabit(name: name, symbol: symbol, goal: goal))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
