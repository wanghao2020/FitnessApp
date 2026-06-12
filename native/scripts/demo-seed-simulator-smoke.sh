#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/native/FitnessRPG.xcodeproj"
DERIVED_DATA_PATH="${TMPDIR:-/tmp}/fitnessrpg-demo-seed-derived-data"
BUNDLE_ID="com.hao.fitnessrpg"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/FitnessRPG.app"

device_id="${1:-}"

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

echo "FitnessRPGDemo smoke passed on simulator $device_id."
