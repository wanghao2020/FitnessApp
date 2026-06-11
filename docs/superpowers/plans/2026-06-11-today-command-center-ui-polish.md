# Today 中枢 UI 优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Today 中枢优化为和 History 一致的 Native Pro + 轻 RPG 行动中心。

**Architecture:** 在 `FitnessRPGCore` 增加 `TodayCommandCenterSummary`，集中派生 Today 页面文案；SwiftUI 负责布局、图标、字体层级和卡片结构。保持 HealthKit、WatchConnectivity、持久化和结算逻辑不变。

**Tech Stack:** Swift、SwiftUI、XCTest、Xcode iOS/watchOS Simulator build。

---

## 文件结构

- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`
  - Today 页面展示摘要。
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
  - 为 Today 展示摘要写红测。
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - 重构 Today 布局为 hero、任务卡、Watch 回传、Readiness 指导、故事进度。

## Task 1: Core 摘要红测

- [x] **Step 1: 写失败测试**

新增 `testTodayCommandCenterSummaryBuildsHeroAndQuestLabels`，断言 readiness、Watch 进度、任务上下文和奖励摘要。

- [x] **Step 2: 运行测试确认失败**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsHeroAndQuestLabels
```

Expected: FAIL，`TodayCommandCenterSummary` 未定义。

## Task 2: 实现 Core 摘要

- [x] **Step 1: 创建 `TodayCommandCenterSummary.swift`**

实现 `TodayCommandCenterSummary`，从 `ReadinessResult`、`DailyQuest` 和 execution log count 派生展示文案。

- [x] **Step 2: 运行测试确认通过**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTodayCommandCenterSummaryBuildsHeroAndQuestLabels
```

Expected: PASS。

## Task 3: 重构 Today SwiftUI

- [x] **Step 1: 在 `TodayCommandCenterView` 使用 summary**

新增 `todaySummary` 私有属性。

- [x] **Step 2: 新增 SwiftUI 子视图**

在同一文件内新增：

- `TodayHeroCard`
- `TodayQuestActionCard`
- `TodayWatchResultCard`
- `TodayReadinessGuidanceCard`
- `TodayStoryProgressCard`
- `TodaySectionCard`

- [x] **Step 3: 保持导航和 Watch payload 处理不变**

不修改 `NavigationStack` destination 和 `onChange(of: latestExecutionPayload)` 行为。

## Task 4: 验证

- [x] **Step 1: SwiftPM 测试**

```bash
cd native/FitnessRPGCore
swift test
```

- [x] **Step 2: iOS build**

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGTodayPolishIOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Watch build**

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGTodayPolishWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: 模拟器截图**

安装 iOS build，默认启动 App，抓取 Today 截图确认首屏布局。
