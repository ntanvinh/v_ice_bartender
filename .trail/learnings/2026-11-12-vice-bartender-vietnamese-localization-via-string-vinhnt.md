---
title: VIce Bartender Vietnamese localization via String Catalog
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 29, tokens: 240943 }
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
Vietnamese added with Ice/Resources/Localizable.xcstrings (source en, vi translated) and `vi` in knownRegions of Ice.xcodeproj. The app follows the system language by default, no in-app switch. SwiftUI literals localize on their own; AppKit strings (NSMenuItem titles, NSAlert text, notification text, error messages) were wrapped in String(localized:). Strings passed as plain String to Text (permission titles/details, section names, icon set names) were changed to LocalizedStringKey. Interpolated keys use %@ (Strings) or %lld (Int).
## Tried and ruled out
`xcodebuild -exportLocalizations` hangs for over 10 minutes here; skip it and build the catalog from source with a script instead.
## Watch out
Keys with \u{...} escapes must be stored in the catalog as the real character. Keys were entered by hand (extractionState manual), so new UI strings need a catalog entry too. Build and a look at the app under a Vietnamese system language were not verified when this was written; the load average was 44 and the build was slow. Scripts/test.sh reports tracked .trail cache files as an error before building.
