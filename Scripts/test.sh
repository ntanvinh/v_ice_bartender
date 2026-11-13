#!/bin/bash
# Runs the checks of VIce Bartender. Nothing here opens a window or needs a permission or a signing certificate.
#
#   Scripts/test.sh              the unit tests (swift test): the macOS 27 logic in Ice/MenuBar/MacOS27/Core, see Package.swift
#   Scripts/test.sh --build      also build the app (Debug, not signed) with xcodebuild, to catch what the unit tests cannot compile
#   Scripts/test.sh --all        the same as --build
#   Scripts/test.sh --build-only only the build
#   Scripts/test.sh --filter X   only the unit tests whose name matches X (passed to swift test --filter)
#
# The build goes to a folder of its own (VICE_TEST_BUILD_DIR, default /tmp/vice-test-build), so it never touches an app that is
# running or installed, and its log is next to it. The exit code is 0 only when everything that was asked for passed.
# Every run first checks the repository (Scripts/check-repo.sh): no local cache or ignored file may be tracked.
source "$(dirname "$0")/common.sh"

UNIT=1; BUILD=0; FILTER=""
while [ $# -gt 0 ]; do
    case "$1" in
        --build|--all) BUILD=1 ;;
        --build-only)  BUILD=1; UNIT=0 ;;
        --filter)      shift; [ $# -gt 0 ] || die "--filter needs a name"; FILTER="$1" ;;
        -h|--help)     sed -n '2,/^source/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

cd "$ROOT"
BUILD_DIR="${VICE_TEST_BUILD_DIR:-/tmp/vice-test-build}"
failed=0

# A machine under heavy load makes long steps stall without failing; say so instead of leaving a silent wait.
load="$(uptime | sed -E 's/.*load averages?: ([0-9.]+).*/\1/')"
if [ "${load%%.*}" -ge 40 ] 2>/dev/null; then warn "the machine is busy (load average $load): the steps below can take a few minutes"; fi

"$ROOT/Scripts/check-repo.sh" || failed=1

if [ "$UNIT" = 1 ]; then
    say "Unit tests (swift test)"
    args=(test)
    [ -z "$FILTER" ] || args+=(--filter "$FILTER")
    mkdir -p "$ROOT/.build" # ignored by git; holds the log next to SwiftPM's own files
    if swift "${args[@]}" > "$ROOT/.build/unit-tests.log" 2>&1; then
        say "Unit tests passed: $(grep -E 'Test run with [0-9]+ tests' "$ROOT/.build/unit-tests.log" | tail -1 | sed -E 's/^[^T]*//')"
    else
        failed=1
        grep -E 'error:|✘|failed' "$ROOT/.build/unit-tests.log" | head -30 >&2 || true
        warn "unit tests FAILED, full log: $ROOT/.build/unit-tests.log"
    fi
fi

if [ "$BUILD" = 1 ]; then
    say "Building $DISPLAY_NAME (Debug, not signed) into $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    if xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -derivedDataPath "$BUILD_DIR" \
        CODE_SIGNING_ALLOWED=NO build > "$BUILD_DIR.log" 2>&1; then
        app="$BUILD_DIR/Build/Products/Debug/$DISPLAY_NAME.app"
        [ -d "$app" ] || { failed=1; warn "the build said it succeeded but there is no $app"; }
        got="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
        [ "$got" = "$BUNDLE_ID" ] || { failed=1; warn "the built app has the identifier '$got', expected $BUNDLE_ID"; }
        [ "$failed" = 1 ] || say "Build passed: $app"
    else
        failed=1
        grep -E 'error:' "$BUILD_DIR.log" | head -20 >&2 || true
        warn "build FAILED, full log: $BUILD_DIR.log"
    fi
fi

[ "$failed" = 0 ] && say "All checks passed" || die "some checks failed"
