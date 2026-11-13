---
title: "VIce Bartender: Settings window rebuilt on native grouped Form and standard sidebar"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 15, tokens: 212726 }
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
IceForm/IceSection/IcePicker/IceSlider/IceMenu are now thin wrappers over Form(.grouped), Section, Picker(.menu), Slider and Menu; IceGroupBox was deleted and CalloutBox is a plain Label row. Sidebar is a standard List(.sidebar) with System-Settings style coloured icon tiles (SettingsNavigationIdentifier.tint) that scale with the system sidebar icon size; the big "VIce Bartender" title and manual fonts are gone. IceSlider snaps in its Binding instead of using Slider(step:) because step draws a tick per step (a dotted line on 0...60). The CaptureHarness has scenes general, about, acknowledgements and settings-advanced/-layout/-appearance/-hotkeys, VICE_CAPTURE_APPEARANCE=light and VICE_CAPTURE_WIDTH/HEIGHT, to look at every pane.
## Tried and ruled out
listRowBackground / listRowInsets are ignored by a grouped Form on macOS 27, so the About hero and the layout bars stay inside a card. CompactSlider is no longer used by code but is still linked and credited in Acknowledgements.rtf.
## Watch out
Not looked at: the floating Appearance editor panel (location .panel), the macOS 26 spacing control (the app runs 27 here), VoiceOver, a real (active) window; captures are of an inactive window so the sidebar looks grey.
