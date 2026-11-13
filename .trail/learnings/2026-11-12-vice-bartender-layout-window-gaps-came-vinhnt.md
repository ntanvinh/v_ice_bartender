---
title: "VIce Bartender: layout window gaps came from undrawn items and lost tile files; version 1.0.0"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 27, tokens: 278088 }
touches:
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Hotkeys/Hotkey.swift
  - Ice/Main/AppDelegate.swift
  - Ice/Main/AppState.swift
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarContainer.swift
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
  - Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift
---

## Decided
- The blank gaps in the Visible row of Menu Bar Layout (macOS 27) were tiles of items Accessibility lists but MenuBarAgent does not draw (the VPN item, com.apple.systemuiserver, w=22, with its switch off), whose stored picture was also gone. LayoutBarContainer.isHole now leaves such a tile out of the Visible row only (an imageless item that is not on screen or not listed in MenuBarItemProvider27.barFrames). Hidden rows keep imageless tiles so a hidden app can always be moved back. The row is worked out again, one main-queue turn after $images speaks, when pictures arrive.
- ItemImageStore27: all disk writes/removals go through one serial queue (a removal of a refused tile could land after the write of its replacement under the same file name, leaving index entries with no file: 6 of 22 on 2026-11-12). image(for:) forgets an index entry whose file is missing, so the next capture replaces it. Phantom frames (not listed on the bar) are no longer photographed and no longer count in the overlap test.
- Dimmed tiles (disabledFraction 0.35) are intentional; the battery pill looks like a grey box because of it. The glyph is recoloured to one colour, so the purple screen item looks plain in the window.
- Version is now 1.0.0 (build 1128) via Scripts/version.sh bump major; its generated CHANGELOG entry just repeats old commit subjects, so the 1.0.0 entry was rewritten by hand.

## Tried and ruled out
- Running Scripts/macos27/verify-layout.sh: it quits Ice and rewrites the layout. Instead the layout window was opened by reopening the installed app, and read with Scripts/macos27/layout-ax.swift (add f.width to the label to tell blank tiles by width).

## Watch out
- The fix was built and unit tested (229 pass) but not looked at in a running window: the installed dev build was not replaced. Install with Scripts/dev.sh and open Menu Bar Layout to confirm the gaps are gone.
- Which tile is which was matched by width and order, not by an exact frame match; the gap after Wi-Fi may be a second undrawn system item.
