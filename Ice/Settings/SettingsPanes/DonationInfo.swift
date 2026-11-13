//
//  DonationInfo.swift
//  Ice
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// The developer's donation recipients, the same reviewed ones as the other LSSoft apps.
enum DonationInfo {
    static let bankName = "VPBank"
    static let accountNumber = "0988181872"
    static let accountName = "NGUYEN TAN VINH"
    static let transferNote = "VIce Bartender donate"
    static let paypalName = "Vinh Nguyen"
    static let paypalURL = URL(string: "https://paypal.me/ntanvinh")! // swiftlint:disable:this force_unwrapping

    static let developerName = "LSSoft"
    static let websiteURL = URL(string: "https://lssoft.io.vn")! // swiftlint:disable:this force_unwrapping
    static let contactEmail = "lssoft.adm@gmail.com"

    static let originalProjectURL = URL(string: "https://github.com/jordanbaird/Ice")! // swiftlint:disable:this force_unwrapping
    static let issuesURL = URL(string: "https://github.com/ntanvinh/v_ice_bartender/issues")! // swiftlint:disable:this force_unwrapping

    /// The original author's donation page, offered as a courtesy next to ours.
    static let originalAuthorDonateURL = URL(string: "https://icemenubar.app/Donate")! // swiftlint:disable:this force_unwrapping

    /// Static VietQR (NAPAS 247, VPBank BIN 970432). No amount is set: the donor types it
    /// in their banking app.
    static var vietQRPayload: String {
        func field(_ id: String, _ value: String) -> String {
            id + String(format: "%02d", value.count) + value
        }
        let beneficiary = field("00", "970432") + field("01", accountNumber)
        let merchant = field("00", "A000000727") + field("01", beneficiary) + field("02", "QRIBFTTA")
        let payload = field("00", "01")
            + field("01", "11")
            + field("38", merchant)
            + field("53", "704")
            + field("58", "VN")
            + field("62", field("08", transferNote))
            + "6304"
        return payload + checksum(payload)
    }

    /// CRC16/CCITT-FALSE over the payload, including the checksum field's id and length.
    static func checksum(_ payload: String) -> String {
        var crc: UInt16 = 0xFFFF
        for byte in payload.utf8 {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000 != 0) ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return String(format: "%04X", crc)
    }

    static func qrImage(for text: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else {
            return nil
        }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}

struct DonationView: View {
    private enum Region: Hashable {
        case vietnam
        case international
    }

    @Environment(\.dismiss) private var dismiss
    @AppStorage(Defaults.Key.hasDonated.rawValue) private var hasDonated = false
    @State private var region = Region.vietnam
    @State private var copiedValue: String?

    private let qr = DonationInfo.qrImage(for: DonationInfo.vietQRPayload)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Support VIce Bartender")
                .font(.title2.weight(.semibold))
                .lineLimit(1)
            if hasDonated {
                Label {
                    Text("Thank you for your support.")
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
                .font(.callout.weight(.medium))
            }
            Text("If VIce Bartender makes your day easier, you can help keep it maintained. Any amount is welcome and entirely optional.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Region", selection: $region) {
                Text("Vietnam").tag(Region.vietnam)
                Text("International").tag(Region.international)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch region {
            case .vietnam:
                vietnamSection
            case .international:
                internationalSection
            }

            Divider()

            Text("The app does not verify transfers and nothing is unlocked by donating.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Link("Support Ice's original author", destination: DonationInfo.originalAuthorDonateURL)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                if !hasDonated {
                    Button("I've donated") {
                        hasDonated = true
                        dismiss()
                    }
                    .help("Shows a thank-you in About. Nothing is sent or checked.")
                }
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .lineLimit(1)
        }
        .padding(24)
        .frame(width: 460)
    }

    @ViewBuilder
    private var vietnamSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let qr {
                Image(nsImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding(8)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("VietQR donation bank transfer")
                Text("Scan with your banking app and enter any amount.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Could not create the QR code. You can still transfer using the details below.")
                    .foregroundStyle(.secondary)
            }
            detailRow("Bank", DonationInfo.bankName, copyable: false)
            detailRow("Account number", DonationInfo.accountNumber, copyable: true)
            detailRow("Recipient", DonationInfo.accountName, copyable: false)
            detailRow("Transfer note", DonationInfo.transferNote, copyable: true)
        }
    }

    @ViewBuilder
    private var internationalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow("Recipient", DonationInfo.paypalName, copyable: false)
            detailRow("Payment link", DonationInfo.paypalURL.absoluteString, copyable: true)
            Link(destination: DonationInfo.paypalURL) {
                Label("Open PayPal", systemImage: "arrow.up.right.square")
            }
            Text("Choose any amount on PayPal. A browser will open; internet access is required.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func detailRow(_ title: LocalizedStringKey, _ value: String, copyable: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(.medium)
                .textSelection(.enabled)
                .multilineTextAlignment(.trailing)
            if copyable {
                Button(copiedValue == value ? "Copied" : "Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    copiedValue = value
                }
                .controlSize(.small)
            }
        }
    }
}
