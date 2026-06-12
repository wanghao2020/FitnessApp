# LiteRT-LM Integration Kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 LiteRT-LM / Gemma 真实 SDK 接入工具包，让未来接入 SDK、模型包和编译 flag 时有可复制模板和本地 checklist。

**Architecture:** 保持默认仓库不链接 SDK、不提交模型、不打开真实 runtime flag。新增示例 xcconfig、模型包 manifest 模板和 checklist 脚本，脚本复用现有 LiteRT-LM preflight 来验证 fallback wiring 或真实 runtime wiring。

**Tech Stack:** Bash, Xcode xcconfig, JSON manifest template, Markdown, Swift Package tests, xcodebuild.

---

### Task 1: Integration Checklist RED/GREEN

**Files:**
- Create: `native/scripts/litertlm-integration-checklist.sh`

- [x] **Step 1: Verify RED for missing script**

Run:

```bash
bash native/scripts/litertlm-integration-checklist.sh --help
```

Expected: fails with “No such file or directory”.

- [x] **Step 2: Create checklist script**

Create `native/scripts/litertlm-integration-checklist.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REQUIRE_REAL_RUNTIME=0

usage() {
  cat <<'USAGE'
Usage: native/scripts/litertlm-integration-checklist.sh [options]

Checks the local LiteRT-LM / Gemma SDK integration kit and current project wiring.

Options:
  --require-real-runtime Also require the real LiteRTLM package reference, FITNESSRPG_ENABLE_LITERTLM flag, and licensed .litertlm model package.
  -h, --help             Show this help.

Templates:
  native/Config/LiteRTLMRealRuntime.example.xcconfig
  native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json

Validation:
  native/scripts/litertlm-real-device-preflight.sh
  docs/validation/litertlm-real-device-runbook.md
USAGE
}

log() {
  printf '\n==> %s\n' "$1"
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
    --require-real-runtime)
      REQUIRE_REAL_RUNTIME=1
      shift
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

ADAPTER_FILE="native/AppSources/iOS/ModelRuntime/GemmaLocalModelAdapter.swift"
XCCONFIG_TEMPLATE="native/Config/LiteRTLMRealRuntime.example.xcconfig"
MANIFEST_TEMPLATE="native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json"
RESOURCES_README="native/AppSources/iOS/ModelRuntime/ModelResources/README.md"
RUNBOOK_FILE="docs/validation/litertlm-real-device-runbook.md"
PREFLIGHT_SCRIPT="native/scripts/litertlm-real-device-preflight.sh"

log "Checking integration kit files"
require_file "$ADAPTER_FILE"
require_file "$XCCONFIG_TEMPLATE"
require_file "$MANIFEST_TEMPLATE"
require_file "$RESOURCES_README"
require_file "$RUNBOOK_FILE"
require_file "$PREFLIGHT_SCRIPT"

log "Checking bridge and template content"
require_text "$ADAPTER_FILE" "canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM" "conditional LiteRTLM bridge"
require_text "$ADAPTER_FILE" "EngineConfig(" "LiteRTLM engine configuration boundary"
require_text "$XCCONFIG_TEMPLATE" "FITNESSRPG_ENABLE_LITERTLM" "real runtime Swift compilation condition"
require_text "$XCCONFIG_TEMPLATE" "SWIFT_ACTIVE_COMPILATION_CONDITIONS" "Swift compilation condition setting"
require_text "$MANIFEST_TEMPLATE" "\"fileName\": \"gemma-4-E2B-it.litertlm\"" "model package file name"
require_text "$MANIFEST_TEMPLATE" "\"bundleRelativePath\": \"ModelResources/gemma-4-E2B-it.litertlm\"" "bundle-relative model path"
require_text "$MANIFEST_TEMPLATE" "\"minimumByteSize\": 1024" "minimum model byte size"
require_text "$RESOURCES_README" "model-package-manifest.example.json" "manifest template documentation"
require_text "$RUNBOOK_FILE" "LiteRT-LM Integration Kit" "integration kit runbook section"

log "Checking current LiteRT-LM fallback wiring"
preflight_args=(--skip-build --skip-tests)
if [[ "$REQUIRE_REAL_RUNTIME" -eq 1 ]]; then
  preflight_args+=(--require-real-runtime)
fi
bash "$PREFLIGHT_SCRIPT" "${preflight_args[@]}"

cat <<'NEXT'

LiteRT-LM integration checklist complete.

Next:
  1. Add the LiteRTLM Swift package in Xcode when the package URL is confirmed.
  2. Link the LiteRTLM product to the FitnessRPG iOS target.
  3. Copy the xcconfig template into an active iOS Debug configuration or add FITNESSRPG_ENABLE_LITERTLM manually.
  4. Place the licensed gemma-4-E2B-it.litertlm under ModelResources.
  5. Rerun this checklist with --require-real-runtime.
NEXT
```

- [x] **Step 3: Verify script help GREEN**

Run:

```bash
bash native/scripts/litertlm-integration-checklist.sh --help
```

Expected: prints usage and exits 0.

### Task 2: Integration Templates

**Files:**
- Create: `native/Config/LiteRTLMRealRuntime.example.xcconfig`
- Create: `native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json`

- [x] **Step 1: Create example xcconfig**

Create `native/Config/LiteRTLMRealRuntime.example.xcconfig` with:

```xcconfig
// Example only. Do not enable until LiteRTLM is linked to the FitnessRPG iOS target.
//
// To use:
// 1. Add the LiteRTLM Swift package in Xcode.
// 2. Link the LiteRTLM product to the FitnessRPG iOS target.
// 3. Copy this file or assign it as the iOS Debug configuration base.
// 4. Run: bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime

SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) FITNESSRPG_ENABLE_LITERTLM
```

- [x] **Step 2: Create model manifest template**

Create `native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json` with:

```json
{
  "model": "Gemma 4 E2B LiteRT-LM",
  "fileName": "gemma-4-E2B-it.litertlm",
  "bundleRelativePath": "ModelResources/gemma-4-E2B-it.litertlm",
  "minimumByteSize": 1024,
  "doNotCommitModelFile": true,
  "licenseSource": "Record the licensed source or internal artifact location outside git.",
  "checksum": {
    "algorithm": "sha256",
    "value": "record-checksum-outside-git"
  },
  "validationCommand": "bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime"
}
```

### Task 3: Documentation Entrypoints

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`
- Modify: `native/AppSources/iOS/ModelRuntime/ModelResources/README.md`
- Modify: `docs/validation/litertlm-real-device-runbook.md`

- [x] **Step 1: Update ModelResources README**

Mention:

```markdown
Use `model-package-manifest.example.json` to record the expected package name, bundle path, minimum byte size, license/source notes, and checksum outside git.
```

- [x] **Step 2: Update LiteRT-LM runbook**

Add a `## LiteRT-LM Integration Kit` section that references:

```markdown
bash native/scripts/litertlm-integration-checklist.sh
native/Config/LiteRTLMRealRuntime.example.xcconfig
native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json
```

- [x] **Step 3: Update README entrypoints**

Mention `bash native/scripts/litertlm-integration-checklist.sh` in the root and native LiteRT-LM bullets.

### Task 4: Verification And Commit

**Files:**
- All changed files.

- [x] **Step 1: Run script checks**

```bash
bash native/scripts/litertlm-integration-checklist.sh --help
bash -n native/scripts/litertlm-integration-checklist.sh
bash native/scripts/litertlm-integration-checklist.sh
```

- [x] **Step 2: Run project verification**

```bash
bash native/scripts/litertlm-real-device-preflight.sh --skip-build --skip-tests
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMIntegrationKitIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGLiteRTLMIntegrationKitWatch CODE_SIGNING_ALLOWED=NO build
git diff --check
```

- [x] **Step 3: Commit and push**

```bash
git add README.md native/README.md native/Config/LiteRTLMRealRuntime.example.xcconfig native/AppSources/iOS/ModelRuntime/ModelResources/README.md native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json native/scripts/litertlm-integration-checklist.sh docs/validation/litertlm-real-device-runbook.md docs/superpowers/specs/2026-06-12-litertlm-integration-kit-design.md docs/superpowers/plans/2026-06-12-litertlm-integration-kit.md
git commit -m "docs(native): add litertlm integration kit"
git push
```
