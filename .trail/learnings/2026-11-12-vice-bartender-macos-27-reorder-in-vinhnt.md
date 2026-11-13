---
title: "VIce Bartender macOS 27: reorder in the layout window drags the real bar; Ice Bar opens left of the icon"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 12, tokens: 174309 }
touches:
  - Ice.xcodeproj/project.pbxproj
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift
  - Ice/Settings/SettingsPanes/AboutSettingsPane.swift
  - Ice/Settings/SettingsView.swift
  - Ice/Utilities/Defaults.swift
  - README.md
  - Scripts/test.sh
  - AGENTS.md
  - Ice/MenuBar/MacOS27/Core/ItemReorder27.swift
---

## Decided
- Dropping a tile in the Visible row now carries the order to the real bar: LayoutBarPaddingView -> ItemReorderer27.reflect, which posts a synthetic ⌘ drag (flagsChanged keycode 55, then mouse events flagged ⌘ through .cghidEventTap, marked with HIDEventManager.menuBarActivationMarker, pointer warped back) and re-reads the bar with MenuBarItemProvider27.items(), up to 3 drags. Pure logic is in Core/ItemReorder27.swift (tests in ItemReorder27Tests).
- Measured on macOS 27.2, built-in display (2026-11-12, Wi-Fi/Bluetooth/Sound, restored afterwards): the dragged item swaps with a neighbour when the pointer passes the neighbour's centre; release a quarter in from the side the item must end on (before: minX + w/4, after: maxX - w/4); a drag across two items works.
- Ice Bar on macOS 27: IceBarPanel.updateOrigin anchors the panel's right edge to the Ice icon's maxX (the icon sits beside Control Center, so centring pushed the panel right, under the clock).
## Tried and ruled out
- Dragging concealed items: iTerm2, Tailscale, VMonitor AI were in Hidden, so nothing was drawn under the pointer and the drag did nothing although AX still reported frames. Check isOnScreen / a screenshot before trusting AX frames.
- MenuBarItemManager.move (window-ID events) is not used on 27: there are no windows.
## Watch out
- The whole path (drop -> drag -> layout window refresh) was NOT run end to end: the installed dev build was not replaced. Only the drag primitive and the unit tests (219) and the Debug build were run. Hidden/Always hidden rows are not reordered on the bar (nothing drawn), and apps signed on this Mac (VOpenKey, VMonitor AI, VIce) cannot be moved by macOS, so the drag fails and is only logged.
- A screenshot of the bar (screencapture -R) shows the real order; AX frames of MenuBarAgent items update, but identical widths make them hard to tell apart.
