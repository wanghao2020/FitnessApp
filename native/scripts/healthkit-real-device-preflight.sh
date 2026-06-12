#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DERIVED_DATA_DIR="${TMPDIR:-/tmp}/FitnessRPGHealthKitRealDevicePreflight"
RUN_TESTS=1
RUN_BUILDS=1

usage() {
  cat <<'USAGE'
Usage: native/scripts/healthkit-real-device-preflight.sh [options]

Runs local project checks before HealthKit permission/data coverage validation on a real iPhone.

Options:
  --skip-tests       Skip Swift package tests.
  --skip-build       Skip iOS/watchOS generic builds.
  --derived-data DIR Use a custom DerivedData directory.
  -h, --help         Show this help.

Runbook:
  docs/validation/healthkit-real-device-runbook.md

Recommended DEBUG Run Argument:
  --fitnessrpg-show-diagnostics
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

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

require_text() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -Fq "$pattern" "$file"; then
    printf 'Missing %s in %s\n' "$label" "$file" >&2
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

PROJECT_FILE="native/FitnessRPG.xcodeproj/project.pbxproj"
ENTITLEMENTS_FILE="native/AppSources/iOS/FitnessRPG.entitlements"
PROVIDER_FILE="native/AppSources/iOS/HealthKit/HealthKitHealthSummaryProvider.swift"

log "Checking local toolchain"
require_command xcodebuild
require_command swift
require_command plutil

log "Checking HealthKit project wiring"
require_file "$PROJECT_FILE"
require_file "$ENTITLEMENTS_FILE"
require_file "$PROVIDER_FILE"
plutil -lint "$ENTITLEMENTS_FILE" >/dev/null
require_text "$ENTITLEMENTS_FILE" "com.apple.developer.healthkit" "HealthKit entitlement"
require_text "$PROJECT_FILE" "CODE_SIGN_ENTITLEMENTS = AppSources/iOS/FitnessRPG.entitlements" "iOS entitlements build setting"
require_text "$PROJECT_FILE" "INFOPLIST_KEY_NSHealthShareUsageDescription" "Health share usage description"
require_text "$PROJECT_FILE" "HealthKit.framework" "HealthKit.framework reference"
require_text "$PROJECT_FILE" "HealthKitHealthSummaryProvider.swift" "HealthKit provider source reference"
require_text "$PROVIDER_FILE" "requestAuthorization(toShare: nil, read: readTypes)" "read-only HealthKit authorization request"

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

cat <<'NEXT'

HealthKit preflight complete.

Next:
  1. Open native/FitnessRPG.xcodeproj in Xcode.
  2. Select the FitnessRPG iOS scheme and a real iPhone.
  3. Add --fitnessrpg-show-diagnostics to Run Arguments.
  4. Follow docs/validation/healthkit-real-device-runbook.md.
NEXT
