# Native Xcode Buildable Targets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a checked-in Xcode project with buildable iOS and watchOS app targets for the existing Fitness RPG SwiftUI scaffold.

**Architecture:** Create a minimal `native/FitnessRPG.xcodeproj` that owns two app targets, `FitnessRPG` and `FitnessRPGWatch`. Both targets reference the existing local Swift Package at `native/FitnessRPGCore` and compile only their platform-specific SwiftUI sources. Keep runtime behavior unchanged; this pass is about native project buildability.

**Tech Stack:** Xcode 26.5 project file, SwiftUI, Swift Package Manager local package dependency, `xcodebuild`, Swift Package tests.

---

## File Structure

- Create `native/FitnessRPG.xcodeproj/project.pbxproj`: minimal Xcode project with iOS and watchOS app targets.
- Create `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPG.xcscheme`: shared iOS app build scheme.
- Create `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGWatch.xcscheme`: shared watchOS app build scheme.
- Modify `native/README.md`: update current status and add Xcode build commands.
- Modify `README.md`: replace native status and verification notes so the root entry point reflects the new buildable targets.

No source behavior changes are planned. Only touch `native/AppSources/**` if `xcodebuild` proves a compile issue that is impossible to solve through project settings.

---

### Task 1: Create Minimal Xcode Project and Shared Schemes

**Files:**
- Create: `native/FitnessRPG.xcodeproj/project.pbxproj`
- Create: `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPG.xcscheme`
- Create: `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGWatch.xcscheme`

- [ ] **Step 1: Confirm no Xcode project already exists**

Run:

```bash
find native -maxdepth 2 -name '*.xcodeproj' -o -name '*.xcworkspace' -print
```

Expected before this task: no output.

- [ ] **Step 2: Create the project directory**

Run:

```bash
mkdir -p native/FitnessRPG.xcodeproj/xcshareddata/xcschemes
```

- [ ] **Step 3: Add `project.pbxproj`**

Create `native/FitnessRPG.xcodeproj/project.pbxproj` with a minimal hand-authored project containing:

- `PBXProject` with `LastUpgradeCheck = 2650`.
- One `XCLocalSwiftPackageReference` whose `relativePath` is `FitnessRPGCore`.
- One `XCSwiftPackageProductDependency` for product `FitnessRPGCore`.
- iOS `PBXNativeTarget` named `FitnessRPG`.
- watchOS `PBXNativeTarget` named `FitnessRPGWatch`.
- iOS source build files:
  - `FitnessRPGApp.swift`
  - `TodayCommandCenterView.swift`
  - `ReadinessPanel.swift`
  - `QuestPanel.swift`
  - `ModelHarnessPanel.swift`
- watchOS source build files:
  - `FitnessRPGWatchApp.swift`
  - `WatchExecutionView.swift`
- iOS target build settings:
  - `PRODUCT_BUNDLE_IDENTIFIER = com.hao.fitnessrpg`
  - `PRODUCT_NAME = FitnessRPG`
  - `SDKROOT = iphoneos`
  - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`
  - `TARGETED_DEVICE_FAMILY = "1,2"`
  - `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
  - `SWIFT_VERSION = 6.0`
  - `GENERATE_INFOPLIST_FILE = YES`
  - `INFOPLIST_KEY_CFBundleDisplayName = "Fitness RPG"`
  - `CODE_SIGN_STYLE = Automatic`
- watchOS target build settings:
  - `PRODUCT_BUNDLE_IDENTIFIER = com.hao.fitnessrpg.watch`
  - `PRODUCT_NAME = FitnessRPGWatch`
  - `SDKROOT = watchos`
  - `SUPPORTED_PLATFORMS = "watchos watchsimulator"`
  - `WATCHOS_DEPLOYMENT_TARGET = 10.0`
  - `SWIFT_VERSION = 6.0`
  - `GENERATE_INFOPLIST_FILE = YES`
  - `INFOPLIST_KEY_CFBundleDisplayName = "Fitness RPG Watch"`
  - `CODE_SIGN_STYLE = Automatic`

Keep the file small. Do not add asset catalogs, entitlements, app groups, HealthKit, WatchConnectivity, or simulator launch configuration.

- [ ] **Step 4: Add shared iOS scheme**

Create `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPG.xcscheme` with a `BuildAction` that builds only the `FitnessRPG` target and a `LaunchAction` that points at `FitnessRPG.app`.

The `BuildableReference` should use the iOS target's `BlueprintIdentifier`, `BuildableName="FitnessRPG.app"`, `BlueprintName="FitnessRPG"`, and `ReferencedContainer="container:FitnessRPG.xcodeproj"`.

- [ ] **Step 5: Add shared watchOS scheme**

Create `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGWatch.xcscheme` with a `BuildAction` that builds only the `FitnessRPGWatch` target and a `LaunchAction` that points at `FitnessRPGWatch.app`.

The `BuildableReference` should use the watchOS target's `BlueprintIdentifier`, `BuildableName="FitnessRPGWatch.app"`, `BlueprintName="FitnessRPGWatch"`, and `ReferencedContainer="container:FitnessRPG.xcodeproj"`.

- [ ] **Step 6: Validate project and schemes are discoverable**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -list
```

Expected output includes:

```text
Targets:
    FitnessRPG
    FitnessRPGWatch

Schemes:
    FitnessRPG
    FitnessRPGWatch
```

- [ ] **Step 7: Commit project skeleton**

Run:

```bash
git add native/FitnessRPG.xcodeproj
git commit -m "feat: add native xcode project skeleton"
```

---

### Task 2: Make iOS App Target Build

**Files:**
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`
- Modify only if compile output requires it: `native/AppSources/iOS/*.swift`

- [ ] **Step 1: Build the iOS scheme**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 2: If the package is not linked, fix the project dependency**

Only if Step 1 fails with `no such module 'FitnessRPGCore'`, update `project.pbxproj` so the iOS target has:

- `packageProductDependencies = ( FitnessRPGCore product dependency id );`
- a `PBXBuildFile` for the `FitnessRPGCore` product in `Frameworks` build phase.
- `packageReferences = ( FitnessRPGCore local package id );` on `PBXProject`.

Re-run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 3: If Info.plist metadata is missing, fix generated plist settings**

Only if Step 1 fails with missing bundle metadata, keep `GENERATE_INFOPLIST_FILE = YES` and add the specific generated plist keys that the compiler requests, such as:

```text
INFOPLIST_KEY_CFBundleDisplayName = "Fitness RPG";
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
```

Re-run the iOS build command and require `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit iOS buildability fixes**

Run:

```bash
git add native/FitnessRPG.xcodeproj native/AppSources/iOS
git commit -m "build: make ios app target compile"
```

If `native/AppSources/iOS` was not changed, stage only `native/FitnessRPG.xcodeproj`.

---

### Task 3: Make watchOS App Target Build

**Files:**
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`
- Modify only if compile output requires it: `native/AppSources/watchOS/*.swift`

- [ ] **Step 1: Build the watchOS scheme**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 2: If the package is not linked, fix the project dependency**

Only if Step 1 fails with `no such module 'FitnessRPGCore'`, update `project.pbxproj` so the watchOS target has:

- `packageProductDependencies = ( FitnessRPGCore product dependency id );`
- a `PBXBuildFile` for the `FitnessRPGCore` product in `Frameworks` build phase.
- the same `XCLocalSwiftPackageReference` used by the iOS target.

Re-run the watchOS build command and require `** BUILD SUCCEEDED **`.

- [ ] **Step 3: If watchOS requires app category metadata, fix generated plist settings**

Only if the watchOS build fails on generated Info.plist metadata, keep `GENERATE_INFOPLIST_FILE = YES` and add:

```text
INFOPLIST_KEY_CFBundleDisplayName = "Fitness RPG Watch";
INFOPLIST_KEY_WKApplication = YES;
```

Re-run the watchOS build command and require `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit watchOS buildability fixes**

Run:

```bash
git add native/FitnessRPG.xcodeproj native/AppSources/watchOS
git commit -m "build: make watchos app target compile"
```

If `native/AppSources/watchOS` was not changed, stage only `native/FitnessRPG.xcodeproj`.

---

### Task 4: Update Native Documentation

**Files:**
- Modify: `native/README.md`
- Modify: `README.md`

- [ ] **Step 1: Update `native/README.md` current status**

Change the current-status language from "source scaffolds not wired into an Xcode project yet" to "the repo now includes `native/FitnessRPG.xcodeproj` with buildable iOS and watchOS schemes."

Keep the future integration list for HealthKit, WatchConnectivity, LiteRT-LM / Gemma, and persistence.

- [ ] **Step 2: Add native build commands to `native/README.md`**

Add:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

- [ ] **Step 3: Update root `README.md` native status**

Replace:

```text
The native code is currently a Swift Package plus SwiftUI source scaffold. There is no committed `.xcodeproj` or `.xcworkspace` yet.
```

With:

```text
The native code now includes `native/FitnessRPG.xcodeproj` with buildable iOS and watchOS app schemes, plus the shared `native/FitnessRPGCore` Swift Package.
```

- [ ] **Step 4: Update root `README.md` verification section**

Add the same two `xcodebuild` commands before the Swift Package test command.

- [ ] **Step 5: Verify documentation references**

Run:

```bash
rg -n "FitnessRPG.xcodeproj|FitnessRPGWatch|generic/platform=iOS|generic/platform=watchOS|FitnessRPGCore" README.md native/README.md
```

Expected output includes both xcodebuild commands and the shared core package reference.

- [ ] **Step 6: Commit documentation updates**

Run:

```bash
git add README.md native/README.md
git commit -m "docs: document native xcode builds"
```

---

### Task 5: Final Verification

**Files:**
- No planned file edits.

- [ ] **Step 1: Verify the Xcode project list**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -list
```

Expected output includes targets and schemes for `FitnessRPG` and `FitnessRPGWatch`.

- [ ] **Step 2: Verify iOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 3: Verify watchOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected final output:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 4: Verify shared core tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected output includes:

```text
Executed 6 tests, with 0 failures
```

- [ ] **Step 5: Verify prototype checks still pass**

Run from the repository root:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
```

Expected final output includes:

```text
prototype contract ok
```

- [ ] **Step 6: Confirm clean status**

Run:

```bash
git status --short
```

Expected: no output.

---

## Final Verification Checklist

- `native/FitnessRPG.xcodeproj` exists and is tracked.
- `xcodebuild -project native/FitnessRPG.xcodeproj -list` lists both app targets and shared schemes.
- `FitnessRPG` iOS scheme builds with `CODE_SIGNING_ALLOWED=NO`.
- `FitnessRPGWatch` watchOS scheme builds with `CODE_SIGNING_ALLOWED=NO`.
- `FitnessRPGCore` Swift Package tests still pass with 6 tests and 0 failures.
- Prototype syntax and contract checks still pass.
- `README.md` and `native/README.md` document the new native build commands.
- No HealthKit, WatchConnectivity, persistence, local model runtime, signing, simulator launch, or product behavior changes are included in this pass.
