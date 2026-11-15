// @title To-Do List App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show TodoAppView() in ContentView's body.
// @keywords swiftui todo app, swiftui checklist, swiftui save list, swiftui codable appstorage
// @about A to-do list where you add, tick off and delete tasks, and they are saved so they are still there next time.

import SwiftUI

// Codable lets us turn tasks into JSON text to save them
struct TodoTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done = false
}

struct TodoAppView: View {
    @State private var tasks: [TodoTask] = []
    @State private var newTitle = ""
    @AppStorage("todoAppSavedTasks") private var savedJSON = ""

    var remaining: Int { tasks.filter { !$0.done }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("What do you need to do?", text: $newTitle)
                            .onSubmit(addTask)
                        Button("Add", action: addTask)
                            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section("\(remaining) left to do") {
                    ForEach($tasks) { $task in
                        HStack {
                            Button {
                                task.done.toggle()
                            } label: {
                                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(task.done ? Color.green : Color.gray)
                            }
                            .buttonStyle(.plain)
                            Text(task.title)
                                .strikethrough(task.done)
                                .foregroundStyle(task.done ? Color.secondary : Color.primary)
                        }
                    }
                    .onDelete { offsets in tasks.remove(atOffsets: offsets) }
                }
            }
            .navigationTitle("To-Do")
            .toolbar {
                Button("Clear done") { tasks.removeAll { $0.done } }
            }
            .onAppear(perform: load)
            // Save every time the list changes
            .onChange(of: tasks) { save() }
        }
    }

    func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        tasks.append(TodoTask(title: title))
        newTitle = ""
    }

    func save() {
        if let data = try? JSONEncoder().encode(tasks), let text = String(data: data, encoding: .utf8) {
            savedJSON = text
        }
    }

    func load() {
        guard let data = savedJSON.data(using: .utf8) else { return }
        if let saved = try? JSONDecoder().decode([TodoTask].self, from: data) {
            tasks = saved
        }
    }
}
