//
//  PermissionSettingsRow.swift
//  Ice
//

import SwiftUI

/// A permission's line in the settings: its name, where it stands, and a button while it is missing.
struct PermissionSettingsRow: View {
    @ObservedObject var permission: Permission

    var body: some View {
        LabeledContent {
            HStack(spacing: 12) {
                PermissionStatusBadge(status: permission.status)
                if !permission.hasPermission {
                    Button("Grant Permission") {
                        permission.performRequest()
                    }
                }
            }
        } label: {
            Text(LocalizedStringKey(permission.title))
        }
        .frame(height: 22)
        // The checks stop once the app is set up, so the line asks again when it appears and
        // when the app comes back to the front, which is where a grant in System Settings ends.
        .onAppear {
            permission.recheck()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permission.recheck()
        }
    }
}
