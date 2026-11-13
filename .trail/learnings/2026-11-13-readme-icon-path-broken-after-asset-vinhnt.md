---
title: README icon path broken after asset move; Markdown link guard in check-repo.sh
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 2, tokens: 74541 }
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
- The README header icon pointed to Ice/Assets.xcassets/, which has not existed since the assets moved to Ice/Resources/ (commit eb5d14a). README.md:7 now uses Ice/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png.
- Guard: Scripts/check-repo.sh now fails when a local src="..." or ](...) target in any tracked .md file does not exist, resolved from that file's folder. test.sh and release.sh already run this script. .trail/ notes are excluded because their links point into the ignored local cache.
- AGENTS.md "Repository rules" has a line telling whoever moves an asset to update the Markdown that shows it.

## Tried and ruled out
- Scanning every tracked Markdown file: the README icon was the only broken local picture or link. The LICENSE links resolve.
- Searching for the old path in code and docs: no other reference, apart from a comment in check-repo.sh that describes the history.
- Running the guard against the unfixed README first: it failed with "README.md points to 'Ice/Assets.xcassets/...', which is not in the repository", so the check does catch the bug.

## Watch out
- The README download line (VIceBartender.dmg), the first two rules in AGENTS.md "Repository rules", and the download-name check in check-repo.sh were already uncommitted before this change. They are not part of it.
- The link check does not decode percent-encoded paths. A link with a space in its path would be reported as missing.
- No build or swift test was run; the change was checked only with Scripts/check-repo.sh.
- Not committed yet: the README, AGENTS.md, check-repo.sh and this learning need to go into the same commit.
