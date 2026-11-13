import CoreGraphics
import Testing
@testable import IceMacOS27Core

@Suite("IceBarPlacement27")
struct IceBarPlacement27Tests {
    /// The built-in display of 2026-11-13 (macOS 27.2): 1800 wide, Ice's icon at 1589...1624.
    private let icon = CGRect(x: 1589, y: 7.5, width: 35, height: 24)

    private func originX(
        width: CGFloat,
        icon: CGRect?,
        screen: ClosedRange<CGFloat> = 0...1800
    ) -> CGFloat {
        IceBarPlacement27.originX(
            panelWidth: width,
            margin: 5,
            iconFrame: icon,
            screenMinX: screen.lowerBound,
            screenMaxX: screen.upperBound
        )
    }

    @Test("The drawn bar's right edge stands under the icon's right edge")
    func rightAlignedWithTheIcon() {
        // Panel 300 wide with a margin of 5: the drawn bar ends at 1624 when the panel ends at 1629.
        let expected: CGFloat = 1329
        #expect(originX(width: 300, icon: icon) == expected)
    }

    @Test("A bar too wide to end under the icon starts at the left edge")
    func startsAtTheLeftEdge() {
        // Ending under the icon would put the left end at -71, past the screen.
        #expect(originX(width: 1700, icon: icon) == 0)
        #expect(originX(width: 1800, icon: icon) == 0)
    }

    @Test("A bar that would stick out past the right edge ends at the screen's right edge")
    func neverPastTheRightEdge() {
        let nearTheEdge = CGRect(x: 1780, y: 7.5, width: 35, height: 24)
        #expect(originX(width: 300, icon: nearTheEdge) == 1500)
    }

    @Test("Without an icon the bar's right edge is the screen's right edge")
    func noIcon() {
        #expect(originX(width: 53, icon: nil) == 1747)
    }

    @Test("An icon that is not on this display counts as no icon")
    func iconOnAnotherDisplay() {
        // The external display stands right of the built-in one, from 1800 to 3400.
        #expect(originX(width: 300, icon: icon, screen: 1800...3400) == 3100)
        let left = CGRect(x: 100, y: 7.5, width: 35, height: 24)
        #expect(originX(width: 300, icon: left, screen: 1800...3400) == 3100)
    }

    @Test("An icon parked at the origin with no size counts as no icon")
    func parkedIcon() {
        #expect(originX(width: 300, icon: .zero) == 1500)
    }

    @Test("A second display's bar stays between its own edges")
    func secondDisplay() {
        let onExternal = CGRect(x: 2500, y: 7.5, width: 35, height: 24)
        let x = originX(width: 400, icon: onExternal, screen: 1800...3400)
        // The icon ends at 2535, so the panel ends at 2540.
        #expect(x == 2140)
        #expect(x >= 1800)
        #expect(x + 400 <= 3400)
    }

    @Test("The panel is whole on the screen for every icon position and width")
    func alwaysOnTheScreen() {
        for width in stride(from: 40 as CGFloat, through: 1800, by: 130) {
            for iconX in stride(from: -50 as CGFloat, through: 1850, by: 50) {
                let x = originX(width: width, icon: CGRect(x: iconX, y: 7.5, width: 35, height: 24))
                #expect(x >= 0 && x + width <= 1800, "width \(width), icon at \(iconX): x \(x)")
            }
        }
    }
}
