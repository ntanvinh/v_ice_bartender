---
title: "VIce Bartender: Acknowledgements.pdf removed, Acknowledgements.rtf is the only license source"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 3, tokens: 12525 }
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
  - Ice/MenuBar/ControlItem/ControlItem.swift
---

## Decided
Deleted Ice/Resources/Acknowledgements.pdf (English, unused). Nothing in the Swift sources, the Xcode project or the scripts referenced it; the Ghi công pane reads Acknowledgements.rtf only. The build succeeded and the built app's Resources folder now contains only Acknowledgements.rtf (Vietnamese).

## Tried and ruled out
Nothing else. This supersedes the earlier note in 2026-11-13-vice-bartender-acknowledgements-rtf-is-parsed that said the PDF was still in the bundle.

## Watch out
The deletion is not staged or committed (git shows " D"). Restore it from git if the English PDF is needed as a reference.
