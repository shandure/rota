import SwiftUI

/// Three steps to add the widget on iOS (§4.4). The screenshot is added with the widget in Step 7.
struct WidgetExplainerView: View {
    private let steps = [
        "Touch and hold an empty area of your Home Screen until the apps jiggle.",
        "Tap Edit, then Add Widget (or the + in the top corner on older iOS).",
        "Search for Rota, choose a size, and tap Add Widget.",
    ]

    var body: some View {
        List {
            Section {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: Spacing.s12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: Spacing.s24)
                        Text(text)
                    }
                    .padding(.vertical, Spacing.s4)
                    .accessibilityElement(children: .combine)
                }
            }
            Section {
                WidgetPreviewImage()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s8)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Add the widget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Placeholder until the widget exists; Step 7 replaces this with a real screenshot asset.
private struct WidgetPreviewImage: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.card)
            .fill(Color.secondary.opacity(0.15))
            .frame(height: 160)
            .overlay {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Widget preview")
    }
}
