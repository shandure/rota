import SwiftUI

/// Type styles (§6). System font, no rounded design.
enum Typography {
    static let monthTitle: Font = .largeTitle
    static let weekday: Font = .caption
    static let dateNumber: Font = .caption
    static let cellLabel: Font = .caption2.weight(.semibold)
    static let detailPill: Font = .title2.weight(.semibold)
    static let summary: Font = .footnote
    static let emptyHeadline: Font = .headline
    static let emptyBody: Font = .body

    /// Largest Dynamic Type size the month grid is allowed to grow to.
    static let gridMaxDynamicType: DynamicTypeSize = .xxLarge
}
