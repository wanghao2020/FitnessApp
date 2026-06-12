#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DERIVED_DATA_DIR="${TMPDIR:-/tmp}/FitnessRPGEndToEndRealDevicePreflight"
RUN_TESTS=1
RUN_BUILDS=1
LIST_DEVICES=1
REQUIRE_REAL_RUNTIME=0

usage() {
  cat <<'USAGE'
Usage: native/scripts/end-to-end-real-device-preflight.sh [options]

Runs aggregate local checks before the full real-device validation pass.

Options:
  --skip-tests           Skip Swift package tests.
  --skip-build           Skip iOS/watchOS generic builds.
  --skip-devices         Skip xcrun devicectl device listing.
  --require-real-runtime Require LiteRT-LM model package, SDK reference, and FITNESSRPG_ENABLE_LITERTLM flag.
  --derived-data DIR     Use a custom DerivedData directory.
  -h, --help             Show this help.

Runbook:
  docs/validation/end-to-end-real-device-runbook.md

Default DEBUG Run Argument:
  --fitnessrpg-show-diagnostics

Archive Run Argument:
  --fitnessrpg-open-validation-report-archive
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
    --require-real-runtime)
      REQUIRE_REAL_RUNTIME=1
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
require_command bash
require_command xcodebuild
require_command xcrun
require_command swift

log "Checking WatchConnectivity wiring"
bash native/scripts/watchconnectivity-real-device-preflight.sh \
  --skip-build \
  --skip-tests \
  --skip-devices

log "Checking HealthKit wiring"
bash native/scripts/healthkit-real-device-preflight.sh \
  --skip-build \
  --skip-tests

log "Checking LiteRT-LM / Gemma wiring"
litertlm_args=(--skip-build --skip-tests)
if [[ "$REQUIRE_REAL_RUNTIME" -eq 1 ]]; then
  litertlm_args+=(--require-real-runtime)
fi
bash native/scripts/litertlm-real-device-preflight.sh "${litertlm_args[@]}"

if [[ "$RUN_TESTS" -eq 1 ]]; then
  log "Running FitnessRPGCore tests once"
  mkdir -p \
    "$DERIVED_DATA_DIR/SwiftPM/cache" \
    "$DERIVED_DATA_DIR/SwiftPM/config" \
    "$DERIVED_DATA_DIR/SwiftPM/security" \
    "$DERIVED_DATA_DIR/SwiftPM/scratch" \
    "$DERIVED_DATA_DIR/SwiftPM/module-cache"

  CLANG_MODULE_CACHE_PATH="$DERIVED_DATA_DIR/SwiftPM/module-cache" swift test \
    --package-path native/FitnessRPGCore \
    --cache-path "$DERIVED_DATA_DIR/SwiftPM/cache" \
    --config-path "$DERIVED_DATA_DIR/SwiftPM/config" \
    --security-path "$DERIVED_DATA_DIR/SwiftPM/security" \
    --scratch-path "$DERIVED_DATA_DIR/SwiftPM/scratch" \
    --manifest-cache local \
    --disable-sandbox
fi

if [[ "$RUN_BUILDS" -eq 1 ]]; then
  mkdir -p \
    "$DERIVED_DATA_DIR/XcodeModuleCache" \
    "$DERIVED_DATA_DIR/SourcePackages" \
    "$DERIVED_DATA_DIR/PackageCache"

  log "Building iOS generic target once"
  CLANG_MODULE_CACHE_PATH="$DERIVED_DATA_DIR/XcodeModuleCache" xcodebuild -quiet \
    -project native/FitnessRPG.xcodeproj \
    -scheme FitnessRPG \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_DIR/iOS" \
    -clonedSourcePackagesDirPath "$DERIVED_DATA_DIR/SourcePackages" \
    -packageCachePath "$DERIVED_DATA_DIR/PackageCache" \
    CODE_SIGNING_ALLOWED=NO \
    build

  log "Building watchOS generic target once"
  CLANG_MODULE_CACHE_PATH="$DERIVED_DATA_DIR/XcodeModuleCache" xcodebuild -quiet \
    -project native/FitnessRPG.xcodeproj \
    -scheme FitnessRPGWatch \
    -destination 'generic/platform=watchOS' \
    -derivedDataPath "$DERIVED_DATA_DIR/watchOS" \
    -clonedSourcePackagesDirPath "$DERIVED_DATA_DIR/SourcePackages" \
    -packageCachePath "$DERIVED_DATA_DIR/PackageCache" \
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

End-to-end real-device preflight complete.

Next:
  1. Open native/FitnessRPG.xcodeproj in Xcode.
  2. Select the FitnessRPG iOS scheme and a paired real iPhone.
  3. Add --fitnessrpg-show-diagnostics to Run Arguments.
  4. Use --fitnessrpg-open-validation-report-archive when collecting archive screenshots.
  5. Follow docs/validation/end-to-end-real-device-runbook.md.
NEXT
