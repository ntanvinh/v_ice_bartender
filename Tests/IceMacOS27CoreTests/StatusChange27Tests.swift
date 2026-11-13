import Testing
@testable import IceMacOS27Core

@Suite("StatusChange27")
struct StatusChange27Tests {
    @Test func firstReadingIsAStartingPointNotAChange() {
        var watcher = StatusChange27()
        let changed = watcher.observe(["com.example.App": "Connected"])
        #expect(changed.isEmpty)
    }

    @Test func aChangedTextIsReported() {
        var watcher = StatusChange27()
        _ = watcher.observe(["com.example.App": "Connected"])
        let result = watcher.observe(["com.example.App": "Disconnected"])
        #expect(result == ["com.example.App"])
    }

    @Test func anUnchangedTextIsNotReported() {
        var watcher = StatusChange27()
        _ = watcher.observe(["com.example.App": "Connected"])
        let result = watcher.observe(["com.example.App": "Connected"])
        #expect(result.isEmpty)
    }

    @Test func anApplicationNotReadThisTimeKeepsItsText() {
        var watcher = StatusChange27()
        _ = watcher.observe(["com.example.A": "One", "com.example.B": "Two"])
        let unchanged = watcher.observe(["com.example.A": "One"])
        #expect(unchanged.isEmpty)
        let changed = watcher.observe(["com.example.B": "Three"])
        #expect(changed == ["com.example.B"])
    }

    @Test func anApplicationWithoutTextCannotBeWatched() {
        var watcher = StatusChange27()
        _ = watcher.observe(["com.example.Silent": "", "com.example.Talks": "Ready"])
        #expect(!watcher.canDetect(bundleID: "com.example.Silent"))
        #expect(watcher.canDetect(bundleID: "com.example.Talks"))
        #expect(!watcher.canDetect(bundleID: "com.example.Unknown"))
    }

    @Test func anApplicationThatStartsPublishingTextIsReportedOnce() {
        var watcher = StatusChange27()
        _ = watcher.observe(["com.example.App": ""])
        let result = watcher.observe(["com.example.App": "Ready"])
        #expect(result == ["com.example.App"])
        #expect(watcher.canDetect(bundleID: "com.example.App"))
    }

    @Test func everyChangeOfAnApplicationThatFlipsNowAndThenIsShown() {
        var watcher = StatusChange27()
        // Caps Lock on, off, on, off, on, off, 15 s apart: the second press used to fall in the
        // 30 s of silence after the first reveal and was never shown.
        let shown = [100.0, 115, 130, 145, 160, 175].map { watcher.recordChange(bundleID: "com.example.App", now: $0) }
        #expect(shown == [true, true, true, true, true, true])
    }

    @Test func aChangeWhileTheItemIsShownIsShownToo() {
        var watcher = StatusChange27()
        let first = watcher.recordChange(bundleID: "com.example.App", now: 100)
        let second = watcher.recordChange(bundleID: "com.example.App", now: 103)
        #expect(first)
        #expect(second)
    }

    @Test func anApplicationThatTicksIsLeftAlone() {
        var watcher = StatusChange27()
        // A figure that changes every second for half a minute.
        let shown = (0..<30).map { watcher.recordChange(bundleID: "com.example.Ticker", now: 100 + Double($0)) }
        #expect(shown.filter { $0 }.count == StatusChange27.chattyLimit)
        #expect(shown.prefix(StatusChange27.chattyLimit).allSatisfy { $0 })
    }

    @Test func aTickerStaysQuietForAsLongAsItTicks() {
        var watcher = StatusChange27()
        // One change every 5 s for ten minutes: the ignored changes count too, so each lands in
        // a window that still holds eleven before it, and only the first few are ever shown.
        let shown = (0..<120).map { watcher.recordChange(bundleID: "com.example.Ticker", now: 100 + Double($0) * 5) }
        #expect(shown.filter { $0 }.count == StatusChange27.chattyLimit)
        #expect(shown.prefix(StatusChange27.chattyLimit).allSatisfy { $0 })
    }

    @Test func anApplicationThatChangesOnceInAWhileIsAlwaysShown() {
        var watcher = StatusChange27()
        // One change every 25 s is under three in a window, however long it goes on.
        let shown = (0..<40).map { watcher.recordChange(bundleID: "com.example.Slow", now: 100 + Double($0) * 25) }
        #expect(shown.allSatisfy { $0 })
    }

    @Test func anApplicationThatWasQuietForTheWindowIsShownAgain() {
        var watcher = StatusChange27()
        _ = (0..<10).map { watcher.recordChange(bundleID: "com.example.Ticker", now: 100 + Double($0)) }
        let after = watcher.recordChange(bundleID: "com.example.Ticker", now: 109 + StatusChange27.chattyWindow)
        #expect(after)
    }

    @Test func eachApplicationCountsItsOwnChanges() {
        var watcher = StatusChange27()
        _ = (0..<10).map { watcher.recordChange(bundleID: "com.example.Ticker", now: 100 + Double($0)) }
        let other = watcher.recordChange(bundleID: "com.example.Other", now: 110)
        #expect(other)
    }

    @Test func textJoinsDescriptionTitleAndHelpOnce() {
        #expect(StatusChange27.text(description: "Mode: AI", title: "", help: "Mode: AI") == "Mode: AI")
        #expect(StatusChange27.text(description: nil, title: nil, help: "FortiClient-7.4") == "FortiClient-7.4")
        #expect(StatusChange27.text(description: "A", title: "B", help: "C") == "A | B | C")
        #expect(StatusChange27.text(description: nil, title: " ", help: nil).isEmpty)
    }

    @Test func onlyAHiddenItemWithTheSettingOnIsRevealed() {
        #expect(StatusChange27.shouldReveal(section: .hidden, isEnabled: true))
        #expect(!StatusChange27.shouldReveal(section: .hidden, isEnabled: false))
        #expect(!StatusChange27.shouldReveal(section: .alwaysHidden, isEnabled: true))
        #expect(!StatusChange27.shouldReveal(section: .visible, isEnabled: true))
        #expect(!StatusChange27.shouldReveal(section: nil, isEnabled: true))
    }
}
