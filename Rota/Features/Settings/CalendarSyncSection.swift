import SwiftUI

/// "Add shifts to Calendar" toggle (§4.4), gated by the unlock.
struct CalendarSyncSection: View {
    let isUnlocked: Bool
    let onLocked: () -> Void

    @Environment(CalendarSync.self) private var sync

    var body: some View {
        Section {
            Toggle("Add shifts to Calendar", isOn: binding)
                .disabled(sync.isWorking)
            if let message = sync.lastError {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Shifts appear in the Calendar app and anywhere else it syncs to.")
        }
    }

    private var binding: Binding<Bool> {
        Binding {
            sync.isEnabled && isUnlocked
        } set: { on in
            guard isUnlocked else {
                if on { onLocked() }
                return
            }
            if on {
                Task { _ = await sync.enable() }
            } else {
                sync.disable()
            }
        }
    }
}
