//
//  IceBarPlacement27.swift
//  Ice
//

import CoreGraphics
import Foundation

/// Where the Ice Bar's left edge goes along the screen, so that it opens right under Ice's icon
/// and never leaves the screen.
///
/// The bar's right edge stands under the icon's right edge: the hidden items are the ones left of
/// the icon, so the bar grows to the left of it, away from Control Center and the clock. When the
/// icon is not known, or is not on this display, the bar's right edge stands at the screen's
/// right edge instead. Either way the bar is whole on the screen.
enum IceBarPlacement27 {
    /// The x of the panel's left edge, in the same space as the arguments.
    ///
    /// - Parameters:
    ///   - panelWidth: The width of the panel, margin included.
    ///   - margin: The transparent margin the panel keeps around the bar. The drawn bar's edge,
    ///     not the panel's, is what lines up with the icon.
    ///   - iconFrame: Ice's own icon on the bar, or `nil` if it was not read.
    ///   - screenMinX: The left edge of the screen the bar opens on.
    ///   - screenMaxX: The right edge of that screen.
    static func originX(
        panelWidth: CGFloat,
        margin: CGFloat,
        iconFrame: CGRect?,
        screenMinX: CGFloat,
        screenMaxX: CGFloat
    ) -> CGFloat {
        let rightmost = screenMaxX - panelWidth
        // A panel as wide as the screen, or wider, can only start at the left edge.
        guard rightmost > screenMinX else {
            return screenMinX
        }
        guard
            let iconFrame,
            iconFrame.width > 0,
            // An icon on another display, or at the origin where macOS 27 parks an item it does
            // not draw, is no place to stand under.
            iconFrame.maxX > screenMinX,
            iconFrame.minX < screenMaxX
        else {
            return rightmost
        }
        return min(max(iconFrame.maxX + margin - panelWidth, screenMinX), rightmost)
    }
}
