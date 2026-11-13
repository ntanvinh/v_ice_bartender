---
title: VIce Bartender macOS 27 feature picture is a created image
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 9, tokens: 163354 }
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
Feature "Works on macOS 27 too" has no raw screenshot: the real macOS 27 menu bar cannot be shown from the isolated capture instance. The picture is created on purpose, as the person asked: marketing/screenshots/desktop/06-macos-27-support.png, 2880x1800 (16:10), PNG without alpha, with the app icon, the headline and a crop of the real Advanced window ("Hiding on macOS 27" + Permissions). Rebuild it with marketing/screenshots/seed/macos27-feature-image.swift; the source render comes from CaptureHarness scene `advanced` (780x1100 window).
captures.json says plainly that it is a created image. marketing/screenshots/features.json is approved and was not touched: the person adds the feature in "Features and order" and may renumber 06.

## Tried and ruled out
Advanced window at 1000 wide: the macOS 27 part came out small and unreadable in a thumbnail. Run the harness with `-AppleLanguages "(en)" -AppleLocale en_US`, otherwise a Vietnamese Mac prints "0,2 seconds".

## Watch out
The crop in the script is fixed pixels (440,1085,1120x655 of a 1560x2200 capture); it exits when the capture size changes, check the crop then. Not shown, on purpose: the Ice Bar and search on macOS 27, since no claim about them was verified.
