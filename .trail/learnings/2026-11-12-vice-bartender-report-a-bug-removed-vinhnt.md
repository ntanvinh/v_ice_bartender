---
title: "VIce Bartender: Report a Bug removed, screenshot always-hidden row came from CaptureHarness"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 1, tokens: 1646 }
touches:
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Hotkeys/Hotkey.swift
  - Ice/Main/AppDelegate.swift
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift
  - Ice/MenuBar/MenuBarItems/MenuBarItem.swift
  - Ice/MenuBar/MenuBarItems/MenuBarItemImageCache.swift
  - Ice/MenuBar/MenuBarItems/MenuBarItemManager.swift
---

## Decided
- Removed the "Report a Bug" sidebar link from SettingsView. DonationInfo.issuesURL is now unused but left in place (file belongs to another agent).
- The always-hidden row in the layout screenshot came from CaptureHarness seeding demo items into .alwaysHidden. The real app only shows that section when "Enable the always-hidden section" (Advanced) is on, default off. Removed the seeding.

## Tried and ruled out
- Did not regenerate marketing/screenshots/desktop/02-drag-and-drop-layout.png; it still shows the old row.

## Watch out
- captures.json (lines 8, 23) and features.json (line 19) still describe Always-Hidden; the Hotkeys screenshot still shows ^⌥A. Debug build passed; app not run.
