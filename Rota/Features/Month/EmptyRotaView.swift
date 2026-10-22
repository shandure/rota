import SwiftUI

/// Shown when the user has no patterns yet (§4.1).
struct EmptyRotaView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Spacing.s16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Set up your rota")
                .font(Typography.emptyHeadline)
            Text("Enter your pattern once. See every shift forever.")
                .font(Typography.emptyBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Create pattern", action: onCreate)
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.s8)
        }
        .padding(Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
