//
//  CaptureHarness.swift
//  Ice
//

#if DEBUG
import SwiftUI

/// Renders the app's own windows with demo data to PNG files, for the website screenshots.
///
/// It runs only in a Debug build, started with `VICE_CAPTURE_DIR=<folder>` (and
/// `VICE_CAPTURE_SCENES=<comma separated names>`). It never sets the app up (no hiding, no
/// permissions, no hotkey listeners except for the shortcuts a picture shows), keeps its windows
/// off the displays, never activates the app and never touches the menu bar items of other
/// apps: the "menu bar items" it lists are demo items drawn here. Use a separate bundle
/// identifier so that its preferences are not the installed app's.
/// A window that stays where it is put, beyond the displays, instead of being pulled back onto one.
private final class CaptureWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

@MainActor
enum CaptureHarness {
    static var isActive: Bool {
        ProcessInfo.processInfo.environment["VICE_CAPTURE_DIR"] != nil
    }

    private static var directory: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["VICE_CAPTURE_DIR"] ?? "/tmp")
    }

    private static var keepAlive = [NSWindow]()

    /// The demo item that the status-reveal picture marks as watched, as an app that publishes its
    /// status would be. The harness reads no status: the badge on its tile is drawn by the app's
    /// own view, and only the "watched" state is set here.
    static let demoStatusNamespace = "io.tailscale.ipn.macsys"

    /// Set only while the status-reveal picture is made, so the other Menu Bar Layout pictures keep
    /// their tiles unmarked.
    static var marksStatusDemo = false

    static func run(appState: AppState) {
        NSApp.setActivationPolicy(.accessory)
        // VICE_CAPTURE_APPEARANCE=light shows the light appearance; anything else keeps dark.
        let light = ProcessInfo.processInfo.environment["VICE_CAPTURE_APPEARANCE"] == "light"
        NSApp.appearance = NSAppearance(named: light ? .aqua : .darkAqua)
        let scenes = (ProcessInfo.processInfo.environment["VICE_CAPTURE_SCENES"] ?? "")
            .split(separator: ",").map(String.init)
        Task { @MainActor in
            seed(appState: appState)
            for scene in scenes {
                do {
                    try await capture(scene: scene, appState: appState)
                    print("captured \(scene)")
                } catch {
                    print("FAILED \(scene): \(error)")
                }
            }
            print("capture done")
            NSApp.terminate(nil)
        }
    }

    // MARK: Demo data

    private struct DemoItem {
        let name: String
        let namespace: String
        let symbol: String
    }

    private static let visible = [
        DemoItem(name: "Zoom", namespace: "us.zoom.xos", symbol: "video.fill"),
        DemoItem(name: "Dropbox", namespace: "com.getdropbox.dropbox", symbol: "shippingbox.fill"),
        DemoItem(name: "Bluetooth", namespace: "com.apple.controlcenter.bluetooth", symbol: "wave.3.right"),
    ]
    private static let hidden = [
        DemoItem(name: "Slack", namespace: "com.tinyspeck.slackmacgap", symbol: "number"),
        DemoItem(name: "Slack Huddle", namespace: "com.tinyspeck.slackmacgap.huddle", symbol: "headphones"),
        DemoItem(name: "1Password", namespace: "com.1password.1password", symbol: "lock.shield.fill"),
        DemoItem(name: "iTerm2", namespace: "com.googlecode.iterm2", symbol: "terminal.fill"),
        DemoItem(name: "Tailscale", namespace: "io.tailscale.ipn.macsys", symbol: "point.3.connected.trianglepath.dotted"),
        DemoItem(name: "iStat Menus", namespace: "com.bjango.istatmenus", symbol: "gauge.with.dots.needle.50percent"),
    ]
    private static let alwaysHidden = [
        DemoItem(name: "Sleep Timer", namespace: "com.example.sleeptimer", symbol: "moon.zzz.fill"),
        DemoItem(name: "Clipboard History", namespace: "com.example.clipboardhistory", symbol: "doc.on.clipboard.fill"),
    ]

    private static func glyph(_ symbol: String) -> MenuBarItemImageCache.CapturedImage? {
        let scale: CGFloat = 2
        let size = CGSize(width: 30, height: 24)
        guard
            let base = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(.init(pointSize: 15, weight: .medium)
                    .applying(.init(paletteColors: [NSColor(white: 0.95, alpha: 1)])))
        else {
            return nil
        }
        let image = NSImage(size: size, flipped: false) { rect in
            let s = base.size
            base.draw(in: CGRect(x: (rect.width - s.width) / 2, y: (rect.height - s.height) / 2, width: s.width, height: s.height))
            return true
        }
        var rect = CGRect(origin: .zero, size: CGSize(width: size.width * scale, height: size.height * scale))
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return nil
        }
        return .init(cgImage: cgImage, scale: scale)
    }

    private static func seed(appState: AppState) {
        var cache = MenuBarItemManager.ItemCache(displayID: nil)
        var images = [MenuBarItemTag: MenuBarItemImageCache.CapturedImage]()
        var windowID: CGWindowID = 9000
        func add(_ items: [DemoItem], to section: MenuBarSection.Name) {
            for demo in items {
                windowID += 1
                let tag = MenuBarItemTag(namespace: .string(demo.namespace), title: demo.name)
                let item = MenuBarItem(captureTag: tag, windowID: windowID, name: demo.name, size: CGSize(width: 30, height: 24))
                cache[section].append(item)
                images[tag] = glyph(demo.symbol)
            }
        }
        add(visible, to: .visible)
        add(hidden, to: .hidden)
        add(alwaysHidden, to: .alwaysHidden)
        appState.itemManager.seedForCapture(cache)
        appState.imageCache.seedForCapture(images)

        // Hotkeys a person would really assign (these shortcuts are registered only while this
        // process lives, a few seconds).
        let hotkeys = appState.settings.hotkeys
        let combos: [(HotkeyAction, KeyCombination)] = [
            (.toggleHiddenSection, .init(key: .h, modifiers: [.control, .option])),
            (.toggleAlwaysHiddenSection, .init(key: .a, modifiers: [.control, .option])),
            (.searchMenuBarItems, .init(key: .space, modifiers: [.control, .option])),
            (.enableIceBar, .init(key: .b, modifiers: [.control, .option])),
            (.toggleApplicationMenus, .init(key: .m, modifiers: [.control, .option])),
        ]
        for (action, combination) in combos {
            guard let hotkey = hotkeys.hotkey(withAction: action) else { continue }
            hotkey.captureShowsEnabled = true
            hotkey.keyCombination = combination
        }

    }

    /// A tint, border and shape a person would pick, set only for the appearance picture.
    private static func styleMenuBar(appState: AppState) {
        var partial = MenuBarAppearancePartialConfiguration.defaultConfiguration
        partial.tintKind = .gradient
        partial.hasBorder = true
        partial.borderWidth = 2
        partial.borderColor = CGColor(red: 0.92, green: 0.92, blue: 0.95, alpha: 1)
        partial.tintGradient = IceGradient(stops: [
            .stop(CGColor(red: 0.36, green: 0.25, blue: 0.80, alpha: 1), location: 0),
            .stop(CGColor(red: 0.10, green: 0.62, blue: 0.82, alpha: 1), location: 1),
        ])
        partial.hasShadow = true
        var configuration = MenuBarAppearanceConfigurationV2.defaultConfiguration
        configuration.staticConfiguration = partial
        configuration.shapeKind = .full
        configuration.fullShapeInfo = MenuBarFullShapeInfo(leadingEndCap: .round, trailingEndCap: .round)
        appState.appearanceManager.configuration = configuration
    }

    // MARK: Scenes

    private static func capture(scene: String, appState: AppState) async throws {
        switch scene {
        case "general":
            try await captureSettings(.general, file: "settings-general", appState: appState)
        case "about":
            try await captureSettings(.about, file: "settings-about", appState: appState)
        case "acknowledgements":
            try await captureSettings(.acknowledgements, file: "settings-acknowledgements", appState: appState)
        case "settings-advanced":
            try await captureSettings(.advanced, file: "settings-advanced", appState: appState)
        case "settings-layout":
            try await captureSettings(.menuBarLayout, file: "settings-layout", appState: appState)
        case "settings-appearance":
            styleMenuBar(appState: appState)
            try await captureSettings(.menuBarAppearance, file: "settings-appearance", appState: appState)
        case "settings-hotkeys":
            try await captureSettings(.hotkeys, file: "settings-hotkeys", appState: appState)
        case "settings-status":
            marksStatusDemo = true
            try await captureSettings(.menuBarLayout, file: "settings-status", appState: appState)
        case "layout":
            try await captureSettings(.menuBarLayout, file: "03-drag-and-drop-layout", appState: appState)
        case "appearance":
            styleMenuBar(appState: appState)
            try await captureSettings(.menuBarAppearance, file: "05-menu-bar-appearance", appState: appState)
        case "hotkeys":
            try await captureSettings(.hotkeys, file: "06-keyboard-shortcuts", appState: appState)
        case "advanced":
            // Tall enough to show "Hiding on macOS 27", the part of the app that exists only on 27.
            // It is a source picture for the macOS 27 feature image, not a picture of its own.
            // Narrow, so that the part that matters is taller and can be shown larger.
            try await captureSettings(.advanced, file: "macos27-advanced", appState: appState, width: 780, height: 1100)
        case "icebar":
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let view = IceBarPanel.captureView(appState: appState, screen: screen, section: .hidden)
            view.setFrameSize(view.fittingSize)
            try await captureView(view, margin: 230, radius: 12, file: "02-ice-bar")
        case "search":
            let model = MenuBarSearchModel()
            model.searchText = "slack"
            let view = MenuBarSearchPanel.captureView(appState: appState, model: model)
            view.setFrameSize(view.fittingSize)
            try await captureView(view, margin: 120, radius: 14, file: "04-search-menu-bar-items")
        default:
            throw NSError(domain: "capture", code: 1, userInfo: [NSLocalizedDescriptionKey: "unknown scene \(scene)"])
        }
    }

    private static func captureSettings(
        _ pane: SettingsNavigationIdentifier,
        file: String,
        appState: AppState,
        width: CGFloat = CGFloat(Double(ProcessInfo.processInfo.environment["VICE_CAPTURE_WIDTH"] ?? "") ?? 1000),
        height: CGFloat = CGFloat(Double(ProcessInfo.processInfo.environment["VICE_CAPTURE_HEIGHT"] ?? "") ?? 700)
    ) async throws {
        appState.navigationState.settingsNavigationIdentifier = pane
        let root = SettingsView(navigationState: appState.navigationState)
            .environmentObject(appState)
        let controller = NSHostingController(rootView: root)
        let window = CaptureWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.setContentSize(CGSize(width: width, height: height))
        window.title = pane.rawValue
        try await snapshot(window, file: file)
    }

    private static func captureView(_ view: NSView, margin: CGFloat, radius: CGFloat, file: String) async throws {
        let size = view.frame.size
        let canvas = NSView(frame: CGRect(origin: .zero, size: CGSize(width: size.width + margin * 2, height: size.height + margin * 2)))
        canvas.wantsLayer = true
        view.setFrameOrigin(CGPoint(x: margin, y: margin))
        view.wantsLayer = true
        view.layer?.cornerRadius = radius
        view.layer?.masksToBounds = true
        let host = NSView(frame: view.frame)
        host.wantsLayer = true
        host.shadow = NSShadow()
        host.layer?.backgroundColor = NSColor(white: 0.14, alpha: 1).cgColor
        host.layer?.cornerRadius = radius
        host.layer?.shadowColor = NSColor.black.cgColor
        host.layer?.shadowOpacity = 0.45
        host.layer?.shadowRadius = 24
        host.layer?.shadowOffset = CGSize(width: 0, height: -10)
        view.setFrameOrigin(.zero)
        host.addSubview(view)
        canvas.addSubview(host)
        let window = NSWindow(contentRect: canvas.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.contentView = canvas
        try await snapshot(window, file: file)
    }

    /// Shows the window beyond the displays without activating the app, and writes it as a PNG.
    private static func snapshot(_ window: NSWindow, file: String) async throws {
        window.isReleasedWhenClosed = false
        keepAlive.append(window)
        let far = NSScreen.screens.map(\.frame.maxX).max() ?? 0
        window.setFrameOrigin(CGPoint(x: far + 3000, y: 200))
        window.orderFrontRegardless()
        try await Task.sleep(for: .seconds(2))
        print("window \(file) frame \(window.frame) scale \(window.backingScaleFactor) screen \(String(describing: window.screen?.frame))")
        let id = CGWindowID(window.windowNumber)
        guard let image = CGWindowListCreateImage(.null, .optionIncludingWindow, id, [.boundsIgnoreFraming, .bestResolution]) else {
            throw NSError(domain: "capture", code: 2, userInfo: [NSLocalizedDescriptionKey: "no image for window \(id)"])
        }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "capture", code: 3)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent("\(file).png"))
        window.orderOut(nil)
    }
}
#endif
