import SwiftUI

/// The sass slider in Settings: Mild, Spicy or Extra. Shown when Sassy mode is on.
struct SassSlider: View {
    @Binding var level: String

    private var current: SassLevel { SassLevel(setting: level) }

    private var value: Binding<Double> {
        Binding(
            get: { Double(SassLevel(setting: level).rawValue) },
            set: { new in
                let picked = SassLevel(rawValue: Int(new.rounded())) ?? .extra
                if picked.setting != level { level = picked.setting }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Slider(value: value, in: 1...3, step: 1)
                .accessibilityLabel("Sass level")
                .accessibilityValue(current.title)
            stops
        }
        .padding(.vertical, 4)
    }

    private var header: some View {
        HStack {
            Text("Sass level")
            Spacer()
            Text(current.title)
                .fontWeight(.semibold)
                .foregroundStyle(AceTheme.muted)
        }
    }

    private var stops: some View {
        HStack {
            Text("Mild")
            Spacer()
            Text("Spicy")
            Spacer()
            Text("Extra")
        }
        .font(.caption)
        .foregroundStyle(AceTheme.muted)
        .accessibilityHidden(true)
    }
}
