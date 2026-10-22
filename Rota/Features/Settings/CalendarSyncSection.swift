import SwiftUI

/// "Add shifts to Calendar" toggle (§4.4). The export itself is built in Step 8; until then the
/// toggle only reflects the stored preference and the paywall gate.
struct CalendarSyncSection: View {
    let isUnlocked: Bool
    let onLocked: () -> Void

    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled = false

    var body: some View {
        Section {
            Toggle("Add shifts to Calendar", isOn: binding)
        } header: {
            Text("Calendar")
        } footer: {
            Text("Shifts appear in the Calendar app and anywhere else it syncs to.")
        }
    }

    private var binding: Binding<Bool> {
        Binding {
            calendarSyncEnabled && isUnlocked
        } set: { on in
            guard isUnlocked else {
                if on { onLocked() }
                return
            }
            calendarSyncEnabled = on
            // Step 8: request EventKit access and write or delete the calendar here.
        }
    }
}
