#!/bin/bash
# Build, sign and package VIce Bartender for release, and with a version argument do the whole release in one go.
#
#   Scripts/release.sh patch           raise the version (0.11.13 -> 0.11.14; minor, major or an explicit 0.13.0 also work), build,
#                                      sign, notarize, push, publish the GitHub release with the dmg and the Sparkle appcast.
#                                      The app finds the release by itself: it reads
#                                        https://github.com/<repo>/releases/latest/download/appcast.xml
#                                      (the appcast of the newest release) and downloads VIceBartender-<version>.dmg from it.
#                                      The release also carries VIceBartender.dmg, the same file without the version in its name,
#                                      for a fixed download link. "current" releases the version that is in the project without
#                                      raising it (also how a release that stopped half way is finished).
#   Scripts/release.sh patch --yes     the same without asking for confirmation
#   Scripts/release.sh patch --dry-run check everything and say what would happen, change nothing
#
#   Scripts/release.sh                 no version argument: only build, sign, make dist/VIceBartender-<version>.dmg (+ .sha256)
#   Scripts/release.sh --notarize      also have Apple notarize it and staple the ticket (what other Macs need to open it
#                                      without a warning)
#   Scripts/release.sh --publish       also create the GitHub release with the dmg; this puts it online, so it needs
#                                      --notarize as well (ALLOW_UNNOTARIZED=1 to publish anyway)
#
#   --no-appcast                       do not make the Sparkle appcast: the release is online but the apps do not offer it as an update
#
# Signing uses the first "Developer ID Application" certificate in the keychain (SIGN_IDENTITY to pick another).
#
# Notarizing needs your Apple ID credentials in the keychain, once (the profile is per Apple account, so the one made for
# VOpenKey is reused by default):
#   xcrun notarytool store-credentials VOpenKey-notary --apple-id <your apple id> --team-id <team id> --password <app-specific password>
# NOTARY_PROFILE picks another profile name.
#
# The appcast is signed with Sparkle's EdDSA key, which must be the one whose public half is SUPublicEDKey in Ice/Resources/Info.plist.
# That key in the project is still the original author's, so make your own once and put its public half in the plist:
#   <Sparkle>/bin/generate_keys        (<Sparkle> is build/release/SourcePackages/artifacts/sparkle/Sparkle after a first build;
#                                       it keeps the private key in your keychain and prints the public one)
source "$(dirname "$0")/common.sh"

BUMP=""; NOTARIZE=0; PUBLISH=0; ASSUME_YES=0; DRY_RUN=0; APPCAST=1
for arg in "$@"; do
    case "$arg" in
        patch|minor|major|current) BUMP="$arg" ;;
        [0-9]*.[0-9]*.[0-9]*)      BUMP="$arg" ;;
        --notarize)  NOTARIZE=1 ;;
        --publish)   PUBLISH=1 ;;
        --no-appcast) APPCAST=0 ;;
        --yes|-y)    ASSUME_YES=1 ;;
        --dry-run)   DRY_RUN=1 ;;
        -h|--help)   sed -n '2,/^source/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $arg (see --help)" ;;
    esac
done
[ "$DRY_RUN" = 0 ] || [ -n "$BUMP" ] || die "--dry-run goes with a version argument: Scripts/release.sh patch --dry-run"
FULL=0
if [ -n "$BUMP" ]; then # a whole release: it goes online, so it is notarized
    FULL=1; PUBLISH=1
    [ "${ALLOW_UNNOTARIZED:-0}" = 1 ] || NOTARIZE=1
fi
NOTARY_PROFILE="${NOTARY_PROFILE:-VOpenKey-notary}"
BRANCH="main"
REPO="$(git -C "$ROOT" config --get remote.origin.url | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
VERSION_SH="$ROOT/Scripts/version.sh"
INFO_PLIST="$ROOT/Ice/Resources/Info.plist"
EDIT_FILES=("Ice.xcodeproj/project.pbxproj" "CHANGELOG.md")
MIN_MACOS="14.0" # MACOSX_DEPLOYMENT_TARGET of the app target
KEYCHAIN_SERVICE="https://sparkle-project.org" # where Sparkle's generate_keys keeps the private key

# If something goes wrong after the version was raised, the files go back to what they were.
EDITED=0; CHANGELOG_WAS_TRACKED=1
on_exit() {
    local status=$?
    if [ "$status" -ne 0 ] && [ "$EDITED" = 1 ]; then
        git -C "$ROOT" checkout -- Ice.xcodeproj/project.pbxproj 2>/dev/null || true
        if [ "$CHANGELOG_WAS_TRACKED" = 1 ]; then git -C "$ROOT" checkout -- CHANGELOG.md 2>/dev/null || true; else rm -f "$ROOT/CHANGELOG.md"; fi
        warn "the release did not finish: the version change was undone"
    fi
}
trap on_exit EXIT

need_gh() {
    command -v gh >/dev/null || die "this needs the GitHub CLI (brew install gh) and 'gh auth login'"
    gh auth status >/dev/null 2>&1 || die "gh is not logged in: run 'gh auth login'"
}
# Releases are made from main. When the work is on another branch (and committed), bring it to main first: switch to main and merge
# the branch into it, so that "publish" works from wherever the project happens to be checked out. A merge that does not go through
# cleanly is undone and the release stops before anything was changed.
switch_to_main() {
    local branch; branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
    [ "$branch" = "$BRANCH" ] && return 0
    [ "$branch" != HEAD ] || die "releases are made from the $BRANCH branch, and HEAD is detached: git checkout $BRANCH"
    [ -z "$(git -C "$ROOT" status --porcelain)" ] || die "you are on '$branch', not $BRANCH, and there are uncommitted changes: commit or stash them first"
    if [ "$DRY_RUN" = 1 ]; then
        warn "you are on '$branch': a real release would switch to $BRANCH and merge '$branch' into it"
        return 0
    fi
    say "On '$branch': switching to $BRANCH and merging '$branch' into it"
    git -C "$ROOT" worktree prune
    git -C "$ROOT" fetch origin "$BRANCH" --quiet || die "cannot reach GitHub to check $BRANCH"
    git -C "$ROOT" checkout -q "$BRANCH" 2>/dev/null \
        || die "cannot switch to $BRANCH (another worktree may hold it, see: git worktree list)"
    git -C "$ROOT" merge --ff-only -q "origin/$BRANCH" 2>/dev/null || true
    if ! git -C "$ROOT" merge --no-edit -q "$branch" >/dev/null 2>&1; then
        git -C "$ROOT" merge --abort 2>/dev/null
        git -C "$ROOT" checkout -q "$branch"
        die "merging '$branch' into $BRANCH has conflicts, nothing was changed. Resolve it once by hand: git checkout $BRANCH && git merge $branch"
    fi
}
need_clean_main() {
    switch_to_main
    [ "$DRY_RUN" = 1 ] || [ "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || die "releases are made from the $BRANCH branch"
    git -C "$ROOT" fetch origin "$BRANCH" --quiet || die "cannot reach GitHub to check $BRANCH"
    [ "$(git -C "$ROOT" rev-list --count "HEAD..origin/$BRANCH")" = 0 ] || die "$BRANCH is behind origin/$BRANCH: git pull first"
}
need_clean_tree() {
    [ "$DRY_RUN" = 1 ] && return 0
    [ -z "$(git -C "$ROOT" status --porcelain)" ] || die "there are uncommitted changes, commit or stash them first (the release makes its own commit):
$(git -C "$ROOT" status --short | sed 's/^/    /')"
}

# No release goes out with a local cache tracked, or with a README that names a file the release does not publish.
"$ROOT/Scripts/check-repo.sh" || exit 1

# --- checks, before anything is changed -----------------------------------------------------------------------------
if [ "$PUBLISH" = 1 ] && [ "$NOTARIZE" = 0 ] && [ "${ALLOW_UNNOTARIZED:-0}" != 1 ]; then
    die "--publish needs --notarize: an app that is not notarized cannot be opened on other Macs without a warning (ALLOW_UNNOTARIZED=1 to override)"
fi
if [ "$NOTARIZE" = 1 ]; then
    xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
        || die "no notarytool profile named '$NOTARY_PROFILE' in the keychain. Create it once with:
  xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <your apple id> --team-id <team id> --password <app-specific password>"
fi
if [ "$PUBLISH" = 1 ] && [ "$APPCAST" = 1 ]; then
    security find-generic-password -s "$KEYCHAIN_SERVICE" -a ed25519 >/dev/null 2>&1 \
        || die "there is no Sparkle signing key in the keychain, so the apps could not trust an update. Make one (see --help), or release without updates: --no-appcast"
fi
[ "$PUBLISH" = 1 ] && need_gh
if [ "$FULL" = 1 ]; then
    need_clean_main
    need_clean_tree
    NEXT="$("$VERSION_SH" next "$BUMP")" # a plain assignment: when version.sh refuses the version the script stops here
    read -r NEXT_VERSION NEXT_BUILD <<< "$NEXT"
    [ -n "$NEXT_VERSION" ] && [ -n "$NEXT_BUILD" ] || die "could not work out the next version"
    TAG="v$NEXT_VERSION"
    RESUME_RELEASE=0
    if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
        if [ "$BUMP" = current ]; then
            RESUME_RELEASE=1
        else
            die "release $TAG already exists on $REPO"
        fi
    fi
    if [ "$RESUME_RELEASE" = 0 ]; then
        git -C "$ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null && die "tag $TAG already exists"
    fi
    CURRENT="$("$VERSION_SH" current)"

    say "Plan"
    {
        if [ "$RESUME_RELEASE" = 1 ]; then
            echo "  $APP_NAME ${CURRENT% *} (build ${CURRENT#* })"
            echo "  Release $TAG is already on $REPO. Resuming and completing the release:"
            echo "  1. ensure $DISPLAY_NAME.app and the dmg are built and present"
            echo "  2. ensure the files are uploaded to the GitHub release $TAG"
        else
            step=1
            echo "  $APP_NAME ${CURRENT% *} (build ${CURRENT#* })  ->  $NEXT_VERSION (build $NEXT_BUILD)"
            echo "  $step. raise the version in the Xcode project and the change log"; step=$((step + 1))
            if [ "$NOTARIZE" = 1 ]; then echo "  $step. build, sign and notarize $DISPLAY_NAME.app and the dmg"; else echo "  $step. build and sign $DISPLAY_NAME.app and the dmg (NOT notarized)"; fi
            step=$((step + 1))
            if [ "$APPCAST" = 1 ]; then echo "  $step. sign the dmg for Sparkle and make appcast.xml"; step=$((step + 1)); fi
            if [ "$APPCAST" = 1 ]; then echo "  $step. commit and push to $BRANCH, create the GitHub release $TAG on $REPO with the dmg and the appcast"
            else echo "  $step. commit and push to $BRANCH, create the GitHub release $TAG on $REPO with the dmg (no appcast: the apps will not be offered it)"; fi
            [ "$APPCAST" = 0 ] || echo "     From then on the installed apps are offered the update, from the appcast of the newest release."
        fi
    } >&2
    [ "$DRY_RUN" = 1 ] && { say "Dry run: every check passed, nothing was changed"; exit 0; }
    if [ "$ASSUME_YES" != 1 ]; then
        [ -t 0 ] || die "no terminal to ask on, use --yes"
        read -r -p "Go ahead? This puts a release online. [y/N] " answer
        case "$answer" in [yY]*) ;; *) die "cancelled" ;; esac
    fi

    if [ "$RESUME_RELEASE" = 0 ]; then
        git -C "$ROOT" ls-files --error-unmatch CHANGELOG.md >/dev/null 2>&1 || CHANGELOG_WAS_TRACKED=0
        "$VERSION_SH" bump "$BUMP"
        EDITED=1
    fi
fi

IDENTITY="$(find_identity)"
[ -n "$IDENTITY" ] || die "no 'Developer ID Application' certificate in the keychain (set SIGN_IDENTITY to use another)"
STATE="$("$VERSION_SH" current)"; VERSION="${STATE% *}"; BUILD="${STATE#* }"
[ -n "$VERSION" ] && [ -n "$BUILD" ] || die "could not read the version from the Xcode project"
say "Releasing $APP_NAME $VERSION (build $BUILD)"

BUILD_DIR="$ROOT/build/release"
DIST_DIR="$ROOT/dist"
DMG="$DIST_DIR/$APP_NAME-$VERSION.dmg"
LATEST_DMG="$DIST_DIR/$APP_NAME.dmg"
APPCAST_FILE="$DIST_DIR/appcast.xml"
SPARKLE_BIN="$BUILD_DIR/SourcePackages/artifacts/sparkle/Sparkle/bin"

# submit <file>: waits for Apple's verdict, shows the log when it is not "Accepted"
notarize() {
    local file="$1" result
    say "Notarizing $(basename "$file") (this takes a few minutes)"
    if ! result="$(xcrun notarytool submit "$file" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)"; then
        echo "$result" >&2; die "notarization failed"
    fi
    echo "$result" | sed 's/^/    /' >&2
    if ! echo "$result" | grep -q "status: Accepted"; then
        local id; id="$(echo "$result" | sed -n 's/^ *id: //p' | head -1)"
        [ -n "$id" ] && xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE" >&2
        die "Apple did not accept $(basename "$file")"
    fi
}

SKIP_BUILD=0
if [ "${RESUME_RELEASE:-0}" = 1 ] && [ -f "$DMG" ] && [ -f "$DMG.sha256" ]; then
    if codesign --verify "$DMG" >/dev/null 2>&1 && { [ "$NOTARIZE" = 0 ] || xcrun stapler validate "$DMG" >/dev/null 2>&1; }; then
        say "Disk image $(basename "$DMG") is already built, notarized and verified; reusing it"
        SKIP_BUILD=1
        cp "$DMG" "$LATEST_DMG"
    fi
fi

if [ "$SKIP_BUILD" = 0 ]; then
    rm -rf "$BUILD_DIR/Build" "$BUILD_DIR.log" "$ROOT/build/dmg"
    mkdir -p "$BUILD_DIR" "$DIST_DIR"

    # --- build and sign -------------------------------------------------------------------------------------------------
    APP="$(build_app Release "$BUILD_DIR" CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO ENABLE_HARDENED_RUNTIME=YES OTHER_CODE_SIGN_FLAGS="--timestamp")"
    [ -d "$APP" ] || die "build did not produce $APP"

    say "Checking the signature"
    codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | sed 's/^/    /' >&2
    SIGNING="$(codesign -dv --verbose=4 "$APP" 2>&1)"
    echo "$SIGNING" | grep -q "flags=.*runtime" || die "the app is not signed with the hardened runtime, Apple would refuse to notarize it"
    echo "$SIGNING" | grep -q "Timestamp=" || die "the signature has no secure timestamp, Apple would refuse to notarize it"
    BUILT_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Contents/Info.plist")"
    [ "$BUILT_ID" = "$BUNDLE_ID" ] || die "the built app has the identifier '$BUILT_ID', expected $BUNDLE_ID"
    BUILT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
    [ "$BUILT_VERSION" = "$VERSION" ] || die "the built app says version '$BUILT_VERSION', the project says $VERSION"
    echo "    architectures: $(lipo -archs "$APP/Contents/MacOS/$DISPLAY_NAME")" >&2
    echo "    identity:      $(echo "$SIGNING" | sed -n 's/^Authority=\(Developer ID Application.*\)$/\1/p' | head -1)" >&2

    # The appcast is signed with the key in the keychain; the app trusts the public half it carries. They must be a pair, or no
    # installed app would accept this release as an update. Checked before the slow notarization.
    if [ "$PUBLISH" = 1 ] && [ "$APPCAST" = 1 ]; then
        [ -x "$SPARKLE_BIN/generate_keys" ] || die "Sparkle's tools are not in $SPARKLE_BIN"
        KEYCHAIN_PUBLIC="$("$SPARKLE_BIN/generate_keys" -p 2>/dev/null | tail -1)"
        APP_PUBLIC="$(/usr/libexec/PlistBuddy -c 'Print SUPublicEDKey' "$APP/Contents/Info.plist")"
        [ -n "$KEYCHAIN_PUBLIC" ] && [ "$KEYCHAIN_PUBLIC" = "$APP_PUBLIC" ] \
            || die "SUPublicEDKey in the app ($APP_PUBLIC) is not the public half of the Sparkle key in your keychain (${KEYCHAIN_PUBLIC:-none}).
Put the keychain one in Ice/Resources/Info.plist and run again, or release without updates: --no-appcast"
    fi

    # --- notarization -----------------------------------------------------------------------------------------------------
    if [ "$NOTARIZE" = 1 ]; then
        ZIP="$ROOT/build/$APP_NAME-notarize.zip"
        rm -f "$ZIP"; ditto -c -k --keepParent "$APP" "$ZIP"
        notarize "$ZIP"
        say "Stapling the ticket to the app"
        xcrun stapler staple "$APP" >&2
    fi

    # --- disk image -------------------------------------------------------------------------------------------------------
    say "Making $(basename "$DMG")"
    STAGING="$ROOT/build/dmg/$APP_NAME"
    mkdir -p "$STAGING"
    ditto "$APP" "$STAGING/$DISPLAY_NAME.app"
    ln -s /Applications "$STAGING/Applications"
    rm -f "$DMG"
    hdiutil create -volname "$DISPLAY_NAME $VERSION" -srcfolder "$STAGING" -ov -format UDZO -fs HFS+ "$DMG" >/dev/null
    codesign --force --sign "$IDENTITY" --timestamp "$DMG"

    if [ "$NOTARIZE" = 1 ]; then
        notarize "$DMG"
        say "Stapling the ticket to the disk image"
        xcrun stapler staple "$DMG" >&2
        xcrun stapler validate "$DMG" >&2
    fi

    ( cd "$DIST_DIR" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256" )

    # The same file under a name without the version, attached to every release too: GitHub sends
    #   https://github.com/<repo>/releases/latest/download/VIceBartender.dmg
    # to this file of the newest release, so a website can link to that address and never has to change it. (The app updates itself
    # from the appcast, which points at VIceBartender-<version>.dmg, it does not use this copy.)
    cp "$DMG" "$LATEST_DMG"

    # --- what macOS thinks of it ------------------------------------------------------------------------------------------
    say "Gatekeeper's verdict"
    spctl -a -vv -t exec "$STAGING/$DISPLAY_NAME.app" 2>&1 | sed 's/^/    /' >&2 || true
    if [ "$NOTARIZE" = 0 ]; then
        warn "not notarized: it runs on this Mac, but another Mac will warn that it cannot check it for malicious software. Use --notarize for a release."
    fi
fi

# --- Sparkle appcast: one item, the version being released (the feed is the newest release's file, so it never needs older items) ---
make_appcast() {
    [ -x "$SPARKLE_BIN/sign_update" ] || die "Sparkle's sign_update is not in $SPARKLE_BIN (run a build first)"
    local sig length notes
    sig="$("$SPARKLE_BIN/sign_update" "$DMG" 2>/dev/null | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
    [ -n "$sig" ] || die "sign_update did not sign $(basename "$DMG") (is the Sparkle key in the keychain?)"
    length="$(stat -f %z "$DMG")"
    notes="$("$VERSION_SH" notes 2>/dev/null || true)"
    /usr/bin/python3 - "$APPCAST_FILE" "$REPO" "$VERSION" "$BUILD" "$MIN_MACOS" "$sig" "$length" "$(basename "$DMG")" "$DISPLAY_NAME" "$notes" <<'PY'
import email.utils, html, sys
out, repo, version, build, minos, sig, length, dmg, name, notes = sys.argv[1:11]
items = [l[2:].strip() for l in notes.splitlines() if l.startswith('- ')]
body = '<ul>' + ''.join('<li>%s</li>' % html.escape(i) for i in items) + '</ul>' if items else ''
description = '\n      <description><![CDATA[%s]]></description>' % body if body else ''
open(out, 'w', encoding='utf-8').write('''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>%(name)s</title>
    <item>
      <title>%(name)s %(version)s</title>
      <pubDate>%(date)s</pubDate>
      <sparkle:version>%(build)s</sparkle:version>
      <sparkle:shortVersionString>%(version)s</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>%(minos)s</sparkle:minimumSystemVersion>%(description)s
      <enclosure url="https://github.com/%(repo)s/releases/download/v%(version)s/%(dmg)s" length="%(length)s" type="application/octet-stream" sparkle:edSignature="%(sig)s"/>
    </item>
  </channel>
</rss>
''' % dict(name=html.escape(name), version=version, date=email.utils.formatdate(localtime=True), build=build, minos=minos,
           description=description, repo=repo, dmg=dmg, length=length, sig=sig))
PY
    /usr/bin/python3 -c 'import sys, xml.dom.minidom as m; m.parse(sys.argv[1])' "$APPCAST_FILE" || die "the appcast is not valid XML"
    say "Made $(basename "$APPCAST_FILE") for $VERSION (build $BUILD)"
}
ASSETS=("$DMG" "$DMG.sha256" "$LATEST_DMG")
if [ "$PUBLISH" = 1 ] && [ "$APPCAST" = 1 ]; then
    make_appcast
    ASSETS+=("$APPCAST_FILE")
fi

# --- GitHub release ---------------------------------------------------------------------------------------------------
if [ "$PUBLISH" = 1 ]; then
    TAG="v$VERSION"
    if [ "${RESUME_RELEASE:-0}" = 0 ]; then
        gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1 && die "release $TAG already exists on $REPO (raise the version first)"
    fi
    if [ "$FULL" = 1 ]; then
        if [ "${RESUME_RELEASE:-0}" = 0 ]; then
            say "Committing and pushing the new version"
            git -C "$ROOT" add "${EDIT_FILES[@]}"
            if ! git -C "$ROOT" diff --cached --quiet; then
                git -C "$ROOT" commit -q -m "release: $APP_NAME $VERSION (build $BUILD)"
            fi
            EDITED=0 # it is in the history now, it stays
            git -C "$ROOT" push -q origin "HEAD:$BRANCH"
        fi
        SHA="$(git -C "$ROOT" rev-parse HEAD)"
        NOTES="$ROOT/build/release-notes.md"
        "$VERSION_SH" notes > "$NOTES" 2>/dev/null || : > "$NOTES"
        if [ "${RESUME_RELEASE:-0}" = 1 ]; then
            say "Release $TAG already exists on $REPO, ensuring the files are uploaded"
            gh release upload "$TAG" "${ASSETS[@]}" --clobber --repo "$REPO"
        else
            say "Publishing $TAG on $REPO"
            if [ -s "$NOTES" ]; then
                gh release create "$TAG" "${ASSETS[@]}" --repo "$REPO" --target "$SHA" --title "$DISPLAY_NAME $VERSION" --notes-file "$NOTES"
            else
                gh release create "$TAG" "${ASSETS[@]}" --repo "$REPO" --target "$SHA" --title "$DISPLAY_NAME $VERSION" --generate-notes
            fi
        fi
        say "Released: https://github.com/$REPO/releases/tag/$TAG"
        say "Always the newest version, for a website: https://github.com/$REPO/releases/latest/download/$APP_NAME.dmg"
    else
        say "Publishing $TAG on $REPO"
        gh release create "$TAG" "${ASSETS[@]}" --repo "$REPO" --title "$DISPLAY_NAME $VERSION" --generate-notes
    fi
fi

say "Done"
echo "$DMG"
echo "$(cut -d' ' -f1 "$DMG.sha256")  sha256"
