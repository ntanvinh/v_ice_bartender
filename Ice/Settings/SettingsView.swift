//
//  SettingsView.swift
//  Ice
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var navigationState: AppNavigationState
    @Environment(\.sidebarRowSize) private var sidebarRowSize
    @State private var isShowingDonation = false

    /// The side of an icon tile. It follows the sidebar icon size chosen in System Settings,
    /// the way the sidebars of Apple's own apps do.
    private var iconTileSize: CGFloat {
        switch sidebarRowSize {
        case .small: 20
        case .medium: 24
        case .large: 28
        @unknown default: 24
        }
    }

    private var navigationTitle: LocalizedStringKey {
        navigationState.settingsNavigationIdentifier.localized
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle(navigationTitle)
    }

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $navigationState.settingsNavigationIdentifier) {
            Section {
                ForEach(SettingsNavigationIdentifier.mainPanes) { identifier in
                    sidebarItem(for: identifier)
                }
            }

            Section {
                sidebarItem(for: .acknowledgements)
                sidebarLink("Donate", systemImage: "heart.fill", tint: .pink) {
                    isShowingDonation = true
                }
                sidebarLink("Quit VIce Bartender", systemImage: "power", tint: .red) {
                    NSApp.terminate(nil)
                }
            }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $isShowingDonation) {
            DonationView()
        }
        .toolbar(removing: .sidebarToggle)
        .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 270)
    }

    @ViewBuilder
    private func sidebarItem(for identifier: SettingsNavigationIdentifier) -> some View {
        Label {
            Text(identifier.localized)
                .lineLimit(1)
        } icon: {
            iconTile(tint: identifier.tint) {
                identifier.iconResource.view
            }
        }
        .tag(identifier)
    }

    /// A sidebar row that runs an action instead of selecting a pane.
    @ViewBuilder
    private func sidebarLink(
        _ title: LocalizedStringKey,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .lineLimit(1)
            } icon: {
                iconTile(tint: tint) {
                    Image(systemName: systemImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The rounded coloured square behind a sidebar icon, as in System Settings.
    @ViewBuilder
    private func iconTile(tint: Color, @ViewBuilder icon: () -> some View) -> some View {
        icon()
            .foregroundStyle(.white)
            .padding(iconTileSize * 0.2)
            .frame(width: iconTileSize, height: iconTileSize)
            .background(tint.gradient, in: .rect(cornerRadius: iconTileSize * 0.27))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var detailView: some View {
        if #available(macOS 26.0, *) {
            settingsPane
                .scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            settingsPane
        }
    }

    @ViewBuilder
    private var settingsPane: some View {
        switch navigationState.settingsNavigationIdentifier {
        case .general:
            GeneralSettingsPane(settings: appState.settings.general)
        case .menuBarLayout:
            MenuBarLayoutSettingsPane(itemManager: appState.itemManager)
        case .menuBarAppearance:
            MenuBarAppearanceSettingsPane(appearanceManager: appState.appearanceManager)
        case .hotkeys:
            HotkeysSettingsPane(settings: appState.settings.hotkeys)
        case .advanced:
            AdvancedSettingsPane(settings: appState.settings.advanced)
        case .about:
            AboutSettingsPane(updatesManager: appState.updatesManager)
        case .acknowledgements:
            AcknowledgementsSettingsPane()
        }
    }
}
