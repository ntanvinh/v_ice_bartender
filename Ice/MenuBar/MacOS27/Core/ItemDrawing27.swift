//
//  ItemDrawing27.swift
//  Ice
//

import CoreGraphics

/// Decides whether an item reported through Accessibility is drawn on the active menu bar.
///
/// Accessibility keeps a concealed application's items at the frames where they were last
/// drawn, which can be on the other display (measured on macOS 27.0). Such items still
/// belong in Ice's sections, so they are kept but not treated as drawn.
enum ItemDrawing27 {
    /// - Parameter notchXRange: The span the active display's notch covers, or `nil` where it
    ///   has none. See `NotchGeometry27`.
    static func isDrawn(
        itemFrame: CGRect,
        activeDisplayBounds: CGRect?,
        notchXRange: ClosedRange<CGFloat>? = nil,
        chevronFrame: CGRect?
    ) -> Bool {
        if let activeDisplayBounds, !activeDisplayBounds.intersects(itemFrame) {
            return false
        }
        // An item the bar has laid out across the notch is drawn on nothing, and a click where
        // it says it is lands on nothing.
        if let notchXRange, itemFrame.minX < notchXRange.upperBound, itemFrame.maxX > notchXRange.lowerBound {
            return false
        }
        return !OverflowDetection27.isInOverflow(itemFrame: itemFrame, chevronFrame: chevronFrame)
    }

    /// Whether the menu bar's own window lists an item at the frame its application reports.
    ///
    /// An application reports its items' frames through Accessibility whether or not
    /// MenuBarAgent draws them. Under assessment mode MenuBarAgent drops the items of an
    /// application signed locally and never says so: the frame stays, and it reads as an item
    /// drawn in the middle of a bar that has nothing there (measured on macOS 27.2, 2026-11-12:
    /// Ice's camera indicator stood about 170 points from the next icon, beside VOpenKey AI's
    /// phantom frame). The bar's window lists exactly what it draws, so a frame it does not list
    /// is not on the bar.
    ///
    /// - Parameters:
    ///   - itemFrame: The frame the item's application reports.
    ///   - barFrames: The frames of every entry the bar's window lists, system items included.
    ///     Empty when the bar could not be read, which rules nothing out.
    ///   - tolerance: How far the left edge and the width may differ, in points. The two
    ///     frames come from different Accessibility elements and are not exactly alike
    ///     vertically, which is why only the horizontal extent is compared.
    static func isListed(itemFrame: CGRect, amongBarFrames barFrames: [CGRect], tolerance: CGFloat = 2) -> Bool {
        guard !barFrames.isEmpty else {
            return true
        }
        return barFrames.contains { frame in
            abs(frame.minX - itemFrame.minX) <= tolerance && abs(frame.width - itemFrame.width) <= tolerance
        }
    }
}
