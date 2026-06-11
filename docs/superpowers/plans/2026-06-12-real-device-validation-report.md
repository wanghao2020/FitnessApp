# 实机验证报告复制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 DEBUG Today 诊断区域增加可复制的实机验证纯文本报告。

**Architecture:** `FitnessRPGCore` 新增纯文本报告 builder，消费现有 diagnostics 展示模型；iOS Today 只生成报告字符串并写入剪贴板。普通用户路径和现有业务行为不变。

**Tech Stack:** Swift 6, SwiftUI, XCTest, Xcode iOS/watchOS schemes.

---

### Task 1: Core Validation Report Builder

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/RealDeviceValidationChecklist.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Write failing tests**

Add two tests after the existing checklist tests:

```swift
func testRealDeviceValidationReportIncludesCopyableSections() {
    let checklist = RealDeviceValidationChecklistBuilder.summary(
        watch: WatchConnectivityDiagnosticsSnapshot(
            isSupported: true,
            activationState: .activated,
            isPaired: true,
            isWatchAppInstalled: true,
            isReachable: false,
            lastOutbound: WatchConnectivityTransferRecord(
                date: Date(timeIntervalSince1970: 1),
                transport: .userInfo,
                detail: "灰烬坡道：降阶巡航"
            )
        ),
        health: .authorizationDenied,
        runtime: ModelRuntimeDiagnosticsSummary(
            headline: "本地模型不可用，使用确定性 fallback",
            detail: "Gemma 4 E2B LiteRT-LM：模型执行 adapter 未接入。",
            systemImageName: "exclamationmark.triangle.fill",
            tintName: "orange",
            rows: [
                ModelRuntimeDiagnosticsRow(title: "Provider", value: "Gemma 4 E2B LiteRT-LM", systemImageName: "shippingbox.fill"),
                ModelRuntimeDiagnosticsRow(title: "Adapter", value: "模型执行 adapter 未接入", systemImageName: "wrench.and.screwdriver.fill")
            ]
        ),
        historyRecordCount: 2,
        hasWeeklyPolishCache: false
    )
    let report = RealDeviceValidationReportBuilder.report(
        checklist: checklist,
        watch: WatchConnectivityDiagnosticsSnapshot(
            isSupported: true,
            activationState: .activated,
            isPaired: true,
            isWatchAppInstalled: true,
            isReachable: false,
            lastOutbound: WatchConnectivityTransferRecord(
                date: Date(timeIntervalSince1970: 1),
                transport: .userInfo,
                detail: "灰烬坡道：降阶巡航"
            )
        ),
        health: .authorizationDenied,
        runtime: ModelRuntimeDiagnosticsSummary(
            headline: "本地模型不可用，使用确定性 fallback",
            detail: "Gemma 4 E2B LiteRT-LM：模型执行 adapter 未接入。",
            systemImageName: "exclamationmark.triangle.fill",
            tintName: "orange",
            rows: [
                ModelRuntimeDiagnosticsRow(title: "Provider", value: "Gemma 4 E2B LiteRT-LM", systemImageName: "shippingbox.fill"),
                ModelRuntimeDiagnosticsRow(title: "Adapter", value: "模型执行 adapter 未接入", systemImageName: "wrench.and.screwdriver.fill")
            ]
        ),
        historyRecordCount: 2,
        hasWeeklyPolishCache: false,
        generatedAt: Date(timeIntervalSince1970: 0)
    )

    XCTAssertTrue(report.body.contains("Fitness RPG 实机验证报告"))
    XCTAssertTrue(report.body.contains("生成时间：1970-01-01T00:00:00Z"))
    XCTAssertTrue(report.body.contains("总览：实机验证还有阻塞项"))
    XCTAssertTrue(report.body.contains("- [待验证] Watch 同步"))
    XCTAssertTrue(report.body.contains("HealthKit：HealthKit 权限未完成"))
    XCTAssertTrue(report.body.contains("行动 · 下一步 · 权限"))
    XCTAssertTrue(report.body.contains("Runtime：本地模型不可用，使用确定性 fallback"))
    XCTAssertTrue(report.body.contains("Provider：Gemma 4 E2B LiteRT-LM"))
    XCTAssertTrue(report.body.contains("WatchConnectivity：Watch 已就绪，等待实时可达"))
    XCTAssertTrue(report.body.contains("最近发送：transferUserInfo · 灰烬坡道：降阶巡航"))
    XCTAssertTrue(report.body.contains("History：2 条记录；周回顾缓存：未生成"))
}

func testRealDeviceValidationReportMarksPassedRowsAndCacheReady() {
    let watch = WatchConnectivityDiagnosticsSnapshot(
        isSupported: true,
        activationState: .activated,
        isPaired: true,
        isWatchAppInstalled: true,
        isReachable: true,
        lastInbound: WatchConnectivityTransferRecord(
            date: Date(timeIntervalSince1970: 2),
            transport: .message,
            detail: "3/3 步骤"
        )
    )
    let runtime = ModelRuntimeDiagnosticsSummary(
        headline: "本地模型 Provider 就绪",
        detail: "Fixture provider 已就绪。",
        systemImageName: "cpu.fill",
        tintName: "green",
        rows: [
            ModelRuntimeDiagnosticsRow(title: "状态", value: "ready", systemImageName: "cpu.fill")
        ]
    )
    let checklist = RealDeviceValidationChecklistBuilder.summary(
        watch: watch,
        health: .healthKit,
        runtime: runtime,
        historyRecordCount: 3,
        hasWeeklyPolishCache: true
    )

    let report = RealDeviceValidationReportBuilder.report(
        checklist: checklist,
        watch: watch,
        health: .healthKit,
        runtime: runtime,
        historyRecordCount: 3,
        hasWeeklyPolishCache: true,
        generatedAt: Date(timeIntervalSince1970: 0)
    )

    XCTAssertTrue(report.body.contains("总览：实机验证清单已通过"))
    XCTAssertTrue(report.body.contains("- [通过] Watch 同步"))
    XCTAssertTrue(report.body.contains("HealthKit：HealthKit 已接入"))
    XCTAssertTrue(report.body.contains("WatchConnectivity：Watch 实时可达"))
    XCTAssertTrue(report.body.contains("History：3 条记录；周回顾缓存：已生成"))
}
```

- [x] **Step 2: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter RealDeviceValidationReport
```

Expected: build failure because `RealDeviceValidationReportBuilder` does not exist.

- [x] **Step 3: Implement report builder**

In `RealDeviceValidationChecklist.swift`, import Foundation and implement `RealDeviceValidationReport`, `RealDeviceValidationReportBuilder.report(...)`, and helper functions that produce these exact line formats for the first test fixture:

```text
Fitness RPG 实机验证报告
生成时间：1970-01-01T00:00:00Z

总览：实机验证还有阻塞项
进度：0/4 项已通过。先处理标记为需要操作的检查项。
- [待验证] Watch 同步：已发送 transferUserInfo · 灰烬坡道：降阶巡航，下一步在 Watch 完成步骤并回到 iPhone 查看 History。
- [需处理] HealthKit：下一步 · 权限：打开 iOS 设置 > 健康 > 数据访问与设备 > Fitness RPG，允许读取睡眠、心率和活动。
- [需处理] Runtime：Gemma 4 E2B LiteRT-LM：模型执行 adapter 未接入。
- [待验证] History 周回顾：已有 2 条 History 记录，下一步生成周回顾润色并验证清除/重新生成。

HealthKit：HealthKit 权限未完成
说明：可以在 iOS 设置中检查 Fitness RPG 的 HealthKit 读取权限；在完成前系统会继续使用保守黄灯策略。
行动 · 下一步 · 权限：打开 iOS 设置 > 健康 > 数据访问与设备 > Fitness RPG，允许读取睡眠、心率和活动。
行动 · 当前策略：授权完成前继续使用保守黄灯，不会推进高强度任务。

Runtime：本地模型不可用，使用确定性 fallback
说明：Gemma 4 E2B LiteRT-LM：模型执行 adapter 未接入。
Provider：Gemma 4 E2B LiteRT-LM
Adapter：模型执行 adapter 未接入

WatchConnectivity：Watch 已就绪，等待实时可达
说明：Watch App 已安装，可通过 transferUserInfo 排队发送。实时可达后会优先 sendMessage。
最近发送：transferUserInfo · 灰烬坡道：降阶巡航

History：2 条记录；周回顾缓存：未生成
```

Use `ISO8601DateFormatter` with `.withInternetDateTime` for `generatedAt`. Use these state labels: `.passed` -> `通过`, `.pending` -> `待验证`, `.needsAction` -> `需处理`.

- [x] **Step 4: Verify GREEN**

Run the focused test again:

```bash
swift test --package-path native/FitnessRPGCore --filter RealDeviceValidationReport
```

Expected: both report tests pass.

### Task 2: Today DEBUG Copy Action

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`

- [x] **Step 1: Add report text computed property**

Add `import UIKit`, then add:

```swift
private var realDeviceValidationReport: RealDeviceValidationReport {
    RealDeviceValidationReportBuilder.report(
        checklist: realDeviceValidationChecklist,
        watch: watchSyncModel.diagnosticsSnapshot,
        health: healthDataSourceSnapshot,
        runtime: modelRuntimeDiagnostics,
        historyRecordCount: persistenceModel.historyDays.count,
        hasWeeklyPolishCache: persistenceModel.weeklySummaryPolishEntry != nil
    )
}
```

- [x] **Step 2: Wire copy action into the panel**

Change:

```swift
RealDeviceValidationChecklistPanel(checklist: realDeviceValidationChecklist)
```

to:

```swift
RealDeviceValidationChecklistPanel(
    checklist: realDeviceValidationChecklist,
    report: realDeviceValidationReport
)
```

Update `RealDeviceValidationChecklistPanel` to own `@State private var didCopyReport = false` and add a compact bordered button:

```swift
Button {
    UIPasteboard.general.string = report.body
    didCopyReport = true
} label: {
    Label(didCopyReport ? "已复制" : "复制报告", systemImage: didCopyReport ? "checkmark.circle.fill" : "doc.on.doc.fill")
}
```

Use `.font(.caption.weight(.semibold))`, `.buttonStyle(.bordered)`, and `.controlSize(.small)`.

### Task 3: Documentation And Verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention that DEBUG diagnostics can copy a real-device validation report for issue/test logs.

- [x] **Step 2: Run verification**

```bash
swift test --package-path native/FitnessRPGCore
git diff --check
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' -derivedDataPath /private/tmp/FitnessRPGValidationReportWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 3: Simulator screenshot**

Build and launch the iOS simulator app with:

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGValidationReportSim CODE_SIGNING_ALLOWED=NO build
xcrun simctl install 9B424038-58BD-41D9-A446-399BCC2265C2 /private/tmp/FitnessRPGValidationReportSim/Build/Products/Debug-iphonesimulator/FitnessRPG.app
xcrun simctl launch 9B424038-58BD-41D9-A446-399BCC2265C2 com.hao.fitnessrpg --fitnessrpg-show-diagnostics
xcrun simctl io 9B424038-58BD-41D9-A446-399BCC2265C2 screenshot /private/tmp/fitnessrpg-validation-report.png
```

Expected: the real-device validation card shows a compact copy report button without text overlap.

- [x] **Step 4: Commit and push**

Commit message:

```bash
feat(native): add validation report copy action
```
