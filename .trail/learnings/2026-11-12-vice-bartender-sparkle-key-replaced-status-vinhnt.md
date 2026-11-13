---
title: "VIce Bartender: Sparkle key replaced, status reveal on macOS 27 reads Accessibility text only"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 30, tokens: 93120 }
touches:
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Hotkeys/Hotkey.swift
  - Ice/Main/AppDelegate.swift
  - Ice/Main/AppState.swift
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
  - Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift
  - Ice/MenuBar/MacOS27/Concealer27.swift
---

## Decided
- SUPublicEDKey was Jordan Baird's, so releases could not be signed. A new pair was generated on this Mac (Keychain service https://sparkle-project.org); Info.plist now carries FimZWmagD8zoF1BUYps/MBb9+ytibounCnTIYFouwXg=. Installed builds with the old key will not get auto updates; install the first new release by hand.
- Per-app "show for 10 s when its status changes" on macOS 27 (default on, stored as the exceptions in MacOS27StatusRevealOff): the signal is the text an item publishes through Accessibility (description, title, tooltip). Apps that publish none cannot be watched, so the menu entry is disabled with a reason. Always-Hidden is never revealed. After a reveal the app is quiet for 30 s. Code: Core/StatusChange27.swift (tested), StatusReveal27.swift, the context menu in LayoutBarItemView.

## Tried and ruled out
- Image change detection for hidden items on 27: concealed items are not drawn, so there is nothing to photograph. Measured 2026-11-12: 2 of 9 running items publish any text. Revealing all items briefly to photograph them was rejected (flicker, battery).

## Watch out
- Not run against the real bar: whether a concealed item's Accessibility text still updates is unverified. macOS 14-26 is not done (new-item-to-Visible rule and the reveal).
- A linker failure with no Swift error appeared when swift test and xcodebuild ran together; rebuilt alone it passed.
