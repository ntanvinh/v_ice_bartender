import Testing
@testable import IceMacOS27Core

@Suite("NativeSwitch27")
struct NativeSwitch27Tests {
    /// The list as it was on 2026-11-12 (macOS 27.2): no entry for Text Input, the VPN item or Spotlight's.
    private let tracked: Set<String> = ["com.googlecode.iterm2", "com.apple.ScriptMonitor", "vn.io.lssoft.vopenkey"]

    @Test("macOS's own items that have no entry cannot be hidden by Ice")
    func appleWithoutEntry() {
        #expect(!NativeSwitch27.canIceHide(bundleID: "com.apple.TextInputMenuAgent", tracked: tracked))
        #expect(!NativeSwitch27.canIceHide(bundleID: "com.apple.systemuiserver", tracked: tracked))
        #expect(!NativeSwitch27.canIceHide(bundleID: "com.apple.campo", tracked: tracked))
    }

    @Test("An Apple application that has an entry can be hidden")
    func appleWithEntry() {
        #expect(NativeSwitch27.canIceHide(bundleID: "com.apple.ScriptMonitor", tracked: tracked))
    }

    @Test("An application that is not macOS's own can be hidden, with an entry or not yet")
    func others() {
        #expect(NativeSwitch27.canIceHide(bundleID: "com.googlecode.iterm2", tracked: tracked))
        #expect(NativeSwitch27.canIceHide(bundleID: "com.example.never-created-an-item", tracked: tracked))
    }

    @Test("Nothing is refused when the list could not be read")
    func unreadable() {
        #expect(NativeSwitch27.canIceHide(bundleID: "com.apple.TextInputMenuAgent", tracked: nil))
    }

    @Test("Names the switch for the items that have one")
    func labels() {
        #expect(NativeSwitch27.label(bundleID: "com.apple.TextInputMenuAgent", title: "ABC") == "Text Input")
        #expect(NativeSwitch27.label(bundleID: "com.apple.systemuiserver", title: "VPN") == "VPN")
        #expect(NativeSwitch27.label(bundleID: "com.apple.campo", title: "Search") == "Spotlight")
    }

    @Test("Names nothing it does not know")
    func unknown() {
        #expect(NativeSwitch27.label(bundleID: "com.apple.systemuiserver", title: "Time Machine") == nil)
        #expect(NativeSwitch27.label(bundleID: "com.apple.systemuiserver", title: nil) == nil)
        #expect(NativeSwitch27.label(bundleID: "com.googlecode.iterm2", title: nil) == nil)
    }

    @Test("The pane's checkbox is named after the switch")
    func accessibilityIdentifiers() {
        #expect(NativeSwitch27.textInput.accessibilityIdentifier == "controlcenter-textInput-id")
        #expect(NativeSwitch27.vpn.accessibilityIdentifier == "controlcenter-vpn-id")
        #expect(NativeSwitch27.spotlight.accessibilityIdentifier == "controlcenter-spotlight-id")
        #expect(NativeSwitch27.menuBarSwitch(bundleID: "com.apple.TextInputMenuAgent", title: nil) == NativeSwitch27.textInput)
        #expect(NativeSwitch27.menuBarSwitch(bundleID: "com.apple.systemuiserver", title: "Time Machine") == nil)
    }

    @Test("Records what was turned off, once, and forgets it when turned back on")
    func recording() {
        let off = NativeSwitch27.recording(NativeSwitch27.vpn, shown: false, in: [])
        #expect(off == ["vpn"])
        #expect(NativeSwitch27.recording(NativeSwitch27.vpn, shown: false, in: off) == ["vpn"])
        let more = NativeSwitch27.recording(NativeSwitch27.spotlight, shown: false, in: off)
        #expect(more == ["spotlight", "vpn"])
        #expect(NativeSwitch27.recording(NativeSwitch27.vpn, shown: true, in: more) == ["spotlight"])
        #expect(NativeSwitch27.recording(NativeSwitch27.textInput, shown: true, in: more) == more)
    }
}
