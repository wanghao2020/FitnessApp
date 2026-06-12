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
gallery_index_path=""
run_build=1

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
                       Save gallery screenshots plus manifest.md and index.html.
  --screenshot-delay N Wait N seconds before taking a screenshot. Defaults to 2.
  --skip-build        Reuse the existing DerivedData app build.
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
    --skip-build)
      run_build=0
      shift
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

if [[ "$run_build" -eq 1 ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme FitnessRPGDemo \
    -destination "platform=iOS Simulator,id=$device_id" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build >/dev/null
elif [[ ! -d "$APP_PATH" ]]; then
  echo "Missing existing app build at $APP_PATH. Run without --skip-build first." >&2
  exit 1
fi

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

write_gallery_index() {
  gallery_index_path="$screenshots_dir/index.html"

  cat > "$gallery_index_path" <<HTML
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>FitnessRPG Demo Gallery</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f8fafc;
      --panel: #ffffff;
      --text: #1e293b;
      --muted: #64748b;
      --line: #dbeafe;
      --primary: #2563eb;
      --accent: #f97316;
      --shadow: 0 18px 50px rgba(15, 23, 42, 0.12);
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
      line-height: 1.5;
    }
    main {
      width: min(1440px, calc(100% - 32px));
      margin: 0 auto;
      padding: 32px 0 48px;
    }
    header {
      display: grid;
      gap: 18px;
      padding: 24px;
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      box-shadow: var(--shadow);
    }
    h1 {
      margin: 0;
      font-size: clamp(28px, 4vw, 48px);
      line-height: 1;
      letter-spacing: 0;
    }
    .meta {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      color: var(--muted);
      font-size: 14px;
    }
    .pill {
      display: inline-flex;
      align-items: center;
      min-height: 32px;
      padding: 4px 10px;
      border: 1px solid var(--line);
      border-radius: 999px;
      background: #eff6ff;
    }
    a {
      color: var(--primary);
      font-weight: 700;
      text-decoration: none;
    }
    a:focus-visible {
      outline: 3px solid var(--accent);
      outline-offset: 3px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 18px;
      margin-top: 24px;
    }
    article {
      display: grid;
      gap: 12px;
      padding: 16px;
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      box-shadow: var(--shadow);
    }
    h2 {
      margin: 0;
      font-size: 20px;
      letter-spacing: 0;
    }
    code {
      display: block;
      overflow-wrap: anywhere;
      color: var(--muted);
      font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
      font-size: 12px;
    }
    img {
      display: block;
      width: min(100%, 430px);
      height: auto;
      margin: 0 auto;
      border-radius: 8px;
      border: 1px solid #e2e8f0;
      background: #ffffff;
    }
    @media (prefers-reduced-motion: no-preference) {
      a {
        transition: color 180ms ease;
      }
      a:hover {
        color: var(--accent);
      }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>FitnessRPG Demo Gallery</h1>
      <div class="meta">
        <span class="pill">Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")</span>
        <span class="pill">Simulator: $device_id</span>
        <span class="pill">Bundle: $BUNDLE_ID</span>
        <span class="pill"><a href="manifest.md">Open manifest.md</a></span>
      </div>
    </header>
    <section class="grid" aria-label="Demo screenshots">
      <article>
        <h2>History</h2>
        <code>--fitnessrpg-demo-seed --fitnessrpg-open-history --fitnessrpg-show-diagnostics</code>
        <a href="history.png"><img src="history.png" alt="History demo screen"></a>
      </article>
      <article>
        <h2>History Detail</h2>
        <code>--fitnessrpg-demo-seed --fitnessrpg-open-latest-history-detail --fitnessrpg-show-diagnostics</code>
        <a href="history-detail.png"><img src="history-detail.png" alt="Latest training detail demo screen"></a>
      </article>
      <article>
        <h2>Today</h2>
        <code>--fitnessrpg-demo-seed --fitnessrpg-show-diagnostics</code>
        <a href="today.png"><img src="today.png" alt="Today command center demo screen"></a>
      </article>
      <article>
        <h2>Memory Review</h2>
        <code>--fitnessrpg-demo-seed --fitnessrpg-open-memory-review --fitnessrpg-show-diagnostics</code>
        <a href="memory.png"><img src="memory.png" alt="Memory Review demo screen"></a>
      </article>
      <article>
        <h2>Validation Archive</h2>
        <code>--fitnessrpg-demo-seed --fitnessrpg-open-validation-report-archive</code>
        <a href="validation-archive.png"><img src="validation-archive.png" alt="Validation report archive demo screen"></a>
      </article>
    </section>
  </main>
</body>
</html>
HTML
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
  write_gallery_index
  echo "Index written to $gallery_index_path."
fi

echo "FitnessRPGDemo smoke passed on simulator $device_id."
