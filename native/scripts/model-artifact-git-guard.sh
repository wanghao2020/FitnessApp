#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODEL_RESOURCES_DIR="native/AppSources/iOS/ModelRuntime/ModelResources"
GITIGNORE_FILE=".gitignore"
FORBIDDEN_PATH_REGEX="^${MODEL_RESOURCES_DIR}/.*\\.(litertlm|task|tflite|onnx|mlmodel)(/|$)|^${MODEL_RESOURCES_DIR}/.*\\.mlpackage(/|$)"

REQUIRED_GITIGNORE_RULES=(
  "${MODEL_RESOURCES_DIR}/*.litertlm"
  "${MODEL_RESOURCES_DIR}/*.task"
  "${MODEL_RESOURCES_DIR}/*.tflite"
  "${MODEL_RESOURCES_DIR}/*.onnx"
  "${MODEL_RESOURCES_DIR}/*.mlmodel"
  "${MODEL_RESOURCES_DIR}/*.mlpackage/"
)

usage() {
  cat <<'USAGE'
Usage: native/scripts/model-artifact-git-guard.sh [options]

Checks that licensed/local model artifacts are ignored and not tracked or staged.

Options:
  -h, --help  Show this help.

Protected directory:
  native/AppSources/iOS/ModelRuntime/ModelResources

Blocked artifact types:
  .litertlm, .task, .tflite, .onnx, .mlmodel, .mlpackage
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_command git
require_command grep

missing_rules=()
for rule in "${REQUIRED_GITIGNORE_RULES[@]}"; do
  if ! grep -Fxq -- "$rule" "$GITIGNORE_FILE"; then
    missing_rules+=("$rule")
  fi
done

if [[ "${#missing_rules[@]}" -gt 0 ]]; then
  printf 'Missing model artifact ignore rules in %s:\n' "$GITIGNORE_FILE" >&2
  printf '  %s\n' "${missing_rules[@]}" >&2
  exit 1
fi

tracked_artifacts="$(git ls-files "$MODEL_RESOURCES_DIR" | grep -E "$FORBIDDEN_PATH_REGEX" || true)"
staged_artifacts="$(git diff --cached --name-only -- "$MODEL_RESOURCES_DIR" | grep -E "$FORBIDDEN_PATH_REGEX" || true)"

if [[ -n "$tracked_artifacts" || -n "$staged_artifacts" ]]; then
  printf 'Blocked local model artifacts are tracked or staged.\n' >&2

  if [[ -n "$tracked_artifacts" ]]; then
    printf '\nTracked artifacts:\n' >&2
    printf '%s\n' "$tracked_artifacts" >&2
  fi

  if [[ -n "$staged_artifacts" ]]; then
    printf '\nStaged artifacts:\n' >&2
    printf '%s\n' "$staged_artifacts" >&2
  fi

  cat >&2 <<'NEXT'

Fix:
  1. Keep licensed model files only as local, ignored files.
  2. If one was accidentally added, remove it from the index:
     git rm --cached <path>
  3. Commit the manifest template or checksum notes instead of the model artifact.
NEXT
  exit 1
fi

cat <<'OK'
Model artifact git guard passed.

Local model files can remain under ModelResources for real-device validation, but blocked model artifacts are not tracked or staged.
OK
