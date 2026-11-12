//
//  OwnIconSlot27.swift
//  Ice
//

import CoreGraphics
import Foundation

/// Where Ice's own icon stands among the items the layout window lists under "Visible".
///
/// macOS 27 gives Ice's icon no photograph — taking one broke the bar (see
/// `ItemImageStore27.isPhotographable`) — so the layout window draws it from the icon the user
/// chose, and needs a place for it.
///
/// The place is where the icon is on the bar. macOS keeps an application's own items to the left
/// of the ones it draws itself at the right-hand end, so Ice's icon, which asks for the last
/// place there is, stands before Control Center and the clock, and after the items that sit left
/// of them (measured on macOS 27.2, 2026-11-12: Wi-Fi, Sound, Text Input and the user switcher
/// all stood to its left). Listing it at the far right of the window was a place it never has on
/// the bar, and listing it before the first item macOS draws itself put it at the far left as
/// soon as the leftmost item was one of those, where a long list scrolls it out of view.
///
/// When the icon's place on the bar is not known, it is listed last.
enum OwnIconSlot27 {
    /// The items with the icon among them.
    ///
    /// An icon that is already listed is moved, not listed twice.
    ///
    /// - Parameters:
    ///   - ownIcon: Ice's own icon.
    ///   - items: The items the window lists, in the order they stand on the bar.
    ///   - ownMinX: The left edge of the icon on the bar, or `nil` if it was not read.
    ///   - minX: The left edge of an item on the bar.
    static func placing<Item: Equatable>(
        _ ownIcon: Item,
        in items: [Item],
        ownMinX: CGFloat?,
        minX: (Item) -> CGFloat
    ) -> [Item] {
        var result = items.filter { $0 != ownIcon }
        guard let ownMinX else {
            return result + [ownIcon]
        }
        result.insert(ownIcon, at: result.firstIndex { minX($0) > ownMinX } ?? result.count)
        return result
    }
}
