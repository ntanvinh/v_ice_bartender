---
title: "VIce Bartender: how to find untranslated UI strings (Vietnamese catalog audit)"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 6, tokens: 205779 }
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
Find untranslated text by building with a clean derived data path (-derivedDataPath) and reading the *.stringsdata files under Build/Intermediates.noindex/**/Ice.build. Each file's "tables" lists every key the compiler saw as a LocalizedStringKey or String(localized:). Compare those keys with Ice/Resources/Localizable.xcstrings. Xcode did not write new keys back into the catalog on build, so the missing ones were added by hand, with vi translations. Plain String values (not LocalizedStringKey) are not in stringsdata; wrap them in String(localized:) so the catalog is used at runtime.

## Tried and ruled out
A line-based regex over Swift literals: it flagged many log messages and missed multi-line """ strings. Use the stringsdata check first, then a context-filtered scan for the rest.

## Watch out
Not translated on purpose: product and feature names (Ice Bar, VIce Bartender, Ice), bank data and the donation transfer note (it is used to reconcile payments), internal identifiers, debug-only and logging strings, and macOS item names taken from the system (Clock, Siri, Text Input, VPN, Spotlight). The Acknowledgements license texts (Acknowledgements.rtf) are still English. The menu-bar overlay panel title is never shown. The stringsdata check does not catch the four bare characters 1, 2, 3 and •, which need no translation.
