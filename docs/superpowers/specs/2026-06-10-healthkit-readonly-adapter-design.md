# HealthKit Read-Only Adapter Design

## Goal

Add a read-only HealthKit MVP for the iOS app so real Apple Health data can feed Fitness RPG readiness without changing the deterministic safety model in `FitnessRPGCore`.

This pass should replace the iOS app's fixed green mock input with a HealthKit-backed `HealthSummary` when available, while preserving conservative fallback behavior when HealthKit is unavailable, denied, or incomplete.

## Chosen Direction

Use F2-A: iOS-only read-only HealthKit adapter.

The adapter belongs in the iOS app source area, not in `FitnessRPGCore`:

- `FitnessRPGCore` remains platform-light and deterministic.
- HealthKit framework usage stays isolated to the iOS target.
- watchOS buildability remains unaffected.
- Tests for scoring and fallback can use pure Swift mapping inputs instead of real HealthKit permissions.

## Architecture

Add an iOS HealthKit integration layer under `native/AppSources/iOS/HealthKit/`.

The layer should have three responsibilities:

1. Request read authorization for the HealthKit types needed by the MVP.
2. Read recent health samples and aggregate them into normalized app-level signals.
3. Map those signals into the existing `HealthSummary` domain model.

`FitnessRPGCore` continues to own readiness evaluation. HealthKit code should only produce `HealthSummary`; it should not decide green/yellow/red readiness directly.

## Data Flow

```text
HealthKit raw samples
    -> iOS HealthKit adapter
    -> normalized health signals
    -> HealthSummary
    -> ReadinessEngine.evaluate
    -> TodayCommandCenterView
```

Raw HealthKit values must not be passed into model prompt previews or RPG narrative generation. The model harness should only see existing bounded objects such as `ReadinessResult`, `DailyQuest`, and short explanatory drivers.

## HealthKit Read Types

The MVP should request read access only. It should not request write access.

Read types:

- sleep analysis
- resting heart rate
- heart rate variability SDNN
- heart rate
- active energy burned
- exercise time
- step count
- workouts

These types match the product brief's need to summarize sleep, recovery, recent load, and heart-rate context.

## Mapping To `HealthSummary`

The app already has this domain model:

```swift
public struct HealthSummary: Equatable, Sendable {
    public let energy: Int
    public let recovery: Int
    public let strain: Int
    public let sleep: Int
    public let heartRateTrend: Int
    public let drivers: [String]
}
```

F2 should map HealthKit data into the existing 0-100 style fields:

- `sleep`: based primarily on recent sleep duration and available sleep samples.
- `recovery`: based on HRV and resting heart-rate signals when present.
- `strain`: based on active energy, exercise time, step count, and recent workouts.
- `heartRateTrend`: based on resting heart-rate or heart-rate trend signals.
- `energy`: derived from sleep and recovery, adjusted downward for high strain.
- `drivers`: concise Chinese explanations such as `睡眠稳定`, `恢复偏低`, `昨日负荷偏高`, `HealthKit 数据缺失`.

The first implementation should favor simple bounded heuristics over complex physiological claims. It is acceptable for this MVP to be approximate as long as it is conservative and explainable.

## Fallback Behavior

When HealthKit is unavailable, authorization is denied, or required data is insufficient, the adapter should return a conservative `HealthSummary` equivalent to the existing missing-data profile:

```swift
HealthSummary(
    energy: 55,
    recovery: 55,
    strain: 55,
    sleep: 55,
    heartRateTrend: 0,
    drivers: ["HealthKit 数据缺失", "使用保守黄灯"]
)
```

This is intentional. `ReadinessEngine.evaluate(_:)` already treats `HealthKit 数据缺失` as a yellow readiness state with reduced intensity guidance.

## iOS App State

The iOS app should stop hardcoding `MockHealthProfiles.green` at launch.

Add a lightweight app-facing model that can represent:

- loading or requesting authorization,
- HealthKit available with a loaded summary,
- HealthKit unavailable,
- authorization denied or failed,
- incomplete data using conservative fallback.

The UI may stay minimal for F2. It should be enough for `FitnessRPGApp` to provide a readiness result derived from the current summary. Rich loading, error, and refresh interactions can be expanded in a later F2.1 pass.

## Safety Boundaries

This pass must not:

- write HealthKit data,
- start a workout session,
- add WatchConnectivity,
- add persistence,
- add app groups,
- add local model runtime behavior,
- pass raw HealthKit samples to prompts,
- reward unsafe overreaching in narrative text.

Fitness decisions remain constrained by `ReadinessEngine` and deterministic fallback rules before any model or narrative layer is involved.

## Xcode Project Changes

The iOS target should link HealthKit and include the new iOS source files.

The project will need HealthKit capability/entitlement metadata before real-device authorization can work. F2 should add the smallest required iOS entitlement/configuration for HealthKit read access, without adding unrelated capabilities.

The watchOS target should continue to build and should not link HealthKit in this pass.

## Testing

Use pure Swift tests for the mapper by testing normalized inputs rather than live HealthKit.

Test cases should cover:

- healthy signals map to a green-leaning summary,
- high recent strain or weak recovery maps to yellow-leaning summary,
- poor sleep or elevated heart-rate trend maps to red-leaning summary,
- missing signals produce the conservative missing-data summary.

Build verification should include:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
cd native/FitnessRPGCore
swift test
```

Prototype checks should remain available, but F2 does not change browser prototype behavior.

## Non-Goals

This pass does not include:

- polished HealthKit permission UX,
- manual refresh controls,
- background delivery,
- HealthKit writes,
- workout sessions,
- live workout heart-rate streaming,
- WatchConnectivity,
- persistence,
- HealthKit data visualizations,
- local model runtime integration,
- remote API integration.

## Future Follow-Ups

After F2:

1. F2.1 can improve HealthKit permission/error/loading UI and add manual refresh.
2. F3 can add WatchConnectivity for quest payload and execution logs.
3. F4 can persist summaries, workout results, memory drafts, and story progression.
4. F5 can attach local model runtime behind the deterministic harness and validator.
