//
//  SettingsNavigationIdentifier.swift
//  Ice
//

import SwiftUI

/// The navigation identifier type for the "Settings" interface.
enum SettingsNavigationIdentifier: String, NavigationIdentifier {
    case general = "General"
    case menuBarLayout = "Menu Bar Layout"
    case menuBarAppearance = "Menu Bar Appearance"
    case hotkeys = "Hotkeys"
    case advanced = "Advanced"
    case about = "About"
    case acknowledgements = "Acknowledgements"

    /// The identifiers listed in the sidebar's main section. Acknowledgements sits with the
    /// sidebar's link rows instead.
    static var mainPanes: [SettingsNavigationIdentifier] {
        allCases.filter { $0 != .acknowledgements }
    }

    var iconResource: IconResource {
        switch self {
        case .general: .systemSymbol("gearshape")
        case .menuBarLayout: .systemSymbol("rectangle.topthird.inset.filled")
        case .menuBarAppearance: .systemSymbol("swatchpalette")
        case .hotkeys: .systemSymbol("keyboard")
        case .advanced: .systemSymbol("gearshape.2")
        case .about: .assetCatalog(.iceCubeStroke)
        case .acknowledgements: .systemSymbol("doc.text")
        }
    }

    /// The colour of the tile behind the pane's icon in the sidebar.
    var tint: Color {
        switch self {
        case .general: .gray
        case .menuBarLayout: .blue
        case .menuBarAppearance: .purple
        case .hotkeys: .orange
        case .advanced: .teal
        case .about: .indigo
        case .acknowledgements: .brown
        }
    }
}
