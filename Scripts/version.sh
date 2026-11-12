#!/bin/bash
# The version of VIce Bartender: show it, raise it, print its release notes. Same commands as VOpenKey's version.sh.
#
#   Scripts/version.sh                       show the version and build number, and whether the Debug and Release configurations agree
#   Scripts/version.sh next <bump>           print the next version ("0.12.1 1122") without changing anything
#   Scripts/version.sh bump <bump>           raise the version and the build number in the Xcode project and add an entry to CHANGELOG.md
#   Scripts/version.sh current               print "<version> <build>" of the project, for other scripts
#   Scripts/version.sh notes                 print the CHANGELOG.md entry of the current version (the release notes)
#
# <bump> is patch, minor, major, an explicit version such as 0.13.0, or "current" (no change, for a version that was raised by hand
# and is not released yet: it only makes sure the change log has an entry).
#
# The version is x.y.z (MARKETING_VERSION, what people see and Sparkle shows). The build number (CURRENT_PROJECT_VERSION, what Sparkle
# compares) goes up by one each time the version changes. Only the app target is touched: the MenuBarItemService helper inside it
# keeps its own 1.0 (1).
#
# A version with a suffix, such as 0.11.13-dev.2a, counts as the pre-release of its x.y.z core: "patch" from it gives 0.11.13 (the
# release it was leading up to), "minor" and "major" count from the core.
source "$(dirname "$0")/common.sh"

PBX="$PROJECT/project.pbxproj"
CHANGELOG="$ROOT/CHANGELOG.md"
[ -f "$PBX" ] || die "version.sh: $PBX is missing (run it from a full checkout)"

# --- reading and writing the Xcode project --------------------------------------------------------------------------------
# The app target has two build configurations (Debug, Release); they are found by their bundle identifier, so the helper's
# own version is never read or written. Prints "<marketing version> <build>" per configuration, or writes both into each.
pbx() { # read | write <version> <build>
    /usr/bin/python3 - "$PBX" "$BUNDLE_ID" "$@" <<'PY'
import re, sys
path, bundle, mode = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding='utf-8').read()
block = re.compile(r'(buildSettings = \{\n)(.*?)(\n\t\t\t\};)', re.S)
found = []
def edit(m):
    body = m.group(2)
    if 'PRODUCT_BUNDLE_IDENTIFIER = %s;' % bundle not in body:
        return m.group(0)
    mv = re.search(r'MARKETING_VERSION = ([^;]*);', body)
    cv = re.search(r'CURRENT_PROJECT_VERSION = ([^;]*);', body)
    if not mv or not cv:
        sys.exit('the %s configuration has no MARKETING_VERSION or CURRENT_PROJECT_VERSION' % bundle)
    found.append((mv.group(1).strip('"'), cv.group(1)))
    if mode == 'write':
        version, build = sys.argv[4], sys.argv[5]
        quoted = version if re.fullmatch(r'[0-9.]+', version) else '"%s"' % version
        body = re.sub(r'MARKETING_VERSION = [^;]*;', lambda _: 'MARKETING_VERSION = %s;' % quoted, body)
        body = re.sub(r'CURRENT_PROJECT_VERSION = [^;]*;', lambda _: 'CURRENT_PROJECT_VERSION = %s;' % build, body)
    return m.group(1) + body + m.group(3)
new = block.sub(edit, text)
if not found:
    sys.exit('no build configuration with the bundle identifier %s in the Xcode project' % bundle)
if mode == 'write':
    open(path, 'w', encoding='utf-8').write(new)
else:
    for v, b in found:
        print(v, b)
PY
}

# the configurations must say the same; prints "<version> <build>"
project_state() {
    local all; all="$(pbx read | sort -u)"
    [ "$(printf '%s\n' "$all" | wc -l | tr -d ' ')" = 1 ] || die "the Debug and Release configurations of the project disagree on the version: $(printf '%s' "$all" | tr '\n' ';')"
    echo "$all"
}
project_version() { project_state | cut -d' ' -f1; }
project_build()   { project_state | cut -d' ' -f2; }

core_of()       { echo "$1" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/'; }
valid_version() { echo "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; }

# a.b.c > d.e.f ?  (0 when the first is newer, 1 otherwise; equal is "not newer")
newer() {
    local IFS=.; local a=($1) b=($2) i
    for i in 0 1 2; do
        [ "${a[$i]}" -gt "${b[$i]}" ] && return 0
        [ "${a[$i]}" -lt "${b[$i]}" ] && return 1
    done
    return 1
}

next_version() {
    local bump="$1" current core suffix=0; current="$(project_version)"; core="$(core_of "$current")"
    valid_version "$core" || die "the project version '$current' does not start with x.y.z"
    [ "$core" = "$current" ] || suffix=1
    local IFS=.; local p=($core)
    case "$bump" in
        patch)   if [ "$suffix" = 1 ]; then echo "$core"; else echo "${p[0]}.${p[1]}.$((p[2] + 1))"; fi ;;
        minor)   echo "${p[0]}.$((p[1] + 1)).0" ;;
        major)   echo "$((p[0] + 1)).0.0" ;;
        current) echo "$current" ;;
        *) valid_version "$bump" || die "'$bump' is not patch, minor, major, current or a version like 0.13.0"
           # a pre-release of x.y.z is older than x.y.z itself, so x.y.z may follow it
           if [ "$bump" != "$current" ] && ! newer "$bump" "$core" && ! { [ "$suffix" = 1 ] && [ "$bump" = "$core" ]; }; then
               die "$bump is not newer than the current version $current"
           fi
           echo "$bump" ;;
    esac
}

# --- the change log -------------------------------------------------------------------------------------------------------
# The commit the last release was made at: the newest of the last version tag (v1.2.3) and the last commit whose message starts
# with "release". Empty when there has never been one.
last_release_commit() {
    local tag tag_commit="" marker best="" candidate
    tag="$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
    [ -z "$tag" ] || tag_commit="$(git -C "$ROOT" rev-list -n1 "$tag")"
    marker="$(git -C "$ROOT" log -n1 --format=%H -E --grep='^(release|chore: release)' 2>/dev/null || true)"
    for candidate in "$tag_commit" "$marker"; do
        [ -n "$candidate" ] || continue
        if [ -z "$best" ] || [ "$(git -C "$ROOT" rev-list --count "$candidate"..HEAD)" -lt "$(git -C "$ROOT" rev-list --count "$best"..HEAD)" ]; then
            best="$candidate"
        fi
    done
    echo "$best"
}

# Adds an entry for the version at the top of CHANGELOG.md (made if it does not exist), from the commit messages since the last
# release, unless there is one already (written by hand before releasing).
add_changelog_entry() { # <version> <build>
    local v="$1" b="$2"
    if [ -f "$CHANGELOG" ] && grep -q "^## $v " "$CHANGELOG"; then
        say "The change log already has an entry for $v, keeping it"
        return
    fi
    local base notes="" total count
    base="$(last_release_commit)"
    if [ -n "$base" ]; then
        notes="$(git -C "$ROOT" log "$base"..HEAD --no-merges --pretty='- %s' | grep -Ev '^- (release|chore: release)' || true)"
    else # never released: the last few, not the whole history
        notes="$(git -C "$ROOT" log -n 15 --no-merges --pretty='- %s' | grep -Ev '^- (release|chore: release)' || true)"
    fi
    total="$(printf '%s\n' "$notes" | grep -c . || true)"
    if [ "${total:-0}" -gt 30 ]; then
        count=$((total - 30))
        notes="$(printf '%s\n' "$notes" | head -30)"$'\n'"- ... and $count more changes."
    fi
    [ -n "$notes" ] || notes="- Version update."
    local entry; entry="$(printf '## %s (build %s) - %s\n%s\n' "$v" "$b" "$(date +%Y-%m-%d)" "$notes")"
    /usr/bin/python3 - "$CHANGELOG" "$entry" <<'PY'
import os, sys
path, entry = sys.argv[1], sys.argv[2]
if os.path.exists(path):
    text = open(path, encoding='utf-8').read()
    head, sep, rest = text.partition('\n\n')
else:
    head, sep, rest = '# Changelog', '\n\n', ''
open(path, 'w', encoding='utf-8').write(head + sep + entry + '\n\n' + rest)
PY
}

changelog_notes() { # the entry of the current version, without its heading
    local v; v="$(project_version)"
    [ -f "$CHANGELOG" ] || die "there is no CHANGELOG.md yet: Scripts/version.sh bump current"
    awk -v h="## $v " 'index($0, h) == 1 { on = 1; next } on && /^## / { exit } on { print }' "$CHANGELOG" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# --- commands -------------------------------------------------------------------------------------------------------------
cmd="${1:-show}"
case "$cmd" in
    show)
        state="$(project_state)"
        printf '  %-28s %s (build %s)\n' "$DISPLAY_NAME ($BUNDLE_ID)" "${state% *}" "${state#* }"
        if [ -f "$CHANGELOG" ] && grep -q "^## ${state% *} " "$CHANGELOG"; then
            printf '  %-28s has an entry for %s\n' "CHANGELOG.md" "${state% *}"
        else
            warn "CHANGELOG.md has no entry for ${state% *}: Scripts/version.sh bump current"
        fi
        ;;
    next)
        [ -n "${2:-}" ] || die "usage: version.sh next <patch|minor|major|x.y.z|current>"
        new="$(next_version "$2")"; build="$(project_build)"
        [ "$new" = "$(project_version)" ] || build=$((build + 1))
        echo "$new $build"
        ;;
    bump)
        [ -n "${2:-}" ] || die "usage: version.sh bump <patch|minor|major|x.y.z|current>"
        new="$(next_version "$2")"; old="$(project_version)"; build="$(project_build)"
        if [ "$new" != "$old" ]; then build=$((build + 1)); fi
        pbx write "$new" "$build"
        [ "$(project_state)" = "$new $build" ] || die "could not write the version into the Xcode project"
        add_changelog_entry "$new" "$build"
        say "Version is now $new (build $build)"
        ;;
    current)  project_state ;;
    notes)    changelog_notes ;;
    -h|--help|help) sed -n '2,/^source/p' "$0" | sed '$d; s/^# \{0,1\}//' ;;
    *) die "unknown command: $cmd (see --help)" ;;
esac
