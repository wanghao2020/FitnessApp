# Demo Seed Runbook

Use this runbook when you need a concrete native demo before real HealthKit, WatchConnectivity, or LiteRT-LM resources are available.

## Xcode Path

1. Open `native/FitnessRPG.xcodeproj`.
2. Select the shared scheme `FitnessRPGDemo`.
3. Run on an iPhone simulator.
4. Expected first screen: History opens with seeded weekly summary and recent training rows.
5. Expected data:
   - `2026-06-12` completed Today record.
   - Weekly summary title `演示周报：保守推进已闭环`.
   - Memory Review entries for seeded Watch results.
   - Diagnostics visible from Today because `--fitnessrpg-show-diagnostics` is enabled.

## CLI Smoke Path

Run from the repository root:

```bash
bash native/scripts/demo-seed-simulator-smoke.sh
```

The script finds a booted iPhone simulator or boots `iPhone 17`, builds `FitnessRPGDemo`, installs the app, launches with demo arguments, and verifies these JSON files:

- `training-days.json`
- `weekly-summary-polish-entries.json`
- `validation-reports.json`

Pass output:

```text
FitnessRPGDemo smoke passed on simulator <device-id>.
```

## Manual Launch Arguments

If you use the regular `FitnessRPG` scheme, add these Debug launch arguments manually:

```text
--fitnessrpg-demo-seed
--fitnessrpg-open-history
--fitnessrpg-show-diagnostics
```
