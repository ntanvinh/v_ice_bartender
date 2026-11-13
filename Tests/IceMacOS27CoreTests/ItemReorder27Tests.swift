import CoreGraphics
import Testing
@testable import IceMacOS27Core

@Suite("ItemReorder27")
struct ItemReorder27Tests {
    @Test("A tile dropped before another goes before the one on its right")
    func beforeRightNeighbour() {
        let destination = ItemReorder27.destination(in: ["a", "x", "b", "c"], dragged: "x")
        #expect(destination == .init(target: "b", side: .before))
    }

    @Test("A tile dropped at the end of the row goes after the one on its left")
    func afterLeftNeighbour() {
        let destination = ItemReorder27.destination(in: ["a", "b", "x"], dragged: "x")
        #expect(destination == .init(target: "b", side: .after))
    }

    @Test("Ice's own icon is never the target")
    func skipsExcluded() {
        #expect(ItemReorder27.destination(in: ["a", "x", "ice", "c"], dragged: "x", excluding: ["ice"]) == .init(target: "c", side: .before))
        #expect(ItemReorder27.destination(in: ["a", "x", "ice"], dragged: "x", excluding: ["ice"]) == .init(target: "a", side: .after))
    }

    @Test("A tile alone in the row, or not in it, needs no move")
    func nothingToDo() {
        #expect(ItemReorder27.destination(in: ["x"], dragged: "x") == nil)
        #expect(ItemReorder27.destination(in: ["x", "ice"], dragged: "x", excluding: ["ice"]) == nil)
        #expect(ItemReorder27.destination(in: ["a", "b"], dragged: "x") == nil)
    }

    @Test("The bar has the item in place when it is next to the target on the wanted side")
    func placed() {
        let before = ItemReorder27.Destination(target: "b", side: .before)
        #expect(ItemReorder27.isPlaced("x", at: before, barOrder: ["a", "x", "b"]))
        #expect(!ItemReorder27.isPlaced("x", at: before, barOrder: ["a", "b", "x"]))
        #expect(!ItemReorder27.isPlaced("x", at: before, barOrder: ["x", "a", "b"]))
        let after = ItemReorder27.Destination(target: "b", side: .after)
        #expect(ItemReorder27.isPlaced("x", at: after, barOrder: ["a", "b", "x"]))
        #expect(!ItemReorder27.isPlaced("x", at: after, barOrder: ["a", "x", "b"]))
        #expect(!ItemReorder27.isPlaced("x", at: after, barOrder: ["a", "b"]))
    }

    /// Measured on macOS 27.2 with items 22 wide at 1515 and 1553: dragging the right one to 1520
    /// put it before the left one, dragging the left one to 1566 put it after the right one, and
    /// an item dragged across Bluetooth and released at 1560 stood just before the item at 1553.
    @Test("The release point is a quarter in from the side the item is to stand on")
    func releasePoint() {
        let item = CGRect(x: 1553, y: 0, width: 22, height: 39)
        let target = CGRect(x: 1515, y: 0, width: 22, height: 39)
        let before = ItemReorder27.dragPoints(itemFrame: item, targetFrame: target, side: .before)
        #expect(before.start == CGPoint(x: 1564, y: 19.5))
        #expect(before.end == CGPoint(x: 1520.5, y: 19.5))
        let after = ItemReorder27.dragPoints(itemFrame: item, targetFrame: target, side: .after)
        #expect(after.end == CGPoint(x: 1531.5, y: 19.5))
    }

    @Test("A narrow target still gets a release point inside it, clear of its centre")
    func narrowTarget() {
        let item = CGRect(x: 100, y: 0, width: 20, height: 24)
        let target = CGRect(x: 200, y: 0, width: 6, height: 24)
        let before = ItemReorder27.dragPoints(itemFrame: item, targetFrame: target, side: .before)
        #expect(before.end.x == 202)
        #expect(before.end.x < target.midX)
    }

    @Test("A longer drag takes more steps, within bounds")
    func steps() {
        #expect(ItemReorder27.stepCount(forDistance: 10) == 24)
        #expect(ItemReorder27.stepCount(forDistance: -100) == 50)
        #expect(ItemReorder27.stepCount(forDistance: 1000) == 80)
    }
}
