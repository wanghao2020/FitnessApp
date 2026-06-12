# LiteRT-LM / Gemma 真机执行验证 Runbook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 LiteRT-LM / Gemma 真机模型执行验证 runbook 和本机预检脚本，固定默认 fallback、DEBUG fixture 和真实 runtime 三种验证路径。

**Architecture:** 脚本检查现有 conditional bridge、ModelResources、Core catalog、Xcode resources wiring，并用 `--require-real-runtime` 强制检查未来真实模型包、SDK 和编译 flag。Runbook 负责人工真机步骤、预期 diagnostics 和失败分流；README 提供入口。

**Tech Stack:** Bash, Swift Package tests, Xcode generic builds, Markdown, conditional Swift compilation.

---

### Task 1: LiteRT-LM Preflight Script

**Files:**
- Create: `native/scripts/litertlm-real-device-preflight.sh`

- [x] **Step 1: Verify RED for missing script**

Run:

```bash
bash native/scripts/litertlm-real-device-preflight.sh --help
```

Expected: fails with “No such file or directory”.

- [x] **Step 2: Create script**

Create `native/scripts/litertlm-real-device-preflight.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DERIVED_DATA_DIR="${TMPDIR:-/tmp}/FitnessRPGLiteRTLMRealDevicePreflight"
RUN_TESTS=1
RUN_BUILDS=1
REQUIRE_REAL_RUNTIME=0

usage() {
  cat <<'USAGE'
Usage: native/scripts/litertlm-real-device-preflight.sh [options]

Runs local checks before LiteRT-LM / Gemma real-device model execution validation.

Options:
  --skip-tests           Skip Swift package tests.
  --skip-build           Skip iOS/watchOS generic builds.
  --require-real-runtime Require model package, LiteRTLM project reference, and FITNESSRPG_ENABLE_LITERTLM flag.
  --derived-data DIR     Use a custom DerivedData directory.
  -h, --help             Show this help.

Runbook:
  docs/validation/litertlm-real-device-runbook.md

Default DEBUG Run Argument:
  --fitnessrpg-show-diagnostics

Fixture Run Arguments:
  --fitnessrpg-model-fixture-ready
  --fitnessrpg-model-fixture-parsing-failure
  --fitnessrpg-model-fixture-adapter-failure
  --fitnessrpg-model-fixture-validator-failure
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

file_size() {
  if stat -f '%z' "$1" >/dev/null 2>&1; then
    stat -f '%z' "$1"
  else
    stat -c '%s' "$1"
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

PROJECT_FILE="native/FitnessRPG.xcodeproj/project.pbxproj"
ADAPTER_FILE="native/AppSources/iOS/ModelRuntime/GemmaLocalModelAdapter.swift"
OBSERVER_FILE="native/AppSources/iOS/ModelRuntime/LocalModelResourceBundleObserver.swift"
RESOURCES_README="native/AppSources/iOS/ModelRuntime/ModelResources/README.md"
MODEL_FILE="native/AppSources/iOS/ModelRuntime/ModelResources/gemma-4-E2B-it.litertlm"
CATALOG_FILE="native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeResources.swift"
CORE_TEST_FILE="native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift"

log "Checking local toolchain"
require_command xcodebuild
require_command swift
require_command grep
require_command stat

log "Checking LiteRT-LM bridge wiring"
require_file "$PROJECT_FILE"
require_file "$ADAPTER_FILE"
require_file "$OBSERVER_FILE"
require_file "$RESOURCES_README"
require_file "$CATALOG_FILE"
require_file "$CORE_TEST_FILE"
require_text "$ADAPTER_FILE" "canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM" "LiteRTLM conditional import"
require_text "$ADAPTER_FILE" "ModelRuntimePromptFormatter.prompt(for: context)" "prompt formatter usage"
require_text "$OBSERVER_FILE" "ModelRuntimeResourceCatalog.gemmaE2B" "Gemma resource profile usage"
require_text "$RESOURCES_README" "gemma-4-E2B-it.litertlm" "expected LiteRT-LM model package documentation"
require_text "$PROJECT_FILE" "ModelResources" "ModelResources project reference"
require_text "$PROJECT_FILE" "ModelResources in Resources" "ModelResources resources build phase"
require_text "$CATALOG_FILE" "ModelResources/gemma-4-E2B-it.litertlm" "Core catalog model resource path"
require_text "$CORE_TEST_FILE" "testModelRuntimeResourceCatalogDefinesGemmaE2BBundleRequirements" "Core resource catalog test"

if [[ "$REQUIRE_REAL_RUNTIME" -eq 1 ]]; then
  log "Checking required real LiteRT-LM runtime assets"
  require_file "$MODEL_FILE"
  model_size="$(file_size "$MODEL_FILE")"
  if [[ "$model_size" -le 1024 ]]; then
    printf 'Model package is too small: %s bytes. Expected a licensed .litertlm package larger than 1024 bytes.\n' "$model_size" >&2
    exit 1
  fi
  require_text "$PROJECT_FILE" "LiteRTLM" "LiteRTLM package or product reference"
  require_text "$PROJECT_FILE" "FITNESSRPG_ENABLE_LITERTLM" "FITNESSRPG_ENABLE_LITERTLM Swift flag"
fi

if [[ "$RUN_TESTS" -eq 1 ]]; then
  log "Running FitnessRPGCore tests"
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

  log "Building iOS generic target"
  CLANG_MODULE_CACHE_PATH="$DERIVED_DATA_DIR/XcodeModuleCache" xcodebuild -quiet \
    -project native/FitnessRPG.xcodeproj \
    -scheme FitnessRPG \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_DIR/iOS" \
    -clonedSourcePackagesDirPath "$DERIVED_DATA_DIR/SourcePackages" \
    -packageCachePath "$DERIVED_DATA_DIR/PackageCache" \
    CODE_SIGNING_ALLOWED=NO \
    build

  log "Building watchOS generic target"
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

cat <<'NEXT'

LiteRT-LM preflight complete.

Next:
  1. Use default diagnostics to confirm fallback/resource status.
  2. Use DEBUG model fixture arguments to verify parser, adapter, and validator paths.
  3. After adding the licensed .litertlm package and LiteRTLM Swift package, rerun with --require-real-runtime.
  4. Follow docs/validation/litertlm-real-device-runbook.md.
NEXT
```

- [x] **Step 3: Verify script help GREEN**

Run:

```bash
bash native/scripts/litertlm-real-device-preflight.sh --help
```

Expected: prints usage and exits 0.

- [x] **Step 4: Verify syntax and light path**

Run:

```bash
bash -n native/scripts/litertlm-real-device-preflight.sh
bash native/scripts/litertlm-real-device-preflight.sh --skip-build --skip-tests
```

Expected: both exit 0; light path prints “LiteRT-LM preflight complete.”

### Task 2: LiteRT-LM Real-device Runbook

**Files:**
- Create: `docs/validation/litertlm-real-device-runbook.md`

- [x] **Step 1: Create runbook**

Create a runbook with:

```markdown
# LiteRT-LM / Gemma Real-device Validation Runbook

## Purpose

Validate local model fallback diagnostics, DEBUG fixture paths, and real LiteRT-LM execution readiness on iPhone.

## Prerequisites

- DEBUG iOS build with `--fitnessrpg-show-diagnostics`.
- For real runtime only: a licensed `gemma-4-E2B-it.litertlm` package.
- For real runtime only: LiteRTLM Swift package linked into the iOS target.
- For real runtime only: `FITNESSRPG_ENABLE_LITERTLM` Swift compilation flag enabled for the iOS target.

## Local Preflight

Run the default fallback preflight:

```bash
bash native/scripts/litertlm-real-device-preflight.sh
```

After adding real model assets and SDK wiring, run:

```bash
bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime
```

## Validation Passes

### 1. Default fallback pass

1. Launch iOS with `--fitnessrpg-show-diagnostics`.
2. Confirm Runtime diagnostics reports missing resource or adapter unavailable.
3. Confirm Today still renders deterministic safe copy.
4. Save a validation report.

### 2. DEBUG fixture pass

Run these launch arguments one at a time with diagnostics enabled:

- `--fitnessrpg-model-fixture-ready`
- `--fitnessrpg-model-fixture-parsing-failure`
- `--fitnessrpg-model-fixture-adapter-failure`
- `--fitnessrpg-model-fixture-validator-failure`

Expected:

- Ready fixture shows generated draft title and next action.
- Parsing failure reports parser fallback.
- Adapter failure reports adapter fallback.
- Validator failure reports safety fallback.

### 3. Real runtime pass

1. Place `gemma-4-E2B-it.litertlm` under `native/AppSources/iOS/ModelRuntime/ModelResources/`.
2. Link LiteRTLM Swift package to the iOS target.
3. Add `FITNESSRPG_ENABLE_LITERTLM` to iOS Swift flags.
4. Run the preflight with `--require-real-runtime`.
5. Install on a real iPhone.
6. Launch with `--fitnessrpg-show-diagnostics`.
7. Confirm Runtime diagnostics no longer reports missing resource or adapter unavailable.
8. Trigger Today model output and History weekly polish output.
9. Confirm output passes parser and validator before acceptance.
10. Save baseline and final validation reports.

## Failure Routing

- Missing model package: verify the exact `ModelResources/gemma-4-E2B-it.litertlm` path.
- Model package too small: replace placeholder with licensed model package.
- SDK not linked: confirm the iOS target links LiteRTLM and the package product name appears in the project.
- Flag not enabled: add `FITNESSRPG_ENABLE_LITERTLM` to iOS Swift flags.
- Parser failure: inspect raw model output and JSON contract.
- Validator failure: inspect unsafe or too-broad coach text and keep deterministic fallback.
- Device memory/performance failure: lower `maximumTokenCount` or test on newer hardware.

## Evidence Notes

Use validation report archive timestamps as run identifiers.
```

### Task 3: README Entrypoints

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`
- Modify: `native/AppSources/iOS/ModelRuntime/ModelResources/README.md`

- [x] **Step 1: Update root README**

In `Next Major Work`, update the LiteRT-LM item to reference:

```markdown
Run `bash native/scripts/litertlm-real-device-preflight.sh`, then follow `docs/validation/litertlm-real-device-runbook.md`.
```

- [x] **Step 2: Update native README future integration point**

Mention the preflight script and runbook in the LiteRT-LM / Gemma bullet.

- [x] **Step 3: Update ModelResources README**

Add the preflight and runbook commands.

### Task 4: Verification And Commit

**Files:**
- All changed files.

- [x] **Step 1: Run script checks**

```bash
bash native/scripts/litertlm-real-device-preflight.sh --help
bash -n native/scripts/litertlm-real-device-preflight.sh
bash native/scripts/litertlm-real-device-preflight.sh --skip-build --skip-tests
```

- [x] **Step 2: Run full project verification**

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMRealDevicePreflightIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMRealDevicePreflightWatch CODE_SIGNING_ALLOWED=NO build
git diff --check
```

- [x] **Step 3: Commit and push**

```bash
git add README.md native/README.md native/AppSources/iOS/ModelRuntime/ModelResources/README.md native/scripts/litertlm-real-device-preflight.sh docs/validation/litertlm-real-device-runbook.md docs/superpowers/specs/2026-06-12-litertlm-real-device-runbook-design.md docs/superpowers/plans/2026-06-12-litertlm-real-device-runbook.md
git commit -m "docs(native): add litertlm real-device runbook"
git push
```
