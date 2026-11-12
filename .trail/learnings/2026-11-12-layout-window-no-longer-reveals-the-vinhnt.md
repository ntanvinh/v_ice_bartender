---
title: Layout window no longer reveals the real menu bar on macOS 27
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 7, tokens: 209327 }
touches:
  - Ice/MenuBar/MacOS27/Concealer27.swift
  - Scripts/macos27/verify-layout.sh
---

## Decided
- Concealer27.revealState no longer returns .allRevealed while Settings is open on Menu Bar Layout. That case revealed every item for as long as the window was open, so the real bar lost its Visible/Hidden split and a drag between the rows showed nothing until the window closed (reported 2026-11-12). The bar now follows Ice's sections only, so LayoutBarPaddingView.performDragOperation -> Concealer27.setSection -> update() moves the application on the real bar at once.
- Removed the isSettingsPresented/settingsNavigationIdentifier sink in Concealer27.performSetup, which only existed to call update() for that case. RevealState27.allRevealed stays (the always-hidden section being open still uses it).
- Tiles with no image yet are photographed by ItemImageStore27.photographMissing, which shows one application at a time for a moment, as it already did for the Ice Bar.
- Scripts/macos27/verify-layout.sh now expects the real bar to be unchanged when the window opens and the drop to show on the bar with the window still open.
## Tried and ruled out
- Nothing else tried: the cause was read from the code, not measured on the bar.
## Watch out
- Verified by build (xcodebuild Debug, CODE_SIGNING_ALLOWED=NO) and swift test (195 tests) only. NOT run on the real bar: verify-layout.sh needs the installed app and the mouse, and its new checks (after-drop, bar unchanged on open) have not been run once.
- Items never photographed will flash on the real bar one at a time when the layout window opens, because photographMissing shows their application for a moment.
