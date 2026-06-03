# Native Scaffold Review Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the native skeleton final review polish by surfacing `Memory 草稿` in the iPhone scaffold and adding direct coverage for missing HealthKit readiness.

**Architecture:** Keep the shared core API unchanged. Add one focused Swift test for the existing conservative missing-data branch, then add one scaffold-only UI section in the existing iOS model harness panel.

**Tech Stack:** Swift 6, Swift Package Manager, XCTest, SwiftUI scaffold sources, existing JavaScript prototype contract tests.

---

## File Structure

- Modify `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`: add a direct missing HealthKit readiness test.
- Modify `native/AppSources/iOS/ModelHarnessPanel.swift`: add a compact `Memory 草稿` section inside the existing harness panel.

---

### Task 1: Add Missing HealthKit Readiness Coverage

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Add the missing HealthKit test**

Insert this test after `testRedReadinessProducesRecoveryGuidance()`:

```swift
    func testMissingHealthKitDataUsesConservativeYellowReadiness() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.missing)

        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertEqual(readiness.title, "共振偏移")
        XCTAssertTrue(readiness.explanation.contains("HealthKit 数据缺失"))
        XCTAssertTrue(readiness.safetyGuidance.contains("降低强度"))
    }
```

- [ ] **Step 2: Run Swift tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with 6 tests and 0 failures. If the test fails, inspect `ReadinessEngine.evaluate(_:)`; do not change core logic unless the failure shows the existing missing-data behavior no longer matches the approved spec.

- [ ] **Step 3: Commit the test**

```bash
git add native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "test: cover missing health data readiness"
```

---

### Task 2: Surface Memory Draft Copy in iPhone Scaffold

**Files:**
- Modify: `native/AppSources/iOS/ModelHarnessPanel.swift`

- [ ] **Step 1: Add the `Memory 草稿` section**

In `body`, insert this block after the `Fallback` block and before `Text(snapshot.promptPreview)`:

```swift
            VStack(alignment: .leading, spacing: 6) {
                Text("Memory 草稿")
                    .font(.subheadline.weight(.semibold))
                Text("完成后记录训练反馈、降阶信号和下一次建议。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
```

Expected resulting body section order:

1. `本地模型 Harness`
2. grouped sections for `输入上下文`, `Skill 规则`, `生成路径`
3. `Fallback`
4. `Memory 草稿`
5. prompt preview

- [ ] **Step 2: Run Swift tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with 6 tests and 0 failures.

- [ ] **Step 3: Commit the iPhone scaffold polish**

```bash
git add native/AppSources/iOS/ModelHarnessPanel.swift
git commit -m "feat: show memory draft in native harness"
```

---

### Task 3: Final Verification

**Files:**
- No file edits.

- [ ] **Step 1: Run native tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with 6 tests and 0 failures.

- [ ] **Step 2: Run browser prototype regression checks**

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

Expected: PASS with `prototype contract ok`.

- [ ] **Step 3: Confirm working tree state**

Run:

```bash
git status --short
```

Expected: no tracked changes; only known untracked migration-context paths remain:

```text
?? README.md
?? docs/project-brief.md
?? records/
?? work/
```

---

## Final Verification Checklist

- `cd native/FitnessRPGCore && swift test` passes with 6 tests.
- Existing prototype syntax checks pass.
- `node prototype/tests/prototypeContract.test.mjs` prints `prototype contract ok`.
- `ModelHarnessPanel.swift` visibly includes `Memory 草稿`.
- No real HealthKit, WatchConnectivity, model runtime, persistence, Xcode project, or browser prototype behavior changes were introduced.
