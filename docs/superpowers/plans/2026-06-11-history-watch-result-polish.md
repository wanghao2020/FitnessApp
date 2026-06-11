# History Watch 结果展示优化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 优化 iOS History 页面，让 Watch 回传后的训练结果、完成进度和步骤日志清晰可读。

**Architecture:** 在 `FitnessRPGCore` 的 `TrainingHistoryDay` 中增加展示派生字段和 Watch log row 模型，SwiftUI 只消费这些字段进行布局。视觉方向采用 Native Pro 为主、RPG Chronicle 为辅：系统字体、SF Symbols、稳定留白，详情 hero 轻量展示故事节点和奖励摘要。保持 WatchConnectivity、持久化格式和结算引擎不变。

**Tech Stack:** Swift、SwiftUI、XCTest、Xcode iOS Simulator build。

---

## 文件结构

- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
  - 增加历史展示派生字段测试。
  - 让 `makeHistoryRecord` 支持指定 logs。
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`
  - 新增 `TrainingHistoryWatchLogRow`。
  - 新增 `watchProgressLabel`、`resultSummary`、`rewardSummary`、`storyContextLabel`、`completionSymbolName`、`watchLogRows`。
- Modify: `native/AppSources/iOS/History/HistoryView.swift`
  - 列表行展示结果摘要。
  - 详情页结构化展示 Watch 回传日志。
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
  - DEBUG 构建读取 `--fitnessrpg-open-history` 启动参数。
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
  - 支持用初始导航路径直接打开 History。

## Task 1: Core 展示字段红测

- [ ] **Step 1: 写失败测试**

在 `FitnessRPGCoreTests.swift` 的 history 测试区增加：

```swift
func testTrainingHistoryDaySummarizesWatchProgressAndRows() {
    let logs = [
        ExecutionLog(action: .complete, order: 1, rpe: 6, note: "动态热身 完成"),
        ExecutionLog(action: .rpeWithinTarget, order: 2, rpe: 5, note: "力量循环 RPE 在目标内"),
        ExecutionLog(action: .skip, order: 3, rpe: 2, note: "冷却记录 跳过")
    ]
    let record = makeHistoryRecord(
        date: "2026-06-10",
        readinessColor: .green,
        completionState: .completed,
        storyNode: .mainTrial,
        updatedAt: Date(timeIntervalSince1970: 1_717_172_000),
        logs: logs
    )

    let day = TrainingHistoryDay(record: record)

    XCTAssertEqual(day.watchProgressLabel, "3/3 步骤")
    XCTAssertEqual(day.resultSummary, "已完成 · 3/3 步骤")
    XCTAssertEqual(day.watchLogRows.map(\.stepTitle), ["动态热身", "力量循环", "冷却记录"])
    XCTAssertEqual(day.watchLogRows.map(\.actionLabel), ["完成", "RPE 达标", "跳过"])
    XCTAssertEqual(day.watchLogRows.map(\.rpeLabel), ["RPE 6", "RPE 5", "RPE 2"])
    XCTAssertEqual(day.watchLogRows[1].note, "力量循环 RPE 在目标内")
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTrainingHistoryDaySummarizesWatchProgressAndRows
```

Expected: FAIL，错误包含 `watchProgressLabel`、`resultSummary` 或 `watchLogRows` 未定义。

## Task 2: 实现 Core 展示派生模型

- [ ] **Step 1: 增加最小实现**

在 `TrainingHistory.swift` 中增加：

```swift
public struct TrainingHistoryWatchLogRow: Equatable, Identifiable, Sendable {
    public let id: String
    public let stepTitle: String
    public let actionLabel: String
    public let rpeLabel: String
    public let note: String
}
```

并为 `TrainingHistoryDay` 增加：

```swift
public var watchProgressLabel: String {
    let total = max(record.quest.watchSteps.count, record.executionLogs.count)
    return "\(record.executionLogs.count)/\(total) 步骤"
}

public var resultSummary: String {
    "\(completionLabel) · \(watchProgressLabel)"
}

public var watchLogRows: [TrainingHistoryWatchLogRow] {
    record.executionLogs
        .sorted { $0.order < $1.order }
        .map { log in
            let stepTitle = record.quest.watchSteps[safeOneBased: log.order]?.instruction ?? "步骤 \(log.order)"
            return TrainingHistoryWatchLogRow(
                id: "\(log.order)-\(log.action.rawValue)-\(log.rpe)-\(log.note)",
                stepTitle: stepTitle,
                actionLabel: TrainingHistoryBuilder.actionLabel(for: log.action),
                rpeLabel: "RPE \(log.rpe)",
                note: log.note
            )
        }
}
```

- [ ] **Step 2: 增加 action 映射和安全索引**

在同一文件中增加：

```swift
public static func actionLabel(for action: WatchAction) -> String {
    switch action {
    case .complete:
        return "完成"
    case .tooHeavy:
        return "过重"
    case .skip:
        return "跳过"
    case .rpeWithinTarget:
        return "RPE 达标"
    }
}

private extension Array {
    subscript(safeOneBased index: Int) -> Element? {
        let zeroBasedIndex = index - 1
        guard indices.contains(zeroBasedIndex) else {
            return nil
        }
        return self[zeroBasedIndex]
    }
}
```

- [ ] **Step 3: 运行测试确认通过**

Run:

```bash
cd native/FitnessRPGCore
swift test --filter FitnessRPGCoreTests/testTrainingHistoryDaySummarizesWatchProgressAndRows
```

Expected: PASS。

## Task 3: History UI 展示优化

- [ ] **Step 1: 修改列表行**

在 `HistoryDayRow` 中把状态行改为：

```swift
Text("\(day.resultSummary) · \(day.readinessSummary)")
    .font(.caption)
    .foregroundStyle(.secondary)
```

- [ ] **Step 2: 修改详情页 Watch 区块**

在 `HistoryDetailView` 的 `HistorySectionCard("Watch 回传")` 中显示：

```swift
Text(day.resultSummary)
    .font(.subheadline.weight(.semibold))
Text(day.executionSummary)
Text(day.recommendation)
    .font(.footnote)
    .foregroundStyle(.secondary)

if day.watchLogRows.isEmpty {
    Text("等待 Watch 回传步骤。")
        .font(.footnote)
        .foregroundStyle(.secondary)
} else {
    VStack(alignment: .leading, spacing: 10) {
        ForEach(day.watchLogRows) { row in
            HistoryWatchLogRowView(row: row)
        }
    }
    .padding(.top, 4)
}
```

- [ ] **Step 3: 新增 `HistoryWatchLogRowView`**

在 `HistoryView.swift` 中新增：

```swift
private struct HistoryWatchLogRowView: View {
    let row: TrainingHistoryWatchLogRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.stepTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(row.actionLabel)
                    .font(.caption.weight(.semibold))
                Text(row.rpeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(row.note)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
```

## Task 4: 验证

### Task 4A: DEBUG History 启动入口

- [ ] **Step 1: 写失败测试**

在 `FitnessRPGCoreTests.swift` 增加：

```swift
func testAppLaunchOptionsOpenHistoryFromArguments() {
    XCTAssertEqual(
        AppLaunchOptions.initialDestination(arguments: ["FitnessRPG"]),
        .today
    )
    XCTAssertEqual(
        AppLaunchOptions.initialDestination(arguments: ["FitnessRPG", "--fitnessrpg-open-history"]),
        .history
    )
}
```

- [ ] **Step 2: 实现 core 解析器**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`：

```swift
public enum AppLaunchDestination: Equatable, Sendable {
    case today
    case history
}

public enum AppLaunchOptions {
    public static func initialDestination(arguments: [String]) -> AppLaunchDestination {
        arguments.contains("--fitnessrpg-open-history") ? .history : .today
    }
}
```

- [ ] **Step 3: 接入 iOS DEBUG 启动路径**

在 `FitnessRPGApp.swift` 中将 `TodayCommandCenterView` 增加参数：

```swift
initialDestination: Self.debugInitialDestination
```

并新增：

```swift
private static var debugInitialDestination: AppLaunchDestination {
    #if DEBUG
    AppLaunchOptions.initialDestination(arguments: ProcessInfo.processInfo.arguments)
    #else
    .today
    #endif
}
```

- [ ] **Step 4: 在 Today 导航中使用初始路径**

`TodayCommandCenterView` 新增 `initialDestination: AppLaunchDestination = .today`，并用 `NavigationStack(path:)` 配合 `.navigationDestination` 打开 `HistoryView`。

- [ ] **Step 1: 运行完整 SwiftPM 测试**

```bash
cd native/FitnessRPGCore
swift test
```

Expected: 所有测试通过。

- [ ] **Step 2: 构建 iOS target**

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGHistoryPolishIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 3: 检查工作区**

```bash
git diff --check
git status --short --branch
```

Expected: `git diff --check` 无输出；status 只包含本轮和前序未提交改动。
