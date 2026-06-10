# Native Xcode Buildable Targets Design

## Goal

Create a real native app project baseline for Fitness RPG so the existing iPhone and Apple Watch SwiftUI scaffold can be built by Xcode.

This pass should move the native app layer from "source folders waiting for a future project" to "buildable iOS and watchOS targets", while keeping the current product behavior, mock data, and deterministic shared core unchanged.

## Chosen Direction

Use a minimal checked-in Xcode project under `native/FitnessRPG.xcodeproj`.

The project should define two buildable app targets:

- `FitnessRPG`: iOS app target using `native/AppSources/iOS/*.swift`.
- `FitnessRPGWatch`: watchOS app target using `native/AppSources/watchOS/*.swift`.

Both app targets should depend on the existing local Swift Package at `native/FitnessRPGCore`, and both should link the `FitnessRPGCore` product.

## Why This Direction

The current repository already has app entry points:

- `native/AppSources/iOS/FitnessRPGApp.swift`
- `native/AppSources/watchOS/FitnessRPGWatchApp.swift`

It also already has a compiled shared Swift Package with iOS and watchOS platform support:

- `native/FitnessRPGCore/Package.swift`

The missing piece is the Xcode project container that turns those files into real app targets.

This repository does not currently include XcodeGen, Tuist, or another project generator. Adding one would introduce toolchain setup work before the native baseline exists. For F1, a minimal committed `.xcodeproj` is the shortest path to a buildable baseline.

## Project Shape

Add:

- `native/FitnessRPG.xcodeproj/project.pbxproj`

Optionally add shared Xcode scheme files if they are needed for stable command-line builds:

- `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPG.xcscheme`
- `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGWatch.xcscheme`

Update:

- `native/README.md`
- `README.md`

The docs should say that native app targets now exist and document the build commands.

## Target Behavior

The iOS app target should launch `FitnessRPGApp`, which currently renders `TodayCommandCenterView` with deterministic green mock health data and local-first model mode.

The watchOS app target should launch `FitnessRPGWatchApp`, which currently renders `WatchExecutionView` with a deterministic quest generated from green readiness.

No HealthKit access, WatchConnectivity sync, persistence, local model runtime, signing, or simulator launch behavior should be added in this pass.

## Build Settings

Use conservative settings focused on command-line buildability:

- Swift language version matching the current package toolchain.
- iOS deployment target compatible with the package platform declaration.
- watchOS deployment target compatible with the package platform declaration.
- bundle identifiers that are placeholders but stable within the repo.
- automatic signing disabled or bypassable in command-line verification with `CODE_SIGNING_ALLOWED=NO`.

The implementation should not require a paid developer team or device signing to verify.

## Verification

F1 is complete only if these commands pass locally:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
cd native/FitnessRPGCore
swift test
```

The existing browser prototype checks should also remain available, but F1 does not modify prototype behavior.

## Non-Goals

This pass does not include:

- generating or installing XcodeGen, Tuist, CocoaPods, or other project tooling,
- running either app in a simulator,
- configuring a real Apple development team,
- embedding the watch app inside the iOS app for distribution,
- adding HealthKit entitlements,
- adding WatchConnectivity,
- adding App Groups,
- adding persistence,
- adding LiteRT-LM or Gemma runtime resources,
- changing `FitnessRPGCore` behavior,
- changing browser prototype behavior.

## Risks

Hand-authored Xcode project files are easy to make invalid. The implementation should keep the project minimal and verify with `xcodebuild` after each meaningful project-file change.

watchOS target build settings are more fragile than iOS app settings. If the watch target requires extra project metadata, prefer the smallest metadata needed for command-line buildability and document any trade-off in `native/README.md`.

## Future Follow-Ups

After F1, recommended native work can proceed in this order:

1. F2: HealthKit adapter maps real health data into `HealthSummary`.
2. F3: WatchConnectivity syncs quest payloads and execution logs.
3. F4: persistence stores workout results, memory drafts, and story progression.
4. F5: local model runtime plugs into the deterministic harness and validator.
