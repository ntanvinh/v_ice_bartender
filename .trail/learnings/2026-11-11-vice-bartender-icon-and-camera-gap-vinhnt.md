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
- Added ControlCenterPermission (shown with status dots in the Permissions window and Advanced settings) and Concealer27.requestNativeAccess, which opens the plist directly, retried on app activation.
## Tried and ruled out
- Expecting a prompt: on macOS 27.2 a direct open of ~/Library/Group Containers/group.com.apple.controlcenter/... is denied outright by sandboxd (System Policy deny file-read-data) and shows no dialog, with the screen unlocked too. The same read worked from the agent's own shell, which has Full Disk Access, so that is the expected way through (not yet tried for VIce itself); Grant Permission opens that pane, where VIce is added by hand with +.
- MenuBarClientCore has no API for the Allow in the Menu Bar list (only MBAssessmentMode*, MBMenuBarItemManager, MBLockScreen*), so the plist is the only way.
- Layout window: Ice's own icon was left out on purpose (a tile with no photograph is a hole). It is now listed under Visible by LayoutBarContainer and drawn from the chosen ControlItemImageSet in LayoutBarItemView, never photographed; position by OwnIconSlot27.
- Own icon is always the LAST tile of the Visible bar (OwnIconSlot27.placing), also when the cache has nothing for that section, and falls back to the default icon if a custom one cannot be read. Why: LayoutBarScrollView pins the bar to its right edge, so the left end is what scrolls out of view; the first version put it before the first non-movable item, which is index 0 as soon as a system item (MenuBarAgent-hosted, e.g. Screen Sharing) is leftmost. macOS 27 only: before 27 the Ice icon is a real item whose tile order is its real order (drops use the neighbour as target), so it is not moved.
## Watch out
- Verified 2026-11-12 08:25 on macOS 27.2: once VIce was allowed to read the Control Center group container (user granted it in System Settings and relaunched), the log shows NativeAllowListConcealer27 'Disallowed in the menu bar: ...', the Ellipsis icon stays on the bar while five applications are hidden, and Ice.ControlItem.Visible no longer overlaps a system item. Without access: assessment mode, icon dropped, camera indicator pushed away from the next icon.
- Which exact permission the user turned on (Full Disk Access was what the in-app notice sends them to) was not read back from TCC.
- The `<···>` tile the user asked about is not a VIce item: it is macOS's own Wi-Fi item, which shows the Ethernet glyph while the default route is a wired adapter (here en10, AX88179B). Pressing it in the real bar works (opens the Wi-Fi panel, checked with a synthetic click on 2026-11-12); in the layout window every tile is only a picture and a system tile is non-movable, so a click does nothing by design. AXPress on the MenuBarAgent group is refused (-25206); a real mouse event is needed.
- macOS 27.2 does not report AXIdentifier for MenuBarAgent-hosted items (all empty), so items cannot be named by identifier there; do not rely on `com.apple.menuextra.*`.
- Verified 2026-11-12 on the installed dev build 0.11.15 (macOS 27.2, via Scripts/macos27/layout-ax.swift and a screenshot): the Visible row lists the own icon last, after the clock; hovering a system tile shows its name plus why it cannot be moved. MenuBarAgent-hosted tiles are all named just 'MenuBarAgent' (no identifier on 27.2), so the explanation, not the name, is what tells the user what the tile is.
