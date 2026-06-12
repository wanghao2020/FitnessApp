# WatchConnectivity 真机闭环验证 Runbook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 WatchConnectivity 真机闭环验证 runbook 和本机预检脚本，让真实 iPhone + Apple Watch 验证流程可重复执行。

**Architecture:** 文档负责真机人工流程、失败分流和报告保存节奏；脚本只做本机可自动化的测试、build 和设备列表预检，不处理签名安装。README 提供入口，保持现有 app 行为不变。

**Tech Stack:** Bash, Swift Package tests, Xcode generic builds, xcrun devicectl, Markdown.

---

### Task 1: Preflight Script

**Files:**
- Create: `native/scripts/watchconnectivity-real-device-preflight.sh`

- [x] **Step 1: Verify RED for missing script**

Run:

```bash
bash native/scripts/watchconnectivity-real-device-preflight.sh --help
```

Expected: fails with “No such file or directory”.

- [x] **Step 2: Create script directory and script**

Create `native/scripts/watchconnectivity-real-device-preflight.sh` with:

```bash
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
        printf '--derived-data requires a directory path.\n' >&2
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
```

- [x] **Step 3: Verify script help GREEN**

Run:

```bash
bash native/scripts/watchconnectivity-real-device-preflight.sh --help
```

Expected: prints usage and exits 0.

- [x] **Step 4: Verify syntax and light path**

Run:

```bash
bash -n native/scripts/watchconnectivity-real-device-preflight.sh
bash native/scripts/watchconnectivity-real-device-preflight.sh --skip-build --skip-tests --skip-devices
```

Expected: both exit 0; light path prints “Preflight complete.”

### Task 2: Real-device Runbook

**Files:**
- Create: `docs/validation/watchconnectivity-real-device-runbook.md`

- [x] **Step 1: Create runbook**

Create a runbook with sections:

```markdown
# WatchConnectivity Real-device Validation Runbook

## Purpose

Validate the real iPhone + Apple Watch loop from Today quest send to Watch execution return, History persistence, and validation report archival.

## Prerequisites

- A paired real iPhone and Apple Watch.
- Xcode signing configured for `FitnessRPG` and `FitnessRPGWatch`.
- The iOS app runs a DEBUG build.
- The Watch app is installed on the paired watch.
- The iOS Run Arguments include `--fitnessrpg-show-diagnostics`.

## Local Preflight

Run:

```bash
bash native/scripts/watchconnectivity-real-device-preflight.sh
```

## Validation Pass

1. Launch iOS Today with diagnostics enabled.
2. Save a baseline validation report.
3. Confirm the Watch sync row says the Watch app is installed or ready to send.
4. Tap the bottom `发送到 Watch` button.
5. Open the Watch app.
6. Complete every Watch step using `完成`; use `过重` once in a separate negative pass.
7. Return to iPhone and confirm the Watch sync row reports an inbound return.
8. Open History and confirm a new record exists.
9. Open the latest History detail and confirm Watch progress and result text.
10. Generate or regenerate weekly polish cache if records exist.
11. Save a final validation report.
12. Open the validation report archive and confirm baseline/final reports are visible.

## Expected Evidence

- Baseline and final validation reports are saved.
- WatchConnectivity diagnostics show outbound and inbound rows.
- History contains the completed day.
- The real-device validation overview has no Watch sync blocker after inbound return.

## Failure Routing

- Watch app not installed: reinstall from Xcode and confirm companion bundle settings.
- Watch unreachable: keep both apps foregrounded, unlock both devices, then retry send.
- Outbound only, no inbound: complete all Watch steps and wait for queued transfer.
- Inbound but no History: check iOS status text for quest mismatch or decoding failure.
- HealthKit blocker: follow the HealthKit action row before treating Watch sync as failed.
- Runtime blocker: resource or adapter fallback does not block Watch sync validation.

## Report Naming

When saving report snapshots, use the visible timestamp in the archive row as the run identifier in issue notes.
```

### Task 3: README Entrypoints

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update root README**

In `Next Major Work`, change the first item to reference:

```markdown
Run `bash native/scripts/watchconnectivity-real-device-preflight.sh`, then follow `docs/validation/watchconnectivity-real-device-runbook.md`.
```

- [x] **Step 2: Update native README launch arguments**

Add:

```markdown
- `--fitnessrpg-open-validation-report-archive`: enable diagnostics and open the saved validation report archive sheet for screenshots.
```

- [x] **Step 3: Update native README future integration point**

Mention the runbook path in the WatchConnectivity validation bullet.

### Task 4: Verification And Commit

**Files:**
- All changed files.

- [x] **Step 1: Run script checks**

```bash
bash native/scripts/watchconnectivity-real-device-preflight.sh --help
bash -n native/scripts/watchconnectivity-real-device-preflight.sh
bash native/scripts/watchconnectivity-real-device-preflight.sh --skip-build --skip-tests --skip-devices
```

- [x] **Step 2: Run full project verification**

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGWatchConnectivityRealDevicePreflightIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGWatchConnectivityRealDevicePreflightWatch CODE_SIGNING_ALLOWED=NO build
git diff --check
```

- [x] **Step 3: Commit and push**

```bash
git add README.md native/README.md native/scripts/watchconnectivity-real-device-preflight.sh docs/validation/watchconnectivity-real-device-runbook.md docs/superpowers/specs/2026-06-12-watchconnectivity-real-device-runbook-design.md docs/superpowers/plans/2026-06-12-watchconnectivity-real-device-runbook.md
git commit -m "docs(native): add watchconnectivity real-device runbook"
git push
```
