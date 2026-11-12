//
//  PermissionsContent.swift
//  Ice
//

import SwiftUI

// MARK: - PermissionsLayout

/// The Permissions window: what the app is asking for, one card per permission, and the way on.
///
/// Knows nothing of the permissions themselves, so it can be drawn from plain values.
struct PermissionsLayout<Rows: View>: View {
    let continueTitle: LocalizedStringKey
    let canContinue: Bool
    let onQuit: () -> Void
    let onContinue: () -> Void
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(spacing: 20) {
            header
            VStack(spacing: 10) {
                rows
            }
            footer
        }
        .padding(24)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        VStack(spacing: 6) {
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .accessibilityHidden(true)
            }
            Text("Permissions")
                .font(.title2.weight(.semibold))
                .padding(.top, 2)
            VStack(spacing: 2) {
                Text("VIce Bartender needs your permission to manage the menu bar.")
                Text("Absolutely no personal information is collected or stored.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit", action: onQuit)
            Button(continueTitle, action: onContinue)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
        }
    }
}

// MARK: - PermissionRowContent

/// One permission as a card: its icon and title, where it stands, what it is for, and the
/// button that asks for it while it is missing.
struct PermissionRowContent: View {
    let symbolName: String
    let title: String
    let details: [String]
    let status: PermissionStatus
    let onRequest: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title)
                        .font(.headline)
                    Spacer(minLength: 0)
                    PermissionStatusBadge(status: status)
                }
                purpose
                if status != .granted {
                    request
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .animation(.easeOut(duration: 0.2), value: status)
        .accessibilityElement(children: .contain)
    }

    private var icon: some View {
        Image(systemName: symbolName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.gradient)
            )
            .accessibilityHidden(true)
    }

    private var purpose: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("VIce Bartender needs this to:")
                .fontWeight(.medium)
            ForEach(details, id: \.self) { detail in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                    Text(detail)
                }
                .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
    }

    private var request: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            if status == .missingOptional {
                Text("VIce Bartender can work in a limited mode without this permission.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button("Grant Permission", action: onRequest)
        }
    }
}
