---
title: "VIce Bartender: VOpenKey tile in the layout window looked fine in the running build; report not reproduced"
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 3, tokens: 88436 }
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
- No code changed. In the installed build the VOpenKey tile (vn.io.lssoft.vopenkey:Item-0) in Menu Bar Layout > Visible matched the real bar: white rounded box with the star cut out (Vietnamese mode). The stored tile ItemImages/42e11ea85addca65.png (93x48 px) is the same shape; a small stray white mark sits at its lower left.
- VOpenKey has two template icons: Status.tiff (rounded box with star, Vietnamese) and StatusEng.tiff (striped flag, English). The tile has to change with the typing mode, and the English flag is the one the one-colour keying in ItemImageStore27.withoutBackground is most likely to damage.
- The user's screenshot showed a dark box with a grey star inside a noisy white cloud, which differs from what the running build drew. Cause not found: either English mode, or an older tile that kept bright wallpaper (the tea-field wallpaper survives the colour test).

## Tried and ruled out
- Viewing the stored tile on a dark background (a small Swift compositing script in /tmp) and reading the live window with screencapture: both show a clean tile in Vietnamese mode.
- Clicking in the Settings window with a synthetic CGEvent worked on the second try; the first attempt hit the wrong window and the Settings window closed.
- Did not switch VOpenKey to English: it changes the user's keyboard state, so it was left for the user to allow.

## Watch out
- Reproduce with VOpenKey in English mode, then read the tile in ItemImages and in the layout window before touching ItemImages27.removingBackground or tinted.
- "Language switch position" was read as the V/E icon; the user may have meant clicking the tile to switch, which the layout window does not support.
