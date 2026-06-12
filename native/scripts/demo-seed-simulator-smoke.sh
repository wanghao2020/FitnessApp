#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/native/FitnessRPG.xcodeproj"
DERIVED_DATA_PATH="${TMPDIR:-/tmp}/fitnessrpg-demo-seed-derived-data"
BUNDLE_ID="com.hao.fitnessrpg"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/FitnessRPG.app"

device_id=""
screenshot_path=""
screenshot_delay_seconds="${FITNESSRPG_DEMO_SCREENSHOT_DELAY:-2}"

usage() {
  cat <<'USAGE'
Usage: native/scripts/demo-seed-simulator-smoke.sh [options] [device-id]

Builds and launches the FitnessRPGDemo scheme on an iPhone simulator, seeds
deterministic demo data, verifies persisted JSON artifacts, and optionally
captures a screenshot.

Options:
  --device ID          Use a specific simulator device id.
  --screenshot PATH   Save a simulator screenshot after launch and verification.
  --screenshot-delay N Wait N seconds before taking a screenshot. Defaults to 2.
  -h, --help          Show this help.

Examples:
  bash native/scripts/demo-seed-simulator-smoke.sh
  bash native/scripts/demo-seed-simulator-smoke.sh --screenshot /private/tmp/fitnessrpg-demo.png
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      if [[ $# -lt 2 ]]; then
        echo "--device requires a simulator id." >&2
        exit 1
      fi
      device_id="$2"
      shift 2
      ;;
    --screenshot)
      if [[ $# -lt 2 ]]; then
        echo "--screenshot requires an output path." >&2
        exit 1
      fi
      screenshot_path="$2"
      shift 2
      ;;
    --screenshot-delay)
      if [[ $# -lt 2 ]]; then
        echo "--screenshot-delay requires a number of seconds." >&2
        exit 1
      fi
      screenshot_delay_seconds="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -n "$device_id" ]]; then
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      device_id="$1"
      shift
      ;;
  esac
done

find_booted_iphone() {
  xcrun simctl list devices booted | awk -F '[()]' '/iPhone/ { print $2; exit }'
}

if [[ -z "$device_id" ]]; then
  device_id="$(find_booted_iphone)"
fi

if [[ -z "$device_id" ]]; then
  xcrun simctl boot "iPhone 17" >/dev/null
  device_id="$(find_booted_iphone)"
fi

if [[ -z "$device_id" ]]; then
  echo "No booted iPhone simulator is available." >&2
  exit 1
fi

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme FitnessRPGDemo \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build >/dev/null

xcrun simctl install "$device_id" "$APP_PATH"
xcrun simctl launch "$device_id" "$BUNDLE_ID" \
  --fitnessrpg-demo-seed \
  --fitnessrpg-open-history \
  --fitnessrpg-show-diagnostics >/dev/null

container_path="$(xcrun simctl get_app_container "$device_id" "$BUNDLE_ID" data)"
store_path="$container_path/Library/Application Support/FitnessRPG"

training_days="$store_path/training-days.json"
weekly_polish="$store_path/weekly-summary-polish-entries.json"
validation_reports="$store_path/validation-reports.json"

test -f "$training_days"
test -f "$weekly_polish"
test -f "$validation_reports"

grep -q "2026-06-12" "$training_days"
grep -q "演示周报" "$weekly_polish"
grep -q "demo-seed-local-model" "$weekly_polish"
grep -q "Demo Seed 验证" "$validation_reports"

if [[ -n "$screenshot_path" ]]; then
  mkdir -p "$(dirname "$screenshot_path")"
  sleep "$screenshot_delay_seconds"
  xcrun simctl io "$device_id" screenshot "$screenshot_path" >/dev/null
  test -s "$screenshot_path"
  echo "Screenshot written to $screenshot_path."
fi

echo "FitnessRPGDemo smoke passed on simulator $device_id."
