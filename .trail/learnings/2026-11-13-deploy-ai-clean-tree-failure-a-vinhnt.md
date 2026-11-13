---
title: "Deploy AI clean-tree failure: a third commit claimed the cache untrack, still not committed"
author: Vinhnt
date: 2026-11-13
branch: main
touches:
  - AGENTS.md
  - Scripts/check-repo.sh
---

## Decided
- The "uncommitted or unsynced changes" error of Deploy AI's "Commit and raise the version" step is still caused by the seven trail cache files (.trail/cache/.cache, graft/.cache). HEAD tracks them and the index has them staged as deleted, so the tree is not clean. Local main equals origin/main (2d89c35), so the branch is in sync.
- d657f69, bd5da74 and 2d89c35 each say the caches were untracked. None of their stats lists the removal: 2d89c35 changes only .trail/README.md, a learning and Scripts/check-repo.sh.
- The fix is a commit of the staged removal on main, after review. Editing files cannot clear a staged deletion, and published history is not rewritten.
- AGENTS.md (Repository rules) now says a commit message must match `git show --stat <sha>`.

## Tried and ruled out
- `git restore --staged` on the seven paths: it tracks the caches again, so every trail run shows them as modified.
- Looking for other ignored files in HEAD: `git ls-tree -r HEAD | git check-ignore --no-index --stdin` lists only these seven.
- Scripts/check-repo.sh is not a gap: on the real tree it already fails with "the removal ... is staged but not committed, so HEAD still tracks them".

## Watch out
- Check a commit's content with `git show --stat <sha>` before reporting it as done; the message can be wrong.
- Until the removal is committed on main, the deploy step fails the same way. Deploy AI is outside this repo and was not run.
