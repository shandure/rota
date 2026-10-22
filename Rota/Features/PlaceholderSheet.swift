import SwiftUI

/// Stand-in for a screen from a later build step. Removed once that step lands.
struct PlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let detail: String

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.s8) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary)
            }
            .padding(Spacing.screen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
