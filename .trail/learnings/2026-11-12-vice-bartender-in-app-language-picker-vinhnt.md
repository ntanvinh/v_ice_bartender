---
title: VIce Bartender in-app language picker (en/vi) in General settings
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 3, tokens: 38655 }
touches:
  - CHANGELOG.md
  - Ice.xcodeproj/project.pbxproj
  - Ice/Hotkeys/Hotkey.swift
  - Ice/Main/AppDelegate.swift
  - Ice/Main/AppState.swift
  - Ice/Main/Navigation/NavigationIdentifiers/SettingsNavigationIdentifier.swift
  - Ice/Main/Updates.swift
  - Ice/MenuBar/ControlItem/ControlItem.swift
  - Ice/MenuBar/IceBar/IceBar.swift
  - Ice/MenuBar/LayoutBar/LayoutBarContainer.swift
---

## Decided
The app already had full Vietnamese strings (Ice/Resources/Localizable.xcstrings, 238 keys, all "vi") but no way to choose a language: it followed the system. Added a Language picker (System / English / Tiếng Việt) under "Launch at login" in GeneralSettingsPane.swift. It writes the app's own AppleLanguages default (plus an AppLanguageChosen marker) and needs a restart; a "Restart now" button opens a new instance via NSWorkspace and terminates the old one. AppLanguage.launched is a static snapshot, so the restart hint stays after the value changes. New strings were added to the catalog with vi translations.

## Tried and ruled out
Reading AppleLanguages live to decide whether a restart is due: apply() changes it at once, so the hint would vanish. Hence the launch-time snapshot.

## Watch out
Debug build passed, but the picker and the restart were never run or looked at. Localizable.xcstrings is untracked in git. The catalog was rewritten through Python json with sorted keys, so the first commit of it is large.
