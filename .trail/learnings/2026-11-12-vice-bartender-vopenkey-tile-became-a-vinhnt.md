---
title: "VIce Bartender: VOpenKey tile became a wallpaper cloud because dark wallpaper outvoted the glyph tone"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 10, tokens: 62133 }
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
- Cause (strong evidence, not the user's exact bad frame): ItemImages27.toneVotes counted pixels within 55 of white/black. The wallpaper is a live aerial video of tea fields; across the bar 68,349 px were within 55 of black vs 7,405 within 55 of white, yet glyphs are pure 255 (only 288 within 15 of black vs 3,667 within 15 of white). On a dark frame the bar was judged "dark glyphs", removingBackground keyed the wallpaper instead of the glyph, and the big VOpenKey box came out as a noisy cloud around a box-shaped hole. Forcing tone .dark in an offline harness reproduced exactly that picture.
- Fix: toneVotes now uses toneVoteMargin = 12 (pure white/black only); ItemImageStore27.storeVersion 9 -> 10 so stored bad tiles are recaptured. New test darkWallpaperDoesNotOutvoteTheGlyph in Plan2Core27Tests. 230 unit tests pass, Debug build succeeds.
- The per-tile tone fallback (tone nil) still uses extremeMargin 55; it only runs when no pure pixel exists on the whole bar.

## Tried and ruled out
- The tile was fine in the running build when captured at 17:09 (static frame), so the bug is frame dependent; a tile cannot be judged from one capture.
- Offline harness: compile ItemImages27.swift with a small main.swift, screencapture -R <item x,y,w,h> (frames from Scripts/macos27/ax-items.swift) and run removingBackground with tone light/dark.

## Watch out
- Black glyphs on a light bar were not available to test; the margin 12 assumes MenuBarAgent draws them in pure black too. If a light bar loses its tone, the tone falls back to nil (per tile), not to a wrong global tone.
- Not yet looked at in the running window: the installed dev build was not replaced (Scripts/dev.sh). English mode (striped flag icon) was not tried.
- Scripts/test.sh reports "some checks failed" from check-repo.sh because .trail/cache files are tracked; unrelated to this change.
