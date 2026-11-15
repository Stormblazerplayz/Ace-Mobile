// @title Notes App
// @category SwiftUI apps
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show NotesAppView() in ContentView's body.
// @keywords swiftui notes app, swiftui texteditor, swiftui navigation detail edit, swiftui saved notes
// @about A simple notes app with a list of notes, a page to edit each one, and automatic saving.

import Observation
import SwiftUI

struct NoteEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var text = ""
    var edited = Date.now

    // The first line of the note becomes its title
    var title: String {
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? ""
        return firstLine.isEmpty ? "New note" : firstLine
    }
}

// The store holds all notes and saves them to a file in the app's Documents folder
@Observable
final class NoteStore {
    var notes: [NoteEntry] = []

    let fileURL = URL.documentsDirectory.appending(path: "notes.json")

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([NoteEntry].self, from: data) {
            notes = saved
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            try? data.write(to: fileURL)
        }
    }
}

struct NotesAppView: View {
    @State private var store = NoteStore()

    var body: some View {
        NavigationStack {
            List {
                ForEach($store.notes) { $note in
                    NavigationLink {
                        NoteEditorView(note: $note)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(note.title).font(.headline).lineLimit(1)
                            Text(note.edited, style: .relative).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in store.notes.remove(atOffsets: offsets) }
            }
            .navigationTitle("Notes")
            .toolbar {
                Button("New note", systemImage: "square.and.pencil") {
                    store.notes.insert(NoteEntry(), at: 0)
                }
            }
            // Save to the file whenever any note changes
            .onChange(of: store.notes) { store.save() }
            .overlay {
                if store.notes.isEmpty {
                    ContentUnavailableView("No notes", systemImage: "note.text", description: Text("Tap the pencil to write one."))
                }
            }
        }
    }
}

struct NoteEditorView: View {
    @Binding var note: NoteEntry

    var body: some View {
        TextEditor(text: $note.text)
            .padding()
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: note.text) { note.edited = .now }
    }
}
