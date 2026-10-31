import SwiftUI
import RotaCore

/// Adds a user-defined shift type: a label (max 6 chars) and one of the four custom colours (§6).
/// Times default to 09:00–17:00 and can be changed in the builder's Shift times section.
struct CustomShiftSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (ShiftType) -> Void

    @State private var label = ""
    @State private var colorHex = ShiftType.customPalette[0]
    @FocusState private var labelFocused: Bool

    private var trimmed: String { label.trimmingCharacters(in: .whitespaces) }
    /// HOL and SICK are reserved for the built-in absences.
    private var isReserved: Bool {
        [ShiftType.holiday.label, ShiftType.sick.label].contains(trimmed.uppercased())
    }
    private var canAdd: Bool { !trimmed.isEmpty && !isReserved }

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    TextField("Long", text: $label)
                        .focused($labelFocused)
                        .textInputAutocapitalization(.words)
                        .onChange(of: label) { _, value in
                            if value.count > Limits.maxCustomLabelLength {
                                label = String(value.prefix(Limits.maxCustomLabelLength))
                            }
                        }
                    if isReserved {
                        Text("That label is used for \(trimmed.uppercased() == ShiftType.holiday.label ? "Holiday" : "Sick").")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Colour") {
                    HStack(spacing: Spacing.s16) {
                        ForEach(ShiftType.customPalette, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: Spacing.s32, height: Spacing.s32)
                                    .overlay {
                                        if hex == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(hex == "#FFD43B" ? Color.black : Color.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(hex == colorHex ? "Colour \(hex), selected" : "Colour \(hex)")
                        }
                    }
                    .padding(.vertical, Spacing.s4)
                }
            }
            .navigationTitle("Custom shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(ShiftType(kind: .custom,
                                        label: trimmed,
                                        colorHex: colorHex,
                                        startTime: ShiftType.time(9),
                                        endTime: ShiftType.time(17)))
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
            .onAppear { labelFocused = true }
        }
        .presentationDetents([.medium])
    }
}
