---
title: "VIce Bartender: desktop pictures retaken on the rebuilt Settings; status-reveal already in code"
author: Vinhnt
date: 2026-11-14
branch: main
cost: { minutes: 7, tokens: 266610 }
touches:
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
  - Ice/Utilities/CaptureHarness.swift
  - Scripts/release.sh
  - marketing/screenshots/desktop/01-ice-bar.png
  - marketing/screenshots/desktop/02-drag-and-drop-layout.png
  - marketing/screenshots/desktop/03-search-menu-bar-items.png
  - marketing/screenshots/desktop/04-menu-bar-appearance.png
  - marketing/screenshots/desktop/05-keyboard-shortcuts.png
  - marketing/screenshots/desktop/06-macos-27-support.png
  - marketing/screenshots/desktop/captures.json
---

## Decided
- The "show hidden icon when its status changes" function already exists on macOS 27: StatusChange27 and StatusReveal27 (Ice/MenuBar/MacOS27/), per app, on by default, 10 seconds, switched from the right-click menu of a tile in Menu Bar Layout; a bell badge marks the tile. It is now the catalogued feature show-on-status-change (unique, rank 25, position 3), marketing/features/show-on-status-change.json.
- Pictures retaken with a separate capture build (bundle id vn.io.lssoft.vicebartender.capture, derived data in build/, not committed): 01 Ice Bar, 02 Menu Bar Layout, 03 search, 04 appearance, 05 hotkeys, 06 macOS 27 created image recut from the rebuilt Advanced window (crop 480,1200, 1080x650), 07 status-change marker. marketing/screenshots/seed/captured-desktop/ holds the raw renders.
- Picture 07 is inUse false in captures.json: the reveal itself cannot be shown with demo items.

## Tried and ruled out
- Harness badge with demo items: the badge needs item.sourceApplication (a running app), so demo tiles never show it. A DEBUG-only seam in LayoutBarItemView (CaptureHarness.marksStatusDemo) marks one demo tile; the badge is still drawn by the app's own code.
- Context-menu capture: menu(for:) needs the same sourceApplication, so the menu is not in any picture.

## Watch out
- marketing/screenshots/features.json is approved and was not edited: macos-27-support and show-on-status-change are missing from it, so the screenshot tab does not list them until added in VApp Manager.
- Pictures 02 and 03 are of an inactive window (grey sidebar, grey traffic lights).
- File 03-search and the new file are named by old featured order; the new picture is 07 and its position comes from rank 25.
- Two Swift DEBUG-only edits (CaptureHarness.swift, LayoutBarItemView.swift) are uncommitted.
