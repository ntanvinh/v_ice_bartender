//
//  PermissionStatusBadge.swift
//  Ice
//

import SwiftUI

// MARK: - PermissionStatus

/// Where a permission stands, in the terms the interface shows it.
enum PermissionStatus: Equatable {
    /// The app has the permission.
    case granted
    /// The app does not have the permission, and cannot work properly without it.
    case missingRequired
    /// The app does not have the permission, and can work in a limited mode without it.
    case missingOptional

    /// The colour of the status dot: green for granted, red for what the app cannot do
    /// without, orange for what it can.
    var color: Color {
        switch self {
        case .granted: .green
        case .missingRequired: .red
        case .missingOptional: .orange
        }
    }

    /// The text beside the dot. The colour is never the only thing that tells the states apart.
    var label: LocalizedStringKey {
        switch self {
        case .granted: "Granted"
        case .missingRequired, .missingOptional: "Not Granted"
        }
    }

    /// What VoiceOver says, which also tells whether the missing permission matters.
    var accessibilityLabel: LocalizedStringKey {
        switch self {
        case .granted: "Granted"
        case .missingRequired: "Not granted, required"
        case .missingOptional: "Not granted, optional"
        }
    }
}

// MARK: - PermissionStatusBadge

/// A coloured dot with the status of a permission beside it, the way System Settings shows
/// the state of a service.
struct PermissionStatusBadge: View {
    let status: PermissionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                // A hairline keeps the dot defined on the light card, where green and orange are pale.
                .overlay(Circle().strokeBorder(.black.opacity(0.15), lineWidth: 0.5))
            Text(status.label)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
        .font(.callout)
        .animation(.easeOut(duration: 0.2), value: status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(status.accessibilityLabel))
    }
}
