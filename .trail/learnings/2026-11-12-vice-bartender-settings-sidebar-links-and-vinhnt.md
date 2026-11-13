---
title: "VIce Bartender: settings sidebar links and in-app Acknowledgements"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 5, tokens: 58970 }
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
Removed the About bottom bar and the Contribute button. Acknowledgements (new SettingsNavigationIdentifier case, excluded from `mainPanes`), Report a Bug, Donate and Quit are now vertical rows in a second sidebar Section in SettingsView. Acknowledgements renders in-app from the bundled Acknowledgements.rtf, with the original author (Ice by Jordan Baird, GPL-3.0, donate link) shown first. Acknowledgements.rtf was removed from the pbxproj membershipExceptions so it is bundled.

## Tried and ruled out
Nothing else tried. Acknowledgements.pdf is now unused but was not deleted.

## Watch out
Debug build passed, but the sidebar and the new pane were never run or looked at (light/dark, short window). Sidebar `.scrollDisabled(true)` was removed so extra rows can scroll. Nothing committed.
