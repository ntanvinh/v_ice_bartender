---
title: "VIce Bartender: About section, LSSoft credit and donate sheet"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 4, tokens: 56676 }
touches:
  - Ice/Settings/SettingsPanes/AboutSettingsPane.swift
  - Scripts/test.sh
  - AGENTS.md
  - Ice/Resources/Assets.xcassets/LSSLogo.imageset/Contents.json
  - Ice/Resources/Assets.xcassets/LSSLogo.imageset/lss-logo.png
  - Ice/Settings/SettingsPanes/DonationInfo.swift
  - Scripts/check-repo.sh
  - Ice/Main/AppState.swift
  - Ice/MenuBar/LayoutBar/LayoutBarContainer.swift
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
---

## Decided
- Project is GPL-3.0 (Ice by Jordan Baird): rename/rebrand/donate are allowed, but distributing the app means giving recipients the source; keep upstream copyright and a "Based on Ice" credit in About.
- About copies VMonitor AI (project v_screen, not a folder named vmonitor): LSSoft logo + Developer/Website/Contact rows, from v_screen/apps/desktop/src/renderer/features/settings/SettingsScreen.tsx.
- Donate sheet (Ice/Settings/SettingsPanes/DonationInfo.swift) reuses the recipients in v_screen/marketing/pricing/pricing.json (VPBank VietQR + PayPal). VietQR payload and CRC ported from v_screen/apps/desktop/src/shared/donation.ts; checksum verified equal (FA7A).

## Tried and ruled out
- Searching for a "vmonitor" folder: none exists; it is v_screen.
- The monetization skill (tiers, ad removal) is for mobile store apps; not applied to this macOS app.

## Watch out
- Debug build passes but About/Donate were never run or looked at (light/dark, window height, QR scan).
- Ice.xcodeproj uses synchronized folders, so new files and assets need no pbxproj edit.
- BSD sed needs `-i ''`.
