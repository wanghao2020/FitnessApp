# Today / History 导航入口统一 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Today 右上角 History 入口和 History 页面标题统一为中文显示，并集中导航显示常量。

**Architecture:** 在 `FitnessRPGCore` 新增 `AppNavigationDisplay` 作为跨页面导航显示文案来源；iOS SwiftUI 只消费这些常量，保持现有 `NavigationStack`、`NavigationLink(value:)` 和 DEBUG deep link 逻辑不变。

**Tech Stack:** Swift、SwiftUI、XCTest、Xcode iOS/watchOS Simulator build。

---

## 文件结构

- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppNavigationDisplay.swift`
  - 跨页面导航显示常量。
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
  - 新增导航显示测试。
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - Toolbar 历史入口使用中文文案和 accessibility label。
- Modify: `native/AppSources/iOS/History/HistoryView.swift`
  - 列表页标题使用“训练历史”。

## Task 1: Core 红测

- [x] **Step 1: 写失败测试**

新增测试：

```swift
func testAppNavigationDisplayUsesLocalizedHistoryLabels() {
    XCTAssertEqual(AppNavigationDisplay.todayTitle, "Fitness RPG")
    XCTAssertEqual(AppNavigationDisplay.historyTitle, "训练历史")
    XCTAssertEqual(AppNavigationDisplay.historyEntryLabel, "历史")
    XCTAssertEqual(AppNavigationDisplay.historyEntrySystemImage, "clock.arrow.circlepath")
}
```

- [x] **Step 2: 运行测试确认失败**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testAppNavigationDisplayUsesLocalizedHistoryLabels
```

Expected: FAIL，`AppNavigationDisplay` 未定义。

## Task 2: 实现导航显示常量

- [x] **Step 1: 创建 `AppNavigationDisplay.swift`**

```swift
public enum AppNavigationDisplay {
    public static let todayTitle = "Fitness RPG"
    public static let historyTitle = "训练历史"
    public static let historyEntryLabel = "历史"
    public static let historyEntrySystemImage = "clock.arrow.circlepath"
}
```

- [x] **Step 2: 运行测试确认通过**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testAppNavigationDisplayUsesLocalizedHistoryLabels
```

Expected: PASS。

## Task 3: 接入 iOS 导航

- [x] **Step 1: Today 使用统一文案**

`TodayCommandCenterView` 的 navigation title 使用 `AppNavigationDisplay.todayTitle`，toolbar link 使用 `AppNavigationDisplay.historyEntryLabel` 和 `AppNavigationDisplay.historyEntrySystemImage`。

- [x] **Step 2: History 使用统一标题**

`HistoryView` 列表页标题改为 `AppNavigationDisplay.historyTitle`，详情标题保持“训练详情”。

## Task 4: 验证

- [x] **Step 1: SwiftPM 测试**

```bash
cd native/FitnessRPGCore
swift test
```

- [x] **Step 2: iOS build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGNavigationEntryIOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Watch build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGNavigationEntryWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: 截图验证**

安装 iOS build，默认启动截图到 `/private/tmp/fitnessrpg-navigation-entry.png`。

- [x] **Step 5: DEBUG deep link smoke test**

用 `--fitnessrpg-open-history` 启动 app，确认可返回正常 pid。

- [x] **Step 6: 差异检查**

```bash
git diff --check
```
