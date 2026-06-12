#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/native/FitnessRPG.xcodeproj"
DERIVED_DATA_PATH="${TMPDIR:-/tmp}/fitnessrpg-demo-seed-derived-data"
BUNDLE_ID="com.hao.fitnessrpg"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/FitnessRPG.app"

device_id=""
screenshot_path=""
screenshots_dir=""
screenshot_delay_seconds="${FITNESSRPG_DEMO_SCREENSHOT_DELAY:-2}"
gallery_manifest_path=""

usage() {
  cat <<'USAGE'
Usage: native/scripts/demo-seed-simulator-smoke.sh [options] [device-id]

Builds and launches the FitnessRPGDemo scheme on an iPhone simulator, seeds
deterministic demo data, verifies persisted JSON artifacts, and optionally
captures a screenshot.

Options:
  --device ID          Use a specific simulator device id.
  --screenshot PATH   Save a simulator screenshot after launch and verification.
  --screenshots-dir DIR
                       Save History, detail, Today, Memory, and archive screenshots.
  --screenshot-delay N Wait N seconds before taking a screenshot. Defaults to 2.
  -h, --help          Show this help.

Examples:
  bash native/scripts/demo-seed-simulator-smoke.sh
  bash native/scripts/demo-seed-simulator-smoke.sh --screenshot /private/tmp/fitnessrpg-demo.png
  bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
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
    --screenshots-dir)
      if [[ $# -lt 2 ]]; then
        echo "--screenshots-dir requires an output directory." >&2
        exit 1
      fi
      screenshots_dir="$2"
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

launch_demo() {
  xcrun simctl terminate "$device_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch "$device_id" "$BUNDLE_ID" "$@" >/dev/null
}

capture_screenshot() {
  local output_path="$1"

  mkdir -p "$(dirname "$output_path")"
  sleep "$screenshot_delay_seconds"
  xcrun simctl io "$device_id" screenshot "$output_path" >/dev/null
  test -s "$output_path"
  echo "Screenshot written to $output_path."
}

write_gallery_manifest_header() {
  gallery_manifest_path="$screenshots_dir/manifest.md"

  {
    echo "# FitnessRPG Demo Screenshot Gallery"
    echo
    echo "- Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "- Simulator: $device_id"
    echo "- Bundle ID: $BUNDLE_ID"
    echo "- Screenshot delay: ${screenshot_delay_seconds}s"
    echo
    echo "| Screen | File | Launch arguments | Verification |"
    echo "| --- | --- | --- | --- |"
  } > "$gallery_manifest_path"
}

append_gallery_manifest_row() {
  local screen="$1"
  local filename="$2"
  local launch_arguments="$3"

  echo "| $screen | \`$filename\` | \`$launch_arguments\` | file exists and is non-empty |" >> "$gallery_manifest_path"
}

capture_gallery_screen() {
  local screen="$1"
  local filename="$2"
  shift 2
  local launch_arguments="$*"

  launch_demo "$@"
  capture_screenshot "$screenshots_dir/$filename"
  append_gallery_manifest_row "$screen" "$filename" "$launch_arguments"
}

launch_demo \
  --fitnessrpg-demo-seed \
  --fitnessrpg-open-history \
  --fitnessrpg-show-diagnostics

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
  capture_screenshot "$screenshot_path"
fi

if [[ -n "$screenshots_dir" ]]; then
  mkdir -p "$screenshots_dir"
  write_gallery_manifest_header

  capture_gallery_screen \
    "History" \
    "history.png" \
    --fitnessrpg-demo-seed \
    --fitnessrpg-open-history \
    --fitnessrpg-show-diagnostics

  capture_gallery_screen \
    "History detail" \
    "history-detail.png" \
    --fitnessrpg-demo-seed \
    --fitnessrpg-open-latest-history-detail \
    --fitnessrpg-show-diagnostics

  capture_gallery_screen \
    "Today" \
    "today.png" \
    --fitnessrpg-demo-seed \
    --fitnessrpg-show-diagnostics

  capture_gallery_screen \
    "Memory Review" \
    "memory.png" \
    --fitnessrpg-demo-seed \
    --fitnessrpg-open-memory-review \
    --fitnessrpg-show-diagnostics

  capture_gallery_screen \
    "Validation archive" \
    "validation-archive.png" \
    --fitnessrpg-demo-seed \
    --fitnessrpg-open-validation-report-archive

  echo "Manifest written to $gallery_manifest_path."
fi

echo "FitnessRPGDemo smoke passed on simulator $device_id."
