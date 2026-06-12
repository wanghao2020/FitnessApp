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
bash native/scripts/model-artifact-git-guard.sh
bash native/scripts/litertlm-integration-checklist.sh
bash native/scripts/litertlm-real-device-preflight.sh
```

After adding real model assets and SDK wiring, run:

```bash
bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime
```

## LiteRT-LM Integration Kit

Use the integration checklist before touching Xcode package settings:

```bash
bash native/scripts/litertlm-integration-checklist.sh
```

The checklist verifies the guarded iOS adapter boundary, the model resource documentation, and these local templates:

- `native/scripts/model-artifact-git-guard.sh`
- `native/Config/LiteRTLMRealRuntime.example.xcconfig`
- `native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json`

When the LiteRTLM package URL and licensed model artifact are confirmed:

1. Add the LiteRTLM Swift package in Xcode.
2. Link the LiteRTLM product to the `FitnessRPG` iOS target.
3. Copy `native/Config/LiteRTLMRealRuntime.example.xcconfig` into an active iOS Debug configuration or add `FITNESSRPG_ENABLE_LITERTLM` manually.
4. Place `gemma-4-E2B-it.litertlm` under `native/AppSources/iOS/ModelRuntime/ModelResources/`.
5. Run `bash native/scripts/model-artifact-git-guard.sh` and confirm the model artifact remains local and ignored.
6. Record source and checksum notes using `model-package-manifest.example.json` outside git.
7. Rerun:

```bash
bash native/scripts/model-artifact-git-guard.sh
bash native/scripts/litertlm-integration-checklist.sh --require-real-runtime
bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime
```

## Validation Passes

### 1. Default Fallback Pass

1. Launch iOS with `--fitnessrpg-show-diagnostics`.
2. Confirm Runtime diagnostics reports missing resource or adapter unavailable.
3. Confirm Today still renders deterministic safe copy.
4. Save a validation report.
5. Open the validation report archive and confirm the report is visible.

Expected evidence:

- Runtime row has a clear resource or adapter blocker.
- Real-device validation overview marks Runtime as needing action.
- The app remains usable through deterministic fallback.

### 2. DEBUG Fixture Pass

Run these launch arguments one at a time with diagnostics enabled:

- `--fitnessrpg-model-fixture-ready`
- `--fitnessrpg-model-fixture-parsing-failure`
- `--fitnessrpg-model-fixture-adapter-failure`
- `--fitnessrpg-model-fixture-validator-failure`

Expected evidence:

- Ready fixture shows generated draft title and next action.
- Parsing failure reports parser fallback.
- Adapter failure reports adapter fallback.
- Validator failure reports safety fallback.
- Each pass can be captured in a saved validation report.

### 3. Real Runtime Pass

1. Place `gemma-4-E2B-it.litertlm` under `native/AppSources/iOS/ModelRuntime/ModelResources/`.
2. Link LiteRTLM Swift package to the iOS target.
3. Add `FITNESSRPG_ENABLE_LITERTLM` to iOS Swift flags.
4. Run:

```bash
bash native/scripts/model-artifact-git-guard.sh
bash native/scripts/litertlm-real-device-preflight.sh --require-real-runtime
```

5. Install on a real iPhone.
6. Launch with `--fitnessrpg-show-diagnostics`.
7. Confirm Runtime diagnostics no longer reports missing resource or adapter unavailable.
8. Trigger Today model output and History weekly polish output.
9. Confirm output passes parser and validator before acceptance.
10. Save baseline and final validation reports.

Expected evidence:

- Bundle resource preflight is ready.
- Adapter path executes without `LiteRT/Gemma SDK 尚未接入`.
- Generated title/body/next action appear only after parser and validator accept the output.
- Validator rejection still falls back safely if the model emits unsafe training advice.

## Failure Routing

- Missing model package: verify the exact `ModelResources/gemma-4-E2B-it.litertlm` path.
- Model package appears in Git: run `bash native/scripts/model-artifact-git-guard.sh`, then remove it from the index with `git rm --cached <path>`.
- Model package too small: replace placeholder with a licensed model package.
- SDK not linked: confirm the iOS target links LiteRTLM and the package product name appears in the project.
- Flag not enabled: add `FITNESSRPG_ENABLE_LITERTLM` to iOS Swift flags.
- Parser failure: inspect raw model output and JSON contract.
- Validator failure: inspect unsafe or too-broad coach text and keep deterministic fallback.
- Device memory/performance failure: lower `maximumTokenCount` or test on newer hardware.
- History polish does not update: confirm provider diagnostics are ready and use the regenerate control in History.

## Evidence Notes

Use validation report archive timestamps as run identifiers.

Recommended issue-note format:

```text
Run: 2026-06-12 LiteRT-LM real-device pass
Device: iPhone model / iOS version
Runtime mode: fallback / fixture-ready / fixture-failure / real-runtime
Model package: present / missing / not tested
Report timestamp: <archive timestamp>
Result: pass / blocked
Blocker: <one line if blocked>
```
