import SwiftUI
import RotaCore

/// Horizontal scrolling preset chips (§4.2 step 2). Tapping fills the cycle.
struct PresetChips: View {
    let selected: Preset?
    let onSelect: (Preset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s8) {
                ForEach(Preset.allCases) { preset in
                    Button(preset.name) { onSelect(preset) }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(preset == selected ? Color.accentColor : Color.secondary)
                        .font(.footnote)
                        .accessibilityLabel(preset == selected ? "\(preset.name), selected" : preset.name)
                        .accessibilityHint(preset == .custom ? "Clears the cycle" : "Fills the cycle")
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.vertical, Spacing.s4)
        }
    }
}
