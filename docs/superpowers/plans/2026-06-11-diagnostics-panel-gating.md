# Today 开发诊断面板开关 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 默认隐藏 Today 中的 `ModelHarnessPanel`，仅在 DEBUG 且显式 launch argument 打开时展示。

**Architecture:** 在 `FitnessRPGCore` 的 `AppLaunchOptions` 中集中解析诊断开关；`FitnessRPGApp` 只在 DEBUG build 读取参数并传入 Today；`TodayCommandCenterView` 只根据布尔值决定是否渲染 `ModelHarnessPanel`。

**Tech Stack:** Swift、SwiftUI、XCTest、Xcode iOS Simulator build。

---

## 文件结构

- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`
  - 新增 `showsDiagnostics(arguments:)`。
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
  - 新增 launch argument 解析测试。
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
  - 只在 DEBUG build 中读取诊断参数。
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - 增加 `showsDiagnostics` 参数并条件渲染 `ModelHarnessPanel`。
- Modify: `native/README.md`
  - 记录 DEBUG launch arguments。

## Task 1: Core 红测

- [x] **Step 1: 写失败测试**

新增 `testAppLaunchOptionsShowDiagnosticsFromArguments`：

```swift
func testAppLaunchOptionsShowDiagnosticsFromArguments() {
    XCTAssertFalse(
        AppLaunchOptions.showsDiagnostics(arguments: ["FitnessRPG"])
    )
    XCTAssertTrue(
        AppLaunchOptions.showsDiagnostics(arguments: ["FitnessRPG", "--fitnessrpg-show-diagnostics"])
    )
}
```

- [x] **Step 2: 运行测试确认失败**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testAppLaunchOptionsShowDiagnosticsFromArguments
```

Expected: FAIL，`showsDiagnostics` 未定义。

## Task 2: 实现诊断开关

- [x] **Step 1: 实现 `showsDiagnostics(arguments:)`**

在 `AppLaunchOptions` 中添加：

```swift
public static func showsDiagnostics(arguments: [String]) -> Bool {
    arguments.contains("--fitnessrpg-show-diagnostics")
}
```

- [x] **Step 2: 运行测试确认通过**

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testAppLaunchOptionsShowDiagnosticsFromArguments
```

Expected: PASS。

## Task 3: 接入 iOS Today

- [x] **Step 1: App 注入参数**

`FitnessRPGApp` 增加 DEBUG-only `showsDiagnostics`，Release 固定为 `false`。

- [x] **Step 2: Today 条件渲染**

`TodayCommandCenterView` 增加 `showsDiagnostics: Bool = false`，并把：

```swift
ModelHarnessPanel(snapshot: harness)
```

改为：

```swift
if showsDiagnostics {
    ModelHarnessPanel(snapshot: harness)
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
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGDiagnosticsGateIOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: 默认启动截图**

安装并默认启动 app，截图到 `/private/tmp/fitnessrpg-diagnostics-hidden.png`。

- [x] **Step 4: DEBUG 参数启动检查**

用 `--fitnessrpg-show-diagnostics` 启动 app，确认诊断路径仍可进入。

- [x] **Step 5: 差异检查**

```bash
git diff --check
```
