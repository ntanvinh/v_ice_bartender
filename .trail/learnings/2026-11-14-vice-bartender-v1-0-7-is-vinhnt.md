---
title: "VIce Bartender: 'v1.0.7 is ahead of latest release v0.11.12' is gh resolving to upstream"
author: Vinhnt
date: 2026-11-14
branch: main
cost: { minutes: 1, tokens: 50141 }
touches:
  - Scripts/release.sh
  - Scripts/release-notes.sh
---

## Decided
- The warning "v1.0.7 is ahead of the latest release (v0.11.12)" is a false alarm. On 2026-11-14 the fork's own release v1.0.7 was already published (tag at 89326dd, DMG, sha256, appcast.xml, en-US + vi notes) and marked Latest on ntanvinh/v_ice_bartender.
- Cause: this repo has three remotes (origin = ntanvinh/v_ice_bartender, upstream = jordanbaird/Ice, rabenko) and no gh default repo. `gh release view` / `gh release list` without `--repo` pick the `upstream` remote and answer with Ice's 0.11.12. Reproduced both ways.
- Fix: `gh repo set-default ntanvinh/v_ice_bartender` (writes only .git/config), or always pass `--repo ntanvinh/v_ice_bartender`. Scripts/release.sh and Scripts/release-notes.sh already pass `--repo`, so they are not affected. The tool printing the warning is outside the repo (not found in it); it is assumed to call gh without `--repo`.

## Tried and ruled out
- Looking for the message text in Scripts/ and .github: it is not there. `git tag` locally shows 0.11.x only because release tags are created on the remote by `gh release create --target`; fetch the tag before trusting local tags.

## Watch out
- Before telling the user "publish manually", run `gh release list --repo ntanvinh/v_ice_bartender`. Scripts/release.sh stops with "release vX already exists" when the version is already out.
- Checked for v1.0.7: project version 1.0.7 (build 1135), appcast live with 1135 and an EdDSA signature, SUFeedURL points at the fork, check-repo.sh passes. Not checked: test.sh, notarization/stapling of the DMG.
- Commits after the tag (1548bb5, 2ba0a58) only touch docs/ and marketing/, no app code.
