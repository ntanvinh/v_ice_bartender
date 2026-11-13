//
//  StatusChange27.swift
//  Ice
//

import Foundation

/// Notices when an application's menu bar item changes what it says about itself.
///
/// A concealed item is not drawn on macOS 27, so its icon cannot be photographed. What
/// Accessibility still answers is the text an application gives its item: its description,
/// title or tooltip. Many applications keep that text up to date with their status ("Connected",
/// "3 unread"), and a change in it is the signal this type reads. An application that publishes no
/// text at all cannot be watched, and ``canDetect(bundleID:)`` says so, so the setting can be
/// turned off for it instead of promising something that never happens (measured 2026-11-12 on
/// macOS 27.2: two of nine running items published any text).
struct StatusChange27 {
    /// How long a changed item stays shown, counted from its latest change.
    static let revealDuration: TimeInterval = 10

    /// The span over which an application's changes are counted to tell one that reports a
    /// status from one that only ticks (a CPU figure, a clock).
    static let chattyWindow: TimeInterval = 60

    /// How many changes within ``chattyWindow`` still count as a status. One more and the
    /// application is taken for a ticker and not shown, until it has been quiet for the window.
    ///
    /// Six is three flips of a switch each way: VOpenKey turns its icon red with Caps Lock, and
    /// someone who presses it on and off three times in a minute still sees every change. The
    /// limit used to be a 30 s silence after each reveal, which swallowed the second press of a
    /// pair (measured 2026-11-13: a reveal at 14:37:06 and the next at 14:37:46, 40 s on).
    static let chattyLimit = 6

    private var baseline = [String: String]()
    private var detectable = Set<String>()
    private var changeTimes = [String: [TimeInterval]]()

    /// Records what each application's items say now.
    ///
    /// - Parameter texts: The text of every application whose items were read, keyed by bundle
    ///   identifier, empty when the items say nothing. An application missing from it was not
    ///   read this time and keeps what was recorded.
    /// - Returns: The applications whose text changed since they were last read. The first
    ///   reading of an application is its starting point, not a change.
    mutating func observe(_ texts: [String: String]) -> Set<String> {
        var changed = Set<String>()
        for (bundleID, text) in texts {
            if !text.isEmpty {
                detectable.insert(bundleID)
            }
            let previous = baseline.updateValue(text, forKey: bundleID)
            if let previous, previous != text {
                changed.insert(bundleID)
            }
        }
        return changed
    }

    /// Whether the application has published text, so a change in it can be seen.
    func canDetect(bundleID: String) -> Bool {
        detectable.contains(bundleID)
    }

    /// Counts a change of the application's text and says whether it is to be shown.
    ///
    /// Every change is shown, and one that comes while the item is still shown keeps it shown
    /// for another ``revealDuration``. Only an application that changes more than
    /// ``chattyLimit`` times within ``chattyWindow`` is left alone, and its changes keep
    /// counting while it is, so a ticker stays quiet for as long as it ticks.
    ///
    /// - Parameter now: A monotonic time in seconds.
    /// - Returns: `true` when the caller should show the application, or keep it shown, for
    ///   ``revealDuration`` from now.
    mutating func recordChange(bundleID: String, now: TimeInterval) -> Bool {
        var times = changeTimes[bundleID, default: []].filter { now - $0 < Self.chattyWindow }
        times.append(now)
        changeTimes[bundleID] = times
        return times.count <= Self.chattyLimit
    }

    /// The text an item publishes: its description, title and tooltip, each once.
    static func text(description: String?, title: String?, help: String?) -> String {
        var parts = [String]()
        for part in [description, title, help] {
            guard let part = part?.trimmingCharacters(in: .whitespacesAndNewlines), !part.isEmpty, !parts.contains(part) else {
                continue
            }
            parts.append(part)
        }
        return parts.joined(separator: " | ")
    }

    /// Whether a changed application is to be shown: its setting is on, and it is in the hidden
    /// section. An application in Always-Hidden stays hidden whatever it says, and one that is
    /// visible has nothing to reveal.
    static func shouldReveal(section: MacOS27Section?, isEnabled: Bool) -> Bool {
        isEnabled && section == .hidden
    }
}
