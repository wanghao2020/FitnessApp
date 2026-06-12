# 2026-06-12 Real-device Signing Preflight

## Summary

- Result: iPhone connection recovered; real-device build blocked by Xcode account/provisioning state.
- Device: `王皓的 iPhone (2)` / `iPhone 17 Pro Max (iPhone18,2)` / iOS 26.5.1.
- Device UDID: `00008150-000C34A93EEA401C`.
- CoreDevice identifier: `DEDC41C9-11BA-5FE5-B7B9-82A740729A4F`.

## Passed Device Checks

- `xcodebuild -showdestinations` lists the physical iPhone as an iOS destination.
- `xcrun devicectl device info lockState --device 00008150-000C34A93EEA401C --timeout 20` acquired a tunnel connection and usage assertion.
- Device lock state reported `unlockedSinceBoot: true`.

## Signing Configuration Added

The Xcode project now sets `DEVELOPMENT_TEAM = 4J87DT3T95` for:

- `FitnessRPG` Debug and Release.
- `FitnessRPGWatch` Debug and Release.

This Team ID matches the local code signing identity:

```text
Apple Development: 786058404@qq.com (4J87DT3T95)
```

## Blocking Evidence

Real-device build command:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj \
  -scheme FitnessRPG \
  -destination 'id=00008150-000C34A93EEA401C' \
  -derivedDataPath /private/tmp/FitnessRPGRealDevice \
  -allowProvisioningUpdates \
  build
```

Current failure:

- `No Account for Team "4J87DT3T95"`.
- No iOS App Development provisioning profile for `com.hao.fitnessrpg`.
- No iOS App Development provisioning profile for `com.hao.fitnessrpg.watch`.
- `~/Library/MobileDevice/Provisioning Profiles` does not currently exist.

## Resume Steps

1. In Xcode, open Settings > Accounts.
2. Add or refresh the Apple ID for Team `4J87DT3T95`.
3. Confirm Xcode can create/download development profiles for:
   - `com.hao.fitnessrpg`
   - `com.hao.fitnessrpg.watch`
4. Re-run the real-device build command above.
5. Install `/private/tmp/FitnessRPGRealDevice/Build/Products/Debug-iphoneos/FitnessRPG.app` with `xcrun devicectl device install app`.
6. Launch with `--fitnessrpg-show-diagnostics`, then continue `docs/validation/end-to-end-real-device-runbook.md` from baseline report capture.
