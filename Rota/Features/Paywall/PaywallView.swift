import SwiftUI
import UIKit
import RotaCore

/// What opened the paywall; sent with `paywall_shown` in Step 9.
enum PaywallTrigger: String, Identifiable {
    case secondPattern = "second_pattern"
    case calendar, widget, settings

    var id: String { rawValue }
}

/// Full-screen paywall (§4.5). Always dismissible; no countdowns, no crossed-out prices.
struct PaywallView: View {
    let trigger: PaywallTrigger

    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    @State private var message: String?

    private let benefits: [(symbol: String, text: String)] = [
        ("rectangle.stack", "Multiple patterns"),
        ("calendar", "Shifts in your Calendar app"),
        ("square.grid.2x2", "Home screen widget"),
        ("checkmark.seal", "One payment, yours forever"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .padding(Spacing.s8)
                }
                .accessibilityLabel("Close")
                Spacer()
            }

            Spacer()

            Text("Unlock everything")
                .font(.title.weight(.semibold))

            VStack(alignment: .leading, spacing: Spacing.s16) {
                ForEach(benefits, id: \.text) { benefit in
                    Label(benefit.text, systemImage: benefit.symbol)
                        .font(.body)
                }
            }

            Spacer()

            VStack(spacing: Spacing.s12) {
                Button {
                    Task { await buy() }
                } label: {
                    Text("Unlock for \(purchases.priceText)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isWorking)

                Button("Restore purchases") {
                    Task { await restore() }
                }
                .font(.footnote)
                .disabled(isWorking)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(Spacing.screen)
        .task { await purchases.load() }
        .onChange(of: purchases.isUnlocked) { _, unlocked in
            if unlocked { succeed() }
        }
    }

    // MARK: Actions

    private func buy() async {
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await purchases.purchase() {
            case .purchased: break                      // onChange(isUnlocked) dismisses
            case .cancelled: break
            case .pending: message = "Waiting for approval. You can keep using the app."
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await purchases.restore()
            if !purchases.isUnlocked { message = "No previous purchase found." }
        } catch {
            message = error.localizedDescription
        }
    }

    private func succeed() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
