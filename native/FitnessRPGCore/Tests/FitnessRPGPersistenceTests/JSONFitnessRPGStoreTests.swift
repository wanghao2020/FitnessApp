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
