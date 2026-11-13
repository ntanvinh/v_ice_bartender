---
title: "VIce Bartender: Acknowledgements.rtf is parsed line by line, so keep its layout when translating"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 2, tokens: 220232 }
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
The Ghi công pane (AcknowledgementsSettingsPane.swift) loads Ice/Resources/Acknowledgements.rtf with NSAttributedString and splits the text into lines. Each library starts with a "Name - https://url" line. Every other non-empty line is one paragraph. The license text was translated to Vietnamese in the same layout: the file was rebuilt with the same RTF header and the same title/body structure, and Vietnamese characters were written as \uN? escapes. The check was the same parse with the same six titles and the same line counts per entry, plus a Swift run of NSAttributedString (AppKit) that reads 72 lines and shows the Vietnamese text.

## Tried and ruled out
Editing the RTF in place: the translated paragraphs differ in count, so the layout would break. Rebuilding the whole file from the text is simpler.

## Watch out
Do not put " - https://" in a translated line; that makes it a title. The English heading and intro (lines 1-2) are not shown in the pane. Acknowledgements.pdf is still in the bundle, is English, and is no longer used. The license texts are translated for reading; the English originals should still be the reference for legal purposes. Not run in the app.
