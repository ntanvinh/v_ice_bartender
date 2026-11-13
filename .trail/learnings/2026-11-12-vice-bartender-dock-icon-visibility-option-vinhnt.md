---
title: VIce Bartender Dock icon visibility option
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 29, tokens: 229801 }
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
- Keep Dock icon visibility separate from the menu bar status item. Persist `ShowAppIconInDock`, apply changes immediately, and suppress regular activation when disabled.

## Tried and ruled out
- None.

## Watch out
- Default to showing the Dock icon to preserve existing behavior. Keep the menu bar icon's own visibility setting independent.
- This change was verified by reading source only; Dock visibility was not exercised in the running app.
