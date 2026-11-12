//
//  Permission.swift
//  Ice
//

import Combine
import Cocoa

// MARK: - Permission

/// An object that encapsulates the behavior of checking for and requesting
/// a specific permission for the app.
@MainActor
class Permission: ObservableObject, Identifiable {
    /// A Boolean value that indicates whether the app has this permission.
    @Published private(set) var hasPermission = false

    /// The title of the permission.
    let title: String

    /// The name of the system symbol that stands for the permission.
    let symbolName: String

    /// Descriptive details for the permission.
    let details: [String]

    /// A Boolean value that indicates if the app can work without this permission.
    let isRequired: Bool

    /// The URL of the settings pane to open.
    private let settingsURL: URL?

    /// The function that checks permissions.
    private let check: () -> Bool

    /// The function that requests permissions.
    private let request: () -> Void

    /// Observer that runs on a timer to check permissions.
    private var timerCancellable: AnyCancellable?

    /// Observer that observes the ``hasPermission`` property.
    private var hasPermissionCancellable: AnyCancellable?

    /// Where the permission stands right now.
    var status: PermissionStatus {
        if hasPermission {
            .granted
        } else if isRequired {
            .missingRequired
        } else {
            .missingOptional
        }
    }

    /// Creates a permission.
    ///
    /// - Parameters:
    ///   - title: The title of the permission.
    ///   - symbolName: The name of the system symbol that stands for the permission.
    ///   - details: Descriptive details for the permission.
    ///   - isRequired: A Boolean value that indicates if the app can work without this permission.
    ///   - settingsURL: The URL of the settings pane to open.
    ///   - check: A function that checks permissions.
    ///   - request: A function that requests permissions.
    init(
        title: String,
        symbolName: String,
        details: [String],
        isRequired: Bool,
        settingsURL: URL?,
        check: @escaping () -> Bool,
        request: @escaping () -> Void
    ) {
        self.title = title
        self.symbolName = symbolName
        self.details = details
        self.isRequired = isRequired
        self.settingsURL = settingsURL
        self.check = check
        self.request = request
        self.hasPermission = check()
        configureCancellables()
    }

    /// Sets up the internal observers for the permission.
    private func configureCancellables() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .merge(with: Just(.now))
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                hasPermission = check()
            }
    }

    /// Checks the permission once more, without waiting for the timer.
    ///
    /// The timer stops once the app has been set up, so a screen that outlives it asks again
    /// when it appears and when the app comes to the front.
    func recheck() {
        hasPermission = check()
    }

    /// Performs the request and opens the System Settings app to the appropriate pane.
    func performRequest() {
        request()
        if let settingsURL {
            NSWorkspace.shared.open(settingsURL)
        }
    }

    /// Asynchronously waits for the app to be granted this permission.
    func waitForPermission() async {
        configureCancellables()
        guard !hasPermission else {
            return
        }
        return await withCheckedContinuation { continuation in
            hasPermissionCancellable = $hasPermission.sink { [weak self] hasPermission in
                guard let self else {
                    continuation.resume()
                    return
                }
                if hasPermission {
                    hasPermissionCancellable?.cancel()
                    continuation.resume()
                }
            }
        }
    }

    /// Stops running the permission check.
    func stopCheck() {
        timerCancellable?.cancel()
        timerCancellable = nil
        hasPermissionCancellable?.cancel()
        hasPermissionCancellable = nil
    }
}

// MARK: - AccessibilityPermission

final class AccessibilityPermission: Permission {
    init() {
        super.init(
            title: "Accessibility",
            symbolName: "accessibility",
            details: [
                "Get real-time information about the menu bar.",
                "Arrange menu bar items.",
            ],
            isRequired: true,
            settingsURL: nil,
            check: {
                AXHelpers.isProcessTrusted()
            },
            request: {
                AXHelpers.isProcessTrusted(prompt: true)
            }
        )
    }
}

// MARK: - ScreenRecordingPermission

final class ScreenRecordingPermission: Permission {
    init() {
        super.init(
            title: "Screen Recording",
            symbolName: "record.circle",
            details: [
                "Change the menu bar's appearance.",
                "Display images of individual menu bar items.",
            ],
            isRequired: false,
            settingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
            check: {
                ScreenCapture.checkPermissions()
            },
            request: {
                ScreenCapture.requestPermissions()
            }
        )
    }
}

// MARK: - ControlCenterPermission

/// Access to the data Control Centre keeps its "Allow in the Menu Bar" switches in.
///
/// Without it macOS 27 hides items through assessment mode, under which MenuBarAgent also drops
/// VIce Bartender's own icon (see ``NativeAllowListConcealer27/requestAccess()``).
@available(macOS 27.0, *)
final class ControlCenterPermission: Permission {
    /// Where "Full Disk Access" is in System Settings: the place to turn the access on once the
    /// system has stopped asking.
    private nonisolated static let fullDiskAccessURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")

    init() {
        super.init(
            title: "Control Center Access",
            symbolName: "switch.2",
            details: [
                "Hide menu bar items with macOS's own \u{201C}Allow in the Menu Bar\u{201D} switch.",
                "Keep the VIce Bartender icon in the menu bar while items are hidden.",
            ],
            isRequired: false,
            settingsURL: nil,
            check: {
                NativeAllowListConcealer27.isAvailable
            },
            request: {
                // The system asks the first time. After a refusal it does not ask again, and the
                // switch to flip is in System Settings.
                Task.detached(priority: .userInitiated) {
                    guard !NativeAllowListConcealer27.requestAccess(), let url = ControlCenterPermission.fullDiskAccessURL else {
                        return
                    }
                    await MainActor.run {
                        _ = NSWorkspace.shared.open(url)
                    }
                }
            }
        )
    }
}
