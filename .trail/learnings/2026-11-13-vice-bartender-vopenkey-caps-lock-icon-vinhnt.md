---
title: "VIce Bartender: VOpenKey caps-lock icon not always revealed — 30 s cooldown and 5 s scan, fixed with a count rule and a 0.5 s reader"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 23, tokens: 288307 }
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
- Symptom (user, 2026-11-13): toggling Caps Lock in VOpenKey changes its tray icon colour, but the hidden item was sometimes revealed and sometimes not.
- Causes, measured on macOS 27.2 with the installed dev build: (1) StatusChange27 kept an item quiet for 30 s after each 10 s reveal, so a second press inside 40 s was swallowed (log: reveal 14:37:06, next 14:37:46 = +40 s; a pulse 16 s after the first showed nothing). (2) Status text was read only by the full Accessibility scan, about every 5 s, so a short on/off could be missed. (3) Not fixable here: the language switch V/E changes only the image, VOpenKey's label stays "VOpenKey AI".
- VOpenKey (v_open_key 3.7.26, StatusMenuController.m refresh) sets accessibilityLabel to "VOpenKey AI, Caps Lock đang bật" while Caps Lock is on, and the tooltip to the same text. That is the whole signal Ice can see. Reading a concealed item's Accessibility text works: the label changed while the item was concealed.
- Fix: StatusChange27.recordChange replaces the cooldown: every change is shown, a change while shown restarts the 10 s timer (one show, one end), and only more than chattyLimit = 6 changes in 60 s (ignored changes still count) marks a ticker that is left alone. StatusReveal27.startWatching reads hidden, enabled, detectable apps every 0.5 s (2 s when none) through MenuBarItemProvider27.statusTexts(of:), which reads the stored elements of the last scan on its own queue and leaves an app out if any item did not answer. The scan's text is ignored for an app the quick read answered in the last 3 s, so two readers of different age do not report a change back.
- Checked live on the final build: Caps Lock pulse A shown in 0.1 s, kept shown by the second change, hidden 10 s after the last; pulse B 13 s later (2.6 s after the hide) shown in 0.07 s; 100 s with no toggle gave no reveal. 243 unit tests pass; with chattyLimit = 1 three of the new tests fail.

## Tried and ruled out
- Photographing or image-diffing a concealed item: nothing is drawn (see the earlier learning on status reveal).
- A 30 s style cooldown for chatty apps: it is what hid the second toggle.
- Test input: IOHIDSetModifierLockState(kIOHIDCapsLockState, true) from a small Swift tool turns Caps Lock on for only about a second (VOpenKey polls modifier flags every 0.3 s and sees on, then off), so each pulse is two text changes. A held state was not found. `log show` needs /usr/bin/log (zsh has a builtin `log`), and the Showing lines are info level but do appear in `log show --info`.

## Watch out
- Not tested: a real key press (only the synthetic pulses), the V/E language switch (undetectable until VOpenKey puts the language in its accessibility label), macOS 14-26, a second display. CPU of the quick read was not isolated: a 6 s `sample` showed no samples in it against dozens in the old scan.
- Scripts/test.sh still reports "some checks failed" from check-repo.sh because .trail/cache files are tracked; unrelated.
