//
//  OwnIconSlot27.swift
//  Ice
//

import Foundation

/// Where Ice's own icon stands among the items the layout window lists under "Visible".
///
/// macOS 27 gives Ice's icon no photograph — taking one broke the bar (see
/// `ItemImageStore27.isPhotographable`) — so the layout window draws it from the icon the user
/// chose, and needs a place for it. On the bar it stands where the items the user can arrange end
/// and the ones macOS draws itself begin, so that is where it is listed: before the first item
/// that cannot be moved, or at the end when every item can.
enum OwnIconSlot27 {
    /// - Parameter isMovable: Whether each listed item can be moved, in the order they are listed.
    static func index(isMovable: [Bool]) -> Int {
        isMovable.firstIndex(of: false) ?? isMovable.count
    }
}
