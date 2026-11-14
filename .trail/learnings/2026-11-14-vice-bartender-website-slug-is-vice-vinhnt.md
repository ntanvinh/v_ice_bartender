---
title: "VIce Bartender: website slug is vice-bartender and the macOS link is the direct DMG"
author: Vinhnt
date: 2026-11-14
branch: main
cost: { minutes: 1, tokens: 23439 }
touches:
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
  - Ice/Utilities/CaptureHarness.swift
  - Scripts/release.sh
  - marketing/features/drag-and-drop-layout.json
  - marketing/features/keyboard-shortcuts.json
  - marketing/features/macos-27-support.json
  - marketing/features/menu-bar-appearance.json
  - marketing/features/search-menu-bar-items.json
  - marketing/product.json
  - marketing/screenshots/desktop/01-ice-bar.png
---

## Decided
- The website folder for the product entry is docs/vice-bartender/ (the `websiteSlug` in marketing/product.json), not docs/v-ice-bartender/. The file there is a byte-identical copy of marketing/website/product.json, which stays the source. This replaces the earlier assumption that the item uses the product `slug`.
- The macOS download link (`links.macos` in marketing/product.json) points straight to the file: https://github.com/ntanvinh/v_ice_bartender/releases/latest/download/VIceBartender.dmg. It does not point to the releases page. Scripts/release.sh (around line 290) attaches the unversioned DMG to every release for this link.
- The other links (appStore, googlePlay, website, windows, linux) stay "#": no URL is known for them.

## Tried and ruled out
- The releases/latest web page as the download link: the user asked for the direct file instead.

## Watch out
- The direct link returns 404 until the first release with VIceBartender.dmg is published (the parity checklist, items E5 and E6, says no release exists yet). The link was not tested against GitHub.
- docs/vice-bartender/product.json must be updated with marketing/website/product.json whenever the copy changes; nothing syncs them.
