---
title: Commit blocked by ignored .trail/cache that was tracked
author: Vinhnt
date: 2026-11-12
branch: main
cost: { minutes: 2, tokens: 52980 }
touches:
  - ".gitignore"
  - ".trail/.gitignore"
  - ".trail/README.md"
  - Scripts/check-repo.sh
  - Scripts/test.sh
---

## Decided
- .trail/cache and graft/ (repo root) are the trail tool's cache on each machine and are never committed. .trail/.gitignore ignores cache/, and the root .gitignore now ignores /graft/.
- Both were committed before any ignore rule existed (43470c1, 9722746), so they stayed tracked and showed as modified on every run. They are now untracked with git rm -r --cached; the files stay on disk.
- Scripts/check-repo.sh fails when a local cache is tracked, when a tracked file matches a .gitignore rule, or when a local cache is not ignored. Scripts/test.sh runs it first.

## Tried and ruled out
- Adding the ignore rule alone did not fix the commit error: the files were already tracked, and git still refused the explicit add of the tracked cache files.
- Untracking alone does not make explicit adds of the cache dirs pass: git add -A -- .trail/cache is refused while the ignored files exist on disk. git add -u works.

## Watch out
- git refuses explicit add of ignored paths even when they are tracked. Stage real paths, or use git add -u, never a cache path one by one.
- The seven cache deletions are staged and not yet committed. A tool that re-adds each status path will still be refused for them until the commit is made.
- Only .trail/cache had an auto-written ignore rule. graft/ had none, because it was created by a default-dir run of the trail tool.
