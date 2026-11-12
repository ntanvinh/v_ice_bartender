> [!IMPORTANT]
> **VIce Bartender** is a community-maintained fork of [Ice](https://github.com/jordanbaird/Ice) by Jordan Baird, continued because the original project is no longer maintained. It stays open source under GPL-3.0; all original copyright belongs to its author. Upstream is tracked as the `upstream` git remote.
>
> macOS 27 (Golden Gate) support is based on [jordanbaird/Ice#995](https://github.com/jordanbaird/Ice/pull/995) by RabenkoYevhenii (GPL-3.0). On macOS 27 the menu bar is drawn by `MenuBarAgent`, so items are no longer windows; the macOS 27 code path reads them through Accessibility. Moving an app between sections works in Menu Bar Layout, and the order inside a section is set by ⌘-dragging in the menu bar.

<div align="center">
    <img src="Ice/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width=200 height=200>
    <h1>VIce Bartender</h1>
</div>

VIce Bartender is a powerful menu bar management tool. While its primary function is hiding and showing menu bar items, it aims to cover a wide variety of additional features to make it one of the most versatile menu bar tools available.

![Banner](https://github.com/user-attachments/assets/4423085c-4e4b-4f3d-ad0f-90a217c03470)

[![Download](https://img.shields.io/badge/download-latest-brightgreen?style=flat-square)](https://github.com/ntanvinh/v_ice_bartender/releases/latest)
![Platform](https://img.shields.io/badge/platform-macOS-blue?style=flat-square)
![Requirements](https://img.shields.io/badge/requirements-macOS%2014%2B-fa4e49?style=flat-square)
[![License](https://img.shields.io/github/license/ntanvinh/v_ice_bartender?style=flat-square)](LICENSE)

> [!NOTE]
> VIce Bartender is currently in active development. Some features have not yet been implemented. Download the latest release [here](https://github.com/ntanvinh/v_ice_bartender/releases/latest) and see the roadmap below for upcoming features.

## Install

### Manual Installation

Download the "VIce Bartender.zip" file from the [latest release](https://github.com/ntanvinh/v_ice_bartender/releases/latest) and move the unzipped app into your `Applications` folder.

## Features/Roadmap

### Menu bar item management

- [x] Hide menu bar items
- [x] "Always-hidden" menu bar section
- [x] Show hidden menu bar items when hovering over the menu bar
- [x] Show hidden menu bar items when an empty area in the menu bar is clicked
- [x] Show hidden menu bar items by scrolling or swiping in the menu bar
- [x] Automatically rehide menu bar items
- [x] Hide application menus when they overlap with shown menu bar items
- [x] Drag and drop interface to arrange individual menu bar items
- [x] Display hidden menu bar items in a separate bar (e.g. for MacBooks with the notch)
- [x] Search menu bar items
- [x] Menu bar item spacing (BETA)
- [ ] Profiles for menu bar layout
- [ ] Individual spacer items
- [ ] Menu bar item groups
- [ ] Show menu bar items when trigger conditions are met

### Menu bar appearance

- [x] Menu bar tint (solid and gradient)
- [x] Menu bar shadow
- [x] Menu bar border
- [x] Custom menu bar shapes (rounded and/or split)
- [ ] Remove background behind menu bar
- [ ] Rounded screen corners
- [ ] Different settings for light/dark mode

### Hotkeys

- [x] Toggle individual menu bar sections
- [x] Show the search panel
- [x] Enable/disable the Ice Bar
- [x] Show/hide section divider icons
- [x] Toggle application menus
- [ ] Enable/disable auto rehide
- [ ] Temporarily show individual menu bar items

### Other

- [x] Launch at login
- [x] Automatic updates
- [ ] Menu bar widgets

## Why does VIce Bartender only support macOS 14 and later?

VIce Bartender uses a number of system APIs that are available starting in macOS 14. As such, there are no plans to support earlier versions of macOS.

## Gallery

#### Show hidden menu bar items below the menu bar

![Ice Bar](https://github.com/user-attachments/assets/f1429589-6186-4e1b-8aef-592219d49b9b)

#### Drag-and-drop interface to arrange menu bar items

![Menu Bar Layout](https://github.com/user-attachments/assets/095442ba-f2d0-4bb4-9632-91e26ef8d45b)

#### Customize the menu bar's appearance

![Menu Bar Appearance](https://github.com/user-attachments/assets/8c22c185-c3d2-49bb-971e-e1fc17df04b3)

#### Menu bar item search

![Menu Bar Item Search](https://github.com/user-attachments/assets/d1a7df3a-4989-4077-a0b1-8e7d5a1ba5b8)

#### Custom menu bar item spacing

![Menu Bar Item Spacing](https://github.com/user-attachments/assets/b196aa7e-184a-4d4c-b040-502f4aae40a6)

## Development

```sh
Scripts/test.sh              # unit tests (swift test)
Scripts/test.sh --build      # unit tests and an unsigned Debug build of the app
Scripts/version.sh           # show the version and build number
Scripts/version.sh bump patch   # or minor, major, current, or 0.13.0: raises MARKETING_VERSION and the build number, adds a CHANGELOG.md entry
```

## License

VIce Bartender is available under the [GPL-3.0 license](LICENSE).
