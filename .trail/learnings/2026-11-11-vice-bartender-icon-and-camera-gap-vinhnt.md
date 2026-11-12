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
- Own icon in the layout window stands where it is on the bar (OwnIconSlot27.placing with MenuBarItemProvider27.ownIconMinX), i.e. before Control Center and the clock, after the user switcher; last when its frame was not read. Not 'always last' and not 'before the first non-movable item' (index 0 as soon as a system item is leftmost, so a long list scrolls it out). Its preferred position is already 0 (defaults key NSStatusItem Preferred Position Ice.ControlItem.Visible), the rightmost slot third-party items get; every third-party item on the bar sits left of Control Center. Dragging it past Control Center was NOT tried.
## Watch out
- Verified 2026-11-12 08:25 on macOS 27.2: once VIce was allowed to read the Control Center group container (user granted it in System Settings and relaunched), the log shows NativeAllowListConcealer27 'Disallowed in the menu bar: ...', the Ellipsis icon stays on the bar while five applications are hidden, and Ice.ControlItem.Visible no longer overlaps a system item. Without access: assessment mode, icon dropped, camera indicator pushed away from the next icon.
- Which exact permission the user turned on (Full Disk Access was what the in-app notice sends them to) was not read back from TCC.
- The `<···>` tile the user asked about is not a VIce item: it is macOS's own Wi-Fi item, which shows the Ethernet glyph while the default route is a wired adapter (here en10, AX88179B). Pressing it in the real bar works (opens the Wi-Fi panel, checked with a synthetic click on 2026-11-12); in the layout window every tile is only a picture and a system tile is non-movable, so a click does nothing by design. AXPress on the MenuBarAgent group is refused (-25206); a real mouse event is needed.
- macOS 27.2 does not report AXIdentifier for MenuBarAgent-hosted items (all empty), so items cannot be named by identifier there; do not rely on `com.apple.menuextra.*`.
- Verified 2026-11-12 on the installed dev build 0.11.15 (macOS 27.2, via Scripts/macos27/layout-ax.swift and a screenshot): the Visible row lists the own icon last, after the clock; hovering a system tile shows its name plus why it cannot be moved. MenuBarAgent-hosted tiles are all named just 'MenuBarAgent' (no identifier on 27.2), so the explanation, not the name, is what tells the user what the tile is.
- iTerm2 stayed on the bar although its switch was off (2026-11-12, 27.2): MenuBarAgent finds a switch by the locations the switch lists, and iTerm2's entry listed only a Chrome for Testing binary from ms-playwright (launched from iTerm2), not iTerm2's own bundle. Appending {"bundle":{"_0":"com.googlecode.iterm2"}} to that entry's menuItemLocations hid the icon at once. NativeAllowListConcealer27.apply now does this for the applications it hides (TrackedApplications27.registeringItem, only when no location is the owner's bundle or a binary inside the owner's bundle; applications signed on this Mac list a binary inside their own bundle and are left alone). Verified on a restored copy of the old list: the log said 'Listed the menu bar item of the switch macOS kept without it: com.googlecode.iterm2' and the icon went. This is the one place Ice edits MenuBarAgent's data besides isAllowed.
- System Settings > Menu Bar > Menu Bar Controls has the switches (AX ids controlcenter-<name>-id: siri, spotlight, wifi, bluetooth, battery, airdrop, focus, screenMirroring, display, sound, nowPlaying, userSwitcher, textInput, timeMachine, keyboardBrightness, vpn, timer, weather). Pressing 'Spotlight' removed the Search icon (campo) and deleted the key 'NSStatusItem VisibleCC Item-0' from com.apple.campo; writing that key to 0 by hand did nothing, even after restarting the Siri agent. Pane URL: x-apple.systempreferences:com.apple.ControlCenter-Settings.extension (opens on Menu Bar).
- Text Input (com.apple.TextInputMenuAgent), the VPN item (com.apple.systemuiserver) and the Search item (com.apple.campo) have no entry in trackedApplications, so Ice cannot hide them, yet a layout that put them in Hidden was accepted and left them on the bar. NativeSwitch27.canIceHide: they are listed under Visible, a drop into Hidden/Always Hidden is refused with an alert that names the switch, and dimmed system tiles open the Menu Bar pane on a click.
- Not verified live: the drag refusal alert and the click-through (the screen locked during the test), and nothing on macOS 14-26. The tooltips, the new header text and the own-icon position were seen in the running 0.11.15 build.
- Do not click by coordinates in the layout window while another app is in front: iPhone Mirroring (a real phone) was in front once during the test, and the click at the sidebar position could have hit it. Select panes through AX (AXSelected on the sidebar row) instead.
- Decided with the user (2026-11-12): VIce presses the System Settings switch itself for the macOS-owned items it cannot hide. NativeMenuBarSwitches27 opens the Menu Bar pane without activating System Settings, finds the checkbox by AX identifier (controlcenter-textInput-id / -vpn-id / -spotlight-id), AXPresses it, waits for its value to change, and quits System Settings again if VIce started it. Dropping Text Input, VPN or the Search item into Hidden does this (LayoutBarPaddingView); what VIce turned off is recorded in Defaults MacOS27NativeSwitchesOff and listed in the layout pane under 'Turned off in macOS' with a 'Show again' button, because the item leaves the bar and the window once it is off. Spotlight was turned off by hand before this existed, so it is not in that record.
- The press path (opening the pane in the background, finding and pressing the checkbox, the Show again button, the drop handler) is built and unit-tested only for the pure parts (NativeSwitch27, 211 tests); NOT run live yet. AXPress on the Spotlight checkbox from a separate process did work on 2026-11-12.

