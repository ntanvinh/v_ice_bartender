//
//  NativeSwitch27.swift
//  Ice
//

import Foundation

/// Which menu bar items only macOS can hide, and which switch of System Settings does it.
///
/// Ice hides an application's items through the application's entry in MenuBarAgent's list (see
/// ``TrackedApplications27``). Some of what is on the bar belongs to macOS and has no entry:
/// Text Input, VPN and the Spotlight item (measured on macOS 27.2, 2026-11-12: none of them is in
/// the list, and a layout that put them in "Hidden" left every one on the bar). System Settings >
/// Menu Bar has a switch for each of them, and turning Spotlight's off took its icon off the bar.
enum NativeSwitch27 {
    /// Whether Ice can hide the items of an application.
    ///
    /// It can when the application has an entry in the list, and when it is not macOS's own: an
    /// application that has not created an item yet has no entry until it does, and Ice applies
    /// again once it has. Without a readable list nothing is refused.
    ///
    /// - Parameters:
    ///   - bundleID: The application that owns the items.
    ///   - tracked: The applications in MenuBarAgent's list, or `nil` if it could not be read.
    static func canIceHide(bundleID: String, tracked: Set<String>?) -> Bool {
        guard let tracked else {
            return true
        }
        return tracked.contains(bundleID) || !bundleID.hasPrefix("com.apple.")
    }

    /// A switch of System Settings > Menu Bar > Menu Bar Controls.
    struct MenuBarSwitch: Hashable {
        /// The name the pane gives its checkbox: `controlcenter-<identifier>-id` (measured on
        /// macOS 27.2, 2026-11-12, by reading the pane through Accessibility).
        let identifier: String

        /// What the pane calls it.
        let label: String

        var accessibilityIdentifier: String {
            "controlcenter-\(identifier)-id"
        }
    }

    static let textInput = MenuBarSwitch(identifier: "textInput", label: "Text Input")
    static let vpn = MenuBarSwitch(identifier: "vpn", label: "VPN")
    static let spotlight = MenuBarSwitch(identifier: "spotlight", label: "Spotlight")

    /// The switches Ice knows the items of.
    static let known = [textInput, vpn, spotlight]

    /// The switch that hides an item of macOS's own, or `nil` if there is none that is known.
    ///
    /// - Parameters:
    ///   - bundleID: The application that owns the item.
    ///   - title: The item's description, which is what Accessibility says it is ("VPN", "Search").
    static func menuBarSwitch(bundleID: String, title: String?) -> MenuBarSwitch? {
        switch bundleID {
        case "com.apple.TextInputMenuAgent":
            return textInput
        case "com.apple.systemuiserver" where title?.localizedCaseInsensitiveContains("VPN") == true:
            return vpn
        case "com.apple.campo":
            return spotlight
        default:
            return nil
        }
    }

    /// The name of the switch for an item, or `nil` (see ``menuBarSwitch(bundleID:title:)``).
    static func label(bundleID: String, title: String?) -> String? {
        menuBarSwitch(bundleID: bundleID, title: title)?.label
    }

    /// The identifiers Ice has turned off, after turning one off or back on.
    ///
    /// What Ice turned off is recorded, because the item leaves the bar and with it the layout
    /// window, and the record is the one way back that does not go through System Settings.
    static func recording(_ menuBarSwitch: MenuBarSwitch, shown: Bool, in turnedOff: [String]) -> [String] {
        var set = Set(turnedOff)
        if shown {
            set.remove(menuBarSwitch.identifier)
        } else {
            set.insert(menuBarSwitch.identifier)
        }
        return set.sorted()
    }
}
