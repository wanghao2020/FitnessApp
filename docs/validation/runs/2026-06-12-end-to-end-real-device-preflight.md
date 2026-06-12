# 2026-06-12 End-to-end Real-device Preflight Run

## Summary

- Result: local preflight passed; real-device validation blocked by unavailable iPhone tunnel.
- Runtime mode: default fallback validation path.
- Command: `bash native/scripts/end-to-end-real-device-preflight.sh`

## Passed Local Checks

- Model artifact git guard passed.
- WatchConnectivity wiring preflight passed.
- HealthKit wiring preflight passed.
- LiteRT-LM / Gemma wiring preflight passed.
- `FitnessRPGCore` Swift Package tests passed: 110 tests, 0 failures.
- iOS generic build passed.
- watchOS generic build passed.

## Device Discovery

`xcrun devicectl list devices` found:

- Name: `王皓的 iPhone (2)`
- Identifier: `DEDC41C9-11BA-5FE5-B7B9-82A740729A4F`
- Model: `iPhone 17 Pro Max (iPhone18,2)`
- State: `unavailable`

Verbose device details showed:

- Pairing state: paired.
- Developer Mode: enabled.
- DDI services available: false.
- Tunnel state: unavailable.
- Last connection: 2026-06-01 13:13 UTC, 2026-06-01 21:13 Asia/Shanghai.

## Blocking Evidence

- `xcrun devicectl device info lockState --device 00008150-000C34A93EEA401C --timeout 10` failed with CoreDevice error 1011: CoreDeviceService could not locate the device.
- `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -showdestinations` did not list the physical iPhone as an available run destination.

## Resume Steps

1. Connect or wake the iPhone and keep it unlocked.
2. Confirm the Mac trusts the iPhone in Finder or Xcode Devices and Simulators.
3. Re-run `xcrun devicectl list devices`; continue only when the device state is available.
4. Re-run `bash native/scripts/end-to-end-real-device-preflight.sh`.
5. Continue from `docs/validation/end-to-end-real-device-runbook.md` baseline report capture.
