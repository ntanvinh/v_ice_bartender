---
title: "VIce Bartender: Ice Bar opens under the Ellipsis icon on macOS 27, never past the screen edge"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 9, tokens: 187610 }
touches:
  - AGENTS.md
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Hotkeys/Hotkey.swift
  - Ice/Hotkeys/KeyCode.swift
  - Ice/Main/AppDelegate.swift
  - Ice/Main/AppState.swift
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/Main/Updates.swift
  - Ice/MenuBar/ControlItem/ControlItem.swift
---

## Decided
- Symptom (user, 2026-11-13): the hidden-items panel (Ice Bar) opened at the screen's right edge under the clock, away from the Ellipsis icon. Evidence: the last panel of the installed build stood at x=1747 w=53 (right edge = screen edge) while Ice.ControlItem.Visible was at 1589..1624 (AX frame).
- Fix: on macOS 27 the .iceIcon placement no longer needs the item cache to hold the icon. IceBarPanel.updateOrigin takes the icon's frame from MenuBarItemProvider27.ownIconFrame() (new; lastOwnIconMinX became lastOwnIconFrame), falls back to the cached control item, and IceBarPlacement27.originX (pure, Core, 8 tests) puts the drawn bar's right edge under the icon's right edge (panel margin 5 = IceBarPanel.margin), clamps into [screen.minX, screen.maxX - width], and uses the screen's right edge when the icon is unknown or on another display.
- Second cause found in the log: IceBarPanel.show placed the panel before it had its content's size (width 0 the first time, the last bar's width after), so a wide bar stuck out past the right edge for ~38 ms until the frame-size sink moved it. show now does setContentSize(hostingView.fittingSize) before updateOrigin; the first placement logs the real width.
## Tried and ruled out
- AXPress on the Ice icon returns success but does not open the Ice Bar (it needs a real click); a CGEvent click at the icon's centre (1606,19) opens it and a second click closes it.
- Why the old guard (itemCache.managedItems.first(matching: .visibleControlItem) + Bridging.getWindowBounds) fell back to the right edge was NOT pinned down; the new code does not depend on it.
## Watch out
- Verified live on the installed dev build (0.11.15, macOS 27.2, built-in 1800 wide, external display to its right): panel x=1576 w=53, screenshot shows the tile right under the Ellipsis icon. NOT verified: a bar wider than one tile (only one hidden item here), the external display's bar, IceBarLocation set to mouse pointer.
- Debug-level os_log lines are not stored: read 'Ice Bar origin x ...' with `log stream --level debug`, not `log show`.
- trail check flags IceBar.swift lines 143-149 against unrelated learnings by keyword overlap only; none concern placement.
