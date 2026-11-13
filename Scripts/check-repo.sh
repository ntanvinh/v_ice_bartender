#!/bin/bash
# Fails when git tracks a local cache or a file that a .gitignore rule matches. The trail tool writes its cache into .trail/cache and
# graft/ on each machine, and it changes on every run. Once such files are tracked they show up as changes, and git refuses to add
# them ("ignored by one of your .gitignore files"), which blocks commits. Fix: git rm -r --cached <path> (the files stay on disk).
# It also checks that the README's download step names the file that Scripts/release.sh uploads, and that every local picture or
# link in the Markdown files points to a file that exists. See .trail/README.md. Run by Scripts/test.sh and Scripts/release.sh.
# Outside a git checkout (for example a source archive) there is nothing to check.
source "$(dirname "$0")/common.sh"

cd "$ROOT"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { warn "not a git checkout: the repository check is skipped"; exit 0; }

LOCAL_CACHES=(".trail/cache" "graft")

# Each local cache must be ignored, so that nothing new under it can be added by mistake.
for dir in "${LOCAL_CACHES[@]}"; do
    git check-ignore -q --no-index -- "$dir/probe" || die "$dir/ is not ignored by any .gitignore: add it, see .trail/README.md"
done

# Checked in the index (what the next commit records) and in HEAD (what is published). An untracking that is staged but not committed
# leaves HEAD tracking the files: git then refuses to add them, and the commit step fails with "ignored by .gitignore".
tracked="$({
    git ls-files -- "${LOCAL_CACHES[@]}"
    git ls-files -ci --exclude-standard
    git ls-tree -r --name-only HEAD -- "${LOCAL_CACHES[@]}"
    git ls-tree -r --name-only HEAD | git check-ignore --no-index --stdin || true # exit 1 only means that nothing matched
} | sort -u)"
if [ -n "$tracked" ]; then
    printf '%s\n' "$tracked" | sed 's/^/  tracked: /' >&2
    die "git tracks local cache or ignored files, in the index or in HEAD (listed above). Untrack them with git rm -r --cached <path>, then commit that removal"
fi

# The README's download step must name the file that release.sh uploads with every release: the disk image without a version in
# its name, $APP_NAME.dmg. Any other name (for example a zip that is never made) sends people to a file that does not exist.
readme_asset="$(sed -n 's/^Download `\([^`]*\)`.*/\1/p' README.md | head -1)"
[ "$readme_asset" = "$APP_NAME.dmg" ] \
    || die "README.md must start its download step with Download \`$APP_NAME.dmg\` (found: '${readme_asset:-none}')"
grep -q 'ASSETS=(.*"\$LATEST_DMG")' Scripts/release.sh \
    || die "Scripts/release.sh no longer uploads \$LATEST_DMG ($APP_NAME.dmg), which README.md tells people to download"

# Every local picture or link in a Markdown file must point to a file of the repository, resolved from that file's folder. A moved
# asset leaves a broken picture on the front page: the README's icon still named Ice/Assets.xcassets after the folder had moved to
# Ice/Resources. The notes of the trail tool (.trail/) are not checked: their links point into its local cache, which git ignores.
while IFS= read -r md; do
    base="$ROOT/$(dirname "$md")"
    while IFS= read -r target; do
        path="${target%%#*}"
        case "$path" in ""|http://*|https://*|mailto:*) continue ;; esac
        [ -e "$base/$path" ] || die "$md points to '$target', which is not in the repository"
    done < <(grep -o -E 'src="[^"]*"|\]\([^)]*\)' "$md" | sed -E 's/^src="(.*)"$/\1/; s/^\]\((.*)\)$/\1/')
done < <(git ls-files -- '*.md' | grep -v '^\.trail/')

say "Repository check passed: no local cache or ignored file is tracked, the README names the released file, and every local link exists"
