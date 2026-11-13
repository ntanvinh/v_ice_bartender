---
title: VIce Bartender screenshot feature list draft
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 1, tokens: 32203 }
touches:
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarPaddingView.swift
  - Ice/Settings/SettingsPanes/AboutSettingsPane.swift
  - Ice/Settings/SettingsView.swift
  - Ice/Utilities/Defaults.swift
  - README.md
  - Scripts/test.sh
---

## Decided
Draft at marketing/screenshots/features.json: 9 features, dark theme (app has no own theme setting; follows system appearance). Order: hide items, Ice Bar, layout, search, appearance, hotkeys, camera indicator, macOS 27 support, spacing.

## Tried and ruled out
flexible-show-triggers, auto-rehide, launch-at-login left out: only General toggles, nothing to show in use. Nothing was built or run in this step.

## Watch out
camera-microphone-indicator needs macOS 27.2 with Control Center access and camera in use; may end up inUse:false. macos-27-support must use a different screen than the layout picture.
