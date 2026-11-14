// Builds the feature picture "Works on macOS 27" (marketing/screenshots/desktop/06-macos-27-support.png).
//
// It is a created image, not a raw screenshot: the real menu bar of a macOS 27 Mac cannot be photographed
// in the background (see .trail/learnings, assessment mode). It is made of
//   - the app's own icon (Ice/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png),
//   - a headline and one line of text, and
//   - a crop of the app's real Advanced window ("Hiding on macOS 27" and "Permissions"), rendered by
//     the DEBUG capture harness: VICE_CAPTURE_SCENES=advanced (see Ice/Utilities/CaptureHarness.swift).
// The size is 2880 x 1800 px (16:10, a size the Mac App Store takes), PNG, no transparency.
//
// Usage: swiftc -O macos27-feature-image.swift -o make && ./make <advanced.png> <icon.png> <output.png>

import AppKit

let args = CommandLine.arguments
guard args.count == 4 else {
    FileHandle.standardError.write(Data("usage: make <advanced.png> <icon.png> <output.png>\n".utf8))
    exit(2)
}

func load(_ path: String) -> NSBitmapImageRep {
    guard let data = FileManager.default.contents(atPath: path), let rep = NSBitmapImageRep(data: data) else {
        FileHandle.standardError.write(Data("cannot read \(path)\n".utf8))
        exit(1)
    }
    return rep
}

let width = 2880
let height = 1800
let W = CGFloat(width)
let H = CGFloat(height)

// The part of the 1560 x 2200 px Advanced capture that is macOS 27 only, with the permissions it needs:
// "Hiding on macOS 27" down to the Permissions block. Re-measured on the rebuilt Settings window (2026-11-14).
let cropRect = CGRect(x: 480, y: 1200, width: 1080, height: 650)
let source = load(args[1])
guard source.pixelsWide == 1560, source.pixelsHigh == 2200,
      let cropped = source.cgImage?.cropping(to: cropRect)
else {
    FileHandle.standardError.write(Data("the Advanced capture is not 1560 x 2200 px: the layout changed, check the crop\n".utf8))
    exit(1)
}
let icon = load(args[2])

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let cg = CGContext(
    data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
) else { exit(1) }

// Work from the top left corner.
cg.translateBy(x: 0, y: H)
cg.scaleBy(x: 1, y: -1)
let gc = NSGraphicsContext(cgContext: cg, flipped: true)
NSGraphicsContext.current = gc

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha
    )
}

// MARK: Background: the icon's navy, darkening to the corner, with two soft glows.
let base = CGGradient(
    colorsSpace: space,
    colors: [color(0x1B0A66), color(0x0C0A26), color(0x07071A)] as CFArray,
    locations: [0, 0.55, 1]
)!
cg.drawLinearGradient(base, start: CGPoint(x: 0, y: 0), end: CGPoint(x: W, y: H), options: [])

func glow(center: CGPoint, radius: CGFloat, hex: UInt32, alpha: CGFloat) {
    let g = CGGradient(
        colorsSpace: space, colors: [color(hex, alpha), color(hex, 0)] as CFArray, locations: [0, 1]
    )!
    cg.drawRadialGradient(g, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}
glow(center: CGPoint(x: 1950, y: 900), radius: 1300, hex: 0x5B3FD6, alpha: 0.42)
glow(center: CGPoint(x: 2700, y: 160), radius: 1000, hex: 0x19A0D0, alpha: 0.22)

// MARK: Left: icon and name, headline, one line.
let left: CGFloat = 170
let textWidth: CGFloat = 1000

let iconSide: CGFloat = 340  // the icon's own margin leaves a ~270 px tile
let iconRect = CGRect(x: left - 34, y: 300, width: iconSide, height: iconSide)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: 22), blur: 40, color: color(0x000000, 0.55))
NSImage(cgImage: icon.cgImage!, size: iconRect.size)
    .draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
cg.restoreGState()

func draw(_ text: String, in rect: CGRect, size: CGFloat, weight: NSFont.Weight, hex: UInt32,
          alpha: CGFloat = 1, kern: CGFloat = 0, lineHeight: CGFloat? = nil) {
    let style = NSMutableParagraphStyle()
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(cgColor: color(hex, alpha))!,
        .kern: kern,
        .paragraphStyle: style,
    ]
    NSAttributedString(string: text, attributes: attributes).draw(with: rect, options: [.usesLineFragmentOrigin])
}

draw("VIce Bartender", in: CGRect(x: iconRect.maxX - 10, y: iconRect.minY + 128, width: 700, height: 100),
     size: 72, weight: .semibold, hex: 0xFFFFFF, alpha: 0.92, kern: -1)

draw("Works on", in: CGRect(x: left, y: 700, width: textWidth, height: 230),
     size: 200, weight: .bold, hex: 0xFFFFFF, kern: -5)
draw("macOS 27", in: CGRect(x: left, y: 900, width: textWidth, height: 230),
     size: 200, weight: .bold, hex: 0xA8E6FF, kern: -5)

draw("Hide and arrange your menu bar items on the latest macOS.",
     in: CGRect(x: left, y: 1190, width: 900, height: 200),
     size: 60, weight: .regular, hex: 0xFFFFFF, alpha: 0.72, kern: -0.4, lineHeight: 84)

// MARK: Right: the real window, cropped.
let card = CGRect(x: 1420, y: 539, width: 1200, height: cropRect.height * 1200 / cropRect.width)
let radius: CGFloat = 46
let path = CGPath(roundedRect: card, cornerWidth: radius, cornerHeight: radius, transform: nil)

cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: 40), blur: 80, color: color(0x000000, 0.6))
cg.addPath(path)
cg.setFillColor(color(0x1E1E1E))
cg.fillPath()
cg.restoreGState()

cg.saveGState()
cg.addPath(path)
cg.clip()
NSImage(cgImage: cropped, size: card.size)
    .draw(in: card, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
cg.restoreGState()

cg.addPath(path)
cg.setStrokeColor(color(0xFFFFFF, 0.14))
cg.setLineWidth(2)
cg.strokePath()

// MARK: Write.
NSGraphicsContext.current = nil
guard let image = cg.makeImage() else { exit(1) }
let out = NSBitmapImageRep(cgImage: image)
guard let png = out.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: args[3]))
print("wrote \(args[3]) \(width)x\(height)")
