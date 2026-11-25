import SwiftUI

/// Every time Ace woke up and looked around, newest first.
struct ChecksView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var core: AceCore
    @EnvironmentObject var settings: SettingsStore
    /// Turns true when Checks opens, so the cards spring in one after another.
    @State private var shown = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        OrbStill(mood: core.latestCheck?.needsAttention == true ? .alert : .happy)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wakeText)
                                .foregroundStyle(AceTheme.fg)
                            Text("Ace wakes up every 15 to 30 minutes while it's open, looks around, and checks your iPad.")
                                .font(.caption)
                                .foregroundStyle(AceTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .aceCard()
                    .bounceReveal(shown, order: 0)

                    Button {
                        dismiss()
                        Task { await core.wakeUp(reason: .manual) }
                    } label: {
                        Label("Check now", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(core.busy)
                    .bounceReveal(shown, order: 1)

                    if core.checkHistory.isEmpty {
                        Text("No checks yet.")
                            .foregroundStyle(AceTheme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    }
                    ForEach(Array(core.checkHistory.enumerated()), id: \.element.id) { i, report in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(report.summary)
                                .font(.subheadline)
                                .foregroundStyle(AceTheme.fg)
                            CheckReportView(report: report)
                        }
                        .bounceReveal(shown, order: i + 2)
                    }
                }
                .padding(16)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .background(AceTheme.background.ignoresSafeArea())
            .navigationTitle("Checks")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { shown = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AceTheme.ace)
    }

    private var wakeText: String {
        guard settings.wakeChecks else { return "Wake-up checks are off." }
        guard let next = core.nextWake else { return "Next check soon." }
        let time: String = next.formatted(date: .omitted, time: .shortened)
        return "Next check around " + time + "."
    }
}
