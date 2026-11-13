---
title: "VIce Bartender: macOS 27 picture request already catalogued as macos-27-support"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 1, tokens: 93046 }
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
- The "Works on macOS 27" feature is already in the list as marketing/features/macos-27-support.json (rank 30, unique). Its picture is marketing/screenshots/desktop/06-macos-27-support.png: a created image, 2880x1800, no alpha, showing the app icon, the headline, and a crop of the Advanced window with "Hiding on macOS 27", the Hiding method and the Permissions block.
- The picture is built by marketing/screenshots/seed/macos27-feature-image.swift from the Advanced capture (1560x2200 px, crop at 440,1085 size 1120x655). marketing/screenshots/desktop/captures.json records it as created.
- A request to add the same feature again is a duplicate: do not add a second entry without the user's explicit choice.

## Tried and ruled out
- Adding a new feature file for the request: rejected, the feature exists and the run said not to rewrite existing features.
- Checking the feature list for a missing entry: all 12 JSON files in marketing/features parse; "macos 27" appears only in macos-27-support.json and camera-microphone-indicator.json.

## Watch out
- The request text was cut off after "(Hiding method) a", so its last words could not be matched to the picture; captures.json describes the Permissions block.
- The real macOS 27 menu bar cannot be photographed in the background, so the picture must always be called created.
- marketing/positioning.md and marketing/features/*.json are staged in the git index but were not committed by this session.
