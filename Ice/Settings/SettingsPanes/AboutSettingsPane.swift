//
//  AboutSettingsPane.swift
//  Ice
//

import SwiftUI

struct AboutSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var updatesManager: UpdatesManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(Defaults.Key.hasDonated.rawValue) private var hasDonated = false

    private var lastUpdateCheckString: String {
        if let date = updatesManager.lastUpdateCheckDate {
            date.formatted(date: .abbreviated, time: .standard)
        } else {
            String(localized: "Never")
        }
    }

    var body: some View {
        IceForm {
            Section {
                appIconAndCopyrightSection
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            IceSection {
                automaticallyCheckForUpdates
                automaticallyDownloadUpdates
                if updatesManager.canCheckForUpdates {
                    checkForUpdates
                }
            }

            IceSection {
                aboutRow("Developer") {
                    Text(DonationInfo.developerName)
                }
                aboutRow("Website") {
                    Link(DonationInfo.websiteURL.host() ?? "lssoft.io.vn", destination: DonationInfo.websiteURL)
                }
                aboutRow("Contact") {
                    // swiftlint:disable:next force_unwrapping
                    Link(DonationInfo.contactEmail, destination: URL(string: "mailto:\(DonationInfo.contactEmail)")!)
                }
            }
        }
    }

    /// The app icon, name and credits, centred as in the About window of a Mac app. Every line
    /// is a single line that shrinks before it wraps or truncates, so a longer name or a narrow
    /// window never breaks the layout.
    @ViewBuilder
    private var appIconAndCopyrightSection: some View {
        VStack(spacing: 4) {
            if let nsImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 112, height: 112)
                    .accessibilityHidden(true)
            }

            Text("VIce Bartender")
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 8)

            Text("Version \(Constants.versionString)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            developedByLine
                .padding(.top, 12)

            HStack(spacing: 4) {
                Text("Based on")
                Link("Ice by Jordan Baird", destination: DonationInfo.originalProjectURL)
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.top, 2)

            Text("© 2025 Jordan Baird · © 2026 \(DonationInfo.developerName) · GPL-3.0")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if hasDonated {
                thankYouLine
                    .padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var developedByLine: some View {
        HStack(spacing: 8) {
            Image("LSSLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .brightness(colorScheme == .dark ? 0 : -0.5)
                .frame(width: 32, height: 22)
                .accessibilityHidden(true)
            Text("Developed by \(DonationInfo.developerName)")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
    }

    /// Shown only after the person says they donated. It never asks for another donation.
    @ViewBuilder
    private var thankYouLine: some View {
        Label {
            Text("Thank you for your support.")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } icon: {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func aboutRow(_ title: LocalizedStringKey, @ViewBuilder value: () -> some View) -> some View {
        LabeledContent(title) {
            value()
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private var automaticallyCheckForUpdates: some View {
        Toggle(
            "Automatically check for updates",
            isOn: $updatesManager.automaticallyChecksForUpdates
        )
    }

    @ViewBuilder
    private var automaticallyDownloadUpdates: some View {
        Toggle(
            "Automatically download updates",
            isOn: $updatesManager.automaticallyDownloadsUpdates
        )
    }

    @ViewBuilder
    private var checkForUpdates: some View {
        LabeledContent {
            Button("Check for Updates") {
                updatesManager.checkForUpdates()
            }
        } label: {
            Text("Last checked: \(lastUpdateCheckString)")
                .foregroundStyle(.secondary)
        }
    }
}
