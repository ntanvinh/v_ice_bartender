//
//  NativeMenuBarSwitches27.swift
//  Ice
//

import AppKit
import ApplicationServices
import Foundation

/// Turns macOS's own menu bar items off and on by pressing their switch in System Settings.
///
/// Text Input, VPN and the Spotlight item belong to macOS, have no entry in MenuBarAgent's list
/// (see ``NativeSwitch27``) and can only be hidden by the checkboxes of System Settings > Menu Bar
/// > Menu Bar Controls. Pressing one of them through Accessibility is what a click would do:
/// `AXPress` on the checkbox named `controlcenter-spotlight-id` took the Spotlight icon off the
/// bar (measured on macOS 27.2, 2026-11-12). Ice already needs the Accessibility permission.
///
/// The pane is opened without being brought to the front, and closed again if Ice was what
/// started System Settings. What Ice turns off is recorded, because the item then leaves the bar
/// and the layout window, and the record is how the layout window offers it back.
@available(macOS 27.0, *)
@MainActor
final class NativeMenuBarSwitches27: ObservableObject {
    enum Outcome: Equatable {
        case changed
        case alreadyThere
        case failed(String)
    }

    /// The identifiers of the switches Ice turned off and has not turned back on.
    @Published private(set) var turnedOff = Defaults.stringArray(forKey: .macOS27NativeSwitchesOff) ?? []

    /// Whether a switch is being pressed right now.
    @Published private(set) var isWorking = false

    private nonisolated static let settingsBundleID = "com.apple.systempreferences"
    private nonisolated static let queue = DispatchQueue(label: "vn.io.lssoft.vicebartender.NativeMenuBarSwitches27", qos: .userInitiated)

    /// Turns the switch on (`shown`) or off, and says what came of it.
    func set(_ menuBarSwitch: NativeSwitch27.MenuBarSwitch, shown: Bool) async -> Outcome {
        guard !isWorking else {
            return .failed(String(localized: "Another switch is being changed. Try again in a moment."))
        }
        guard AXIsProcessTrusted() else {
            return .failed(String(localized: "VIce Bartender needs the Accessibility permission to press the switch for you."))
        }
        isWorking = true
        defer { isWorking = false }

        let wasRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: Self.settingsBundleID).isEmpty
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        do {
            _ = try await NSWorkspace.shared.open(MenuBarSettingsLink27.paneURL, configuration: configuration)
        } catch {
            return .failed(String(localized: "System Settings could not be opened: \(error.localizedDescription)"))
        }
        let identifier = menuBarSwitch.accessibilityIdentifier
        let outcome = await withCheckedContinuation { continuation in
            Self.queue.async {
                continuation.resume(returning: Self.press(accessibilityIdentifier: identifier, shown: shown))
            }
        }
        if !wasRunning {
            NSRunningApplication.runningApplications(withBundleIdentifier: Self.settingsBundleID).first?.terminate()
        }
        if case .failed = outcome {
            return outcome
        }
        turnedOff = NativeSwitch27.recording(menuBarSwitch, shown: shown, in: turnedOff)
        Defaults.set(turnedOff, forKey: .macOS27NativeSwitchesOff)
        return outcome
    }

    // MARK: Accessibility

    /// Waits for the checkbox to exist, presses it if it is not as asked, and waits for it to change.
    private nonisolated static func press(accessibilityIdentifier: String, shown: Bool) -> Outcome {
        let wanted = shown ? 1 : 0
        guard let checkbox = waitForCheckbox(accessibilityIdentifier, timeout: 10) else {
            return .failed(String(localized: "The switch was not found in System Settings > Menu Bar. Turn it off there by hand."))
        }
        if value(of: checkbox.element) == wanted {
            return .alreadyThere
        }
        guard AXUIElementPerformAction(checkbox.element, kAXPressAction as CFString) == .success else {
            return .failed(String(localized: "System Settings did not accept the press. Turn it off there by hand."))
        }
        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline {
            // The pane redraws after a press, so the checkbox is looked up again each time.
            if let current = findCheckbox(accessibilityIdentifier), value(of: current.element) == wanted {
                return .changed
            }
            Thread.sleep(forTimeInterval: 0.15)
        }
        return .failed(String(localized: "The switch did not change in System Settings. Turn it off there by hand."))
    }

    private struct Checkbox {
        let element: AXUIElement
    }

    private nonisolated static func waitForCheckbox(_ identifier: String, timeout: TimeInterval) -> Checkbox? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let checkbox = findCheckbox(identifier) {
                return checkbox
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return nil
    }

    private nonisolated static func findCheckbox(_ identifier: String) -> Checkbox? {
        guard let application = NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleID).first else {
            return nil
        }
        let element = AXUIElementCreateApplication(application.processIdentifier)
        AXUIElementSetMessagingTimeout(element, 1.5)
        guard let windows = attribute(element, kAXWindowsAttribute) as? [AXUIElement] else {
            return nil
        }
        for window in windows {
            if let found = search(window, identifier: identifier, depth: 0) {
                return Checkbox(element: found)
            }
        }
        return nil
    }

    private nonisolated static func search(_ element: AXUIElement, identifier: String, depth: Int) -> AXUIElement? {
        guard depth < 40 else {
            return nil
        }
        if
            attribute(element, kAXRoleAttribute) as? String == kAXCheckBoxRole,
            attribute(element, kAXIdentifierAttribute) as? String == identifier
        {
            return element
        }
        for child in attribute(element, kAXChildrenAttribute) as? [AXUIElement] ?? [] {
            if let found = search(child, identifier: identifier, depth: depth + 1) {
                return found
            }
        }
        return nil
    }

    private nonisolated static func value(of element: AXUIElement) -> Int? {
        (attribute(element, kAXValueAttribute) as? NSNumber)?.intValue
    }

    private nonisolated static func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }
}
