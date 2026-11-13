//
//  AcknowledgementsSettingsPane.swift
//  Ice
//

import SwiftUI

/// One credited project and its license text.
private struct Acknowledgement: Identifiable {
    let id = UUID()
    let title: String
    let url: URL?
    let notice: String
}

/// Credits the original author and every open source library, inside the app.
struct AcknowledgementsSettingsPane: View {
    private let libraries = Self.loadLibraries()

    var body: some View {
        IceForm {
            Section {
                Text("VIce Bartender is built on the work of the people below.")
                    .foregroundStyle(.secondary)
            }

            originalAuthorSection

            if libraries.isEmpty {
                Section {
                    Text("The license notices could not be loaded.")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(libraries) { library in
                    librarySection(library)
                }
            }
        }
    }

    @ViewBuilder
    private var originalAuthorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Link("Ice by Jordan Baird", destination: DonationInfo.originalProjectURL)
                    .font(.headline)
                Text("VIce Bartender is a fork of Ice. © 2025 Jordan Baird, licensed under GPL-3.0.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Link("Support the original author", destination: DonationInfo.originalAuthorDonateURL)
        }
    }

    @ViewBuilder
    private func librarySection(_ library: Acknowledgement) -> some View {
        Section {
            Text(library.notice)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            if let url = library.url {
                Link(library.title, destination: url)
            } else {
                Text(library.title)
            }
        }
    }

    /// Reads the bundled notices. Each library starts with a "Name - URL" line.
    private static func loadLibraries() -> [Acknowledgement] {
        guard
            let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "rtf"),
            let attributed = try? NSAttributedString(
                url: url,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        else {
            return []
        }
        var result = [Acknowledgement]()
        var title: String?
        var link: URL?
        var lines = [String]()

        func flush() {
            if let title {
                result.append(Acknowledgement(
                    title: title,
                    url: link,
                    notice: lines.joined(separator: "\n\n")
                ))
            }
            lines.removeAll()
        }

        for line in attributed.string.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if let range = trimmed.range(of: " - https://") {
                flush()
                title = String(trimmed[..<range.lowerBound])
                link = URL(string: String(trimmed[trimmed.index(range.lowerBound, offsetBy: 3)...]))
            } else if title != nil {
                lines.append(trimmed)
            }
        }
        flush()
        return result
    }
}
