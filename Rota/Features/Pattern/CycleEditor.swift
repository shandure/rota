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
/// Reorder: long-press a cell and drag it onto another cell (or the end slot).
/// Remove: tap a cell to show its "x". (The spec says long press, but on iOS a long press is
/// what starts the drag, so tap reveals the "x" instead.)
struct CycleEditor: View {
    @Binding var cells: [CycleCell]
    let onAddCustom: () -> Void

    @State private var removableID: UUID?

    private static let cellSize: CGFloat = 44
    private let quickTypes: [ShiftType] = [.day, .night, .late, .early, .off]

    private var isFull: Bool { cells.count >= Limits.maxCycleLength }

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
            .onTapGesture { removableID = nil }

            HStack(spacing: Spacing.s8) {
                ForEach(quickTypes, id: \.label) { shift in
                    Button {
                        append(shift)
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
                    .accessibilityLabel("Add \(shift.spokenName)")
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
                .accessibilityLabel("Add custom shift type")
            }
            .disabled(isFull)

            Text(isFull ? "Cycle: \(cells.count) days (maximum)" : "Cycle: \(cells.count) \(cells.count == 1 ? "day" : "days")")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Cells

    private func cellView(_ cell: CycleCell, index: Int) -> some View {
        let shift = cell.shift
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
        .overlay(alignment: .topTrailing) {
            if removableID == cell.id {
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
            removableID = removableID == cell.id ? nil : cell.id
        }
        .draggable(cell)
        .dropDestination(for: CycleCell.self) { dropped, _ in
            move(dropped, toIndex: index)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(shift.spokenName), position \(index + 1) of \(cells.count)")
        .accessibilityHint("Tap to show remove. Drag to reorder.")
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

    // MARK: Mutations

    private func append(_ shift: ShiftType) {
        guard !isFull else { return }
        cells.append(CycleCell(shift: shift))
        removableID = nil
    }

    private func remove(_ cell: CycleCell) {
        cells.removeAll { $0.id == cell.id }
        removableID = nil
    }

    /// Moves the dragged cell so it lands at `toIndex` in the current ordering.
    private func move(_ dropped: [CycleCell], toIndex: Int) -> Bool {
        guard let item = dropped.first, let from = cells.firstIndex(where: { $0.id == item.id }) else { return false }
        let destination = toIndex > from ? toIndex + 1 : toIndex
        cells.move(fromOffsets: IndexSet(integer: from), toOffset: min(destination, cells.count))
        removableID = nil
        return true
    }
}
