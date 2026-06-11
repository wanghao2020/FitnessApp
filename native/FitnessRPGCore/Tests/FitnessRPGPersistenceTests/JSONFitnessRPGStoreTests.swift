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

    func testSavingWeeklySummaryPolishEntriesCanBeLoadedAgain() throws {
        let store = try temporaryStore()
        let summary = WeeklyTrainingSummary(
            dateRangeLabel: "2026-06-10",
            headline: "本周训练稳定完成",
            detail: "已完成 1 天，降阶 0 天，跳过 0 天，待执行 0 天。",
            completionLabel: "完成 1 · 降阶 0 · 跳过 0 · 待执行 0",
            readinessLabel: "绿 1 · 黄 0 · 红 0",
            safetyLabel: "未记录过重或跳过信号。",
            nextWeekPlanTitle: "下周计划：稳定推进",
            nextWeekActions: ["保持 3 次标准 Watch 任务"]
        )
        let entry = WeeklySummaryPolishEntry(
            summary: summary,
            draft: ModelRuntimeDraft(
                title: "本地周报",
                body: "稳定完成。",
                nextAction: "查看下周计划"
            ),
            providerID: "fixture-provider",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        try store.saveWeeklySummaryPolishEntries([entry])
        let loaded = store.loadWeeklySummaryPolishEntries()

        XCTAssertEqual(loaded.value, [entry])
        XCTAssertNil(loaded.warning)
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
