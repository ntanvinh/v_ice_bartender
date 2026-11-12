//
//  MenuBarSettingsLink27.swift
//  Ice
//

import AppKit

/// The one place macOS lets the user turn its own menu bar items off.
///
/// System Settings > Menu Bar has a switch for each item macOS draws itself — Wi-Fi, Bluetooth,
/// Sound, Display, Focus, Screen Mirroring, Now Playing, the user switcher, Text Input, VPN,
/// Spotlight, Siri and a few more (measured on macOS 27.2, 2026-11-12, by reading the switches
/// of the open pane through Accessibility). Ice cannot move or hide these items, so the layout
/// window sends the user there. Turning Spotlight off took its icon off the bar at once.
@available(macOS 27.0, *)
enum MenuBarSettingsLink27 {
    /// The pane of System Settings that holds the switches. It is the Control Center extension's,
    /// which opens on "Menu Bar" (measured on macOS 27.2).
    static let paneURL = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!

    @MainActor
    static func open() {
        NSWorkspace.shared.open(paneURL)
    }

    /// What the dimmed tiles of the layout window say about the item they stand for.
    static let explanation = "macOS draws this item itself, so VIce Bartender cannot move or hide it. macOS can: turn it off under Menu Bar Controls in System Settings > Menu Bar. Wi\u{2011}Fi, Bluetooth, Sound, Spotlight, Siri, Text Input and VPN each have a switch there."
}
