---
title: "VIce Bartender: Deploy AI commit blocked by a cache untracking that was staged but never committed"
author: Vinhnt
date: 2026-11-13
branch: main
touches:
  - Scripts/check-repo.sh
  - AGENTS.md
---

## Decided
- The seven tracked cache files (.trail/cache and graft/.cache) were never untracked in HEAD. `git rm --cached` only staged the removal, and commit d657f69 (already pushed, so not amended) went out without it, although its message says it untracked them. The index shows them as "D " staged, so Deploy AI's "Commit and raise the version" step selects them, and git refuses to add ignored paths: "Nothing to commit: every selected path is ignored".
- Scripts/check-repo.sh now checks HEAD as well as the index: `git ls-tree` for the local caches, and `git check-ignore --no-index` over HEAD for any ignored file. It fails and says to commit the removal.
- AGENTS.md repository rule: a removal from git must be committed, because a staged-only removal leaves HEAD tracking the file.

## Tried and ruled out
- The index-only check passed on the broken state, so the guard missed the bug. Running it on the real tree before the change printed "Repository check passed".
- `git restore --staged` on the seven deletions makes the tree look clean, but it tracks the caches again, so each trail run shows them as modified. Not a fix.
- The release.sh commit step only adds project.pbxproj and CHANGELOG.md; no other ignored path is tracked in HEAD.

## Watch out
- Until the removal is committed, the deploy step still fails: the person commits it after review, then pushes. Verified with a throwaway clone where the removal was committed: the check passes. The real tree fails with the seven paths listed.
- Deploy AI's own step code is outside this repo and was not run.
