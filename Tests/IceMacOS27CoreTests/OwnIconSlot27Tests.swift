import Testing
@testable import IceMacOS27Core

@Suite("OwnIconSlot27")
struct OwnIconSlot27Tests {
    @Test("Stands before the first item macOS draws itself")
    func beforeSystemItems() {
        #expect(OwnIconSlot27.index(isMovable: [true, true, false, false, false]) == 2)
    }

    @Test("Stands at the end when every item can be moved")
    func atTheEnd() {
        #expect(OwnIconSlot27.index(isMovable: [true, true]) == 2)
    }

    @Test("Stands first when only system items are listed")
    func onlySystemItems() {
        #expect(OwnIconSlot27.index(isMovable: [false, false]) == 0)
    }

    @Test("Stands alone in an empty section")
    func empty() {
        #expect(OwnIconSlot27.index(isMovable: []) == 0)
    }
}
