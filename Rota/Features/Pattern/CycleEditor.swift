import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers
import RotaCore

/// One cell of the cycle being edited. Has identity so drag-to-reorder is stable.
struct CycleCell: Identifiable, Codable, Hashable, Transferable {
    var id = UUID()
    var shift: ShiftType

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

/// The reorderable cycle row, the shift-type buttons and the "Cycle: 8 days" line (§4.2 step 3).
///
/// - Tap a cell to select it (ring + "x"). The shift buttons then replace that cell.
/// - With nothing selected, the shift buttons append to the end of the cycle.
/// - "x" on the selected cell removes it. Long-press and drag a cell to reorder.
struct CycleEditor: View {
    @Binding var cells: [CycleCell]
    /// The selected cell, if any. Owned by the builder so the custom-shift sheet can replace it too.
    @Binding var selectedID: UUID?
    let onAddCustom: () -> Void

    private static let cellSize: CGFloat = 44
    private let quickTypes: [ShiftType] = [.day, .night, .late, .early, .off]

    private var isFull: Bool { cells.count >= Limits.maxCycleLength }
    private var selectedIndex: Int? { cells.firstIndex { $0.id == selectedID } }
    /// Buttons are usable when they can replace the selection or there is room to append.
    private var canApply: Bool { selectedIndex != nil || !isFull }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s4) {
                    ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                        cellView(cell, index: index)
                    }
                    endDropSlot
                    if cells.isEmpty {
                        Text("Tap a shift below to add it")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.s8)
                .padding(.trailing, Spacing.s8)
            }
            .onTapGesture { selectedID = nil }

            HStack(spacing: Spacing.s8) {
                ForEach(quickTypes, id: \.label) { shift in
                    Button {
                        apply(shift)
                    } label: {
                        Text(shift.label)
                            .font(Typography.cellLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s8)
                            .background(Palette.fill(for: shift), in: RoundedRectangle(cornerRadius: Radius.cell))
                            .overlay {
                                if shift.isOff {
                                    RoundedRectangle(cornerRadius: Radius.cell).strokeBorder(Color.secondary)
                                }
                            }
                            .foregroundStyle(shift.isOff ? Color.secondary : Palette.label(for: shift))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(buttonLabel(for: shift))
                }
                Button(action: onAddCustom) {
                    Image(systemName: "plus")
                        .font(Typography.cellLabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s8)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.cell).strokeBorder(Color.secondary)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectedIndex == nil ? "Add custom shift type" : "Replace with a custom shift type")
            }
            .disabled(!canApply)

            Text(statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Cells

    private func cellView(_ cell: CycleCell, index: Int) -> some View {
        let shift = cell.shift
        let isSelected = selectedID == cell.id
        return ZStack {
            RoundedRectangle(cornerRadius: Radius.cell)
                .fill(Palette.fill(for: shift))
            if shift.isOff {
                RoundedRectangle(cornerRadius: Radius.cell)
                    .strokeBorder(Color.secondary)
            }
            Text(shift.label)
                .font(Typography.cellLabel)
                .foregroundStyle(shift.isOff ? Color.secondary : Palette.label(for: shift))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, Spacing.s4)
        }
        .frame(width: Self.cellSize, height: Self.cellSize)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.cell)
                    .strokeBorder(Color.primary, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Button {
                    remove(cell)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .offset(x: Spacing.s8, y: -Spacing.s8)
                .accessibilityLabel("Remove \(shift.spokenName) at position \(index + 1)")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedID = isSelected ? nil : cell.id
        }
        .draggable(cell)
        .dropDestination(for: CycleCell.self) { dropped, _ in
            move(dropped, toIndex: index)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(shift.spokenName), position \(index + 1) of \(cells.count)\(isSelected ? ", selected" : "")")
        .accessibilityHint(isSelected ? "Choose a shift below to replace it, or remove it." : "Tap to select. Drag to reorder.")
    }

    /// Drop target after the last cell.
    private var endDropSlot: some View {
        RoundedRectangle(cornerRadius: Radius.cell)
            .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
            .frame(width: cells.isEmpty ? 0 : Spacing.s16, height: Self.cellSize)
            .opacity(cells.isEmpty ? 0 : 1)
            .dropDestination(for: CycleCell.self) { dropped, _ in
                move(dropped, toIndex: cells.count)
            }
            .accessibilityHidden(true)
    }

    // MARK: Text

    private var statusText: String {
        let count = "Cycle: \(cells.count) \(cells.count == 1 ? "day" : "days")"
        if let index = selectedIndex {
            return "\(count) · day \(index + 1) selected, tap a shift to replace it"
        }
        if isFull { return "\(count) (maximum)" }
        return cells.isEmpty ? count : "\(count) · tap a day to change it"
    }

    private func buttonLabel(for shift: ShiftType) -> String {
        if let index = selectedIndex {
            return "Replace day \(index + 1) with \(shift.spokenName)"
        }
        return "Add \(shift.spokenName)"
    }

    // MARK: Mutations

    /// Replaces the selected cell, or appends when nothing is selected.
    private func apply(_ shift: ShiftType) {
        if let index = selectedIndex {
            cells[index].shift = shift
        } else if !isFull {
            cells.append(CycleCell(shift: shift))
        }
    }

    private func remove(_ cell: CycleCell) {
        cells.removeAll { $0.id == cell.id }
        selectedID = nil
    }

    /// Moves the dragged cell so it lands at `toIndex` in the current ordering.
    private func move(_ dropped: [CycleCell], toIndex: Int) -> Bool {
        guard let item = dropped.first, let from = cells.firstIndex(where: { $0.id == item.id }) else { return false }
        let destination = toIndex > from ? toIndex + 1 : toIndex
        cells.move(fromOffsets: IndexSet(integer: from), toOffset: min(destination, cells.count))
        selectedID = nil
        return true
    }
}
