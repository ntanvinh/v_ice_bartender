import Foundation
import Testing
@testable import IceMacOS27Core

@Suite("TrackedApplications27")
struct TrackedApplications27Tests {
    // The shape MenuBarAgent writes, measured on macOS 27.0.1 (2026-10-22): key, value, key, value.
    static func bundleKey(_ id: String) -> [String: Any] {
        ["bundle": ["_0": id]]
    }

    static func value(for key: [String: Any], isAllowed: Bool) -> [String: Any] {
        ["location": key, "menuItemLocations": [key], "isAllowed": isAllowed]
    }

    static let adhocKey: [String: Any] = ["adhocBinary": ["_0": ["relative": "file:///Users/me/Developer/Ice/Ice"]]]

    let fixture: [Any] = [
        bundleKey("com.bitwarden.desktop"), value(for: bundleKey("com.bitwarden.desktop"), isAllowed: true),
        adhocKey, value(for: adhocKey, isAllowed: true),
        bundleKey("net.matthewpalmer.Horo"), value(for: bundleKey("net.matthewpalmer.Horo"), isAllowed: true),
        bundleKey("com.user.disallowed"), value(for: bundleKey("com.user.disallowed"), isAllowed: false),
    ]

    func same(_ lhs: [Any], _ rhs: [Any]) -> Bool {
        (lhs as NSArray).isEqual(to: rhs)
    }

    @Test("Reads the allowed state of each bundle, and nothing for other keys")
    func reads() {
        #expect(TrackedApplications27.allowedStates(in: fixture) == [
            "com.bitwarden.desktop": true,
            "net.matthewpalmer.Horo": true,
            "com.user.disallowed": false,
        ])
        #expect(TrackedApplications27.entries(in: fixture).map(\.bundleID) == [
            "com.bitwarden.desktop", nil, "net.matthewpalmer.Horo", "com.user.disallowed",
        ])
    }

    @Test("Flipping to false changes only the named bundle")
    func flipToFalse() {
        let (array, changed) = TrackedApplications27.settingAllowed(false, for: ["net.matthewpalmer.Horo"], in: fixture)
        #expect(changed == ["net.matthewpalmer.Horo"])
        #expect(TrackedApplications27.allowedStates(in: array) == [
            "com.bitwarden.desktop": true,
            "net.matthewpalmer.Horo": false,
            "com.user.disallowed": false,
        ])
        #expect(array.count == fixture.count)
        let value = array[5] as? [String: Any]
        #expect((value?["location"] as? NSDictionary)?.isEqual(to: Self.bundleKey("net.matthewpalmer.Horo")) == true)
        #expect((value?["menuItemLocations"] as? NSArray)?.isEqual(to: [Self.bundleKey("net.matthewpalmer.Horo")]) == true)
    }

    @Test("Flipping back restores the original exactly")
    func flipBack() {
        let hidden = TrackedApplications27.settingAllowed(false, for: ["com.bitwarden.desktop", "net.matthewpalmer.Horo"], in: fixture)
        #expect(hidden.changed == ["com.bitwarden.desktop", "net.matthewpalmer.Horo"])
        let shown = TrackedApplications27.settingAllowed(true, for: hidden.changed, in: hidden.array)
        #expect(shown.changed == hidden.changed)
        #expect(same(shown.array, fixture))
    }

    @Test("An unknown bundle, or one already as asked, changes nothing")
    func unknown() {
        let (array, changed) = TrackedApplications27.settingAllowed(false, for: ["com.example.missing", "com.user.disallowed"], in: fixture)
        #expect(changed.isEmpty)
        #expect(same(array, fixture))
    }

    @Test("Keys that are not bundle keys are passed through untouched")
    func nonBundlePreserved() {
        let (array, _) = TrackedApplications27.settingAllowed(false, for: ["com.bitwarden.desktop", "net.matthewpalmer.Horo"], in: fixture)
        #expect((array[2] as? NSDictionary)?.isEqual(to: Self.adhocKey) == true)
        #expect((array[3] as? NSDictionary)?.isEqual(to: Self.value(for: Self.adhocKey, isAllowed: true)) == true)
    }

    @Test("Round-trips through the binary property list exactly")
    func roundTrip() throws {
        let data = try TrackedApplications27.encode(fixture)
        let decoded = try #require(TrackedApplications27.decode(data))
        #expect(same(decoded, fixture))
        let unchanged = TrackedApplications27.settingAllowed(true, for: [], in: decoded)
        #expect(same(unchanged.array, fixture))
    }

    @Test("An unpaired element at the end is kept and not read")
    func unpaired() {
        let odd = fixture + [Self.bundleKey("com.trailing.key")]
        #expect(TrackedApplications27.entries(in: odd).count == 4)
        let (array, _) = TrackedApplications27.settingAllowed(false, for: ["com.trailing.key"], in: odd)
        #expect(same(array, odd))
    }
}

@Suite("TrackedApplications27 – the switch must list the item")
struct TrackedApplications27RegistrationTests {
    typealias Fixtures = TrackedApplications27Tests

    /// iTerm2's switch as it was on 2026-11-12 (macOS 27.2): off, listing only a Chrome for Testing binary.
    static let itermKey = Fixtures.bundleKey("com.googlecode.iterm2")
    static let chromeLocation: [String: Any] = [
        "adhocBinary": ["_0": ["relative": "file:///Users/me/Library/Caches/ms-playwright/chrome-mac/Google%20Chrome%20for%20Testing.app/Contents/MacOS/Google%20Chrome%20for%20Testing"]],
    ]
    static let iterm: [Any] = [
        itermKey, ["location": itermKey, "menuItemLocations": [chromeLocation], "isAllowed": false] as [String: Any],
    ]

    @Test("A switch that lists a foreign binary does not cover the application's own item")
    func foreignBinary() {
        #expect(!TrackedApplications27.switchCoversItem(
            ofBundle: "com.googlecode.iterm2", at: "/Applications/iTerm.app", switchID: "com.googlecode.iterm2", in: Self.iterm
        ))
    }

    @Test("Registering adds the owner's bundle to that switch's locations, and nothing else")
    func registers() throws {
        let (array, changed) = TrackedApplications27.registeringItem(
            ofBundle: "com.googlecode.iterm2", at: "/Applications/iTerm.app", underSwitch: "com.googlecode.iterm2", in: Self.iterm
        )
        #expect(changed)
        #expect(array.count == Self.iterm.count)
        let value = try #require(array[1] as? [String: Any])
        let locations = try #require(value["menuItemLocations"] as? [Any])
        #expect(locations.count == 2)
        #expect((locations[0] as? NSDictionary)?.isEqual(to: Self.chromeLocation) == true)
        #expect((locations[1] as? NSDictionary)?.isEqual(to: Fixtures.bundleKey("com.googlecode.iterm2")) == true)
        #expect(value["isAllowed"] as? Bool == false)
        #expect((value["location"] as? NSDictionary)?.isEqual(to: Self.itermKey) == true)
    }

    @Test("Registering twice changes nothing the second time")
    func idempotent() {
        let once = TrackedApplications27.registeringItem(
            ofBundle: "com.googlecode.iterm2", at: "/Applications/iTerm.app", underSwitch: "com.googlecode.iterm2", in: Self.iterm
        )
        let twice = TrackedApplications27.registeringItem(
            ofBundle: "com.googlecode.iterm2", at: "/Applications/iTerm.app", underSwitch: "com.googlecode.iterm2", in: once.array
        )
        #expect(!twice.changed)
        #expect((twice.array as NSArray).isEqual(to: once.array))
    }

    @Test("An application signed on this Mac is covered by a binary inside its own bundle")
    func adhocInsideOwnBundle() {
        let key = Fixtures.bundleKey("vn.io.lssoft.vmonitorai")
        let location: [String: Any] = ["adhocBinary": ["_0": ["relative": "file:///Users/me/Applications/VMonitor%20AI.app/Contents/MacOS/VMonitor%20AI"]]]
        let array: [Any] = [key, ["location": key, "menuItemLocations": [location], "isAllowed": false] as [String: Any]]
        #expect(TrackedApplications27.switchCoversItem(
            ofBundle: "vn.io.lssoft.vmonitorai", at: "/Users/me/Applications/VMonitor AI.app", switchID: "vn.io.lssoft.vmonitorai", in: array
        ))
        let result = TrackedApplications27.registeringItem(
            ofBundle: "vn.io.lssoft.vmonitorai", at: "/Users/me/Applications/VMonitor AI.app", underSwitch: "vn.io.lssoft.vmonitorai", in: array
        )
        #expect(!result.changed)
    }

    @Test("A helper's bundle listed by the application's switch is covered, as FortiClient's is")
    func helperBundleListed() {
        let key = Fixtures.bundleKey("com.fortinet.FortiClient")
        let helper = Fixtures.bundleKey("com.fortinet.forticlient.macos.vpn")
        let array: [Any] = [key, ["location": key, "menuItemLocations": [helper, key], "isAllowed": false] as [String: Any]]
        #expect(TrackedApplications27.switchCoversItem(
            ofBundle: "com.fortinet.forticlient.macos.vpn", at: "/Applications/FortiClient.app/Contents/Helpers/vpn.app", switchID: "com.fortinet.FortiClient", in: array
        ))
    }

    @Test("An unknown switch, or one with no list, is left alone")
    func leftAlone() {
        #expect(TrackedApplications27.switchCoversItem(ofBundle: "x", at: "/x.app", switchID: "missing", in: Self.iterm))
        let key = Fixtures.bundleKey("a.b")
        let bare: [Any] = [key, ["location": key, "isAllowed": false] as [String: Any]]
        let result = TrackedApplications27.registeringItem(ofBundle: "a.b", at: "/a.app", underSwitch: "a.b", in: bare)
        #expect(!result.changed)
        #expect((result.array as NSArray).isEqual(to: bare))
    }
}
