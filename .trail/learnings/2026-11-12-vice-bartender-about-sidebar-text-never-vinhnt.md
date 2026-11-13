---
title: "VIce Bartender: About/sidebar text never wraps, copyright credit, donate thanks"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 5, tokens: 92124 }
touches:
  - Ice.xcodeproj/project.pbxproj
  - Ice/Settings/SettingsPanes/AboutSettingsPane.swift
  - Ice/Settings/SettingsView.swift
  - Ice/Utilities/Defaults.swift
  - Scripts/test.sh
  - AGENTS.md
  - Ice/Resources/Assets.xcassets/LSSLogo.imageset/Contents.json
  - Ice/Resources/Assets.xcassets/LSSLogo.imageset/lss-logo.png
  - Ice/Settings/SettingsPanes/DonationInfo.swift
  - Scripts/check-repo.sh
---

## Decided
- Copyright: GPL-3.0 requires keeping Jordan Baird's notice, so it is not replaced by LSSoft. About shows "Developed by LSSoft", "Based on Ice by Jordan Baird" (link) and "© 2025 Jordan Baird · © 2026 LSSoft · GPL-3.0"; Info.plist (INFOPLIST_KEY_NSHumanReadableCopyright, 2 places in project.pbxproj) says "Copyright © 2025 Jordan Baird. Modifications © 2026 LSSoft. GPL-3.0."
- Text never wraps: sidebar title is 1.5x row font with lineLimit(1) + minimumScaleFactor; About name is 42pt single line; the bottom bar is a ViewThatFits (all links when wide, "More" menu when narrow) because the five buttons need about 580pt and the pane has about 549pt at the minimum window width.
- Donate thanks: the app cannot verify transfers, so the sheet has "I've donated", which stores Defaults.Key.hasDonated (HasDonated); About shows "Thank you for your support." only then, and never asks again. The original author's donate link moved from the bottom bar into the donate sheet.

## Tried and ruled out
- Launching the build to look at it: the user's own dev build is already running from ~/Applications, so a second instance was not started; widths were measured with NSAttributedString instead.

## Watch out
- Not looked at in the running app (light/dark, minimum window width, the More menu style with BottomBarButtonStyle, QR scan). Run Scripts/dev.sh --no-bump to see it.
- Scripts/test.sh fails its repository check while .trail/cache and graft files are tracked; the build itself passes.
