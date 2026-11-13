---
title: "VIce Bartender: untrack the trail cache and tie the README download name to release.sh"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 1, tokens: 4127 }
touches:
  - AGENTS.md
  - README.md
  - ".trail/README.md"
  - Scripts/check-repo.sh
  - Scripts/release.sh
---

## Decided
- .trail/cache and graft/ stay untracked. The last three tracked cache files (trail-branches.json and two session JSONs) were untracked with git rm --cached -f. The files stay on disk.
- Scripts/release.sh runs Scripts/check-repo.sh before anything changes, so a release cannot go out with a tracked cache. Before this, only Scripts/test.sh ran the check.
- check-repo.sh also checks that the README download step starts with Download `$APP_NAME.dmg` (APP_NAME from common.sh), and that the ASSETS line in release.sh still uploads $LATEST_DMG.
- The README install step names VIceBartender.dmg, not the old zip, and keeps the release link.
- AGENTS.md has a Repository rules section after the trail block: never stage .trail/cache or graft/, and keep the README download name in step with release.sh.

## Tried and ruled out
- git rm --cached without -f is refused for trail-branches.json when it has both staged and unstaged changes (status MM). -f with --cached only changes the index.
- A plain grep for VIceBartender.dmg in release.sh matches only comments, so the guard checks the ASSETS line instead.

## Watch out
- The README link has no GitHub release to point to yet: gh release list is empty for ntanvinh/v_ice_bartender. The download works once the first release with VIceBartender.dmg is published.
- The release.sh change was checked with bash -n only. It was not run, because it builds, signs and publishes.
- The learning is not committed. It goes in the same commit as the cache and README changes.
