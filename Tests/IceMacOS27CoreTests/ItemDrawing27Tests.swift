import CoreGraphics
import Testing
@testable import IceMacOS27Core

@Suite("ItemDrawing27")
struct ItemDrawing27Tests {
    // Measured on macOS 27.0: the external display is primary, the built-in one sits to its left.
    let external = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let builtIn = CGRect(x: -1512, y: 98, width: 1512, height: 982)

    @Test("An item on the active menu bar is drawn")
    func drawn() {
        #expect(ItemDrawing27.isDrawn(itemFrame: CGRect(x: 1478, y: 2, width: 33, height: 24), activeDisplayBounds: external, chevronFrame: nil))
    }

    @Test("A concealed item's frame left on the other display is not drawn")
    func otherDisplay() {
        #expect(!ItemDrawing27.isDrawn(itemFrame: CGRect(x: -651, y: 102, width: 42, height: 24), activeDisplayBounds: external, chevronFrame: nil))
    }

    @Test("An item folded behind the overflow button is not drawn")
    func folded() {
        let chevron = CGRect(x: -619, y: 99, width: 17, height: 30)
        #expect(!ItemDrawing27.isDrawn(itemFrame: CGRect(x: -649, y: 102, width: 47, height: 24), activeDisplayBounds: builtIn, chevronFrame: chevron))
    }

    /// Measured on macOS 27.2: the built-in display is 1512 points wide and its notch spans
    /// 664 to 848 points from the left edge, which is -848 to -664 beside the primary display.
    let notch: ClosedRange<CGFloat> = -848...(-664)

    @Test("An item that still fits beside the notch is drawn")
    func besideNotch() {
        #expect(ItemDrawing27.isDrawn(
            itemFrame: CGRect(x: -639, y: 102, width: 36, height: 24),
            activeDisplayBounds: builtIn,
            notchXRange: notch,
            chevronFrame: nil
        ))
    }

    @Test("An item laid out across the notch is not drawn")
    func acrossNotch() {
        #expect(!ItemDrawing27.isDrawn(
            itemFrame: CGRect(x: -690, y: 102, width: 47, height: 24),
            activeDisplayBounds: builtIn,
            notchXRange: notch,
            chevronFrame: nil
        ))
    }

    /// Measured 2026-11-04: with the system overflow expanded, the item Ice had revealed was
    /// drawn at 602 to 648 points from the display's left edge, past the notch and among the
    /// application menus, where it is visible and can be clicked.
    @Test("An item laid out past the notch is drawn")
    func pastNotch() {
        #expect(ItemDrawing27.isDrawn(
            itemFrame: CGRect(x: -910, y: 102, width: 46, height: 24),
            activeDisplayBounds: builtIn,
            notchXRange: notch,
            chevronFrame: nil
        ))
    }

    /// Measured 2026-11-04 by giving the bar a 216 pt status item it had no room for. While the
    /// overflow was collapsed, the folded item was listed at x=-834 — straight across the notch,
    /// drawn on nothing. Pressing the overflow control laid it out at x=-1084, beside the notch,
    /// 0.17 s later. Those two frames are the before and the after of the whole fix.
    @Test("A folded item is not drawn, and the same item is once the overflow is expanded")
    func foldedAcrossTheNotchThenUnfolded() {
        let folded = CGRect(x: -834, y: 102, width: 216, height: 24)
        let unfolded = CGRect(x: -1084, y: 102, width: 216, height: 24)
        #expect(!ItemDrawing27.isDrawn(
            itemFrame: folded,
            activeDisplayBounds: builtIn,
            notchXRange: notch,
            chevronFrame: CGRect(x: -634, y: 99, width: 18, height: 30)
        ))
        #expect(ItemDrawing27.isDrawn(
            itemFrame: unfolded,
            activeDisplayBounds: builtIn,
            notchXRange: notch,
            chevronFrame: nil
        ))
    }

    @Test("A display with no notch draws its whole bar")
    func noNotch() {
        #expect(ItemDrawing27.isDrawn(
            itemFrame: CGRect(x: 24, y: 2, width: 33, height: 24),
            activeDisplayBounds: external,
            notchXRange: nil,
            chevronFrame: nil
        ))
    }

    // Measured on macOS 27.2, 2026-11-12, under assessment mode: the bar's own window listed one
    // application item, iTerm2's at 1414. VOpenKey AI, signed locally, had been dropped by
    // MenuBarAgent, yet its process still reported 1224 through Accessibility.
    let listedByTheBar = [
        CGRect(x: 1414, y: 7, width: 46, height: 24),
        CGRect(x: 1473, y: 0, width: 21, height: 39),
        CGRect(x: 1662, y: 0, width: 114, height: 39),
    ]

    @Test("An item the bar lists at the frame the application reports is listed")
    func listed() {
        #expect(ItemDrawing27.isListed(itemFrame: CGRect(x: 1414, y: 7.5, width: 46, height: 24), amongBarFrames: listedByTheBar))
    }

    @Test("An item the bar does not list is not, whatever its application reports")
    func droppedByTheBar() {
        #expect(!ItemDrawing27.isListed(itemFrame: CGRect(x: 1224, y: 7.5, width: 40, height: 24), amongBarFrames: listedByTheBar))
    }

    @Test("A frame a point or two off still counts as the same item")
    func nearlyTheSameFrame() {
        #expect(ItemDrawing27.isListed(itemFrame: CGRect(x: 1415.5, y: 7.5, width: 45, height: 24), amongBarFrames: listedByTheBar))
    }

    @Test("A frame the same width but further away is another item")
    func sameWidthElsewhere() {
        #expect(!ItemDrawing27.isListed(itemFrame: CGRect(x: 1300, y: 7.5, width: 46, height: 24), amongBarFrames: listedByTheBar))
    }

    @Test("With nothing known about what the bar lists, nothing is ruled out")
    func nothingKnown() {
        #expect(ItemDrawing27.isListed(itemFrame: CGRect(x: 1224, y: 7.5, width: 40, height: 24), amongBarFrames: []))
    }

    @Test("Without a known active display only the overflow button decides")
    func unknownDisplay() {
        #expect(ItemDrawing27.isDrawn(itemFrame: CGRect(x: -442, y: 102, width: 33, height: 24), activeDisplayBounds: nil, chevronFrame: nil))
    }
}
