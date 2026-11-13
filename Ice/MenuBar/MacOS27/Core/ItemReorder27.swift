//
//  ItemReorder27.swift
//  Ice
//

import CoreGraphics
import Foundation

/// How a tile dropped in a row of the layout window is reflected on the real menu bar.
///
/// macOS 27 draws the bar itself, so Ice cannot place an item: the only way to move one is the
/// gesture the user would make, a ⌘ drag with the pointer. That gesture was measured on macOS 27.2
/// (2026-11-12, built-in display, Wi-Fi, Bluetooth and Sound):
/// - the dragged item follows the pointer and swaps with a neighbour once the pointer passes the
///   neighbour's centre, so a drag across several items reorders each of them in turn;
/// - an item the pointer has not passed its centre stays where it was, so releasing in the near
///   half of the target puts the item before it and releasing in the far half puts it after it;
/// - the same release point works whichever way the item travels.
enum ItemReorder27 {
    /// Which side of the target the item has to stand on.
    enum Side: Equatable {
        case before
        case after
    }

    struct Destination<ID: Hashable>: Equatable {
        let target: ID
        let side: Side
    }

    /// Where on the bar the dragged item has to stand, from the order the row shows after the drop.
    ///
    /// The neighbour on the right is the target, so the item goes before it; an item dropped at the
    /// end of the row goes after the neighbour on its left, and an item alone in the row needs no
    /// move.
    ///
    /// - Parameters:
    ///   - order: The tiles of the row, left to right, after the drop.
    ///   - dragged: The tile that was dropped.
    ///   - excluded: Tiles that cannot be a target, such as Ice's own icon, which is not an item
    ///     macOS lets another one be placed against.
    static func destination<ID: Hashable>(in order: [ID], dragged: ID, excluding excluded: Set<ID> = []) -> Destination<ID>? {
        guard let index = order.firstIndex(of: dragged) else {
            return nil
        }
        if let next = order[(index + 1)...].first(where: { !excluded.contains($0) }) {
            return Destination(target: next, side: .before)
        }
        if let previous = order[..<index].last(where: { !excluded.contains($0) }) {
            return Destination(target: previous, side: .after)
        }
        return nil
    }

    /// Whether the bar already has the item where the drop wants it.
    ///
    /// - Parameters:
    ///   - barOrder: The ids of the row's tiles in the order they stand on the bar now. Items that
    ///     are not in the row, such as an application's concealed ones, are not in it.
    static func isPlaced<ID: Hashable>(_ item: ID, at destination: Destination<ID>, barOrder: [ID]) -> Bool {
        guard
            let itemIndex = barOrder.firstIndex(of: item),
            let targetIndex = barOrder.firstIndex(of: destination.target)
        else {
            return false
        }
        switch destination.side {
        case .before: return itemIndex + 1 == targetIndex
        case .after: return itemIndex == targetIndex + 1
        }
    }

    /// The points of the drag: where the item is grabbed and where the pointer is released.
    ///
    /// The release point is a quarter of the way into the target from the side the item is to
    /// stand on, which keeps it clear of the target's centre, the line the swap happens on, for
    /// any width.
    static func dragPoints(itemFrame: CGRect, targetFrame: CGRect, side: Side) -> (start: CGPoint, end: CGPoint) {
        let inset = max(2, targetFrame.width / 4)
        let endX = switch side {
        case .before: targetFrame.minX + inset
        case .after: targetFrame.maxX - inset
        }
        return (
            start: CGPoint(x: itemFrame.midX, y: itemFrame.midY),
            end: CGPoint(x: endX, y: itemFrame.midY)
        )
    }

    /// How many pointer steps a drag over the given distance takes.
    ///
    /// The measured drag used 40 steps over about 70 points. Fewer left the bar no time to swap
    /// the items in between one at a time.
    static func stepCount(forDistance distance: CGFloat) -> Int {
        min(80, max(24, Int((abs(distance) / 2).rounded(.up))))
    }
}
