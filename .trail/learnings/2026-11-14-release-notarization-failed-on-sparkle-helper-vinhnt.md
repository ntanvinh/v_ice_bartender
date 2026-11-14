---
title: Release notarization failed on Sparkle helper signatures
author: Vinhnt
date: 2026-11-14
branch: main
cost: { minutes: 2, tokens: 96105 }
touches:
  - Scripts/common.sh
  - Scripts/release.sh
  - scripts/common.sh
  - scripts/release.sh
---

## Decided
- Sparkle 2.8.0 (SPM xcframework) ships Downloader.xpc, Installer.xpc, Autoupdate and Updater.app ad hoc signed. Xcode signs only Sparkle.framework around them, so notarization rejects them ("not signed with a valid Developer ID certificate", "no secure timestamp").
- Scripts/common.sh: resign_sparkle re-signs those helpers inside out with the Developer ID, --timestamp and runtime, keeping entitlements, then the framework, then the app. Called from release.sh right after build_app.
- Scripts/common.sh: check_developer_id_binaries requires every Mach-O executable in the app to be Developer ID, hardened runtime and timestamped; release.sh runs it before notarizing.

## Tried and ruled out
- Changing OTHER_CODE_SIGN_FLAGS alone: the nested helpers are not re-signed by Xcode, so the flag does not reach them.

## Watch out
- dev.sh and install.sh are not notarized and were left alone; they still produce ad hoc Sparkle helpers.
- Tested on a copy of the built app only; the release script itself was not run.
