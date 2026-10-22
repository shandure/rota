import Foundation

/// Built-in presets (§4.2). Just prefilled `cycle` arrays, not a separate type.
public enum Preset: String, CaseIterable, Identifiable, Sendable {
    case fourOnFourOff = "4 on 4 off"
    case twoDayTwoNightFourOff = "2D 2N 4 off"
    case monToFri = "Mon–Fri"
    case continental = "Continental (2-2-3)"
    case threeOnThreeOff = "3 on 3 off"
    case fiveTwoFiveThree = "5 on 2 off / 5 on 3 off"
    case custom = "Custom"

    public var id: String { rawValue }

    /// Chip title.
    public var name: String { rawValue }

    /// Identifier sent with `pattern_created` (§8). Never the user's pattern name.
    public var analyticsName: String {
        switch self {
        case .fourOnFourOff: return "4_on_4_off"
        case .twoDayTwoNightFourOff: return "2d_2n_4_off"
        case .monToFri: return "mon_fri"
        case .continental: return "continental"
        case .threeOnThreeOff: return "3_on_3_off"
        case .fiveTwoFiveThree: return "5_2_5_3"
        case .custom: return "custom"
        }
    }

    /// The cycle this preset fills in. `custom` is empty.
    public var cycle: [ShiftType] {
        switch self {
        case .fourOnFourOff:
            return days(4) + off(4)
        case .twoDayTwoNightFourOff:
            return days(2) + nights(2) + off(4)
        case .monToFri:
            // Start date should be a Monday; the preview makes that obvious.
            return days(5) + off(2)
        case .continental:
            // 14-day 2-2-3: on on, off off, on on on, off off, on on, off off off.
            return days(2) + off(2) + days(3) + off(2) + days(2) + off(3)
        case .threeOnThreeOff:
            return days(3) + off(3)
        case .fiveTwoFiveThree:
            return days(5) + off(2) + days(5) + off(3)
        case .custom:
            return []
        }
    }

    /// The preset whose cycle exactly matches `cycle`, if any.
    public static func matching(_ cycle: [ShiftType]) -> Preset? {
        allCases.first { $0 != .custom && $0.cycle == cycle }
    }

    private func days(_ n: Int) -> [ShiftType] { Array(repeating: .day, count: n) }
    private func nights(_ n: Int) -> [ShiftType] { Array(repeating: .night, count: n) }
    private func off(_ n: Int) -> [ShiftType] { Array(repeating: .off, count: n) }
}
