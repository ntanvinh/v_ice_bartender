//
//  StatusReveal27.swift
//  Ice
//

import Foundation
import OSLog

/// Shows a hidden application's item for a few seconds when what it says about itself changes.
///
/// The change is read from the text the item publishes through Accessibility (see
/// ``StatusChange27``); an application that publishes none cannot be watched, and its setting is
/// off and cannot be turned on. The setting is per application and on by default. An application
/// in Always-Hidden is never shown.
///
/// The full scan of every process runs about every five seconds, which is too slow for a status
/// someone flips by hand: VOpenKey's Caps Lock icon was seen late, or not at all when it went on
/// and off between two scans. The hidden applications that publish text are therefore read on
/// their own, twice a second, from the items the last scan found (see ``watch()``).
@available(macOS 27.0, *)
@MainActor
final class StatusReveal27 {
    private let logger = Logger(category: "StatusReveal27")
    private weak var concealer: Concealer27?
    private var watcher = StatusChange27()
    private var revealTasks = [String: Task<Void, Never>]()
    private var watchTask: Task<Void, Never>?
    /// When each application was last read by ``watch()``, as a monotonic time in seconds.
    private var lastQuickRead = [String: TimeInterval]()

    /// How often the hidden applications are read, and how often while there are none to read.
    private static let watchInterval = Duration.milliseconds(500)
    private static let idleInterval = Duration.seconds(2)

    /// How long the scan leaves an application to the quick read after it last answered it. An
    /// application whose items stop answering the quick read goes back to the scan.
    private static let quickReadTrust: TimeInterval = 3

    init(concealer: Concealer27) {
        self.concealer = concealer
    }

    /// Whether the setting is on for the application. It is on unless the user turned it off.
    func isEnabled(bundleID: String) -> Bool {
        !disabledBundleIDs.contains(bundleID)
    }

    func setEnabled(_ enabled: Bool, bundleID: String) {
        var disabled = disabledBundleIDs
        if enabled {
            disabled.remove(bundleID)
        } else {
            disabled.insert(bundleID)
        }
        Defaults.set(disabled.sorted(), forKey: .macOS27StatusRevealOff)
        NotificationCenter.default.post(name: Self.settingDidChange, object: nil)
    }

    /// Posted when an application's setting changes, so a tile that marks it can redraw.
    nonisolated static let settingDidChange = Notification.Name("StatusReveal27.settingDidChange")

    /// Whether the application's item publishes text, so a change in it can be seen.
    func canDetect(bundleID: String) -> Bool {
        watcher.canDetect(bundleID: bundleID)
    }

    /// Reads what the applications' items say now, and shows the hidden ones that changed.
    ///
    /// This is the scan's reading. An application the quick read has answered lately is left to
    /// it: the scan's text can be seconds older than the quick read's, and handing both to the
    /// same baseline would report the older one as a change back.
    func observe(texts: [String: String], layout: [String: MacOS27Section]) {
        let now = ProcessInfo.processInfo.systemUptime
        let others = texts.filter { bundleID, _ in
            guard let readAt = lastQuickRead[bundleID] else {
                return true
            }
            return now - readAt >= Self.quickReadTrust
        }
        reveal(changed: watcher.observe(others), layout: layout)
    }

    /// Starts reading the hidden applications on their own. Does nothing if it already has.
    func startWatching() {
        guard watchTask == nil else {
            return
        }
        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                let hadWork = await self?.watch() ?? false
                try? await Task.sleep(for: hadWork ? Self.watchInterval : Self.idleInterval)
            }
        }
    }

    /// Reads what the hidden applications that publish text say now, and shows the ones that
    /// changed.
    ///
    /// It reads the items the last scan found and nothing else, so it costs three Accessibility
    /// calls per item and does not sweep the running processes.
    ///
    /// - Returns: Whether there was an application to read.
    private func watch() async -> Bool {
        guard let concealer else {
            return false
        }
        let watched = watchedBundleIDs(layout: concealer.layoutForStatusReveal)
        guard !watched.isEmpty else {
            return false
        }
        let texts = await MenuBarItemProvider27.statusTexts(of: watched)
        let now = ProcessInfo.processInfo.systemUptime
        for bundleID in texts.keys {
            lastQuickRead[bundleID] = now
        }
        // The layout is read again: the user can move an item while the read is under way.
        reveal(changed: watcher.observe(texts), layout: concealer.layoutForStatusReveal)
        return true
    }

    /// The applications that would be shown for a change and whose change can be seen.
    private func watchedBundleIDs(layout: [String: MacOS27Section]) -> Set<String> {
        Set(layout.keys.filter { bundleID in
            StatusChange27.shouldReveal(section: layout[bundleID], isEnabled: isEnabled(bundleID: bundleID))
                && watcher.canDetect(bundleID: bundleID)
        })
    }

    private var disabledBundleIDs: Set<String> {
        Set(Defaults.stringArray(forKey: .macOS27StatusRevealOff) ?? [])
    }

    private func reveal(changed: Set<String>, layout: [String: MacOS27Section]) {
        for bundleID in changed {
            guard StatusChange27.shouldReveal(section: layout[bundleID], isEnabled: isEnabled(bundleID: bundleID)) else {
                continue
            }
            reveal(bundleID: bundleID)
        }
    }

    /// Shows the application for ``StatusChange27/revealDuration`` from now. One that is already
    /// shown by an earlier change is kept shown for that long again, with no second show to end.
    private func reveal(bundleID: String) {
        guard let concealer else {
            return
        }
        guard watcher.recordChange(bundleID: bundleID, now: ProcessInfo.processInfo.systemUptime) else {
            logger.debug("\(bundleID, privacy: .public) changes too often to be shown for each change")
            return
        }
        if revealTasks[bundleID] == nil {
            logger.info("Showing \(bundleID, privacy: .public) for \(Int(StatusChange27.revealDuration)) s: its status changed")
            concealer.showTemporarily(bundleID: bundleID)
        } else {
            logger.info("Keeping \(bundleID, privacy: .public) shown for \(Int(StatusChange27.revealDuration)) s: its status changed again")
        }
        revealTasks[bundleID]?.cancel()
        revealTasks[bundleID] = Task { [weak self] in
            try? await Task.sleep(for: .seconds(StatusChange27.revealDuration))
            // A change that came in the meantime has replaced this task, and its show is the
            // one that is ended.
            guard !Task.isCancelled else {
                return
            }
            self?.concealer?.endTemporaryShow(bundleID: bundleID)
            self?.revealTasks[bundleID] = nil
        }
    }
}
