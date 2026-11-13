//
//  ItemReorderer27.swift
//  Ice
//

import AppKit
import OSLog

/// Puts the items of the real menu bar in the order the layout window shows, on macOS 27.
///
/// macOS 27 draws the bar itself and offers no way to place an item, so the one way to reorder is
/// the gesture the user would make: a ⌘ drag with the pointer (see ``ItemReorder27`` for what was
/// measured). Ice does it only for a tile the user has just dropped in the Visible row — never on
/// its own accord — and puts the pointer back afterwards. It reads the bar again once the drag is
/// over, and tries again a couple of times when the item did not land where it was meant to.
///
/// An item macOS will not move by hand (those of applications signed on this Mac, and the ones
/// macOS draws itself) does not move for Ice either; that is logged, and the layout window goes
/// back to the order the bar has.
@available(macOS 27.0, *)
@MainActor
enum ItemReorderer27 {
    private static let logger = Logger(category: "ItemReorderer27")

    /// How many times a drag is made before Ice gives up on an item.
    private static let maxAttempts = 3

    /// How long Ice waits for an application that was just allowed to be drawn.
    private static let drawTimeout = Duration.seconds(4)

    /// How long Ice waits for the user to stop using the pointer and the keyboard.
    private static let idleTimeout = Duration.seconds(3)

    private static var isReordering = false

    /// Reflects a drop on the real bar.
    ///
    /// - Parameters:
    ///   - item: The item that was dropped.
    ///   - order: The tiles of the Visible row after the drop, left to right.
    static func reflect(item: MenuBarItem, order: [MenuBarItem], appState: AppState) async {
        guard !isReordering else {
            logger.info("A reorder is already under way, ignoring the drop of \(item.logString, privacy: .public)")
            return
        }
        isReordering = true
        defer { isReordering = false }

        let ownIDs = Set(order.filter(\.isControlItem).map(\.windowID))
        guard let destination = ItemReorder27.destination(in: order.map(\.windowID), dragged: item.windowID, excluding: ownIDs) else {
            return
        }
        let rowIDs = Set(order.map(\.windowID))

        guard await waitUntilUserIsIdle() else {
            logger.notice("The pointer or keyboard stayed in use, so the bar was left as it is")
            return
        }

        appState.hidEventManager.stopAll()
        defer { appState.hidEventManager.startAll() }

        for attempt in 1...maxAttempts {
            guard let bar = await drawnBar(containing: [item.windowID, destination.target], timeout: drawTimeout) else {
                logger.notice("\(item.logString, privacy: .public) or its neighbour is not drawn on the bar, so it cannot be moved")
                break
            }
            let barOrder = bar.filter { rowIDs.contains($0.windowID) }.map(\.windowID)
            if ItemReorder27.isPlaced(item.windowID, at: destination, barOrder: barOrder) {
                logger.notice("\(item.logString, privacy: .public) is in place after \(attempt - 1, privacy: .public) drags")
                break
            }
            guard
                let moving = bar.first(where: { $0.windowID == item.windowID }),
                let target = bar.first(where: { $0.windowID == destination.target })
            else {
                break
            }
            let points = ItemReorder27.dragPoints(itemFrame: moving.bounds, targetFrame: target.bounds, side: destination.side)
            logger.notice(
                """
                Drag \(attempt, privacy: .public) of \(item.logString, privacy: .public) \
                \(destination.side == .before ? "before" : "after", privacy: .public) \(target.logString, privacy: .public): \
                x \(points.start.x, privacy: .public) to \(points.end.x, privacy: .public)
                """
            )
            await commandDrag(from: points.start, to: points.end)
            // The bar settles for a moment after the drop.
            try? await Task.sleep(for: .milliseconds(500))
        }

        // The layout window lists the bar's order, so it follows what the drag did.
        await appState.itemManager.cacheItemsRegardless()
    }

    /// Waits until the item and the target are drawn on the bar, and returns the bar then.
    ///
    /// An application that was concealed is allowed again by the drop that moves it to the
    /// Visible row, and macOS takes a moment to publish and draw its item.
    private static func drawnBar(containing ids: [CGWindowID], timeout: Duration) async -> [MenuBarItem]? {
        let deadline = ContinuousClock.now + timeout
        while true {
            let items = await MenuBarItemProvider27.items()
            let drawn = items.filter(\.isOnScreen)
            if ids.allSatisfy({ id in drawn.contains { $0.windowID == id } }) {
                return drawn
            }
            guard ContinuousClock.now < deadline else {
                return nil
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    private static func waitUntilUserIsIdle() async -> Bool {
        let deadline = ContinuousClock.now + idleTimeout
        while ContinuousClock.now < deadline {
            if
                NSEvent.modifierFlags.isEmpty,
                !MouseHelpers.lastMovementOccurred(within: .milliseconds(200)),
                !MouseHelpers.lastScrollWheelOccurred(within: .milliseconds(200)),
                !MouseHelpers.isButtonPressed()
            {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return false
    }

    /// Drags from one point to another with ⌘ held, the way the user reorders the bar, then puts
    /// the pointer back where it was.
    ///
    /// The events are marked so that Ice's own mouse handlers ignore them (they would otherwise
    /// take the drag for a click on the bar).
    private static func commandDrag(from start: CGPoint, to end: CGPoint) async {
        let source = CGEventSource(stateID: .hidSystemState)
        let original = MouseHelpers.locationCoreGraphics

        func mouse(_ type: CGEventType, at point: CGPoint) {
            guard let event = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else {
                return
            }
            event.flags = .maskCommand
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            event.setIntegerValueField(.eventSourceUserData, value: HIDEventManager.menuBarActivationMarker)
            event.post(tap: .cghidEventTap)
        }

        // The ⌘ key itself: the bar looks at the modifier state, and the flag on the mouse events
        // alone was not enough in the measurement.
        func commandKey(down: Bool) {
            guard let event = CGEvent(source: source) else {
                return
            }
            event.type = .flagsChanged
            event.setIntegerValueField(.keyboardEventKeycode, value: 55)
            event.flags = down ? .maskCommand : []
            event.setIntegerValueField(.eventSourceUserData, value: HIDEventManager.menuBarActivationMarker)
            event.post(tap: .cghidEventTap)
        }

        MouseHelpers.hideCursor()
        defer {
            if let original {
                MouseHelpers.warpCursor(to: original)
            }
            MouseHelpers.showCursor()
        }

        commandKey(down: true)
        try? await Task.sleep(for: .milliseconds(100))
        mouse(.mouseMoved, at: start)
        try? await Task.sleep(for: .milliseconds(150))
        mouse(.leftMouseDown, at: start)
        try? await Task.sleep(for: .milliseconds(250))
        let steps = ItemReorder27.stepCount(forDistance: end.x - start.x)
        for step in 1...steps {
            let progress = CGFloat(step) / CGFloat(steps)
            mouse(.leftMouseDragged, at: CGPoint(x: start.x + (end.x - start.x) * progress, y: start.y))
            try? await Task.sleep(for: .milliseconds(20))
        }
        try? await Task.sleep(for: .milliseconds(250))
        mouse(.leftMouseUp, at: end)
        try? await Task.sleep(for: .milliseconds(150))
        commandKey(down: false)
        try? await Task.sleep(for: .milliseconds(100))
    }
}
