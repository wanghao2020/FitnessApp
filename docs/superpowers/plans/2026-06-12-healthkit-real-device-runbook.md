# HealthKit 真机验证 Runbook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 HealthKit 真机权限与数据覆盖验证 runbook 和本机预检脚本，固定验证授权、数据不足、成功读取和报告归档流程。

**Architecture:** 脚本检查本机工程配置和可选 build/test；runbook 负责真机人工步骤、预期 UI 状态和失败分流；README 提供入口。现有 HealthKit provider 和 UI 行为不变。

**Tech Stack:** Bash, Swift Package tests, Xcode generic builds, Markdown, plutil.

---

### Task 1: HealthKit Preflight Script

**Files:**
- Create: `native/scripts/healthkit-real-device-preflight.sh`

- [x] **Step 1: Verify RED for missing script**

Run:

```bash
bash native/scripts/healthkit-real-device-preflight.sh --help
```

Expected: fails with “No such file or directory”.

- [x] **Step 2: Create script**

Create `native/scripts/healthkit-real-device-preflight.sh` with:

```bash
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
```

- [x] **Step 3: Verify script help GREEN**

Run:

```bash
bash native/scripts/healthkit-real-device-preflight.sh --help
```

Expected: prints usage and exits 0.

- [x] **Step 4: Verify syntax and light path**

Run:

```bash
bash -n native/scripts/healthkit-real-device-preflight.sh
bash native/scripts/healthkit-real-device-preflight.sh --skip-build --skip-tests
```

Expected: both exit 0; light path prints “HealthKit preflight complete.”

### Task 2: HealthKit Real-device Runbook

**Files:**
- Create: `docs/validation/healthkit-real-device-runbook.md`

- [x] **Step 1: Create runbook**

Create a runbook with:

```markdown
# HealthKit Real-device Validation Runbook

## Purpose

Validate HealthKit authorization, data coverage, conservative fallback notices, and validation report evidence on a real iPhone.

## Prerequisites

- A real iPhone with Apple Health available.
- Optional but recommended: paired Apple Watch with recent sleep/activity data.
- Xcode signing configured for `FitnessRPG`.
- The iOS app runs a DEBUG build.
- The iOS Run Arguments include `--fitnessrpg-show-diagnostics`.

## Local Preflight

Run:

```bash
bash native/scripts/healthkit-real-device-preflight.sh
```

## Validation Matrix

| State | How to trigger | Expected Today UI | Expected report evidence |
| --- | --- | --- | --- |
| HealthKit unavailable | Run on Simulator or unsupported environment | `HealthKit 不可用` notice | `HealthKit：HealthKit 不可用` |
| Authorization unfinished/denied | Deny Health access or remove permissions | `HealthKit 权限未完成` notice with `下一步 · 权限` | report contains `行动 · 下一步 · 权限` |
| Insufficient data | Grant access on a device missing sleep/recovery/activity data | `HealthKit 数据不足` and missing signal labels | report contains `缺少信号` and `下一步 · 数据` |
| HealthKit success | Grant access on a device with sleep, recovery, and activity data | no fallback notice; source note says HealthKit summary loaded | report contains `HealthKit：HealthKit 已接入` |

## Validation Pass

1. Run local preflight.
2. Install and launch the DEBUG iOS app on a real iPhone.
3. Save a baseline validation report.
4. Trigger or observe one HealthKit state from the matrix.
5. Confirm the Today HealthKit notice/action rows match the expected state.
6. Save a state-specific validation report.
7. Open the validation report archive and confirm the snapshot is visible.
8. If testing a failure state, fix the state in iOS Settings or Health app data, then relaunch and save a final report.

## Failure Routing

- HealthKit prompt never appears: verify entitlement, usage description, and Xcode signing profile.
- `HealthKit 不可用` on a real iPhone: confirm the app is not running under Simulator and Health is available on the device.
- Authorized but still `权限未完成`: toggle Fitness RPG permissions in Settings > Health > Data Access & Devices.
- Data remains insufficient: confirm Apple Watch has produced sleep, heart/recovery, and activity samples inside the queried windows.
- Success state still uses conservative yellow: inspect report drivers for `HealthKit 数据缺失` and compare missing signal labels.

## Evidence Notes

Use validation report archive timestamps as run identifiers in issue notes.
```

### Task 3: README Entrypoints

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update root README**

In `Next Major Work`, update the HealthKit item to reference:

```markdown
Run `bash native/scripts/healthkit-real-device-preflight.sh`, then follow `docs/validation/healthkit-real-device-runbook.md`.
```

- [x] **Step 2: Update native README HealthKit section**

Mention the preflight script and runbook under `HealthKit MVP`.

- [x] **Step 3: Update native README future integration point**

Mention the runbook path in the HealthKit validation bullet.

### Task 4: Verification And Commit

**Files:**
- All changed files.

- [x] **Step 1: Run script checks**

```bash
bash native/scripts/healthkit-real-device-preflight.sh --help
bash -n native/scripts/healthkit-real-device-preflight.sh
bash native/scripts/healthkit-real-device-preflight.sh --skip-build --skip-tests
```

- [x] **Step 2: Run full project verification**

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGHealthKitRealDevicePreflightIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGHealthKitRealDevicePreflightWatch CODE_SIGNING_ALLOWED=NO build
git diff --check
```

- [x] **Step 3: Commit and push**

```bash
git add README.md native/README.md native/scripts/healthkit-real-device-preflight.sh docs/validation/healthkit-real-device-runbook.md docs/superpowers/specs/2026-06-12-healthkit-real-device-runbook-design.md docs/superpowers/plans/2026-06-12-healthkit-real-device-runbook.md
git commit -m "docs(native): add healthkit real-device runbook"
git push
```
