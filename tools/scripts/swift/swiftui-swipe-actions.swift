// @title Swipe, Delete and Move Rows
// @category SwiftUI basics
// @kind SwiftUI view
// @where Add a new Swift file to your iOS 17 app in Xcode or Swift Playgrounds, paste this in, then show SwipeActionsView() in ContentView's body.
// @keywords swiftui swipe actions, swiftui delete rows, swiftui onmove, swiftui editbutton, swiftui reorder list
// @about A chore list where you swipe rows to delete or pin them and use Edit to reorder.

import SwiftUI

struct ChoreItem: Identifiable {
    let id = UUID()
    var title: String
    var pinned = false
}

struct SwipeActionsView: View {
    @State private var chores = [
        ChoreItem(title: "Feed the cat"),
        ChoreItem(title: "Take out trash"),
        ChoreItem(title: "Homework"),
        ChoreItem(title: "Practice coding"),
        ChoreItem(title: "Tidy room"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach($chores) { $chore in
                    HStack {
                        if chore.pinned {
                            Image(systemName: "pin.fill").foregroundStyle(.orange)
                        }
                        Text(chore.title)
                    }
                    // Swipe left on a row to see these buttons
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            chores.removeAll { $0.id == chore.id }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    // Swipe right on a row to see this one
                    .swipeActions(edge: .leading) {
                        Button {
                            chore.pinned.toggle()
                        } label: {
                            Label("Pin", systemImage: "pin")
                        }
                        .tint(.orange)
                    }
                }
                .onDelete { offsets in chores.remove(atOffsets: offsets) }
                .onMove { from, to in chores.move(fromOffsets: from, toOffset: to) }
            }
            .navigationTitle("Chores")
            .toolbar {
                EditButton()  // turns on drag handles for moving rows
            }
        }
    }
}
