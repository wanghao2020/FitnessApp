# WatchConnectivity Real-device Validation Runbook

## Purpose

Validate the real iPhone + Apple Watch loop from Today quest send to Watch execution return, History persistence, and validation report archival.

## Prerequisites

- A paired real iPhone and Apple Watch.
- Xcode signing configured for `FitnessRPG` and `FitnessRPGWatch`.
- The iOS app runs a DEBUG build.
- The Watch app is installed on the paired watch.
- The iOS Run Arguments include `--fitnessrpg-show-diagnostics`.

For archive screenshots, use `--fitnessrpg-open-validation-report-archive` to enable diagnostics and open the saved-report archive sheet directly.

## Local Preflight

Run from the repository root:

```bash
bash native/scripts/watchconnectivity-real-device-preflight.sh
```

This checks local tools, runs Core tests, builds iOS/watchOS generic targets, and attempts to list connected devices with `devicectl`.

## Validation Pass

1. Launch iOS Today with diagnostics enabled.
2. Save a baseline validation report from the real-device validation overview.
3. Confirm the Watch sync row says the Watch app is installed or ready to send.
4. Tap the bottom `发送到 Watch` button.
5. Open the Watch app.
6. Complete every Watch step using `完成`.
7. Return to iPhone and confirm the Watch sync row reports an inbound return.
8. Open History and confirm a new record exists.
9. Open the latest History detail and confirm Watch progress and result text.
10. Generate or regenerate weekly polish cache if records exist.
11. Save a final validation report.
12. Open the validation report archive and confirm baseline/final reports are visible.

## Negative Pass

Run a second pass where one Watch step uses `过重`.

Expected result:

- iPhone still receives inbound Watch logs.
- History stores the day.
- Result copy reflects reduced load or safety downgrade.
- Memory draft mentions the heavy feedback path.

## Expected Evidence

- Baseline and final validation reports are saved.
- WatchConnectivity diagnostics show outbound and inbound rows.
- History contains the completed day.
- Latest History detail shows Watch step progress and result copy.
- The real-device validation overview has no Watch sync blocker after inbound return.

## Failure Routing

- Watch app not installed: reinstall from Xcode and confirm companion bundle settings.
- Watch unreachable: keep both apps foregrounded, unlock both devices, then retry send.
- Outbound only, no inbound: complete all Watch steps and wait for queued transfer.
- Inbound but no History: check iOS status text for quest mismatch or decoding failure.
- HealthKit blocker: follow the HealthKit action row before treating Watch sync as failed.
- Runtime blocker: resource or adapter fallback does not block Watch sync validation.
- Weekly polish missing: create at least one History record, then regenerate from History.

## Report Naming

When saving report snapshots, use the visible timestamp in the archive row as the run identifier in issue notes.

Recommended issue-note format:

```text
Run: 2026-06-12 real-device WatchConnectivity pass
Device: iPhone model / watch model / OS versions
Baseline report: <archive timestamp>
Final report: <archive timestamp>
Result: pass / blocked
Blocker: <one line if blocked>
```
