#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DERIVED_DATA_DIR="${TMPDIR:-/tmp}/FitnessRPGWatchConnectivityRealDevicePreflight"
RUN_TESTS=1
RUN_BUILDS=1
LIST_DEVICES=1

usage() {
  cat <<'USAGE'
Usage: native/scripts/watchconnectivity-real-device-preflight.sh [options]

Runs local preflight checks before paired iPhone + Apple Watch validation.

Options:
  --skip-tests       Skip Swift package tests.
  --skip-build       Skip iOS/watchOS generic builds.
  --skip-devices     Skip xcrun devicectl device listing.
  --derived-data DIR Use a custom DerivedData directory.
  -h, --help         Show this help.

After preflight, run the iOS app on a paired real iPhone with:
  --fitnessrpg-show-diagnostics

For archive screenshots, launch with:
  --fitnessrpg-open-validation-report-archive

Runbook:
  docs/validation/watchconnectivity-real-device-runbook.md
USAGE
}

log() {
  printf '\n==> %s\n' "$1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)
      RUN_TESTS=0
      shift
      ;;
    --skip-build)
      RUN_BUILDS=0
      shift
      ;;
    --skip-devices)
      LIST_DEVICES=0
      shift
      ;;
    --derived-data)
      if [[ $# -lt 2 ]]; then
        printf '%s\n' '--derived-data requires a directory path.' >&2
        exit 1
      fi
      DERIVED_DATA_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

log "Checking local toolchain"
require_command xcodebuild
require_command xcrun
require_command swift

if [[ "$RUN_TESTS" -eq 1 ]]; then
  log "Running FitnessRPGCore tests"
  swift test --package-path native/FitnessRPGCore
fi

if [[ "$RUN_BUILDS" -eq 1 ]]; then
  log "Building iOS generic target"
  xcodebuild -quiet \
    -project native/FitnessRPG.xcodeproj \
    -scheme FitnessRPG \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_DIR/iOS" \
    CODE_SIGNING_ALLOWED=NO \
    build

  log "Building watchOS generic target"
  xcodebuild -quiet \
    -project native/FitnessRPG.xcodeproj \
    -scheme FitnessRPGWatch \
    -destination 'generic/platform=watchOS' \
    -derivedDataPath "$DERIVED_DATA_DIR/watchOS" \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

if [[ "$LIST_DEVICES" -eq 1 ]]; then
  log "Listing connected devices with devicectl"
  if ! xcrun devicectl list devices; then
    printf '\nCould not list devices from this environment. Continue in Xcode if the paired iPhone and Watch are visible there.\n' >&2
  fi
fi

cat <<'NEXT'

Preflight complete.

Next:
  1. Open native/FitnessRPG.xcodeproj in Xcode.
  2. Select the FitnessRPG iOS scheme and a paired real iPhone.
  3. Add --fitnessrpg-show-diagnostics to Run Arguments.
  4. Install/run the iOS app and confirm the Watch app installs.
  5. Follow docs/validation/watchconnectivity-real-device-runbook.md.
NEXT
