# Today 固定 Watch 主行动 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `发送到 Watch` 从任务卡内部移到 Today 底部安全区，成为稳定可见的主行动。

**Architecture:** `FitnessRPGCore` 的 `TodayCommandCenterSummary` 负责主行动按钮文案和图标；SwiftUI 使用 `safeAreaInset(edge: .bottom)` 渲染固定 CTA，并保留原有 `watchSyncModel.send` 行为。

**Tech Stack:** Swift、SwiftUI、XCTest、Xcode iOS/watchOS Simulator build。

---

## 文件结构

- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`
  - 新增 `primaryActionLabel` 和 `primaryActionSystemImage`。
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
  - 扩展 Today summary 测试。
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - 新增底部固定 CTA 子视图，移除任务卡内部按钮。

## Task 1: Core 红测

- [x] **Step 1: 扩展 Today summary 测试**

在 `testTodayCommandCenterSummaryBuildsHeroAndQuestLabels` 中新增：

```swift
XCTAssertEqual(summary.primaryActionLabel, "发送到 Watch")
XCTAssertEqual(summary.primaryActionSystemImage, "applewatch")
```

- [x] **Step 2: 运行测试确认失败**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsHeroAndQuestLabels
```

Expected: FAIL，提示 `TodayCommandCenterSummary` 没有对应成员。

## Task 2: 实现主行动摘要

- [x] **Step 1: 更新 `TodayCommandCenterSummary`**

新增属性：

```swift
public let primaryActionLabel: String
public let primaryActionSystemImage: String
```

在 init 中赋值：

```swift
self.primaryActionLabel = "发送到 Watch"
self.primaryActionSystemImage = "applewatch"
```

- [x] **Step 2: 运行测试确认通过**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsHeroAndQuestLabels
```

Expected: PASS。

## Task 3: 重构 Today CTA

- [x] **Step 1: 修改 `TodayQuestActionCard`**

移除 `sendAction` 参数和卡片内部 Button，只保留任务标题、奖励、目标和 Watch 步骤。

- [x] **Step 2: 新增 `TodayStickyWatchCTA`**

新增子视图：

```swift
private struct TodayStickyWatchCTA: View {
    let summary: TodayCommandCenterSummary
    let sendAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: sendAction) {
                Label(summary.primaryActionLabel, systemImage: summary.primaryActionSystemImage)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(.regularMaterial)
    }
}
```

- [x] **Step 3: 在 Today 使用 safe area CTA**

`ScrollView` 内容底部加 `.padding(.bottom, 86)`，并在 `NavigationStack` 链上添加：

```swift
.safeAreaInset(edge: .bottom) {
    TodayStickyWatchCTA(summary: todaySummary) {
        watchSyncModel.send(quest: quest, readinessColor: questReadinessColor)
    }
}
```

## Task 4: 验证

- [x] **Step 1: SwiftPM 测试**

```bash
cd native/FitnessRPGCore
swift test
```

- [x] **Step 2: iOS build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGStickyCTA_iOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Watch build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGStickyCTA_watchOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: 模拟器截图**

安装 iOS build，默认启动 app，截图到 `/private/tmp/fitnessrpg-sticky-cta.png`，确认底部 CTA 可见且内容未被遮挡。

- [x] **Step 5: 差异检查**

```bash
git diff --check
```
