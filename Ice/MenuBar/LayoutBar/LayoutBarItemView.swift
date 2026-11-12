//
//  LayoutBarItemView.swift
//  Ice
//

import Cocoa
import Combine

// MARK: - LayoutBarItemView

/// A view that displays an image in a menu bar layout view.
final class LayoutBarItemView: NSView {
    private weak var appState: AppState?

    private var cancellables = Set<AnyCancellable>()

    /// The item that the view represents.
    let item: MenuBarItem

    /// Temporary information that the item view retains when it is moved outside
    /// of a layout view.
    ///
    /// When the item view is dragged outside of a layout view, this property is set
    /// to hold the layout view's container view, as well as the index of the item
    /// view in relation to the container's other items. Upon being inserted into a
    /// new layout view, these values are removed. If the item is dropped outside of
    /// a layout view, these values are used to reinsert the item view in its original
    /// layout view.
    var oldContainerInfo: (container: LayoutBarContainer, index: Int)?

    /// A Boolean value that indicates whether the item view is currently inside a container.
    var hasContainer = false

    /// The image displayed inside the view.
    private var cachedImage: MenuBarItemImageCache.CapturedImage? {
        didSet {
            if let image = cachedImage {
                setFrameSize(image.scaledSize)
            } else {
                setFrameSize(.zero)
            }
            needsDisplay = true
        }
    }

    /// A Boolean value that indicates whether the view shows Ice's own icon.
    private var isOwnIcon: Bool {
        item.tag == .visibleControlItem
    }

    /// Ice's own icon, as the user chose it. It is drawn rather than photographed: a photograph
    /// of Ice's own item broke the bar (see `ItemImageStore27.isPhotographable`), and the icon is
    /// known anyway.
    private var ownIcon: NSImage? {
        didSet {
            needsDisplay = true
        }
    }

    /// A Boolean value that indicates whether the item view is a dragging placeholder.
    ///
    /// If this value is `true`, the item view does not draw its image.
    var isDraggingPlaceholder = false {
        didSet {
            needsDisplay = true
        }
    }

    /// A Boolean value that indicates whether the view is enabled.
    var isEnabled = true {
        didSet {
            needsDisplay = true
        }
    }

    /// Creates a view that displays the given menu bar item.
    init(appState: AppState, item: MenuBarItem) {
        self.item = item
        self.appState = appState

        // set the frame to the full item frame size; the image will be centered when displayed
        super.init(frame: CGRect(origin: .zero, size: item.bounds.size))
        unregisterDraggedTypes()

        self.toolTip = Self.toolTip(for: item)
        if #available(macOS 27.0, *) {
            // Lets Scripts/macos27/verify-layout.sh find the item.
            setAccessibilityElement(true)
            setAccessibilityRole(.image)
            setAccessibilityLabel(item.displayName)
        }
        // Ice's own icon is shown, not arranged: the section it is in is Ice's to decide.
        self.isEnabled = item.isMovable && !isOwnIcon

        configureCancellables()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// What the tile says when the pointer rests on it.
    ///
    /// The tiles are pictures, and clicking one does nothing, so a tile that cannot be arranged
    /// has to say why it is dimmed: its name alone left an item such as the Wi-Fi one, which
    /// shows an Ethernet glyph on a wired Mac, looking like a button that does not work.
    private static func toolTip(for item: MenuBarItem) -> String {
        if item.tag == .visibleControlItem {
            return "\(item.displayName)\nThis is the VIce Bartender icon. It always stays at the far right of this bar."
        }
        if !item.isMovable {
            return "\(item.displayName)\nmacOS draws this item itself, so VIce Bartender cannot move or hide it. Click it in the menu bar, not here."
        }
        return item.displayName
    }

    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        if let appState {
            if isOwnIcon {
                let general = appState.settings.general
                general.$iceIcon
                    .combineLatest(general.$customIceIconIsTemplate)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] icon, _ in
                        guard let self else {
                            return
                        }
                        // Everything is revealed while this window is open, so the icon is the
                        // one for the visible state.
                        MainActor.assumeIsolated {
                            self.setFrameSize(self.item.bounds.size)
                            // A custom icon that cannot be read must not leave an empty tile: the
                            // icon is always to be seen, so the default one stands in for it.
                            self.ownIcon = icon.visible.nsImage(for: appState)
                                ?? ControlItemImageSet.defaultIceIcon.visible.nsImage(for: appState)
                        }
                    }
                    .store(in: &c)
            }
            appState.imageCache.$images
                .sink { [weak self] images in
                    guard let self, let cachedImage = images[item.tag] else {
                        return
                    }
                    self.cachedImage = cachedImage
                }
                .store(in: &c)
        }

        cancellables = c
    }

    /// Provides an alert to display when the item view is disabled.
    func provideAlertForDisabledItem() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = "Menu bar item is not movable."
        alert.informativeText = "macOS prohibits \"\(item.displayName)\" from being moved."
        return alert
    }

    /// Provides an alert to display when a menu bar item is unresponsive.
    func provideAlertForUnresponsiveItem() -> NSAlert {
        let alert = provideAlertForDisabledItem()
        alert.informativeText = "\(item.displayName) is unresponsive. Until it is restarted, it cannot be moved. Movement of other menu bar items may also be affected until this is resolved."
        return alert
    }

    /// How much of an item that cannot be moved is drawn.
    ///
    /// It was 0.67, which reads as "slightly off" rather than "not yours to drag" — on a
    /// light background a black glyph at two thirds is still almost black. These are a whole
    /// third of the Visible section on macOS 27, where everything macOS draws itself is
    /// listed and none of it can be moved, so the difference has to be plain at a glance.
    private static let disabledFraction: CGFloat = 0.35

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    /// Draws Ice's own icon in the middle of its tile, in the colour the layout bar's glyphs have.
    private func drawOwnIcon() {
        guard !isDraggingPlaceholder, let icon = ownIcon else {
            return
        }
        let rect = CGRect(
            x: bounds.midX - icon.size.width / 2,
            y: bounds.midY - icon.size.height / 2,
            width: icon.size.width,
            height: icon.size.height
        )
        guard icon.isTemplate else {
            icon.draw(in: rect)
            return
        }
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let tint: NSColor = isDark ? .white : .black
        let tinted = NSImage(size: icon.size, flipped: false) { bounds in
            icon.draw(in: bounds)
            tint.set()
            bounds.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: rect)
    }

    override func draw(_ dirtyRect: NSRect) {
        if isOwnIcon {
            drawOwnIcon()
            return
        }
        if !isDraggingPlaceholder {
            cachedImage?.nsImage.draw(
                in: bounds,
                from: .zero,
                operation: .sourceOver,
                fraction: isEnabled ? 1.0 : Self.disabledFraction
            )
            if Bridging.isProcessUnresponsive(item.ownerPID) {
                let warningImage = NSImage.warning
                let width: CGFloat = 15
                let scale = width / warningImage.size.width
                let size = CGSize(
                    width: width,
                    height: warningImage.size.height * scale
                )
                warningImage.draw(
                    in: CGRect(
                        x: bounds.maxX - size.width,
                        y: bounds.minY,
                        width: size.width,
                        height: size.height
                    )
                )
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)

        guard !isOwnIcon else {
            return
        }

        guard isEnabled else {
            let alert = provideAlertForDisabledItem()
            alert.runModal()
            return
        }

        guard !Bridging.isProcessUnresponsive(item.ownerPID) else {
            let alert = provideAlertForUnresponsiveItem()
            alert.runModal()
            return
        }

        // Data doesn't matter, but we do need to set the type.
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setData(Data(), forType: .layoutBarItem)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(bounds, contents: cachedImage?.nsImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

// MARK: LayoutBarItemView: NSDraggingSource
extension LayoutBarItemView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        // make sure the container doesn't update its arranged views and that items
        // aren't arranged during a dragging session
        if let container = superview as? LayoutBarContainer {
            container.canSetArrangedViews = false
        }

        // prevent the dragging image from animating back to its original location
        session.animatesToStartingPositionsOnCancelOrFail = false

        // async to prevent the view from disappearing before the dragging image appears
        DispatchQueue.main.async {
            self.isDraggingPlaceholder = true
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        defer {
            // always remove container info at the end of a session
            oldContainerInfo = nil
        }

        // since the session's `animatesToStartingPositionsOnCancelOrFail` property was
        // set to false when the session began (above), there is no delay between the user
        // releasing the dragging item and this method being called; thus, `isDraggingPlaceholder`
        // only needs to be updated here; if we ever decide we want animation, it may also
        // need to be updated inside `performDragOperation(_:)` on `LayoutBarPaddingView`
        isDraggingPlaceholder = false

        // if the drop occurs outside of a container, reinsert the view into its original
        // container at its original index
        if !hasContainer {
            guard let (container, index) = oldContainerInfo else {
                return
            }
            container.shouldAnimateNextLayoutPass = false
            container.arrangedViews.insert(self, at: index)
        }
    }
}

extension LayoutBarItemView: NSAccessibilityLayoutItem { }

// MARK: Layout Bar Item Pasteboard Type
extension NSPasteboard.PasteboardType {
    static let layoutBarItem = Self("\(Constants.bundleIdentifier).layout-bar-item")
}
