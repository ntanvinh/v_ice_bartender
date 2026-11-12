import CoreGraphics
import Testing
@testable import IceMacOS27Core

@Suite("OwnIconSlot27")
struct OwnIconSlot27Tests {
    private struct Tile: Equatable {
        let name: String
        let minX: CGFloat
    }

    private func names(_ tiles: [Tile]) -> [String] {
        tiles.map(\.name)
    }

    /// The Visible bar of 2026-11-12 (macOS 27.2), left to right, with the icon's own frame at 1582:
    /// Control Center and the clock stood to its right, the user switcher to its left.
    private let bar = [
        Tile(name: "screenSharing", minX: 1256), Tile(name: "openkey", minX: 1289),
        Tile(name: "bluetooth", minX: 1374), Tile(name: "wifi", minX: 1406), Tile(name: "sound", minX: 1444),
        Tile(name: "textInput", minX: 1473), Tile(name: "userSwitcher", minX: 1558),
        Tile(name: "controlCenter", minX: 1624), Tile(name: "clock", minX: 1662),
    ]

    @Test("Stands where it is on the bar: before Control Center, after the user switcher")
    func whereItIs() {
        let icon = Tile(name: "ice", minX: 1582)
        let placed = OwnIconSlot27.placing(icon, in: bar, ownMinX: 1582, minX: \.minX)
        #expect(names(placed) == [
            "screenSharing", "openkey", "bluetooth", "wifi", "sound", "textInput", "userSwitcher",
            "ice", "controlCenter", "clock",
        ])
    }

    @Test("Never stands at the far left because the leftmost item is one macOS draws itself")
    func notFarLeft() {
        let icon = Tile(name: "ice", minX: 1582)
        let placed = OwnIconSlot27.placing(icon, in: bar, ownMinX: 1582, minX: \.minX)
        #expect(placed.first?.name == "screenSharing")
    }

    @Test("Stands last when its place on the bar was not read")
    func unknownPlace() {
        let icon = Tile(name: "ice", minX: 0)
        let placed = OwnIconSlot27.placing(icon, in: bar, ownMinX: nil, minX: \.minX)
        #expect(placed.last?.name == "ice")
        #expect(placed.dropLast() == bar[...])
    }

    @Test("Stands alone in an empty section")
    func empty() {
        let icon = Tile(name: "ice", minX: 10)
        #expect(OwnIconSlot27.placing(icon, in: [], ownMinX: 10, minX: \.minX) == [icon])
        #expect(OwnIconSlot27.placing(icon, in: [], ownMinX: nil, minX: \.minX) == [icon])
    }

    @Test("Stands first when it is the leftmost, and last when it is the rightmost")
    func edges() {
        let items = [Tile(name: "a", minX: 100), Tile(name: "b", minX: 200)]
        #expect(names(OwnIconSlot27.placing(Tile(name: "ice", minX: 50), in: items, ownMinX: 50, minX: \.minX)) == ["ice", "a", "b"])
        #expect(names(OwnIconSlot27.placing(Tile(name: "ice", minX: 500), in: items, ownMinX: 500, minX: \.minX)) == ["a", "b", "ice"])
    }

    @Test("Is moved, not listed twice, when it is already listed")
    func alreadyListed() {
        let icon = Tile(name: "ice", minX: 150)
        let items = [Tile(name: "a", minX: 100), icon, Tile(name: "b", minX: 200)]
        #expect(names(OwnIconSlot27.placing(icon, in: items, ownMinX: 150, minX: \.minX)) == ["a", "ice", "b"])
        #expect(names(OwnIconSlot27.placing(icon, in: items, ownMinX: nil, minX: \.minX)) == ["a", "b", "ice"])
    }
}
