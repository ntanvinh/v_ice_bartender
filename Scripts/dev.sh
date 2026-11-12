#!/bin/bash
# Bump the patch version, build VIce Bartender for development, sign it, put it in ~/Applications and open it.
#
# Why not just run it from Xcode or from the build folder: macOS only lists an app in
# System Settings > Privacy & Security when it can find it, and an app that runs from a hidden build folder is
# neither listed nor easy to pick with the "+" button. In ~/Applications it is both. Signing with the same
# certificate every time also keeps the permissions you granted from one build to the next.
#
#   Scripts/dev.sh                       build, install to ~/Applications, open
#   Scripts/dev.sh --no-bump             do not raise the version (the build number stays the same)
#   Scripts/dev.sh --reset-permissions   also forget the Accessibility / Screen Recording grants (to see the first run again)
#   Scripts/dev.sh --no-open             do not open it
source "$(dirname "$0")/common.sh"

RESET=0; OPEN=1; BUMP=1
for arg in "$@"; do
    case "$arg" in
        --reset-permissions) RESET=1 ;;
        --no-open) OPEN=0 ;;
        --no-bump) BUMP=0 ;;
        -h|--help) sed -n '2,/^source/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $arg (see --help)" ;;
    esac
done

DEST="$HOME/Applications/$DISPLAY_NAME.app"
INSTALL=""
cleanup() {
    if [ -n "$INSTALL" ]; then
        # an install that did not finish: the app that was there before goes back
        if [ -d "$INSTALL/previous" ] && [ ! -e "$DEST" ]; then
            mv "$INSTALL/previous" "$DEST"
        fi
        rm -rf "$INSTALL"
    fi
}
trap cleanup EXIT

running() { pgrep -f "$DISPLAY_NAME.app/Contents/MacOS/$DISPLAY_NAME" >/dev/null 2>&1; }
# waits up to <seconds> for the app to be running (or, with "gone", to be not running)
wait_for() { # <running|gone> <seconds>
    local want="$1" i
    for i in $(seq 1 $(($2 * 4))); do
        if [ "$want" = running ] && running; then return 0; fi
        if [ "$want" = gone ] && ! running; then return 0; fi
        sleep 0.25
    done
    return 1
}
# quits the app the way a person would; only when it does not react, it is terminated
stop_app() {
    running || return 0
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    wait_for gone 8 && return 0
    pkill -TERM -f "$DISPLAY_NAME.app/Contents/MacOS/$DISPLAY_NAME" || true
    wait_for gone 5
}

if [ "$BUMP" = 1 ]; then
    say "Bumping patch version for this dev build"
    "$ROOT/Scripts/version.sh" bump patch
fi

DERIVED="$ROOT/build/dev"
mkdir -p "$ROOT/build"
BUILT="$(build_app Debug "$DERIVED" OTHER_CODE_SIGN_FLAGS="--timestamp=none")"
[ -d "$BUILT" ] || die "build did not produce $BUILT"

mkdir -p "$HOME/Applications"
INSTALL="$(mktemp -d "$HOME/Applications/.vicebartender-install.XXXXXX")"
ditto "$BUILT" "$INSTALL/new"
codesign --verify --deep --strict "$INSTALL/new" || die "the new app has a bad signature"

say "Closing $DISPLAY_NAME"
stop_app || die "could not stop the running app; refusing to replace it"

say "Installing to $DEST"
[ ! -e "$DEST" ] || mv "$DEST" "$INSTALL/previous"
mv "$INSTALL/new" "$DEST"
codesign --verify --deep --strict "$DEST" || die "the installed app has a bad signature"
rm -rf "$INSTALL"
INSTALL=""

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
"$LSREGISTER" -f "$DEST" || die "could not register the new app with macOS"

if [ "$RESET" = 1 ]; then
    say "Forgetting the permissions of $BUNDLE_ID"
    tccutil reset Accessibility "$BUNDLE_ID" || true
    tccutil reset ScreenCapture "$BUNDLE_ID" || true
fi

if [ "$OPEN" = 1 ]; then
    say "Opening $DEST"
    open -n "$DEST"
    wait_for running 15 || die "the installed app did not finish launching"
fi
echo "$DEST"
