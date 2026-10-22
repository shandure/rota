import SwiftUI

/// Spacing scale (§6). Views reference these, never literals.
enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32

    /// Gap between month grid cells.
    static let gridGap = s4
    /// Horizontal screen padding.
    static let screen = s16
}
