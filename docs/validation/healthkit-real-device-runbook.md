# HealthKit Real-device Validation Runbook

## Purpose

Validate HealthKit authorization, data coverage, conservative fallback notices, and validation report evidence on a real iPhone.

## Prerequisites

- A real iPhone with Apple Health available.
- Optional but recommended: paired Apple Watch with recent sleep/activity data.
- Xcode signing configured for `FitnessRPG`.
- The iOS app runs a DEBUG build.
- The iOS Run Arguments include `--fitnessrpg-show-diagnostics`.

For report archive screenshots, use `--fitnessrpg-open-validation-report-archive`.

## Local Preflight

Run from the repository root:

```bash
bash native/scripts/healthkit-real-device-preflight.sh
```

This checks HealthKit entitlement wiring, usage description wiring, HealthKit framework references, provider source references, Core tests, and generic app builds.

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

## Permission Reset Notes

To retest authorization states:

1. Open iOS Settings.
2. Go to Health > Data Access & Devices > Fitness RPG.
3. Toggle the requested read permissions off or on.
4. Relaunch Fitness RPG.
5. Save a new validation report after the Today surface updates.

## Data Coverage Notes

HealthKit success expects enough signal coverage for the current readiness mapper:

- Sleep: sleep analysis samples in the previous day.
- Recovery: HRV SDNN or resting heart-rate samples.
- Activity: active energy, exercise minutes, steps, or workout samples.

If any category is missing, the app should remain conservative and show the missing signal labels.

## Failure Routing

- HealthKit prompt never appears: verify entitlement, usage description, and Xcode signing profile.
- `HealthKit 不可用` on a real iPhone: confirm the app is not running under Simulator and Health is available on the device.
- Authorized but still `权限未完成`: toggle Fitness RPG permissions in Settings > Health > Data Access & Devices.
- Data remains insufficient: confirm Apple Watch has produced sleep, heart/recovery, and activity samples inside the queried windows.
- Success state still uses conservative yellow: inspect report drivers for `HealthKit 数据缺失` and compare missing signal labels.
- Runtime or WatchConnectivity blockers: record them in the same validation report, but do not treat them as HealthKit permission failures.

## Evidence Notes

Use validation report archive timestamps as run identifiers in issue notes.

Recommended issue-note format:

```text
Run: 2026-06-12 HealthKit permission/data pass
Device: iPhone model / iOS version / Watch model if used
HealthKit state: unavailable / authorizationDenied / insufficientData / healthKit
Report timestamp: <archive timestamp>
Result: pass / blocked
Blocker: <one line if blocked>
```
