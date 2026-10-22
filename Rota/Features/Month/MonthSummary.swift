import SwiftUI
import RotaCore

/// "14 shifts · 8 nights · 16 off" for the visible month (§4.1).
struct MonthSummary: View {
    let summary: RotaEngine.Summary

    var body: some View {
        Text(text)
            .font(Typography.summary)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(spoken)
    }

    private var text: String {
        "\(summary.shifts) \(summary.shifts == 1 ? "shift" : "shifts") · \(summary.nights) \(summary.nights == 1 ? "night" : "nights") · \(summary.off) off"
    }

    private var spoken: String {
        "\(summary.shifts) \(summary.shifts == 1 ? "shift" : "shifts"), \(summary.nights) \(summary.nights == 1 ? "night" : "nights"), \(summary.off) off"
    }
}
