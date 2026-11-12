---
title: "VIce Bartender: icon and camera gap on macOS 27.2 come from assessment mode"
author: Vinhnt
date: 2026-11-11
branch: macos-27
cost: { minutes: 1, tokens: 1424 }
touches:
  - Ice.xcodeproj/project.pbxproj
  - Ice/Main/AppState.swift
  - Ice/MenuBar/ControlItem/ControlItemImageSet.swift
  - Ice/MenuBar/MacOS27/Concealer27.swift
  - Ice/MenuBar/MacOS27/Core/ItemDrawing27.swift
  - Ice/MenuBar/MacOS27/MenuBarItemProvider27.swift
  - Ice/MenuBar/MacOS27/NativeAllowListConcealer27.swift
  - Ice/Permissions/AppPermissions.swift
  - Ice/Permissions/Permission.swift
  - Ice/Permissions/PermissionsView.swift
---

## Decided
- Root cause of the missing menu bar icon: on macOS 27.2 the app cannot read group.com.apple.controlcenter (cfprefsd logs 'requires user-preference-read or file-read-data sandbox access'; TCC kTCCServiceSystemPolicyAppDataDetailed 'would require user interaction'). NativeAllowListConcealer27.isAvailable is false, so Concealer27 falls back to assessment mode, where MenuBarAgent drops items of locally signed apps (VIce's own icon, VOpenKey AI) but their processes still report frames through AX.
- The camera indicator gap: CaptureIndicator27 sits left of MenuBarItemProvider27.leftEdge, which counted the dropped apps' phantom frames. Fix: ItemDrawing27.isListed keeps only items the MenuBarAgent bar window lists (probe: AXWindows of com.apple.MenuBarAgent, children frames).
- Added ControlCenterPermission (shown with status dots in the Permissions window and Advanced settings) and Concealer27.requestNativeAccess, which opens the plist directly so macOS can ask, retried on app activation.
## Tried and ruled out
- A direct open at launch while the screen is locked returns false at once and shows no prompt, so launch alone is not enough.
## Watch out
- Never verified that the prompt appears and that native mode brings the icon back: the screen was locked during the session. Check with: log show --predicate 'subsystem == "vn.io.lssoft.vicebartender" AND category == "Concealer27"' and the AX probe of VIce's own AXExtrasMenuBar (Ice.ControlItem.Visible must be on the built-in display).
