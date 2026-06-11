# Today 首屏信息密度微调 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 压缩 Today 首屏顶部信息占用，让任务标题和第一步动作在默认视口中更早出现。

**Architecture:** 只调整 `TodayCommandCenterView.swift` 的 SwiftUI 展示结构和样式，不改变 core、WatchConnectivity、HealthKit、持久化或执行逻辑。

**Tech Stack:** SwiftUI、Xcode iOS/watchOS Simulator build、SwiftPM tests、模拟器截图。

---

## 文件结构

- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - 将 navigation title 改为 inline。
  - 压缩 `TodayHeroCard`。
  - 将 `TodayInlineMetric` 改为横向 compact metric。
  - 小幅压缩 `TodayQuestActionCard` 和 `TodaySectionCard` 的间距。

## Task 1: 压缩 Hero

- [x] **Step 1: Navigation title 使用 inline**

在 Today 的 NavigationStack 链上加入：

```swift
.navigationBarTitleDisplayMode(.inline)
```

- [x] **Step 2: 合并 hero 状态说明**

在 `TodayHeroCard` 中新增：

```swift
private var statusLine: String {
    [watchStatusText, sourceNote]
        .compactMap { note in
            guard let note, !note.isEmpty else { return nil }
            return note
        }
        .joined(separator: " · ")
}
```

并用单个 `Text(statusLine)` 替代两段 footnote。

- [x] **Step 3: 降低 hero 标题和间距**

将 hero spacing 从 14 调整到 10，标题字体从 `.largeTitle` 调整为 `.title`。

## Task 2: 压缩指标和任务卡

- [x] **Step 1: 横向 compact metric**

将 `TodayInlineMetric` 从竖排图标/数字/标题改成横向 icon + 文案。

- [x] **Step 2: 任务卡标题降一级**

将任务标题字体从 `.title2` 调整为 `.title3`，保持 rounded bold。

- [x] **Step 3: 卡片间距小幅收紧**

将 `TodaySectionCard` 的 spacing 从 10 调整为 8，padding 从默认 `padding()` 调整为 `padding(14)`。

## Task 3: 验证

- [x] **Step 1: SwiftPM 测试**

```bash
cd native/FitnessRPGCore
swift test
```

- [x] **Step 2: iOS build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGDensityIOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Watch build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGDensityWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: 模拟器截图**

安装 iOS build，默认启动 app，截图到 `/private/tmp/fitnessrpg-density.png`。

- [x] **Step 5: 差异检查**

```bash
git diff --check
```
