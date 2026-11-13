---
title: "Deploy AI clean-tree failure: cache removal staged but never committed (second time)"
author: Vinhnt
date: 2026-11-13
branch: main
cost: { minutes: 1, tokens: 1717 }
touches:
  - Scripts/check-repo.sh
  - ".trail/README.md"
  - AGENTS.md
---

## Decided
- The deploy step's "uncommitted or unsynced changes" error came from seven tracked trail cache files (.trail/cache/.cache, graft/.cache). Their removal was staged, not committed, so the tree had seven staged deletions and was not clean.
- Commit bd5da74 says it commits that removal, but `git show --stat HEAD` lists only three files. Its message is wrong about its content. Published history is not rewritten; the fix is a commit of the staged removal on main, made by the person after review.
- Scripts/check-repo.sh now distinguishes a removal that is staged but not committed (index no longer lists the path, HEAD still does) and asks for the commit. Before, it told the reader to run `git rm --cached` again, which does nothing once the removal is staged.
- .trail/README.md now says to commit the untrack, matching AGENTS.md.

## Tried and ruled out
- Running `git rm --cached` again or `git restore --staged`: the first is a no-op on a staged removal, the second tracks the caches again.
- Amending or rewriting bd5da74: it is already on origin/main.
- Verified in a throwaway clone under /tmp: tracked with nothing staged exits 1 with the generic message; staged-only exits 1 with the new message; committed passes (exit 0). The real tree exits 1 and lists the seven paths.

## Watch out
- `trail check` flags `git diff --cached` lines in Scripts/check-repo.sh as a conflict with the older learning about `git rm --cached`. It is a false positive: the line reads staged deletions and re-tracks nothing. Say so in the commit message.
- Until the removal is committed on main, the deploy step keeps failing; the commit is the person's step, not a code change.
