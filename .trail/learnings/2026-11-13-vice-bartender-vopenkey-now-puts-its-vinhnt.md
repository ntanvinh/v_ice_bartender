---
title: "VIce Bartender: VOpenKey now puts its typing language in the tray icon's accessibility label, so Ice can reveal on a V/E switch"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 3, tokens: 43161 }
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
  - Ice/MenuBar/Appearance/MenuBarAppearanceEditor/MenuBarAppearanceEditor.swift
---

## Decided
- The V/E switch changed only the image, so Ice's text-based status reveal could not see it (see the Caps Lock learning of 2026-11-13). With the owner's agreement (2026-11-13) the fix was made in the VOpenKey repo (v_open_key, not this one): VOKStatusAccessibilityLabel in ModernKey/VOKUI.m builds the label, StatusMenuController.refresh sets it. Labels now: "VOpenKey AI, Tiếng Việt" / "VOpenKey AI, English", with ", Caps Lock đang bật" appended while Caps Lock is on; with Secure Input forcing English the old "VOpenKey AI: Secure Input đang bật, …" text is kept.
- Ice shows an application's name from its localized name, not from the item's description, so the longer label does not change any name in Ice.
- Test: tests/capslock_test.m TestStatusLabel (red before the function existed, green after); run-capslock-test.sh ALL OK. The full app builds unsigned (xcodebuild, Debug).

## Tried and ruled out
- scripts/dev.sh in v_open_key bumps the patch version and replaces the installed ~/Applications/VOpenKey AI.app, which is the owner's live keyboard input method; a second copy from a build folder would run a second event tap. So the new label was not run live against Ice.

## Watch out
- Not verified live: Ice revealing on a real V/E switch. It needs the new VOpenKey installed; the mechanism is the one already measured for Caps Lock (the same accessibilityLabel property showed up as AXDescription while the item was concealed).
- Ice's reveal rule counts every text change, so a V/E flip counts toward the six-in-60-seconds limit like a Caps Lock press.
