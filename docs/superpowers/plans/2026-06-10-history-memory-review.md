# 历史 / 记忆回顾 UI 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加独立 `History` 页面，让用户能从 Today 中枢查看最近训练日列表，并打开训练日详情查看 quest、执行结果、Memory 草稿和故事节点。

**Architecture:** 先在 `FitnessRPGCore` 增加可测试的历史展示派生模型，把排序、状态文案和详情摘要从 SwiftUI 中拿出来。然后让 `TodayPersistenceModel` 发布历史列表，最后新增 iOS `HistoryView` 并从 `TodayCommandCenterView` 的导航栏进入。

**Tech Stack:** Swift 6, SwiftUI, XCTest, Swift Package Manager, Xcode project file.

---

## 文件结构

- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`：训练历史展示模型和排序构建器。
- 修改 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`：增加历史排序、详情摘要和空历史测试。
- 修改 `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`：发布 `historyDays`，并在加载、保存、回滚路径中刷新历史列表。
- 新建 `native/AppSources/iOS/History/HistoryView.swift`：History 列表、空状态、训练日详情和小型行视图。
- 修改 `native/AppSources/iOS/TodayCommandCenterView.swift`：在导航栏增加 History 入口。
- 修改 `native/FitnessRPG.xcodeproj/project.pbxproj`：把 `HistoryView.swift` 加入 iOS target。

---

### Task 1: 增加可测试的历史展示模型

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`

- [ ] **Step 1: 写失败测试**

把下面测试和 helper 追加到 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift` 的 `FitnessRPGCoreTests` class 内部：

```swift
    func testTrainingHistoryDaysSortNewestFirstAndExposeCompletedDetail() {
        let older = makeHistoryRecord(
            date: "2026-06-09",
            readinessColor: .yellow,
            completionState: .downgraded,
            storyNode: .safetyDowngrade,
            updatedAt: Date(timeIntervalSince1970: 1_717_170_000)
        )
        let newer = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: .completed,
            storyNode: .mainTrial,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let history = TrainingHistoryBuilder.days(from: [older, newer])

        XCTAssertEqual(history.map(\.date), ["2026-06-10", "2026-06-09"])
        XCTAssertEqual(history[0].questTitle, "回声训练厅：力量共振")
        XCTAssertEqual(history[0].readinessTitle, "共振稳定")
        XCTAssertEqual(history[0].completionLabel, "已完成")
        XCTAssertEqual(history[0].memoryDraft, "2026-06-10 的 Memory 草稿")
        XCTAssertEqual(history[0].storyNodeTitle, StoryNode.mainTrial.title)
        XCTAssertTrue(history[0].stepSummary.contains("动态热身"))
    }

    func testTrainingHistoryDayShowsPendingAndIntermediateStates() {
        let pending = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .yellow,
            completionState: nil,
            storyNode: .calibrationRune,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        var inProgress = pending
        inProgress.executionLogs = [
            ExecutionLog(action: .complete, order: 1, rpe: 5, note: "热身完成")
        ]

        let pendingDay = TrainingHistoryDay(record: pending)
        let inProgressDay = TrainingHistoryDay(record: inProgress)

        XCTAssertEqual(pendingDay.completionLabel, "待执行")
        XCTAssertEqual(pendingDay.executionSummary, "尚未收到 Watch 执行结果。")
        XCTAssertEqual(pendingDay.memoryDraft, "Memory 草稿尚未生成。")
        XCTAssertEqual(pendingDay.storyNodeTitle, StoryNode.calibrationRune.title)
        XCTAssertEqual(inProgressDay.completionLabel, "同步中")
        XCTAssertEqual(inProgressDay.executionSummary, "已同步 1 / 3 个 Watch 步骤。")
    }

    func testTrainingHistoryBuilderReturnsEmptyListForEmptyRecords() {
        XCTAssertEqual(TrainingHistoryBuilder.days(from: []), [])
    }

    private func makeHistoryRecord(
        date: String,
        readinessColor: ReadinessColor,
        completionState: CompletionState?,
        storyNode: StoryNode,
        updatedAt: Date
    ) -> TrainingDayRecord {
        let readiness: ReadinessResult
        switch readinessColor {
        case .green:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        case .yellow:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        case .red:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        }

        let quest = QuestEngine.quest(for: readiness, storyNode: storyNode.title)
        let logs = completionState == nil
            ? []
            : [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "完成")]
        let result = completionState.map { state in
            WorkoutResult(
                completionState: state,
                safetyFeedback: "\(date) safety",
                nextRecommendation: "\(date) recommendation",
                memoryDraft: "\(date) 的 Memory 草稿"
            )
        }
        let progression = StoryProgression(
            currentChapterID: storyNode.chapterID,
            currentNodeID: storyNode.id,
            completedNodeIDs: result == nil ? [] : [storyNode.id],
            lastOutcome: completionState == .downgraded ? .downgraded : .advanced,
            lastReason: "\(date) story reason",
            updatedAt: updatedAt
        )

        return TrainingDayRecord(
            date: date,
            readiness: readiness,
            quest: quest,
            executionLogs: logs,
            workoutResult: result,
            storyProgression: progression,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }
```

- [ ] **Step 2: 运行测试确认失败**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: FAIL，错误包含 `TrainingHistoryBuilder` 或 `TrainingHistoryDay` 未定义。

- [ ] **Step 3: 创建历史展示模型实现**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`：

```swift
import Foundation

public struct TrainingHistoryDay: Equatable, Identifiable, Sendable {
    public let record: TrainingDayRecord

    public init(record: TrainingDayRecord) {
        self.record = record
    }

    public var id: String { record.id }
    public var date: String { record.date }
    public var questTitle: String { record.quest.title }
    public var readinessTitle: String { record.readiness.title }
    public var readinessColor: ReadinessColor { record.readiness.color }

    public var readinessSummary: String {
        "\(record.readiness.title) · \(record.readiness.score)"
    }

    public var completionLabel: String {
        guard let result = record.workoutResult else {
            return record.executionLogs.isEmpty ? "待执行" : "同步中"
        }

        switch result.completionState {
        case .completed:
            return "已完成"
        case .downgraded:
            return "已降阶"
        case .skipped:
            return "已跳过"
        }
    }

    public var executionSummary: String {
        if let result = record.workoutResult {
            return result.safetyFeedback
        }

        guard !record.executionLogs.isEmpty else {
            return "尚未收到 Watch 执行结果。"
        }

        return "已同步 \(record.executionLogs.count) / \(record.quest.watchSteps.count) 个 Watch 步骤。"
    }

    public var recommendation: String {
        record.workoutResult?.nextRecommendation ?? "完成 Watch 执行后会生成下一次建议。"
    }

    public var memoryDraft: String {
        record.workoutResult?.memoryDraft ?? "Memory 草稿尚未生成。"
    }

    public var storyNodeTitle: String {
        guard let progression = record.storyProgression else {
            return record.quest.storyNode
        }

        return TrainingHistoryBuilder.storyNodeTitle(for: progression.currentNodeID)
    }

    public var storyReason: String {
        record.storyProgression?.lastReason ?? "故事节点尚未更新。"
    }

    public var stepSummary: String {
        record.quest.watchSteps.map(\.instruction).joined(separator: " / ")
    }
}

public enum TrainingHistoryBuilder {
    public static func days(from records: [TrainingDayRecord]) -> [TrainingHistoryDay] {
        records
            .sorted { left, right in
                if left.date != right.date {
                    return left.date > right.date
                }
                return left.updatedAt > right.updatedAt
            }
            .map(TrainingHistoryDay.init(record:))
    }

    public static func storyNodeTitle(for nodeID: String) -> String {
        switch nodeID {
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
}
```

- [ ] **Step 4: 运行 Core 测试确认通过**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS，所有 `FitnessRPGCoreTests` 和 `FitnessRPGPersistenceTests` 通过。

- [ ] **Step 5: 提交**

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "feat: add training history summaries"
```

---

### Task 2: 让 TodayPersistenceModel 发布历史列表

**Files:**
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`

- [ ] **Step 1: 增加历史发布属性**

在 `TodayPersistenceModel` 顶部已有 `@Published` 属性旁边加入：

```swift
    @Published private(set) var historyDays: [TrainingHistoryDay] = []
```

- [ ] **Step 2: 增加手动刷新入口和发布 helper**

把下面代码加入 `currentStoryNodeTitle` 之后、`loadOrCreateToday` 之前：

```swift
    var historyEmptyStateText: String {
        "还没有历史记录。完成一次 Today 任务或同步一次 Watch 结果后，这里会显示训练回顾。"
    }

    func reloadHistory() {
        guard let records = loadSafeTrainingDays() else {
            return
        }

        publishHistory(from: records)
        storageStatusText = statusText(
            records.isEmpty ? "本地历史为空。" : "已加载 \(records.count) 条历史记录。"
        )
    }
```

在 `loadSafeTrainingDays()` 之前加入：

```swift
    private func publishHistory(from records: [TrainingDayRecord]) {
        historyDays = TrainingHistoryBuilder.days(from: records)
    }
```

- [ ] **Step 3: 替换 loadOrCreateToday 以同步刷新历史**

用下面完整实现替换现有 `loadOrCreateToday(readiness:date:)`：

```swift
    func loadOrCreateToday(readiness: ReadinessResult, date: Date = Date()) {
        let key = Self.dayKey(for: date, calendar: calendar)
        guard var records = loadSafeTrainingDays() else {
            return
        }

        if let existing = records.first(where: { $0.date == key }) {
            todayRecord = existing
            reconcileStoryProgression(with: existing)
            publishHistory(from: records)
            storageStatusText = statusText("已恢复今日任务。")
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
            publishHistory(from: records)
            storageStatusText = statusText("已保存今日任务。")
        } catch {
            storageStatusText = "今日任务保存失败：\(error.localizedDescription)"
        }
    }
```

- [ ] **Step 4: 刷新中间 Watch 快照后的历史列表**

在 `saveIntermediateSnapshot(record:shouldPublishRecord:successStatusText:)` 的 `do` block 中，用下面 block 替换现有 `do` block：

```swift
        do {
            try store.saveTrainingDays(records)
            publishHistory(from: records)
            if shouldPublishRecord {
                todayRecord = record
            }
            storageStatusText = statusText(successStatusText)
        } catch {
            let didRollback = rollbackRecords(oldRecords)
            todayRecord = oldRecord
            if didRollback {
                publishHistory(from: oldRecords)
                storageStatusText = "Watch 训练快照保存失败，已尽量恢复本地记录：\(error.localizedDescription)"
            } else {
                storageStatusText = "Watch 训练快照保存失败，且回滚未完全成功：\(error.localizedDescription)"
            }
        }
```

- [ ] **Step 5: 刷新最终训练结果保存后的历史列表**

在 `persist(record:progression:memory:shouldUpdateGlobalStory:shouldPublishRecord:successStatusText:)` 的 `do` block 中，用下面 block 替换现有 `do` block：

```swift
        do {
            try store.saveTrainingDays(records)
            if shouldUpdateGlobalStory {
                try store.saveStoryProgression(progression)
            }
            try store.saveMemoryEntries(memoryEntries)
            publishHistory(from: records)
            if shouldPublishRecord {
                todayRecord = record
            }
            if shouldUpdateGlobalStory {
                storyProgression = progression
            }
            storageStatusText = statusText(successStatusText)
        } catch {
            let didRollback = rollback(
                records: oldRecords,
                progression: oldProgression,
                memoryEntries: oldMemoryEntries,
                shouldRestoreGlobalStory: shouldUpdateGlobalStory
            )
            todayRecord = oldRecord
            storyProgression = oldPublishedProgression
            if didRollback {
                publishHistory(from: oldRecords)
                storageStatusText = "训练结果保存失败，已尽量恢复本地记录：\(error.localizedDescription)"
            } else {
                storageStatusText = "训练结果保存失败，且回滚未完全成功：\(error.localizedDescription)"
            }
        }
```

- [ ] **Step 6: 运行验证**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS。这个任务没有新增 iOS unit test target，历史派生逻辑已经在 Task 1 覆盖；这里用包测试确认共享模型仍通过。

- [ ] **Step 7: 提交**

```bash
git add native/AppSources/iOS/Persistence/TodayPersistenceModel.swift
git commit -m "feat: publish persisted training history"
```

---

### Task 3: 新建 History SwiftUI 页面

**Files:**
- Create: `native/AppSources/iOS/History/HistoryView.swift`

- [ ] **Step 1: 创建目录和页面文件**

创建目录 `native/AppSources/iOS/History`，然后创建 `native/AppSources/iOS/History/HistoryView.swift`：

```swift
import SwiftUI
import FitnessRPGCore

struct HistoryView: View {
    @ObservedObject var persistenceModel: TodayPersistenceModel

    var body: some View {
        Group {
            if persistenceModel.historyDays.isEmpty {
                HistoryEmptyStateView(message: persistenceModel.historyEmptyStateText)
            } else {
                List {
                    Section("最近训练") {
                        ForEach(persistenceModel.historyDays) { day in
                            NavigationLink {
                                HistoryDetailView(day: day)
                            } label: {
                                HistoryDayRow(day: day)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            persistenceModel.reloadHistory()
        }
    }
}

private struct HistoryDayRow: View {
    let day: TrainingHistoryDay

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ReadinessDot(color: day.readinessColor)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(day.date)
                    .font(.headline)
                Text(day.questTitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("\(day.completionLabel) · \(day.readinessSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct HistoryDetailView: View {
    let day: TrainingHistoryDay

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(day.date)
                        .font(.title.bold())
                    Text(day.questTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Label(day.completionLabel, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(day.readinessColor.historyTint)
                }

                HistorySectionCard("Readiness") {
                    Text(day.readinessSummary)
                    Text(day.record.readiness.explanation)
                        .foregroundStyle(.secondary)
                    Text(day.record.readiness.safetyGuidance)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Quest") {
                    Text(day.record.quest.objective)
                    Text(day.stepSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Watch 回传") {
                    Text(day.executionSummary)
                    Text(day.recommendation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HistorySectionCard("Memory 草稿") {
                    Text(day.memoryDraft)
                }

                HistorySectionCard("故事节点") {
                    Text(day.storyNodeTitle)
                    Text(day.storyReason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HistoryEmptyStateView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "还没有历史记录",
            systemImage: "clock.arrow.circlepath",
            description: Text(message)
        )
        .padding()
    }
}

private struct HistorySectionCard<Content: View>: View {
    let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReadinessDot: View {
    let color: ReadinessColor

    var body: some View {
        Circle()
            .fill(color.historyTint)
            .frame(width: 10, height: 10)
    }
}

private extension ReadinessColor {
    var historyTint: Color {
        switch self {
        case .green:
            return .green
        case .yellow:
            return .orange
        case .red:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(persistenceModel: TodayPersistenceModel())
    }
}
```

- [ ] **Step 2: 运行 Core 测试确认共享层未变**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS。

- [ ] **Step 3: 提交**

```bash
git add native/AppSources/iOS/History/HistoryView.swift
git commit -m "feat: add history review view"
```

---

### Task 4: 接入 Today 导航和 Xcode project

**Files:**
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: 在 Today 增加 History 入口**

在 `native/AppSources/iOS/TodayCommandCenterView.swift` 的 `.navigationTitle("Fitness RPG")` 后面加入 toolbar：

```swift
            .navigationTitle("Fitness RPG")
            .toolbar {
                NavigationLink {
                    HistoryView(persistenceModel: persistenceModel)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
            .onChange(of: watchSyncModel.latestExecutionPayload, initial: true) { _, payload in
                guard let payload else { return }
                persistenceModel.applyExecutionPayload(payload)
            }
```

- [ ] **Step 2: 在 project.pbxproj 增加 build file 和 file reference**

在 `native/FitnessRPG.xcodeproj/project.pbxproj` 的 `PBXBuildFile section` 中加入：

```text
		01A000000000000000000013 /* HistoryView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 01B000000000000000000012 /* HistoryView.swift */; };
```

在 `PBXFileReference section` 中加入：

```text
		01B000000000000000000012 /* HistoryView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HistoryView.swift; sourceTree = "<group>"; };
```

- [ ] **Step 3: 在 iOS group 中加入 History group**

在 `01E000000000000000000003 /* iOS */` group 的 `children` 中，把 `History` group 插入到 `Persistence` 前：

```text
				01E00000000000000000000A /* History */,
```

然后在 `PBXGroup section` 中 `Persistence` group 后面加入：

```text
		01E00000000000000000000A /* History */ = {
			isa = PBXGroup;
			children = (
				01B000000000000000000012 /* HistoryView.swift */,
			);
			path = History;
			sourceTree = "<group>";
		};
```

- [ ] **Step 4: 把 HistoryView 加入 iOS Sources**

在 `01D000000000000000000003 /* Sources */` 的 `files` 中加入：

```text
				01A000000000000000000013 /* HistoryView.swift in Sources */,
```

不要加入 watchOS target。

- [ ] **Step 5: 运行 iOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 6: 运行 watchOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`。History 文件不应被加入 watchOS target。

- [ ] **Step 7: 提交**

```bash
git add native/AppSources/iOS/TodayCommandCenterView.swift native/FitnessRPG.xcodeproj/project.pbxproj
git commit -m "feat: link history review navigation"
```

---

### Task 5: 最终回归验证

**Files:**
- Verify only.

- [ ] **Step 1: 运行 Swift Package 测试**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS，测试总数比开始执行计划前增加 3 个。

- [ ] **Step 2: 运行 iOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 3: 运行 watchOS build**

Run:

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 4: 运行 prototype contract**

Run:

```bash
node prototype/tests/prototypeContract.test.mjs
```

Expected: `prototype contract ok`。

- [ ] **Step 5: 检查工作区**

Run:

```bash
git status --short --branch
```

Expected: 当前分支只包含计划执行产生的提交；没有未暂存的源代码改动。
