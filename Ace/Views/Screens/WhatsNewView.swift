import SwiftUI

/// Settings > What's new: every build's changes, newest first.
struct WhatsNewView: View {
    @EnvironmentObject var core: AceCore
    @Environment(\.dismiss) private var dismiss
    private let releases = WhatsNew.load()

    var body: some View {
        List {
            if releases.isEmpty {
                Text("No notes for this build.")
                    .foregroundStyle(AceTheme.muted)
            }
            ForEach(releases, id: \.build) { r in
                Section {
                    WhatsNewList(items: r.items)
                        .padding(.vertical, 4)
                } header: {
                    Text(r.build == WhatsNew.release(forBuild: WhatsNew.currentBuild, in: releases)?.build
                         ? "Build \(r.build) (this one)" : "Build \(r.build)")
                }
            }
            if !releases.isEmpty {
                Section {
                    Button("Show in the chat") {
                        core.showWhatsNew(force: true)
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AceTheme.background.ignoresSafeArea())
        .navigationTitle("What's new")
        .navigationBarTitleDisplayMode(.inline)
    }
}
