import Testing
@testable import IceMacOS27Core

@Suite("OwnIconSlot27")
struct OwnIconSlot27Tests {
    @Test("Stands at the far right")
    func farRight() {
        #expect(OwnIconSlot27.placing("ice", in: ["a", "b", "c"]) == ["a", "b", "c", "ice"])
    }

    /// The Visible bar as it was reported on 2026-11-12 (macOS 27.2): a system item first, then one
    /// movable item, then system items. The icon used to be put before the first system item,
    /// which is the far left here.
    @Test("Stands at the far right even when a system item is listed first")
    func systemItemFirst() {
        let listed = ["screenSharing", "movable", "user", "bluetooth", "wifi", "sound", "controlCenter", "clock"]
        let placed = OwnIconSlot27.placing("ice", in: listed)
        #expect(placed.last == "ice")
        #expect(placed.dropLast() == listed[...])
    }

    @Test("Stands alone in an empty section")
    func empty() {
        #expect(OwnIconSlot27.placing("ice", in: []) == ["ice"])
    }

    @Test("Is moved to the far right, not listed twice, when it is already listed")
    func alreadyListed() {
        #expect(OwnIconSlot27.placing("ice", in: ["ice", "a", "b"]) == ["a", "b", "ice"])
        #expect(OwnIconSlot27.placing("ice", in: ["a", "ice", "b"]) == ["a", "b", "ice"])
    }
}
