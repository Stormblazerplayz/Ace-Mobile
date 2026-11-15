import SwiftUI
import UIKit

/// Step-by-step cooking: one big step at a time, Back and Next, and a timer button
/// on every step that waits (bake, chill, cool, rise...). The screen stays on while you cook.
struct CookingModeView: View {
    let recipe: RecipeCard
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var timers = KitchenTimers.shared
    @State private var index = 0
    @State private var showIngredients = false

    private var steps: [String] { recipe.steps.isEmpty ? ["No steps for this recipe."] : recipe.steps }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            KitchenTimersStrip()
                .padding(.horizontal, 20)
            TabView(selection: $index) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    stepPage(i, step).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: index)
            bottomBar
        }
        .background(AceTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sheet(isPresented: $showIngredients) {
            NavigationStack {
                List(recipe.ingredients, id: \.self) { Text($0) }
                    .navigationTitle("Ingredients")
                    .toolbar { Button("Done") { showIngredients = false } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close cooking mode")
            Spacer()
            VStack(spacing: 2) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Step \(index + 1) of \(steps.count)")
                    .font(.subheadline)
                    .foregroundStyle(AceTheme.muted)
            }
            Spacer()
            Button {
                showIngredients = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Ingredients")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .tint(AceTheme.ace)
    }

    private func stepPage(_ i: Int, _ step: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("\(i + 1)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(AceTheme.amber.opacity(0.25)))
                    .foregroundStyle(AceTheme.amber)
                Text(step)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(AceTheme.fg)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.6)
                if let found = StepTimer.find(in: step) {
                    StepTimerButton(recipe: recipe.name, found: found, big: true)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(28)
            .frame(maxWidth: .infinity)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button {
                index = max(0, index - 1)
                Haptics.shared.play(.tick)
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.bordered)
            .disabled(index == 0)
            if index < steps.count - 1 {
                Button {
                    index = min(steps.count - 1, index + 1)
                    Haptics.shared.play(.tick)
                    SoundFX.shared.play(.typeTick, gain: 0.5)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(TrailingIcon())
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    SoundFX.shared.play(.success)
                    Haptics.shared.play(.success)
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .tint(AceTheme.amber)
        .padding(20)
    }
}

private struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.title
            configuration.icon
        }
    }
}

/// "Start 30 min timer" for a recipe step. Shows the countdown once it's running.
struct StepTimerButton: View {
    let recipe: String
    let found: StepTimer.Found
    var big = false
    @ObservedObject private var timers = KitchenTimers.shared
    @State private var noAlerts = false

    private var label: String { StepTimer.label(recipe: recipe, activity: found.activity) }
    private var running: KitchenTimers.Running? { timers.timers.last { $0.label == label && !$0.done } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let running {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    Label("\(label): \(KitchenTimers.clock(Int(running.end.timeIntervalSince(ctx.date).rounded(.up))))", systemImage: "timer")
                        .font(big ? .title3.weight(.semibold).monospacedDigit() : .subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AceTheme.amber)
                }
            } else {
                Button {
                    Haptics.shared.play(.pop)
                    SoundFX.shared.play(.success, gain: 0.5)
                    Task { noAlerts = !(await timers.start(label: label, seconds: found.seconds)) }
                } label: {
                    Label("Start \(KitchenTimers.words(found.seconds)) timer", systemImage: "timer")
                        .font(big ? .title3.weight(.semibold) : .subheadline.weight(.semibold))
                        .padding(.horizontal, big ? 20 : 12)
                        .padding(.vertical, big ? 14 : 8)
                        .background(Capsule().fill(AceTheme.amber.opacity(0.22)))
                        .foregroundStyle(AceTheme.amber)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Starts a \(KitchenTimers.words(found.seconds)) timer for \(label.lowercased())")
            }
            if noAlerts {
                Text("Turn on notifications for Ace in the Settings app so timers ring when Ace is closed.")
                    .font(.caption)
                    .foregroundStyle(AceTheme.muted)
            }
        }
    }
}

/// Every running cooking timer, each with its own label and countdown.
struct KitchenTimersStrip: View {
    @ObservedObject private var timers = KitchenTimers.shared

    var body: some View {
        if !timers.timers.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(timers.timers) { t in
                        TimelineView(.periodic(from: .now, by: 1)) { ctx in
                            let left = Int(t.end.timeIntervalSince(ctx.date).rounded(.up))
                            HStack(spacing: 8) {
                                Image(systemName: t.done ? "bell.fill" : "timer")
                                    .symbolEffect(.pulse, isActive: t.done)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(t.label)
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(1)
                                    Text(t.done ? "Done!" : KitchenTimers.clock(left))
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                }
                                Menu {
                                    Button("Add 1 minute") { Task { await timers.addMinute(t.id) } }
                                    if t.done {
                                        Button("Dismiss") { timers.dismiss(t.id) }
                                    } else {
                                        Button("Stop timer", role: .destructive) { timers.cancel(t.id) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .frame(width: 28, height: 28)
                                }
                                .accessibilityLabel("Timer options for \(t.label)")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill((t.done ? AceTheme.good : AceTheme.amber).opacity(0.2)))
                            .foregroundStyle(t.done ? AceTheme.good : AceTheme.amber)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
}
