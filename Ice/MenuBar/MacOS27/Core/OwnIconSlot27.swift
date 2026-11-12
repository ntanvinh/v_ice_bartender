//
//  OwnIconSlot27.swift
//  Ice
//

import Foundation

/// Where Ice's own icon stands among the items the layout window lists under "Visible".
///
/// macOS 27 gives Ice's icon no photograph — taking one broke the bar (see
/// `ItemImageStore27.isPhotographable`) — so the layout window draws it from the icon the user
/// chose, and needs a place for it.
///
/// That place is the far right, always. The layout bar is pinned to its right edge and scrolls
/// when the items outgrow it (see `LayoutBarScrollView`), so what stands at the left end is what
/// scrolls out of sight; the icon was once put before the first item macOS draws itself, which
/// is the first item of the list as soon as the leftmost one is a system item (measured on
/// macOS 27.2, 2026-11-12), and so it stood at the far left and left the view with a long list.
enum OwnIconSlot27 {
    /// The items with the icon as the last of them.
    ///
    /// An icon that is already listed is moved there, not listed twice.
    ///
    /// - Parameters:
    ///   - ownIcon: Ice's own icon.
    ///   - items: The items the window lists, in the order they are listed.
    static func placing<Item: Equatable>(_ ownIcon: Item, in items: [Item]) -> [Item] {
        items.filter { $0 != ownIcon } + [ownIcon]
    }
}
