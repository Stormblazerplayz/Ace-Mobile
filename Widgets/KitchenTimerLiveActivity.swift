import ActivityKit
import SwiftUI
import WidgetKit

/// The cooking timer on the Lock Screen (and the Dynamic Island on iPhone).
struct KitchenTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KitchenTimerAttributes.self) { context in
            KitchenTimerRow(label: context.attributes.label, total: context.attributes.total, state: context.state, big: true)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.75))
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.done ? "bell.fill" : "timer")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.label)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    KitchenTimerClock(total: context.attributes.total, state: context.state)
                        .font(.title2.monospacedDigit().weight(.semibold))
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(.orange)
            } compactTrailing: {
                KitchenTimerClock(total: context.attributes.total, state: context.state)
                    .frame(maxWidth: 56)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.done ? "bell.fill" : "timer").foregroundStyle(.orange)
            }
        }
    }
}

private struct KitchenTimerRow: View {
    var label: String
    var total: Int
    var state: KitchenTimerAttributes.ContentState
    var big: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: state.done ? "bell.fill" : "timer")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.done ? "Time's up!" : "Ace timer")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            KitchenTimerClock(total: total, state: state)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(state.done ? .orange : .white)
        }
    }
}

private struct KitchenTimerClock: View {
    var total: Int
    var state: KitchenTimerAttributes.ContentState

    var body: some View {
        if state.done {
            Text("Done")
        } else {
            Text(timerInterval: state.end.addingTimeInterval(-Double(max(1, total)))...state.end, countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }
}
