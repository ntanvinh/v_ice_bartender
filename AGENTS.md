<!-- trail:start -->
## Trail — repo context graph

This repo is indexed in `.trail/cache/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `trail map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `trail ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `trail grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `trail skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `trail callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `.trail/cache/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `trail ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `trail build` (deterministic,
no API key, $0).
<!-- trail:end -->

## Repository rules
- Never commit or stage `.trail/cache/` or `graft/` (the trail tool's per-machine cache). When git refuses a path as ignored, untrack it with `git rm -r --cached <path>`, never `git add -f`, and commit that removal: a removal that is only staged leaves HEAD tracking the file. `Scripts/check-repo.sh` fails when one is tracked in the index or in HEAD; `Scripts/test.sh` and `Scripts/release.sh` run it first.
- The README's download step names `VIceBartender.dmg`, the file `Scripts/release.sh` uploads with every release. Change the two together; `Scripts/check-repo.sh` fails when they differ.
- Every local picture or link in a Markdown file must point to a file that exists in the repository (paths are relative to that file). When you move or rename an asset, update the Markdown that shows it; `Scripts/check-repo.sh` fails on a missing target.
- A commit message must describe what the commit contains. Before you say a commit untracks, removes, adds or renames a file, check it with `git show --stat <sha>` and make sure the file is listed. d657f69, bd5da74 and 2d89c35 each said the seven trail cache files were untracked, but none of their stats lists them, so HEAD still tracks them and the tree stays dirty.
