# Today Next Focus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Today Hero 中增加可测试的“下一步焦点”提示，让用户能直接判断现在该发送到 Watch、继续执行，还是查看 History。

**Architecture:** `FitnessRPGCore` 的 `TodayCommandCenterSummary` 负责派生 next focus 文案和 SF Symbol；`TodayCommandCenterView` 只渲染一个紧凑 focus row。业务状态、WatchConnectivity、HealthKit 和持久化不变。

**Tech Stack:** Swift, SwiftUI, XCTest, Xcode generic builds.

---

## 文件结构

- 修改 `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`：新增 next focus 字段和派生规则。
- 修改 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`：新增 next focus 状态测试。
- 修改 `native/AppSources/iOS/TodayCommandCenterView.swift`：Hero 中渲染 next focus row。

---

### Task 1: Core next focus 红测

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: 写失败测试**

在 `testTodayCommandCenterSummaryBuildsHeroAndQuestLabels` 附近新增：

```swift
func testTodayCommandCenterSummaryBuildsNextFocusForWatchProgress() {
    let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
    let quest = QuestEngine.quest(for: readiness, storyNode: "回声训练厅")

    let notStarted = TodayCommandCenterSummary(readiness: readiness, quest: quest, executionLogCount: 0)
    XCTAssertEqual(notStarted.nextFocusHeadline, "下一步：发送到 Watch")
    XCTAssertEqual(notStarted.nextFocusDetail, "把 3 个步骤同步到手表。")
    XCTAssertEqual(notStarted.nextFocusSystemImage, "applewatch")

    let inProgress = TodayCommandCenterSummary(readiness: readiness, quest: quest, executionLogCount: 1)
    XCTAssertEqual(inProgress.nextFocusHeadline, "下一步：继续 Watch 执行")
    XCTAssertEqual(inProgress.nextFocusDetail, "已回传 1/3 步，完成剩余步骤后回到 iPhone。")
    XCTAssertEqual(inProgress.nextFocusSystemImage, "figure.run")

    let completed = TodayCommandCenterSummary(readiness: readiness, quest: quest, executionLogCount: 3)
    XCTAssertEqual(completed.nextFocusHeadline, "下一步：查看 History")
    XCTAssertEqual(completed.nextFocusDetail, "今日 Watch 记录已收齐，查看结果与故事进度。")
    XCTAssertEqual(completed.nextFocusSystemImage, "clock.arrow.circlepath")
}
```

- [x] **Step 2: RED 验证**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsNextFocusForWatchProgress
```

Expected: fails because `TodayCommandCenterSummary` has no next focus members.

### Task 2: 实现 Core next focus

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`

- [x] **Step 1: 新增字段**

Add public fields:

```swift
public let nextFocusHeadline: String
public let nextFocusDetail: String
public let nextFocusSystemImage: String
```

- [x] **Step 2: 实现派生规则**

Use `totalSteps = max(quest.watchSteps.count, executionLogCount)` and assign:

```swift
if executionLogCount <= 0 {
    self.nextFocusHeadline = "下一步：发送到 Watch"
    self.nextFocusDetail = "把 \(totalSteps) 个步骤同步到手表。"
    self.nextFocusSystemImage = "applewatch"
} else if executionLogCount < totalSteps {
    self.nextFocusHeadline = "下一步：继续 Watch 执行"
    self.nextFocusDetail = "已回传 \(executionLogCount)/\(totalSteps) 步，完成剩余步骤后回到 iPhone。"
    self.nextFocusSystemImage = "figure.run"
} else {
    self.nextFocusHeadline = "下一步：查看 History"
    self.nextFocusDetail = "今日 Watch 记录已收齐，查看结果与故事进度。"
    self.nextFocusSystemImage = "clock.arrow.circlepath"
}
```

- [x] **Step 3: GREEN 验证**

Run the filtered test again; expected pass.

### Task 3: 更新 Today Hero

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [x] **Step 1: 增加 `TodayNextFocusRow`**

Add a private SwiftUI view near `TodayInlineMetric`:

```swift
private struct TodayNextFocusRow: View {
    let summary: TodayCommandCenterSummary
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: summary.nextFocusSystemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.nextFocusHeadline)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
                    .lineLimit(2)
                Text(summary.nextFocusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
```

- [x] **Step 2: 插入 Hero**

In `TodayHeroCard`, place:

```swift
TodayNextFocusRow(summary: summary, tint: tint)
```

between the status line and inline metrics.

### Task 4: 验证和提交

- [x] `swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsNextFocusForWatchProgress`
- [x] `swift test --package-path native/FitnessRPGCore`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `git diff --check`
- [x] Commit with `feat(native): surface today next focus`
