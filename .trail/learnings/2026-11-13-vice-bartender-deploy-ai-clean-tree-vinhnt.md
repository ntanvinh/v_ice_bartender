---
title: "VIce Bartender: Deploy AI clean-tree failure still open; path-limited commits leave the cache removal staged"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 3, tokens: 101683 }
touches:
  - AGENTS.md
  - Scripts/check-repo.sh
  - README.md
  - Scripts/test.sh
---

## Decided
- The Deploy AI "uncommitted or unsynced changes" failure of "Commit and raise the version" is still caused by the seven tracked trail cache files (.trail/cache/.cache, graft/.cache). HEAD tracks them and their removal is staged but not committed. Local main equals origin/main (009ff41), so the branch is in sync. The fix is to commit the removal and push: a new commit makes main one ahead, which Deploy AI reads as unsynced.
- AGENTS.md (Repository rules) now lists 009ff41 with d657f69, bd5da74 and 2d89c35 as commits whose messages claim the untrack, and says to commit the whole index (no paths) and check that `git diff --cached --name-only` is empty afterwards.
- Scripts/check-repo.sh needed no change. On the real tree it exits 1 and lists the seven paths. With the removal committed (checked in a throwaway clone) it exits 0.

## Tried and ruled out
- Why the false claims recur, confirmed in a throwaway clone: `git commit -- <paths>` commits only those paths and leaves another staged deletion staged (README.md stayed staged after a path-limited commit).
- No other ignored file is tracked in HEAD: `git ls-tree -r HEAD --name-only | git check-ignore --no-index --stdin` lists only the seven. No script runs `git rm --cached` or `git add -f`.
- Not added: a staged-changes check in Scripts/test.sh, because it would block ordinary test runs with work in progress.
- Not done in this session: committing, pushing, and running Deploy AI (the user asked to review first).

## Watch out
- Check a commit's content with `git show --stat <sha>` before reporting it as done. The message can claim an untrack that the commit does not contain.
- Committing the removal alone is not enough. The AGENTS.md edit must be in the same commit, or the tree stays dirty, and local main must be pushed.
- `git restore --staged` on the seven paths tracks them again, so the next trail run shows them as modified. Do not use it.
