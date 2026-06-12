# End-to-end Real-device Validation Runbook

## Purpose

Validate the full DEBUG real-device loop across HealthKit data intake, WatchConnectivity execution, Runtime diagnostics, History persistence, weekly polish cache controls, and validation report archival.

## Prerequisites

- A paired real iPhone and Apple Watch.
- Xcode signing configured for `FitnessRPG` and `FitnessRPGWatch`.
- The iOS app runs a DEBUG build.
- The iOS Run Arguments include `--fitnessrpg-show-diagnostics`.
- For archive screenshots, add `--fitnessrpg-open-validation-report-archive`.
- For real Runtime only: LiteRTLM Swift package, `FITNESSRPG_ENABLE_LITERTLM`, and a licensed `gemma-4-E2B-it.litertlm` model package.

## Local Preflight

Run the aggregate preflight from the repository root:

```bash
bash native/scripts/end-to-end-real-device-preflight.sh
```

This runs the three domain wiring checks, then runs Core tests and iOS/watchOS generic builds once.

If the pass must require real LiteRT-LM execution instead of fallback Runtime diagnostics, run:

```bash
bash native/scripts/end-to-end-real-device-preflight.sh --require-real-runtime
```

## Validation Pass

### 1. Baseline Report

1. Install and launch the DEBUG iOS app on the paired real iPhone.
2. Confirm the Today surface shows the real-device validation overview.
3. Save a baseline validation report.
4. Open the validation report archive and confirm the baseline report is visible.

Expected evidence:

- The report includes Watch sync, HealthKit, Runtime, and History weekly polish sections.
- Any initial blockers are visible before the tester changes device state.

### 2. HealthKit Checkpoint

1. Confirm the HealthKit row state in the validation overview.
2. If HealthKit is unavailable, denied, or missing data, confirm Today shows the matching action rows.
3. If HealthKit is ready, confirm Today has no conservative HealthKit fallback notice.
4. Save a HealthKit state report.

Expected evidence:

- Authorization and data-coverage failures point to permissions or missing signals.
- A HealthKit data blocker does not block WatchConnectivity send/return validation.

### 3. WatchConnectivity Checkpoint

1. Confirm the Watch sync row reports installed or ready-to-send state.
2. Tap `发送到 Watch` from Today.
3. Open the Watch app.
4. Complete every Watch step with `完成`.
5. Return to iPhone and confirm inbound return is shown in diagnostics.
6. Save a Watch return report.

Expected evidence:

- Outbound send and inbound return are both visible.
- If a step is marked `过重`, iPhone still receives logs and routes to a reduced-load result.

### 4. History Checkpoint

1. Open History.
2. Confirm a new training day exists.
3. Open the latest day detail.
4. Confirm Watch step progress and result copy are present.
5. Save a History detail report if the state changed from baseline.

Expected evidence:

- History persists the completed day after Watch inbound return.
- The latest detail reflects the Watch execution path instead of only the pending quest.

### 5. Runtime Checkpoint

Choose one Runtime mode for the pass:

- Default fallback: keep LiteRT-LM SDK/model absent and confirm Runtime diagnostics explains resource or adapter fallback.
- DEBUG fixture: relaunch with one fixture argument and confirm parser, adapter, or validator handling.
- Real Runtime: add LiteRTLM, `FITNESSRPG_ENABLE_LITERTLM`, and the licensed `.litertlm` package, then rerun aggregate preflight with `--require-real-runtime`.

Fixture arguments:

- `--fitnessrpg-model-fixture-ready`
- `--fitnessrpg-model-fixture-parsing-failure`
- `--fitnessrpg-model-fixture-adapter-failure`
- `--fitnessrpg-model-fixture-validator-failure`

Expected evidence:

- Runtime fallback is explicit and does not block Watch or HealthKit validation.
- Ready Runtime output shows generated title and next action only after parser and validator acceptance.
- Validator rejection keeps deterministic safety copy.

### 6. Weekly Polish Cache Checkpoint

1. Open History after at least one training record exists.
2. Generate or regenerate weekly polish cache.
3. Confirm accepted polish copy appears only if provider output passes validation.
4. Clear the weekly polish cache.
5. Regenerate and save a final report.

Expected evidence:

- Weekly summary remains deterministic when Runtime is unavailable or unsafe.
- Cache clear/regenerate controls update the current weekly polish section.

### 7. Final Report

1. Save a final validation report.
2. Open the validation report archive.
3. Confirm baseline, state-specific, and final reports are visible.
4. Record archive timestamps in the issue or QA note.

## Failure Routing

- Watch app not installed: follow `docs/validation/watchconnectivity-real-device-runbook.md`.
- Watch outbound succeeds but no inbound return: keep both apps foregrounded, complete all Watch steps, then save a blocker report.
- HealthKit permission or data issue: follow `docs/validation/healthkit-real-device-runbook.md`; do not treat it as a Watch sync failure.
- Runtime resource or adapter fallback: follow `docs/validation/litertlm-real-device-runbook.md`; default fallback does not block the end-to-end pass unless the pass requires real Runtime.
- History does not update after inbound return: inspect Watch diagnostics for quest mismatch or decoding failure and save the current report.
- Weekly polish does not update: confirm at least one History record exists, then use clear/regenerate controls.

## Evidence Notes

Use validation report archive timestamps as run identifiers.

Recommended issue-note format:

```text
Run: 2026-06-12 end-to-end real-device pass
Device: iPhone model / Watch model / OS versions
Runtime mode: fallback / fixture-ready / fixture-failure / real-runtime
HealthKit state: unavailable / authorizationDenied / insufficientData / healthKit
Baseline report: <archive timestamp>
Watch return report: <archive timestamp>
Final report: <archive timestamp>
Result: pass / blocked
Blocker: <one line if blocked>
```
