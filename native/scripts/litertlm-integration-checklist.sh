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
  native/scripts/model-artifact-git-guard.sh
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
GIT_GUARD_SCRIPT="native/scripts/model-artifact-git-guard.sh"
PREFLIGHT_SCRIPT="native/scripts/litertlm-real-device-preflight.sh"

log "Checking integration kit files"
require_file "$ADAPTER_FILE"
require_file "$XCCONFIG_TEMPLATE"
require_file "$MANIFEST_TEMPLATE"
require_file "$RESOURCES_README"
require_file "$RUNBOOK_FILE"
require_file "$GIT_GUARD_SCRIPT"
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
require_text "$RESOURCES_README" "model-artifact-git-guard.sh" "model artifact git guard documentation"
require_text "$RUNBOOK_FILE" "LiteRT-LM Integration Kit" "integration kit runbook section"
require_text "$RUNBOOK_FILE" "model-artifact-git-guard.sh" "model artifact git guard runbook step"

log "Checking local model artifact git guard"
bash "$GIT_GUARD_SCRIPT"

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
  5. Run native/scripts/model-artifact-git-guard.sh before committing local model setup changes.
  6. Rerun this checklist with --require-real-runtime.
NEXT
