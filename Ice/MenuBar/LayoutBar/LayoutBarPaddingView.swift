//
//  LayoutBarPaddingView.swift
//  Ice
//

import Cocoa
import Combine
import OSLog

/// A Cocoa view that manages the menu bar layout interface.
final class LayoutBarPaddingView: NSView {
    private let container: LayoutBarContainer

    /// The layout view's arranged views.
    var arrangedViews: [LayoutBarItemView] {
        get { container.arrangedViews }
        set { container.arrangedViews = newValue }
    }

    /// Creates a layout bar view with the given app state, section, and spacing.
    ///
    /// - Parameters:
    ///   - appState: The shared app state instance.
    ///   - section: The section whose items are represented.
    init(appState: AppState, section: MenuBarSection.Name) {
        self.container = LayoutBarContainer(appState: appState, section: section)

        super.init(frame: .zero)

        addSubview(container)
        self.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 7.5),
            leadingAnchor.constraint(lessThanOrEqualTo: container.leadingAnchor, constant: -7.5),
        ])

        registerForDraggedTypes([.layoutBarItem])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        container.updateArrangedViewsForDrag(with: sender, phase: .entered)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let sender {
            container.updateArrangedViewsForDrag(with: sender, phase: .exited)
        }
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        container.updateArrangedViewsForDrag(with: sender, phase: .updated)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        container.updateArrangedViewsForDrag(with: sender, phase: .ended)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer {
            DispatchQueue.main.async {
                self.container.canSetArrangedViews = true
            }
        }

        guard let draggingSource = sender.draggingSource as? LayoutBarItemView else {
            return false
        }

        if #available(macOS 27.0, *), let appState = container.appState {
            // On macOS 27 the saved layout decides sections, so a drop moves the item's application
            // to this section. The order within the Visible row is the bar's own, and the drop is
            // carried over to it with a ⌘ drag (see `ItemReorderer27`).
            if !draggingSource.item.isControlItem, let bundleID = draggingSource.item.sourceApplication?.bundleIdentifier {
                if
                    container.section != .visible,
                    !NativeSwitch27.canIceHide(bundleID: bundleID, tracked: NativeAllowListConcealer27.trackedBundleIDs())
                {
                    // Only macOS can hide this one. Putting it in "Hidden" would record a hiding
                    // that never happens, so the tile goes back, and its switch in System Settings
                    // is pressed for the user when it is known, or they are told where to find it.
                    returnToOldContainer(draggingSource)
                    if let menuBarSwitch = NativeSwitch27.menuBarSwitch(bundleID: bundleID, title: draggingSource.item.title) {
                        turnOff(menuBarSwitch, appState: appState, item: draggingSource.item, bundleID: bundleID)
                    } else {
                        presentAlertForItemOnlyMacOSCanHide(draggingSource.item, bundleID: bundleID, failure: nil)
                    }
                    return false
                }
                appState.concealer27.setSection(MacOS27Section(container.section), for: bundleID)
                if container.section == .visible {
                    // The bar is what the Visible row shows, so the order the tile was dropped in
                    // is made the bar's order too. The hidden rows have nothing on the bar to move.
                    let item = draggingSource.item
                    let order = arrangedViews.map(\.item)
                    Task {
                        await ItemReorderer27.reflect(item: item, order: order, appState: appState)
                    }
                }
            }
            return true
        }

        if let index = arrangedViews.firstIndex(of: draggingSource) {
            if arrangedViews.count == 1 {
                Task {
                    // dragging source is the only view in the layout bar, so we
                    // need to find a target item
                    let items = await MenuBarItem.getMenuBarItems(option: .activeSpace)
                    let targetItem: MenuBarItem? = switch container.section {
                    case .visible: nil // visible section always has more than 1 item
                    case .hidden: items.first(matching: .hiddenControlItem)
                    case .alwaysHidden: items.first(matching: .alwaysHiddenControlItem)
                    }
                    if let targetItem {
                        move(item: draggingSource.item, to: .leftOfItem(targetItem))
                    } else {
                        Logger.default.error("No target item for layout bar drag")
                    }
                }
            } else if arrangedViews.indices.contains(index + 1) {
                // we have a view to the right of the dragging source
                let targetItem = arrangedViews[index + 1].item
                move(item: draggingSource.item, to: .leftOfItem(targetItem))
            } else if arrangedViews.indices.contains(index - 1) {
                // we have a view to the left of the dragging source
                let targetItem = arrangedViews[index - 1].item
                move(item: draggingSource.item, to: .rightOfItem(targetItem))
            }
        }

        return true
    }

    /// Puts a tile that was dragged here back in the row and place it came from.
    private func returnToOldContainer(_ view: LayoutBarItemView) {
        container.shouldAnimateNextLayoutPass = false
        arrangedViews.removeAll { $0 === view }
        guard let (old, index) = view.oldContainerInfo else {
            return
        }
        old.shouldAnimateNextLayoutPass = false
        old.arrangedViews.insert(view, at: min(index, old.arrangedViews.count))
    }

    @available(macOS 27.0, *)
    private func turnOff(_ menuBarSwitch: NativeSwitch27.MenuBarSwitch, appState: AppState, item: MenuBarItem, bundleID: String) {
        Task { @MainActor in
            let outcome = await appState.nativeSwitches27.set(menuBarSwitch, shown: false)
            if case .failed(let message) = outcome {
                presentAlertForItemOnlyMacOSCanHide(item, bundleID: bundleID, failure: message)
            }
        }
    }

    @available(macOS 27.0, *)
    private func presentAlertForItemOnlyMacOSCanHide(_ item: MenuBarItem, bundleID: String, failure: String?) {
        let label = NativeSwitch27.label(bundleID: bundleID, title: item.title)
        let alert = NSAlert()
        alert.messageText = label.map { String(localized: "VIce Bartender cannot hide \($0).") } ?? String(localized: "VIce Bartender cannot hide this item.")
        let guidance = String(localized: "macOS draws it and keeps it out of VIce Bartender's reach, so it would stay in the menu bar.") + " "
            + (label.map { String(localized: "Turn off \u{201C}\($0)\u{201D} under Menu Bar Controls in System Settings > Menu Bar to hide it.") }
                ?? String(localized: "If macOS has a switch for it under Menu Bar Controls in System Settings > Menu Bar, turn it off there."))
        alert.informativeText = failure.map { "\($0)\n\n\(guidance)" } ?? guidance
        alert.addButton(withTitle: String(localized: "Open Menu Bar Settings"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        // After the drag has ended: a modal session inside a drop would hold the drag open.
        DispatchQueue.main.async {
            if alert.runModal() == .alertFirstButtonReturn {
                MenuBarSettingsLink27.open()
            }
        }
    }

    private func move(item: MenuBarItem, to destination: MenuBarItemManager.MoveDestination) {
        guard let appState = container.appState else {
            return
        }
        Task {
            try await Task.sleep(for: .milliseconds(25))
            do {
                try await appState.itemManager.move(item: item, to: destination)
                appState.itemManager.removeTemporarilyShownItemFromCache(with: item.tag)
            } catch {
                Logger.default.error("Error moving menu bar item: \(error, privacy: .public)")
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }
}
