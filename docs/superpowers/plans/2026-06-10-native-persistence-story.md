# Native Persistence Story Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 iPhone 权威的 JSON 本地持久化，让当天任务、Watch 回传 logs、训练结果、memory 草稿和 RPG 故事章节/节点进度能在 iOS 重启后恢复。

**Architecture:** Core 继续只放纯领域模型和确定性 engine；新增 `FitnessRPGPersistence` Swift Package target 负责 JSON 文件仓库，并只链接到 iOS app target。iOS 新增 Today 持久化状态模型，把 HealthKit readiness、当日 quest、Watch logs、`ExecutionEngine` 和 `StoryProgressionEngine` 串起来；watchOS 仍然不持久化。

**Tech Stack:** Swift 6, Swift Package Manager, XCTest, SwiftUI, FileManager, Codable, Xcode project file.

---

## 文件结构

- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/PersistenceModels.swift`：`TrainingDayRecord`、`StoryChapter`、`StoryNode`、`StoryProgression`、`StoryProgressionOutcome`、`MemoryEntry`。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/StoryProgressionEngine.swift`：确定性故事推进规则。
- 修改 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`：增加领域模型 JSON round-trip 和故事推进测试。
- 修改 `native/FitnessRPGCore/Package.swift`：增加 `FitnessRPGPersistence` library product、target、test target。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift`：JSON 文件仓库与 load result 类型。
- 新建 `native/FitnessRPGCore/Tests/FitnessRPGPersistenceTests/JSONFitnessRPGStoreTests.swift`：JSON 仓库测试。
- 新建 `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`：iOS Today 持久化状态模型。
- 修改 `native/AppSources/iOS/FitnessRPGApp.swift`：创建并注入 `TodayPersistenceModel`。
- 修改 `native/AppSources/iOS/TodayCommandCenterView.swift`：使用持久化 quest/result/story state，处理 Watch payload。
- 修改 `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift`：发布最新 `ExecutionLogSyncPayload` 供 iOS 持久化模型消费。
- 修改 `native/FitnessRPG.xcodeproj/project.pbxproj`：iOS target 链接 `FitnessRPGPersistence`，加入 `TodayPersistenceModel.swift`；watchOS target 不链接 persistence。
- 修改 `README.md` 和 `native/README.md`：记录 JSON persistence MVP 和验证命令。

---

### Task 1: 增加 Core 持久化领域模型

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/PersistenceModels.swift`

- [ ] **Step 1: 写失败测试**

把下面测试追加到 `FitnessRPGCoreTests` class 内部：

```swift
    func testTrainingDayRecordRoundTripsThroughJSON() throws {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: "破障试炼")
        let result = ExecutionEngine.resolve(
            quest: quest,
            logs: [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "热身完成")]
        )
        let progression = StoryProgression(
            currentChapterID: StoryChapter.mainLine.id,
            currentNodeID: StoryNode.mainTrial.id,
            completedNodeIDs: [StoryNode.mainTrial.id],
            lastOutcome: .advanced,
            lastReason: "绿色任务完成，主线推进。",
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        let record = TrainingDayRecord(
            date: "2026-06-10",
            readiness: readiness,
            quest: quest,
            executionLogs: [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "热身完成")],
            workoutResult: result,
            storyProgression: progression,
            createdAt: Date(timeIntervalSince1970: 1_717_171_900),
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let data = try SyncEnvelope.makeEncoder().encode(record)
        let decoded = try SyncEnvelope.makeDecoder().decode(TrainingDayRecord.self, from: data)

        XCTAssertEqual(decoded, record)
        XCTAssertEqual(decoded.id, "2026-06-10")
    }

    func testStoryModelsAndMemoryEntryRoundTripThroughJSON() throws {
        let memory = MemoryEntry(
            date: "2026-06-10",
            questTitle: "回声训练厅：力量共振",
            completionState: .completed,
            storyNodeID: StoryNode.mainTrial.id,
            draft: "任务完成，力量属性成长。",
            createdAt: Date(timeIntervalSince1970: 1_717_172_100)
        )
        let progression = StoryProgression.initial(
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let chapterData = try SyncEnvelope.makeEncoder().encode(StoryChapter.mainLine)
        let nodeData = try SyncEnvelope.makeEncoder().encode(StoryNode.mainTrial)
        let progressionData = try SyncEnvelope.makeEncoder().encode(progression)
        let memoryData = try SyncEnvelope.makeEncoder().encode(memory)

        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryChapter.self, from: chapterData), .mainLine)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryNode.self, from: nodeData), .mainTrial)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryProgression.self, from: progressionData), progression)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(MemoryEntry.self, from: memoryData), memory)
    }
```

- [ ] **Step 2: 运行测试确认失败**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：编译失败，错误包含 `TrainingDayRecord`、`StoryProgression`、`StoryChapter`、`StoryNode` 或 `MemoryEntry` 尚未定义。

- [ ] **Step 3: 创建领域模型实现**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/PersistenceModels.swift`：

```swift
import Foundation

public struct TrainingDayRecord: Codable, Equatable, Sendable {
    public let id: String
    public let date: String
    public var readiness: ReadinessResult
    public var quest: DailyQuest
    public var executionLogs: [ExecutionLog]
    public var workoutResult: WorkoutResult?
    public var storyProgression: StoryProgression?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String? = nil,
        date: String,
        readiness: ReadinessResult,
        quest: DailyQuest,
        executionLogs: [ExecutionLog] = [],
        workoutResult: WorkoutResult? = nil,
        storyProgression: StoryProgression? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id ?? date
        self.date = date
        self.readiness = readiness
        self.quest = quest
        self.executionLogs = executionLogs
        self.workoutResult = workoutResult
        self.storyProgression = storyProgression
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct StoryChapter: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let kind: Kind

    public enum Kind: String, Codable, Equatable, Sendable {
        case main
        case calibration
        case recovery
    }

    public init(id: String, title: String, kind: Kind) {
        self.id = id
        self.title = title
        self.kind = kind
    }

    public static let mainLine = StoryChapter(
        id: "chapter-1-echo-gate",
        title: "第一章 · 回声城门",
        kind: .main
    )

    public static let calibration = StoryChapter(
        id: "chapter-1-deep-hall",
        title: "第一章 · 深厅回廊",
        kind: .calibration
    )

    public static let recovery = StoryChapter(
        id: "chapter-1-north-camp",
        title: "第一章 · 北境营地",
        kind: .recovery
    )
}

public struct StoryNode: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let chapterID: String
    public let title: String
    public let summary: String

    public init(id: String, chapterID: String, title: String, summary: String) {
        self.id = id
        self.chapterID = chapterID
        self.title = title
        self.summary = summary
    }

    public static let mainTrial = StoryNode(
        id: "node-breakthrough-trial",
        chapterID: StoryChapter.mainLine.id,
        title: "破障试炼",
        summary: "共振稳定时推进主线。"
    )

    public static let calibrationRune = StoryNode(
        id: "node-calibration-rune",
        chapterID: StoryChapter.calibration.id,
        title: "校准符文",
        summary: "共振偏移时用技术质量推进。"
    )

    public static let recoveryCharm = StoryNode(
        id: "node-recovery-charm",
        chapterID: StoryChapter.recovery.id,
        title: "修复护符",
        summary: "恢复任务保护下一章训练。"
    )

    public static let safetyDowngrade = StoryNode(
        id: "node-safety-downgrade",
        chapterID: StoryChapter.recovery.id,
        title: "安全降阶",
        summary: "过重或高 RPE 反馈触发保护性进度。"
    )
}

public enum StoryProgressionOutcome: String, Codable, Equatable, Sendable {
    case advanced
    case calibrated
    case recovered
    case downgraded
}

public struct StoryProgression: Codable, Equatable, Sendable {
    public var currentChapterID: String
    public var currentNodeID: String
    public var completedNodeIDs: [String]
    public var lastOutcome: StoryProgressionOutcome
    public var lastReason: String
    public var updatedAt: Date

    public init(
        currentChapterID: String,
        currentNodeID: String,
        completedNodeIDs: [String] = [],
        lastOutcome: StoryProgressionOutcome,
        lastReason: String,
        updatedAt: Date = Date()
    ) {
        self.currentChapterID = currentChapterID
        self.currentNodeID = currentNodeID
        self.completedNodeIDs = completedNodeIDs
        self.lastOutcome = lastOutcome
        self.lastReason = lastReason
        self.updatedAt = updatedAt
    }

    public static func initial(updatedAt: Date = Date()) -> StoryProgression {
        StoryProgression(
            currentChapterID: StoryChapter.mainLine.id,
            currentNodeID: StoryNode.mainTrial.id,
            completedNodeIDs: [],
            lastOutcome: .advanced,
            lastReason: "故事从回声城门开启。",
            updatedAt: updatedAt
        )
    }
}

public struct MemoryEntry: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let date: String
    public let questTitle: String
    public let completionState: CompletionState
    public let storyNodeID: String
    public let draft: String
    public let createdAt: Date

    public init(
        id: String? = nil,
        date: String,
        questTitle: String,
        completionState: CompletionState,
        storyNodeID: String,
        draft: String,
        createdAt: Date = Date()
    ) {
        self.id = id ?? "\(date)-\(questTitle)-\(createdAt.timeIntervalSince1970)"
        self.date = date
        self.questTitle = questTitle
        self.completionState = completionState
        self.storyNodeID = storyNodeID
        self.draft = draft
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 4: 运行 Core 测试确认通过**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：所有 `FitnessRPGCoreTests` 通过，新增 round-trip 测试通过。

- [ ] **Step 5: 提交 Core 持久化模型**

运行：

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/PersistenceModels.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "feat: add persistence domain models"
```

---

### Task 2: 增加故事推进 engine

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/StoryProgressionEngine.swift`

- [ ] **Step 1: 写失败测试**

把下面测试追加到 `FitnessRPGCoreTests` class 内部：

```swift
    func testStoryProgressionAdvancesMainLineForGreenCompletion() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let result = WorkoutResult(
            completionState: .completed,
            safetyFeedback: "训练完成且未记录过重信号。",
            nextRecommendation: "保持当前节奏。",
            memoryDraft: "主线推进。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.mainLine.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.mainTrial.id)
        XCTAssertEqual(progression.lastOutcome, .advanced)
        XCTAssertTrue(progression.completedNodeIDs.contains(StoryNode.mainTrial.id))
        XCTAssertTrue(progression.lastReason.contains("主线"))
    }

    func testStoryProgressionRecordsCalibrationForYellowCompletion() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let result = WorkoutResult(
            completionState: .completed,
            safetyFeedback: "技术训练完成。",
            nextRecommendation: "继续观察恢复。",
            memoryDraft: "校准推进。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.calibration.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.calibrationRune.id)
        XCTAssertEqual(progression.lastOutcome, .calibrated)
        XCTAssertTrue(progression.lastReason.contains("校准"))
    }

    func testStoryProgressionRecordsSafetyDowngrade() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let result = WorkoutResult(
            completionState: .downgraded,
            safetyFeedback: "检测到过重信号。",
            nextRecommendation: "下一次降阶。",
            memoryDraft: "安全降阶。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.recovery.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.safetyDowngrade.id)
        XCTAssertEqual(progression.lastOutcome, .downgraded)
        XCTAssertFalse(progression.completedNodeIDs.contains(StoryNode.mainTrial.id))
    }

    func testStoryProgressionRecordsRecoveryForRedOrSkippedResult() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
        let result = WorkoutResult(
            completionState: .skipped,
            safetyFeedback: "恢复优先。",
            nextRecommendation: "下一次重新评估。",
            memoryDraft: "恢复进度。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.recovery.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.recoveryCharm.id)
        XCTAssertEqual(progression.lastOutcome, .recovered)
        XCTAssertTrue(progression.lastReason.contains("恢复"))
    }
```

- [ ] **Step 2: 运行测试确认失败**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：编译失败，错误包含 `StoryProgressionEngine` 尚未定义。

- [ ] **Step 3: 创建故事推进实现**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/StoryProgressionEngine.swift`：

```swift
import Foundation

public enum StoryProgressionEngine {
    public static func progression(
        after previous: StoryProgression,
        readinessColor: ReadinessColor,
        quest: DailyQuest,
        result: WorkoutResult,
        updatedAt: Date = Date()
    ) -> StoryProgression {
        let resolution = resolution(for: readinessColor, result: result)
        var completedNodeIDs = previous.completedNodeIDs

        if resolution.shouldMarkComplete && !completedNodeIDs.contains(resolution.node.id) {
            completedNodeIDs.append(resolution.node.id)
        }

        return StoryProgression(
            currentChapterID: resolution.node.chapterID,
            currentNodeID: resolution.node.id,
            completedNodeIDs: completedNodeIDs,
            lastOutcome: resolution.outcome,
            lastReason: reason(for: resolution, quest: quest),
            updatedAt: updatedAt
        )
    }

    public static func displayNode(for readinessColor: ReadinessColor) -> StoryNode {
        switch readinessColor {
        case .green:
            return .mainTrial
        case .yellow:
            return .calibrationRune
        case .red:
            return .recoveryCharm
        }
    }

    private struct Resolution {
        let node: StoryNode
        let outcome: StoryProgressionOutcome
        let shouldMarkComplete: Bool
    }

    private static func resolution(for readinessColor: ReadinessColor, result: WorkoutResult) -> Resolution {
        switch result.completionState {
        case .downgraded:
            return Resolution(node: .safetyDowngrade, outcome: .downgraded, shouldMarkComplete: true)
        case .skipped:
            return Resolution(node: .recoveryCharm, outcome: .recovered, shouldMarkComplete: true)
        case .completed:
            switch readinessColor {
            case .green:
                return Resolution(node: .mainTrial, outcome: .advanced, shouldMarkComplete: true)
            case .yellow:
                return Resolution(node: .calibrationRune, outcome: .calibrated, shouldMarkComplete: true)
            case .red:
                return Resolution(node: .recoveryCharm, outcome: .recovered, shouldMarkComplete: true)
            }
        }
    }

    private static func reason(for resolution: Resolution, quest: DailyQuest) -> String {
        switch resolution.outcome {
        case .advanced:
            return "任务「\(quest.title)」完成，主线节点推进。"
        case .calibrated:
            return "任务「\(quest.title)」完成，记录技术校准进度。"
        case .recovered:
            return "任务「\(quest.title)」保护恢复节奏，记录恢复进度。"
        case .downgraded:
            return "任务「\(quest.title)」出现过重或高 RPE 信号，记录安全降阶。"
        }
    }
}
```

- [ ] **Step 4: 运行 Core 测试确认通过**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：所有 Core 测试通过，新增 4 个故事推进测试通过。

- [ ] **Step 5: 提交故事推进 engine**

运行：

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/StoryProgressionEngine.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "feat: add story progression engine"
```

---

### Task 3: 增加可测试 JSON persistence package

**Files:**
- Modify: `native/FitnessRPGCore/Package.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift`
- Create: `native/FitnessRPGCore/Tests/FitnessRPGPersistenceTests/JSONFitnessRPGStoreTests.swift`

- [ ] **Step 1: 更新 Package 并写失败测试**

替换 `native/FitnessRPGCore/Package.swift` 内容：

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FitnessRPGCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FitnessRPGCore",
            targets: ["FitnessRPGCore"]
        ),
        .library(
            name: "FitnessRPGPersistence",
            targets: ["FitnessRPGPersistence"]
        )
    ],
    targets: [
        .target(
            name: "FitnessRPGCore"
        ),
        .target(
            name: "FitnessRPGPersistence",
            dependencies: ["FitnessRPGCore"]
        ),
        .testTarget(
            name: "FitnessRPGCoreTests",
            dependencies: ["FitnessRPGCore"]
        ),
        .testTarget(
            name: "FitnessRPGPersistenceTests",
            dependencies: ["FitnessRPGCore", "FitnessRPGPersistence"]
        )
    ]
)
```

创建临时模块文件 `native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift`：

```swift
import Foundation
@_exported import FitnessRPGCore
```

创建 `native/FitnessRPGCore/Tests/FitnessRPGPersistenceTests/JSONFitnessRPGStoreTests.swift`：

```swift
import XCTest
import FitnessRPGCore
@testable import FitnessRPGPersistence

final class JSONFitnessRPGStoreTests: XCTestCase {
    private func temporaryStore() throws -> JSONFitnessRPGStore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return JSONFitnessRPGStore(directoryURL: root)
    }

    private func sampleRecord(date: String = "2026-06-10") -> TrainingDayRecord {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        return TrainingDayRecord(
            date: date,
            readiness: readiness,
            quest: quest,
            createdAt: Date(timeIntervalSince1970: 1_717_171_900),
            updatedAt: Date(timeIntervalSince1970: 1_717_171_900)
        )
    }

    func testEmptyStoreLoadsDefaultCollections() throws {
        let store = try temporaryStore()

        XCTAssertEqual(store.loadTrainingDays().value, [])
        XCTAssertEqual(store.loadMemoryEntries().value, [])
        XCTAssertEqual(store.loadStoryProgression().value.currentNodeID, StoryNode.mainTrial.id)
        XCTAssertNil(store.loadTrainingDays().warning)
    }

    func testSavingTrainingDayCanBeLoadedAgain() throws {
        let store = try temporaryStore()
        let record = sampleRecord()

        try store.saveTrainingDays([record])
        let loaded = store.loadTrainingDays()

        XCTAssertEqual(loaded.value, [record])
        XCTAssertNil(loaded.warning)
    }

    func testUpdatingResultForDayPreservesQuest() throws {
        let store = try temporaryStore()
        var record = sampleRecord()
        let originalQuest = record.quest
        let logs = [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "完成")]
        let result = ExecutionEngine.resolve(quest: originalQuest, logs: logs)
        record.executionLogs = logs
        record.workoutResult = result
        record.updatedAt = Date(timeIntervalSince1970: 1_717_172_000)

        try store.saveTrainingDays([record])
        let loaded = store.loadTrainingDays().value[0]

        XCTAssertEqual(loaded.quest, originalQuest)
        XCTAssertEqual(loaded.executionLogs, logs)
        XCTAssertEqual(loaded.workoutResult, result)
    }

    func testAppendingMemoryEntriesPreservesOrder() throws {
        let store = try temporaryStore()
        let first = MemoryEntry(
            date: "2026-06-10",
            questTitle: "破障试炼",
            completionState: .completed,
            storyNodeID: StoryNode.mainTrial.id,
            draft: "第一条",
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let second = MemoryEntry(
            date: "2026-06-10",
            questTitle: "校准符文",
            completionState: .downgraded,
            storyNodeID: StoryNode.safetyDowngrade.id,
            draft: "第二条",
            createdAt: Date(timeIntervalSince1970: 2)
        )

        try store.appendMemoryEntry(first)
        try store.appendMemoryEntry(second)

        XCTAssertEqual(store.loadMemoryEntries().value, [first, second])
    }

    func testCorruptJSONFallsBackWithWarning() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: root.appendingPathComponent("training-days.json"))

        let store = JSONFitnessRPGStore(directoryURL: root)
        let result = store.loadTrainingDays()

        XCTAssertEqual(result.value, [])
        XCTAssertNotNil(result.warning)
        XCTAssertTrue(result.warning?.contains("training-days.json") == true)
    }
}
```

- [ ] **Step 2: 运行 persistence 测试确认失败**

运行：

```bash
cd native/FitnessRPGCore
swift test --filter JSONFitnessRPGStoreTests
```

预期：编译失败，错误包含 `JSONFitnessRPGStore` 尚未定义或缺少 `loadTrainingDays` 等方法。

- [ ] **Step 3: 实现 JSON store**

替换 `native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift`：

```swift
import Foundation
@_exported import FitnessRPGCore

public struct PersistenceLoadResult<Value: Equatable & Sendable>: Equatable, Sendable {
    public let value: Value
    public let warning: String?

    public init(value: Value, warning: String? = nil) {
        self.value = value
        self.warning = warning
    }
}

public final class JSONFitnessRPGStore: @unchecked Sendable {
    public static let currentSchemaVersion = 1

    private let directoryURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.decoder = decoder
    }

    public func loadTrainingDays() -> PersistenceLoadResult<[TrainingDayRecord]> {
        readCollection(filename: "training-days.json", defaultValue: [])
    }

    public func saveTrainingDays(_ records: [TrainingDayRecord]) throws {
        try write(records, filename: "training-days.json")
    }

    public func loadStoryProgression() -> PersistenceLoadResult<StoryProgression> {
        readValue(
            filename: "story-progress.json",
            defaultValue: StoryProgression.initial(updatedAt: Date(timeIntervalSince1970: 0))
        )
    }

    public func saveStoryProgression(_ progression: StoryProgression) throws {
        try write(progression, filename: "story-progress.json")
    }

    public func loadMemoryEntries() -> PersistenceLoadResult<[MemoryEntry]> {
        readCollection(filename: "memory-entries.json", defaultValue: [])
    }

    public func saveMemoryEntries(_ entries: [MemoryEntry]) throws {
        try write(entries, filename: "memory-entries.json")
    }

    public func appendMemoryEntry(_ entry: MemoryEntry) throws {
        var entries = loadMemoryEntries().value
        entries.append(entry)
        try saveMemoryEntries(entries)
    }

    private func readCollection<Element: Codable & Equatable & Sendable>(
        filename: String,
        defaultValue: [Element]
    ) -> PersistenceLoadResult<[Element]> {
        readValue(filename: filename, defaultValue: defaultValue)
    }

    private func readValue<Value: Codable & Equatable & Sendable>(
        filename: String,
        defaultValue: Value
    ) -> PersistenceLoadResult<Value> {
        let url = directoryURL.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: url.path) else {
            return PersistenceLoadResult(value: defaultValue)
        }

        do {
            let data = try Data(contentsOf: url)
            let document = try decoder.decode(JSONDocument<Value>.self, from: data)
            guard document.schemaVersion == JSONFitnessRPGStore.currentSchemaVersion else {
                return PersistenceLoadResult(
                    value: defaultValue,
                    warning: "\(filename) 使用不支持的 schema version：\(document.schemaVersion)"
                )
            }
            return PersistenceLoadResult(value: document.value)
        } catch {
            return PersistenceLoadResult(
                value: defaultValue,
                warning: "\(filename) 读取失败：\(error.localizedDescription)"
            )
        }
    }

    private func write<Value: Codable & Sendable>(_ value: Value, filename: String) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let document = JSONDocument(schemaVersion: JSONFitnessRPGStore.currentSchemaVersion, value: value)
        let data = try encoder.encode(document)
        try data.write(to: directoryURL.appendingPathComponent(filename), options: [.atomic])
    }
}

private struct JSONDocument<Value: Codable & Sendable>: Codable, Sendable {
    let schemaVersion: Int
    let value: Value
}
```

- [ ] **Step 4: 运行 package 测试确认通过**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：`FitnessRPGCoreTests` 和 `FitnessRPGPersistenceTests` 全部通过。

- [ ] **Step 5: 提交 JSON persistence package**

运行：

```bash
git add native/FitnessRPGCore/Package.swift native/FitnessRPGCore/Sources/FitnessRPGPersistence/JSONFitnessRPGStore.swift native/FitnessRPGCore/Tests/FitnessRPGPersistenceTests/JSONFitnessRPGStoreTests.swift
git commit -m "feat: add json persistence store"
```

---

### Task 4: 增加 iOS Today 持久化状态模型

**Files:**
- Create: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`

- [ ] **Step 1: 创建 iOS 持久化状态模型**

创建目录 `native/AppSources/iOS/Persistence/`，再创建 `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`：

```swift
import Combine
import Foundation
import FitnessRPGCore
import FitnessRPGPersistence

@MainActor
final class TodayPersistenceModel: ObservableObject {
    @Published private(set) var todayRecord: TrainingDayRecord?
    @Published private(set) var storyProgression: StoryProgression
    @Published private(set) var storageStatusText = "本地记录尚未加载。"

    private let store: JSONFitnessRPGStore
    private let calendar: Calendar

    init(
        store: JSONFitnessRPGStore = TodayPersistenceModel.defaultStore(),
        calendar: Calendar = .current
    ) {
        self.store = store
        self.calendar = calendar
        self.storyProgression = store.loadStoryProgression().value

        let storyWarning = store.loadStoryProgression().warning
        if let storyWarning {
            storageStatusText = "本地故事记录读取失败：\(storyWarning)"
        }
    }

    var todayQuest: DailyQuest? {
        todayRecord?.quest
    }

    var latestResult: WorkoutResult? {
        todayRecord?.workoutResult
    }

    var currentStoryNodeTitle: String {
        switch storyProgression.currentNodeID {
        case StoryNode.mainTrial.id:
            return StoryNode.mainTrial.title
        case StoryNode.calibrationRune.id:
            return StoryNode.calibrationRune.title
        case StoryNode.recoveryCharm.id:
            return StoryNode.recoveryCharm.title
        case StoryNode.safetyDowngrade.id:
            return StoryNode.safetyDowngrade.title
        default:
            return "未知节点"
        }
    }

    func loadOrCreateToday(readiness: ReadinessResult, date: Date = Date()) {
        let key = Self.dayKey(for: date, calendar: calendar)
        let loadedRecords = store.loadTrainingDays()
        var records = loadedRecords.value

        if let existing = records.first(where: { $0.date == key }) {
            todayRecord = existing
            storageStatusText = loadedRecords.warning ?? "已恢复今日任务。"
            return
        }

        let node = StoryProgressionEngine.displayNode(for: readiness.color)
        let quest = QuestEngine.quest(for: readiness, storyNode: node.title)
        let record = TrainingDayRecord(
            date: key,
            readiness: readiness,
            quest: quest,
            storyProgression: storyProgression,
            createdAt: date,
            updatedAt: date
        )

        records.append(record)
        do {
            try store.saveTrainingDays(records)
            todayRecord = record
            storageStatusText = loadedRecords.warning ?? "已保存今日任务。"
        } catch {
            todayRecord = record
            storageStatusText = "今日任务保存失败：\(error.localizedDescription)"
        }
    }

    func applyExecutionPayload(_ payload: ExecutionLogSyncPayload, receivedAt: Date = Date()) {
        guard var record = todayRecord ?? loadRecord(for: receivedAt) else {
            storageStatusText = "已收到 Watch 记录，但本地没有今日任务。"
            return
        }

        guard payload.questTitle == record.quest.title else {
            storageStatusText = "已收到 Watch 记录，但与今日任务不匹配。"
            return
        }

        let result = ExecutionEngine.resolve(quest: record.quest, logs: payload.logs)
        let nextProgression = StoryProgressionEngine.progression(
            after: storyProgression,
            readinessColor: record.readiness.color,
            quest: record.quest,
            result: result,
            updatedAt: receivedAt
        )
        let memory = MemoryEntry(
            date: record.date,
            questTitle: record.quest.title,
            completionState: result.completionState,
            storyNodeID: nextProgression.currentNodeID,
            draft: result.memoryDraft,
            createdAt: receivedAt
        )

        record.executionLogs = payload.logs
        record.workoutResult = result
        record.storyProgression = nextProgression
        record.updatedAt = receivedAt

        persist(record: record, progression: nextProgression, memory: memory)
    }

    private func loadRecord(for date: Date) -> TrainingDayRecord? {
        let key = Self.dayKey(for: date, calendar: calendar)
        return store.loadTrainingDays().value.first { $0.date == key }
    }

    private func persist(record: TrainingDayRecord, progression: StoryProgression, memory: MemoryEntry) {
        var records = store.loadTrainingDays().value
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }

        do {
            try store.saveTrainingDays(records)
            try store.saveStoryProgression(progression)
            try store.appendMemoryEntry(memory)
            todayRecord = record
            storyProgression = progression
            storageStatusText = "已保存 Watch 训练结果和故事进度。"
        } catch {
            todayRecord = record
            storyProgression = progression
            storageStatusText = "训练结果保存失败：\(error.localizedDescription)"
        }
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func defaultStore() -> JSONFitnessRPGStore {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseURL.appendingPathComponent("FitnessRPG", isDirectory: true)
        return JSONFitnessRPGStore(directoryURL: directory)
    }
}
```

- [ ] **Step 2: 暂不构建，等 Task 6 把文件加入 Xcode project**

不运行 `xcodebuild`。该文件还没有加入 iOS target。

- [ ] **Step 3: 提交 iOS 持久化状态模型**

运行：

```bash
git add native/AppSources/iOS/Persistence/TodayPersistenceModel.swift
git commit -m "feat: add today persistence model"
```

---

### Task 5: 接入 iOS UI 和 Watch payload 流

**Files:**
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift`

- [ ] **Step 1: 修改 Watch sync model 发布 payload**

在 `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift` 中新增 published 属性：

```swift
    @Published private(set) var latestExecutionPayload: ExecutionLogSyncPayload?
```

然后在 `receiveEnvelopeData(_:)` 中，解码 payload 后、`guard let currentQuest` 之前加入：

```swift
            latestExecutionPayload = payload
```

修改后的 `receiveEnvelopeData(_:)` 应为：

```swift
    private func receiveEnvelopeData(_ data: Data?) {
        do {
            guard let data else {
                throw SyncPayloadError.missingEnvelopeData
            }

            let envelope = try SyncEnvelope.makeDecoder().decode(SyncEnvelope.self, from: data)
            let payload = try envelope.decodePayload(
                ExecutionLogSyncPayload.self,
                expectedKind: .executionLogs
            )
            latestExecutionPayload = payload

            guard let currentQuest else {
                statusText = "已收到 Watch 记录，正在尝试本地持久化匹配。"
                return
            }

            guard payload.questTitle == currentQuest.title else {
                statusText = "收到 Watch 记录，但任务不匹配。"
                return
            }

            latestResult = ExecutionEngine.resolve(quest: currentQuest, logs: payload.logs)
            statusText = "已收到 Watch 执行记录：\(payload.logs.count) 条。"
        } catch {
            statusText = "Watch 记录解码失败。"
        }
    }
```

- [ ] **Step 2: 修改 FitnessRPGApp 注入 persistence model**

替换 `native/AppSources/iOS/FitnessRPGApp.swift`：

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    @StateObject private var healthViewModel = TodayHealthViewModel()
    @StateObject private var watchSyncModel = WatchQuestSyncModel()
    @StateObject private var persistenceModel = TodayPersistenceModel()

    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: healthViewModel.readiness,
                modelMode: .localFirst,
                sourceNote: healthViewModel.sourceNote,
                watchSyncModel: watchSyncModel,
                persistenceModel: persistenceModel
            )
            .task {
                await healthViewModel.loadHealthSummary()
                persistenceModel.loadOrCreateToday(readiness: healthViewModel.readiness)
            }
        }
    }
}
```

- [ ] **Step 3: 修改 Today UI 使用持久化 quest/result/story**

在 `native/AppSources/iOS/TodayCommandCenterView.swift` 中加入 `persistenceModel` 属性：

```swift
    @ObservedObject var persistenceModel: TodayPersistenceModel
```

把 `quest` computed property 替换为：

```swift
    private var fallbackQuest: DailyQuest {
        let storyNode = StoryProgressionEngine.displayNode(for: readiness.color).title
        return QuestEngine.quest(for: readiness, storyNode: storyNode)
    }

    private var quest: DailyQuest {
        persistenceModel.todayQuest ?? fallbackQuest
    }
```

把 Watch 回传结果展示条件替换为：

```swift
                    if let result = persistenceModel.latestResult ?? watchSyncModel.latestResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Watch 回传")
                                .font(.headline)
                            Text(result.safetyFeedback)
                            Text(result.nextRecommendation)
                                .foregroundStyle(.secondary)
                            Text(result.memoryDraft)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
```

在 `ModelHarnessPanel(snapshot: harness)` 之前加入紧凑故事状态：

```swift
                    VStack(alignment: .leading, spacing: 6) {
                        Text("故事进度")
                            .font(.headline)
                        Text(persistenceModel.currentStoryNodeTitle)
                        Text(persistenceModel.storyProgression.lastReason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text(persistenceModel.storageStatusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
```

把 `.onAppear` 和三个 `.onChange` 替换为：

```swift
            .task(id: readiness.score) {
                persistenceModel.loadOrCreateToday(readiness: readiness)
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
            .onChange(of: watchSyncModel.latestExecutionPayload) { _, payload in
                guard let payload else { return }
                persistenceModel.applyExecutionPayload(payload)
            }
```

更新 Preview：

```swift
#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst,
        sourceNote: "已读取 HealthKit 今日健康摘要。",
        watchSyncModel: WatchQuestSyncModel(session: nil),
        persistenceModel: TodayPersistenceModel()
    )
}
```

- [ ] **Step 4: 暂不构建，等 Task 6 更新 Xcode project**

不运行 `xcodebuild`。`TodayPersistenceModel.swift` 和 `FitnessRPGPersistence` 还没有接入 project。

- [ ] **Step 5: 提交 iOS 数据流接入**

运行：

```bash
git add native/AppSources/iOS/FitnessRPGApp.swift native/AppSources/iOS/TodayCommandCenterView.swift native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift
git commit -m "feat: restore persisted today state"
```

---

### Task 6: 更新 Xcode project 并验证 native 构建

**Files:**
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: 修改 PBXBuildFile section**

在 `/* Begin PBXBuildFile section */` 中追加：

```text
		01A000000000000000000011 /* FitnessRPGPersistence in Frameworks */ = {isa = PBXBuildFile; productRef = 01C000000000000000000003 /* FitnessRPGPersistence */; };
		01A000000000000000000012 /* TodayPersistenceModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 01B000000000000000000011 /* TodayPersistenceModel.swift */; };
```

- [ ] **Step 2: 修改 PBXFileReference section**

在 `/* Begin PBXFileReference section */` 中追加：

```text
		01B000000000000000000011 /* TodayPersistenceModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TodayPersistenceModel.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: 修改 iOS Frameworks build phase**

把 iOS framework phase 的 `files` 改成：

```text
			files = (
				01A000000000000000000008 /* FitnessRPGCore in Frameworks */,
				01A000000000000000000011 /* FitnessRPGPersistence in Frameworks */,
				01A00000000000000000000C /* HealthKit.framework in Frameworks */,
				01A00000000000000000000F /* WatchConnectivity.framework in Frameworks */,
			);
```

不要修改 watchOS framework phase；watchOS 不链接 `FitnessRPGPersistence`。

- [ ] **Step 4: 修改 iOS group**

在 iOS group 的 children 中加入：

```text
				01E000000000000000000009 /* Persistence */,
```

在 `PBXGroup section` 中追加：

```text
		01E000000000000000000009 /* Persistence */ = {
			isa = PBXGroup;
			children = (
				01B000000000000000000011 /* TodayPersistenceModel.swift */,
			);
			path = Persistence;
			sourceTree = "<group>";
		};
```

- [ ] **Step 5: 修改 iOS target packageProductDependencies**

把 `FitnessRPG` target 的 `packageProductDependencies` 改成：

```text
			packageProductDependencies = (
				01C000000000000000000001 /* FitnessRPGCore */,
				01C000000000000000000003 /* FitnessRPGPersistence */,
			);
```

不要修改 `FitnessRPGWatch` target 的 `packageProductDependencies`。

- [ ] **Step 6: 修改 iOS Sources build phase**

在 iOS sources phase 的 files 中加入：

```text
				01A000000000000000000012 /* TodayPersistenceModel.swift in Sources */,
```

- [ ] **Step 7: 修改 XCSwiftPackageProductDependency section**

在 `/* Begin XCSwiftPackageProductDependency section */` 中追加：

```text
		01C000000000000000000003 /* FitnessRPGPersistence */ = {
			isa = XCSwiftPackageProductDependency;
			package = 01C000000000000000000000 /* XCLocalSwiftPackageReference "FitnessRPGCore" */;
			productName = FitnessRPGPersistence;
		};
```

- [ ] **Step 8: 用 rg 确认 project 文件包含新引用**

运行：

```bash
rg -n "FitnessRPGPersistence|TodayPersistenceModel|Persistence" native/FitnessRPG.xcodeproj/project.pbxproj
```

预期：能看到 iOS framework build file、package product dependency、iOS source file reference、iOS source build phase、iOS Persistence group。watchOS target 不应出现 `FitnessRPGPersistence`。

- [ ] **Step 9: 运行 package 测试**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：Core 和 Persistence 两个 test target 全部通过。

- [ ] **Step 10: 构建 iOS target**

运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

预期：输出 `** BUILD SUCCEEDED **`。

- [ ] **Step 11: 构建 watchOS target**

运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

预期：输出 `** BUILD SUCCEEDED **`，并且没有 `FitnessRPGPersistence` 被 watchOS target 链接的错误。

- [ ] **Step 12: 提交 project 接入**

运行：

```bash
git add native/FitnessRPG.xcodeproj/project.pbxproj
git commit -m "build: link ios persistence package"
```

---

### Task 7: 更新文档并完整验证

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: 更新 root README Native Status**

在 `README.md` 的 `Native Status` 段落中追加：

```markdown
The native iOS app now has a JSON-backed persistence MVP. iPhone restores the same local-day quest after relaunch, saves Watch-returned execution logs and deterministic workout results, stores memory drafts, and advances lightweight RPG chapter/node progression locally. The watchOS target remains an execution surface and does not write durable history.
```

- [ ] **Step 2: 更新 root README Next Major Work**

把 `README.md` 的 `Next Major Work` 列表改成：

```markdown
1. Add a compact native history and memory review surface.
2. Improve real-device WatchConnectivity companion configuration and diagnostics after device testing.
3. Integrate local model runtime behind persisted memory context and deterministic validator.
4. Harden HealthKit data coverage, diagnostics, and onboarding copy after device testing.
```

- [ ] **Step 3: 更新 native README Current Pass**

在 `native/README.md` 的 `Current Pass` 段落后追加：

```markdown
The iOS target now owns local durable state through a JSON persistence store. It restores the same daily quest for the local day, persists Watch execution logs and resolved workout results, stores memory drafts, and advances deterministic RPG story progression. The watchOS target stays non-persistent in this pass.
```

- [ ] **Step 4: 更新 native README Future Integration Points**

把 `native/README.md` 的 `Future Integration Points` 列表改成：

```markdown
- Native history and memory review UI can expose persisted workout results and memory entries.
- LiteRT-LM / Gemma adapter can use persisted memory entries before deterministic safety validation.
- Real-device WatchConnectivity diagnostics and companion target configuration can be hardened after device testing.
```

- [ ] **Step 5: 运行完整验证**

从仓库根目录运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：Core 和 Persistence 测试全部通过。

从仓库根目录运行：

```bash
node prototype/tests/prototypeContract.test.mjs
```

预期：输出 `prototype contract ok`。

从仓库根目录运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

预期：输出 `** BUILD SUCCEEDED **`。

从仓库根目录运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

预期：输出 `** BUILD SUCCEEDED **`。

- [ ] **Step 6: 检查 git diff**

运行：

```bash
git status --short
git diff --stat
```

预期：只包含本计划列出的 Core、Persistence package、iOS app source、Xcode project 和 README 文件。

- [ ] **Step 7: 提交文档**

运行：

```bash
git add README.md native/README.md
git commit -m "docs: document native persistence mvp"
```

---

## 完成标准

- iOS 在同一个本地日期重启后恢复同一个 `DailyQuest`。
- iPhone 保存 Watch 回传的 `ExecutionLog`，并持久化 `WorkoutResult`。
- 最近一次保存的训练结果和 memory draft 能再次显示。
- `StoryProgressionEngine` 通过章节/节点模型推进故事进度。
- `.downgraded`、`.skipped` 和红色恢复任务被记录为保护性进度。
- `FitnessRPGPersistence` 有 JSON 仓库测试覆盖。
- iOS target 链接 `FitnessRPGPersistence`；watchOS target 不链接 persistence。
- `swift test`、prototype contract、iOS build、watchOS build 全部通过。
