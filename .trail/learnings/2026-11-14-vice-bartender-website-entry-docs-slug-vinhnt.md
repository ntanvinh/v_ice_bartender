---
title: "VIce Bartender: website entry docs/<slug>/product.json and the slug choice"
author: Vinhnt
date: 2026-11-14
branch: main
cost: { minutes: 3, tokens: 126518 }
touches:
  - Ice/MenuBar/LayoutBar/LayoutBarItemView.swift
  - Ice/Utilities/CaptureHarness.swift
  - Scripts/release.sh
  - marketing/features/drag-and-drop-layout.json
  - marketing/features/keyboard-shortcuts.json
  - marketing/features/macos-27-support.json
  - marketing/features/menu-bar-appearance.json
  - marketing/features/search-menu-bar-items.json
  - marketing/screenshots/desktop/01-ice-bar.png
  - marketing/screenshots/desktop/02-drag-and-drop-layout.png
---

## Decided
- The Setup checklist item "Website entry" counts as done when docs/<slug>/product.json exists. I used slug = v-ice-bartender, the `slug` field of marketing/product.json, and created docs/v-ice-bartender/product.json as a byte-identical copy of marketing/website/product.json. This is an assumption: the other field, websiteSlug = vice-bartender, would need its own folder.
- marketing/website/product.json already met the P-04 numeric rules (title 50/53 characters, descriptions 150/151, 10 unique keywords per language, Ice credited as GPL-3.0 from LICENSE and README), so it was left unchanged.

## Tried and ruled out
- No website exporter exists in the repo (Scripts/ has none), so nothing copies marketing/website into docs/. The copy was made by hand.
- Only marketing/product.json defines slug and websiteSlug; no other file references either.
- The placeholder scan hits were JSON brackets only. No TODO, TBD or template text in the website copy.
- Scripts/check-repo.sh passes with the new docs/ folder.

## Watch out
- docs/v-ice-bartender/product.json is a copy: edit marketing/website/product.json and the docs copy drifts unless both are updated.
- marketing/product.json still has "#" for appStore, googlePlay, website, macos, windows and linux. privacyPolicy is "/privacy", and the repo has no privacy document. The README's releases/latest link has no release yet (checklist E5 and E6), so it would not work.
- The VApp Manager checklist rule itself was not read, since that is outside the project folder. The slug choice rests on the item text only.
- jsonschema is not installed here, so the schema check was done by reading the schema.
