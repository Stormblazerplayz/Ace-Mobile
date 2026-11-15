// @title Alerts and Confirmation Dialogs
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show AlertsDemoView() in ContentView's body.
// @keywords swiftui alert, swiftui confirmationdialog, swiftui action sheet, swiftui alert textfield, swiftui popup
// @about Shows a simple alert, an alert with a text box, and a confirmation dialog with several choices.

import SwiftUI

struct AlertsDemoView: View {
    @State private var showInfo = false
    @State private var showRename = false
    @State private var showDelete = false
    @State private var petName = "Rex"
    @State private var draftName = ""
    @State private var status = "Nothing happened yet."

    var body: some View {
        VStack(spacing: 18) {
            Text("Pet: \(petName)").font(.title)
            Text(status).foregroundStyle(.secondary)

            Button("Show info alert") { showInfo = true }
            Button("Rename pet") {
                draftName = petName
                showRename = true
            }
            Button("Delete save file", role: .destructive) { showDelete = true }
        }
        .buttonStyle(.bordered)
        .padding()
        // A simple alert with one button
        .alert("Did you know?", isPresented: $showInfo) {
            Button("Cool!", role: .cancel) {}
        } message: {
            Text("Alerts are great for short, important messages.")
        }
        // An alert with a text field inside (iOS 16+)
        .alert("New name", isPresented: $showRename) {
            TextField("Name", text: $draftName)
            Button("Save") {
                if !draftName.isEmpty {
                    petName = draftName
                    status = "Renamed to \(draftName)."
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        // A confirmation dialog slides up with choices
        .confirmationDialog("Delete your save?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete forever", role: .destructive) { status = "Save deleted (pretend)." }
            Button("Make a backup first") { status = "Backup made, save kept." }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}
