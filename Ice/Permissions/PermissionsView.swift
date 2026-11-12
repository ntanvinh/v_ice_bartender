//
//  PermissionsView.swift
//  Ice
//

import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var manager: AppPermissions

    private var continueButtonText: LocalizedStringKey {
        if case .hasRequired = manager.permissionsState {
            "Continue in Limited Mode"
        } else {
            "Continue"
        }
    }

    var body: some View {
        PermissionsLayout(
            continueTitle: continueButtonText,
            canContinue: manager.permissionsState != .missing,
            onQuit: quit,
            onContinue: continueSetup
        ) {
            ForEach(manager.allPermissions) { permission in
                PermissionRow(permission: permission)
            }
        }
    }

    private func quit() {
        NSApp.terminate(nil)
    }

    private func continueSetup() {
        appState.dismissWindow(.permissions)

        guard manager.permissionsState != .missing else {
            appState.performSetup(hasPermissions: false)
            return
        }

        appState.performSetup(hasPermissions: true)

        Task {
            appState.activate(withPolicy: .regular)
            appState.openWindow(.settings)
        }
    }
}

// MARK: - PermissionRow

/// A permission's card in the Permissions window. It observes the permission itself, so the
/// dot changes the moment the system grants it, whether or not the overall state moves.
private struct PermissionRow: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var permission: Permission

    var body: some View {
        PermissionRowContent(
            symbolName: permission.symbolName,
            title: permission.title,
            details: permission.details,
            status: permission.status
        ) {
            permission.performRequest()
            Task {
                await permission.waitForPermission()
                appState.activate(withPolicy: .regular)
                appState.openWindow(.permissions)
            }
        }
    }
}
