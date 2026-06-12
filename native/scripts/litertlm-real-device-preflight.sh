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
