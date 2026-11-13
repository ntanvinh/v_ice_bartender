---
title: VIce Bartender screenshot harness (CaptureHarness)
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 16, tokens: 174053 }
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
Pictures come from a DEBUG-only harness, Ice/Utilities/CaptureHarness.swift: run the Debug build with VICE_CAPTURE_DIR=<dir> VICE_CAPTURE_SCENES=icebar,layout,search,hotkeys,appearance. It feeds demo items/images into the real views and snapshots windows parked beyond the displays. Build: xcodebuild ... CODE_SIGNING_ALLOWED=NO PRODUCT_BUNDLE_IDENTIFIER=vn.io.lssoft.vicebartender.capture (own defaults domain, no setup, so the running app is untouched).
## Tried and ruled out
Titled NSWindow off-screen gets pulled back onto a display (1x, visible on the external one): use the CaptureWindow subclass overriding constrainFrameRect. Spacing control does not exist on macOS 27, so that picture needs an older Mac.
## Watch out
Real menu bar, camera indicator and permission states cannot be shown in the isolated instance; they are in captures.json as needs.
