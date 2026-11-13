//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var itemManager: MenuBarItemManager

    private var hasItems: Bool {
        !itemManager.itemCache.managedItems.isEmpty
    }

    var body: some View {
        if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermissions
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            IceForm {
                header
                if #available(macOS 27.0, *) {
                    StuckOverflowWarning(concealer: appState.concealer27)
                    if let permission = appState.permissions.controlCenter {
                        ControlCenterAccessNotice(permission: permission)
                    }
                    NativeSwitchesOffNotice(switches: appState.nativeSwitches27)
                }
                if !hasItems {
                    IceSection {
                        loadingMenuBarItems
                            .frame(maxWidth: .infinity)
                    }
                }
                layoutBars
                if #available(macOS 27.0, *) {
                    RedrawMenuBarSection(concealer: appState.concealer27)
                }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        IceSection {
            VStack(alignment: .leading, spacing: 6) {
                Text("Drag to arrange your menu bar items into different sections.")
                    .font(.headline)
                Group {
                    // macOS 27 does order the items itself when it lays the bar out, but ⌘
                    // dragging in the bar overrides it and the new order holds — measured
                    // 2026-11-04, by hand and through a synthetic drag. What is different
                    // there is that a concealed item is off the bar altogether, so it has to
                    // be showing before it can be dragged.
                    if #available(macOS 27.0, *) {
                        Text("Items can also be arranged by ⌘ Command + dragging them in the menu bar, while their section is showing.")
                    } else {
                        Text("Items can also be arranged by ⌘ Command + dragging them in the menu bar.")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                if #available(macOS 27.0, *) {
                    // The dimmed items are drawn by macOS. Ice cannot move or hide them, but macOS
                    // has a switch for most of them (see `MenuBarSettingsLink27`).
                    Text("Dimmed items are drawn by macOS and cannot be moved here: click one to open System Settings, where Wi\u{2011}Fi, Bluetooth, Sound and the others can be turned off. Dragging Text Input, VPN or Spotlight to Hidden turns them off there for you.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Menu Bar Settings") {
                        MenuBarSettingsLink27.open()
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var layoutBars: some View {
        ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
            layoutBar(for: section)
        }
        .opacity(hasItems ? 1 : 0.75)
        .blur(radius: hasItems ? 0 : 5)
        .allowsHitTesting(hasItems)
    }

    @ViewBuilder
    private var cannotArrange: some View {
        ContentUnavailableView(
            "VIce Bartender cannot arrange menu bar items in automatically hidden menu bars.",
            systemImage: "menubar.rectangle"
        )
    }

    @ViewBuilder
    private var missingScreenRecordingPermissions: some View {
        ContentUnavailableView {
            Label("Menu bar layout requires screen recording permissions.", systemImage: "record.circle")
        } actions: {
            Button("Go to Advanced Settings") {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            }
        }
    }

    @ViewBuilder
    private var loadingMenuBarItems: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading menu bar items…")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func layoutBar(for name: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: name),
            section.isEnabled
        {
            // The bar draws its own tray, so it sits in the section without the card behind it.
            IceSection(name.localized) {
                LayoutBar(imageCache: appState.imageCache, section: name)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }
}

/// Tells the user when macOS has left items folded away beside the notch, and offers the one
/// thing that brings them back.
///
/// macOS 27 folds the items that do not fit on a built-in display's bar, which is what plugging
/// a second display in sets off. Concealing the hidden applications frees the room again, but the
/// fold is not reconsidered: the "«" that reaches the folded items goes away with the items still
/// behind it. Only the application that owns an item can lay it out afresh, by being relaunched —
/// measured, an item created by anything else is laid out alone and leaves the folded ones where
/// they are. Which application is missing cannot be read off the bar, so they are all offered and
/// the user picks the one they can see is gone.
@available(macOS 27.0, *)
private struct StuckOverflowWarning: View {
    @ObservedObject var concealer: Concealer27

    var body: some View {
        if concealer.isOverflowStuck {
            IceSection {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Some items are folded away on the built-in display.")
                            .font(.headline)
                        Text("macOS stopped laying them out when VIce Bartender freed the space beside the notch, and left no control to reach them. Restarting the menu bar, below, brings them back. So does relaunching the application whose item is missing.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !concealer.visibleApplications.isEmpty {
                        FlowRow {
                            ForEach(concealer.visibleApplications, id: \.bundleID) { application in
                                Button {
                                    concealer.relaunch(bundleID: application.bundleID)
                                } label: {
                                    Text("Relaunch \(application.name)")
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Lists the macOS items Ice turned off in System Settings, and offers each one back.
///
/// An item that is off leaves the menu bar and with it the layout window, so this is the way back
/// that does not go through System Settings. See ``NativeMenuBarSwitches27``.
@available(macOS 27.0, *)
private struct NativeSwitchesOffNotice: View {
    @ObservedObject var switches: NativeMenuBarSwitches27
    @State private var failure: String?

    var body: some View {
        let off = NativeSwitch27.known.filter { switches.turnedOff.contains($0.identifier) }
        if !off.isEmpty {
            IceSection {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Turned off in macOS")
                            .font(.headline)
                        Text("These items are off in System Settings > Menu Bar, so they are neither in the menu bar nor in this window. Turn one back on to see it again.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(off, id: \.identifier) { menuBarSwitch in
                        HStack {
                            Text(menuBarSwitch.label)
                            Spacer(minLength: 0)
                            Button("Show again") {
                                failure = nil
                                Task { @MainActor in
                                    if case .failed(let message) = await switches.set(menuBarSwitch, shown: true) {
                                        failure = message
                                    }
                                }
                            }
                            .disabled(switches.isWorking)
                        }
                    }
                    if let failure {
                        Text(failure)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Tells the user why Ice's icon can leave the menu bar while items are hidden, and offers the
/// permission that stops it.
///
/// Without access to Control Centre's data Ice hides items through assessment mode, under which
/// MenuBarAgent also drops the icon of an application signed on this Mac (measured on macOS 27.2,
/// 2026-11-12), so the way back to the settings goes with them. The native switch drops nothing
/// but Ice's own items it was asked to. See ``ControlCenterPermission``.
@available(macOS 27.0, *)
private struct ControlCenterAccessNotice: View {
    @ObservedObject var permission: Permission

    var body: some View {
        if !permission.hasPermission {
            IceSection {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The VIce Bartender icon can disappear while items are hidden.")
                            .font(.headline)
                        Text("Without access to Control Center, macOS hides items in a way that also removes this icon. With access, VIce Bartender uses macOS's own \u{201C}Allow in the Menu Bar\u{201D} switch, which keeps it. macOS asks for Full Disk Access first: turn it on for VIce Bartender, then quit and reopen the app.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button("Grant Permission") {
                        permission.performRequest()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                permission.recheck()
            }
        }
    }
}

/// Offers to restart the process that draws the menu bar on macOS 27.
///
/// macOS can reach a state where it will not draw an item at all: one created while its
/// application was switched off in the menu bar stays undrawn, and relaunching the application
/// does not help. Restarting MenuBarAgent clears it. See ``Concealer27/restartMenuBarAgent()``
/// for what was measured. It is offered rather than done automatically because Ice cannot tell
/// this state apart from an application that simply has no item.
@available(macOS 27.0, *)
private struct RedrawMenuBarSection: View {
    @ObservedObject var concealer: Concealer27

    var body: some View {
        IceSection {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Items missing, or showing the wrong icon?")
                        .font(.headline)
                    Text("macOS sometimes stops drawing an item, and relaunching the application it belongs to does not bring it back. Restarting the part of macOS that draws the menu bar does. The bar blinks for about a second. Nothing closes, and no settings change.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Restart the menu bar") {
                    concealer.restartMenuBarAgent()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Lays its content out in a row that wraps, so a long list of applications stays readable.
private struct FlowRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content }
            VStack(alignment: .leading, spacing: 8) { content }
        }
    }
}
