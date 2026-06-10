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
    private let initialStoryWarningText: String?

    init(
        store: JSONFitnessRPGStore = TodayPersistenceModel.defaultStore(),
        calendar: Calendar = .current
    ) {
        self.store = store
        self.calendar = calendar
        let loadedStory = store.loadStoryProgression()
        self.storyProgression = loadedStory.value

        if let storyWarning = loadedStory.warning {
            self.initialStoryWarningText = "本地故事记录读取失败：\(storyWarning)"
            storageStatusText = initialStoryWarningText ?? storageStatusText
        } else {
            self.initialStoryWarningText = nil
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
        guard var records = loadSafeTrainingDays() else {
            return
        }

        if let existing = records.first(where: { $0.date == key }) {
            todayRecord = existing
            reconcileStoryProgression(with: existing)
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
            storageStatusText = statusText("已保存今日任务。")
        } catch {
            storageStatusText = "今日任务保存失败：\(error.localizedDescription)"
        }
    }

    func applyExecutionPayload(_ payload: ExecutionLogSyncPayload, receivedAt: Date = Date()) {
        let payloadDayKey = Self.dayKey(for: payload.sentAt, calendar: calendar)
        let currentDayKey = Self.dayKey(for: receivedAt, calendar: calendar)
        let isDisplayedRecord = todayRecord?.date == payloadDayKey
        guard let records = loadSafeTrainingDays() else {
            return
        }
        let diskRecord = records.first { $0.date == payloadDayKey }
        let candidate = diskRecord ?? (isDisplayedRecord ? todayRecord : nil)

        guard var record = candidate else {
            storageStatusText = "已收到 Watch 记录，但本地没有今日任务。"
            return
        }

        guard payload.questTitle == record.quest.title else {
            storageStatusText = "已收到 Watch 记录，但与今日任务不匹配。"
            return
        }

        guard shouldApply(payload: payload, to: record) else {
            return
        }

        let shouldPublishIntermediateRecord = payloadDayKey == currentDayKey || isDisplayedRecord
        let shouldPublishFinalRecord = payloadDayKey == currentDayKey
        let shouldUpdateGlobalStory = payloadDayKey == currentDayKey
        let finalPayload = isFinalPayload(payload, for: record)

        if !finalPayload {
            record.executionLogs = payload.logs
            record.updatedAt = receivedAt
            saveIntermediateSnapshot(
                record: record,
                shouldPublishRecord: shouldPublishIntermediateRecord,
                successStatusText: shouldPublishIntermediateRecord
                    ? "已保存 Watch 训练快照。"
                    : "已保存历史 Watch 训练快照，当前任务未切换。"
            )
            return
        }

        let baselineProgression = record.storyProgression ?? storyProgression
        let result = ExecutionEngine.resolve(quest: record.quest, logs: payload.logs)
        let nextProgression = StoryProgressionEngine.progression(
            after: baselineProgression,
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

        persist(
            record: record,
            progression: nextProgression,
            memory: memory,
            shouldUpdateGlobalStory: shouldUpdateGlobalStory,
            shouldPublishRecord: shouldPublishFinalRecord,
            successStatusText: shouldUpdateGlobalStory
                ? "已保存 Watch 训练结果和故事进度。"
                : "已保存历史 Watch 训练结果和记忆，当前故事未回退。"
        )
    }

    private func saveIntermediateSnapshot(
        record: TrainingDayRecord,
        shouldPublishRecord: Bool,
        successStatusText: String
    ) {
        guard var records = loadSafeTrainingDays() else {
            return
        }

        let oldRecords = records
        let oldRecord = todayRecord

        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }

        do {
            try store.saveTrainingDays(records)
            if shouldPublishRecord {
                todayRecord = record
            }
            storageStatusText = statusText(successStatusText)
        } catch {
            let didRollback = rollbackRecords(oldRecords)
            todayRecord = oldRecord
            if didRollback {
                storageStatusText = "Watch 训练快照保存失败，已尽量恢复本地记录：\(error.localizedDescription)"
            } else {
                storageStatusText = "Watch 训练快照保存失败，且回滚未完全成功：\(error.localizedDescription)"
            }
        }
    }

    private func persist(
        record: TrainingDayRecord,
        progression: StoryProgression,
        memory: MemoryEntry,
        shouldUpdateGlobalStory: Bool,
        shouldPublishRecord: Bool,
        successStatusText: String
    ) {
        guard var records = loadSafeTrainingDays(),
              let oldMemoryEntries = loadSafeMemoryEntries() else {
            return
        }
        let oldProgression: StoryProgression?
        if shouldUpdateGlobalStory {
            guard let loadedProgression = loadSafeStoryProgression() else {
                return
            }
            oldProgression = loadedProgression
        } else {
            oldProgression = nil
        }

        let oldRecords = records
        let oldRecord = todayRecord
        let oldPublishedProgression = storyProgression

        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        var memoryEntries = oldMemoryEntries
        memoryEntries.append(memory)

        do {
            try store.saveTrainingDays(records)
            if shouldUpdateGlobalStory {
                try store.saveStoryProgression(progression)
            }
            try store.saveMemoryEntries(memoryEntries)
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
                storageStatusText = "训练结果保存失败，已尽量恢复本地记录：\(error.localizedDescription)"
            } else {
                storageStatusText = "训练结果保存失败，且回滚未完全成功：\(error.localizedDescription)"
            }
        }
    }

    private func loadSafeTrainingDays() -> [TrainingDayRecord]? {
        let loadedRecords = store.loadTrainingDays()
        if let warning = loadedRecords.warning {
            storageStatusText = "本地训练记录读取失败，已停止写入以保护历史：\(warning)"
            return nil
        }
        return loadedRecords.value
    }

    private func loadSafeMemoryEntries() -> [MemoryEntry]? {
        let loadedMemoryEntries = store.loadMemoryEntries()
        if let warning = loadedMemoryEntries.warning {
            storageStatusText = "本地记忆记录读取失败，已停止写入以保护历史：\(warning)"
            return nil
        }
        return loadedMemoryEntries.value
    }

    private func loadSafeStoryProgression() -> StoryProgression? {
        let loadedStory = store.loadStoryProgression()
        if let warning = loadedStory.warning {
            storageStatusText = "本地故事记录读取失败，已停止写入以保护历史：\(warning)"
            return nil
        }
        return loadedStory.value
    }

    private func reconcileStoryProgression(with record: TrainingDayRecord) {
        guard let recordProgression = record.storyProgression else {
            return
        }

        if isFallbackInitialStoryProgression(storyProgression)
            || recordProgression.updatedAt > storyProgression.updatedAt {
            storyProgression = recordProgression
        }
    }

    private func isFallbackInitialStoryProgression(_ progression: StoryProgression) -> Bool {
        let initial = StoryProgression.initial(updatedAt: Date(timeIntervalSince1970: 0))
        return progression == initial
    }

    private func shouldApply(payload: ExecutionLogSyncPayload, to record: TrainingDayRecord) -> Bool {
        if record.executionLogs == payload.logs {
            storageStatusText = "已忽略重复的 Watch 训练记录。"
            return false
        }

        if payload.logs.count < record.executionLogs.count {
            storageStatusText = "已忽略过期的 Watch 训练记录。"
            return false
        }

        if record.workoutResult != nil {
            storageStatusText = "已忽略已结算后的 Watch 训练记录。"
            return false
        }

        if payload.logs.count == record.executionLogs.count && !record.executionLogs.isEmpty {
            storageStatusText = "已忽略可能覆盖现有结果的 Watch 训练记录。"
            return false
        }

        return true
    }

    private func isFinalPayload(_ payload: ExecutionLogSyncPayload, for record: TrainingDayRecord) -> Bool {
        payload.logs.count >= record.quest.watchSteps.count || containsOverloadSignal(payload.logs)
    }

    private func containsOverloadSignal(_ logs: [ExecutionLog]) -> Bool {
        logs.contains { $0.action == .tooHeavy || $0.rpe >= 9 }
    }

    private func rollbackRecords(_ records: [TrainingDayRecord]) -> Bool {
        do {
            try store.saveTrainingDays(records)
            return true
        } catch {
            return false
        }
    }

    private func rollback(
        records: [TrainingDayRecord],
        progression: StoryProgression?,
        memoryEntries: [MemoryEntry],
        shouldRestoreGlobalStory: Bool
    ) -> Bool {
        do {
            try store.saveTrainingDays(records)
            if shouldRestoreGlobalStory, let progression {
                try store.saveStoryProgression(progression)
            }
            try store.saveMemoryEntries(memoryEntries)
            return true
        } catch {
            return false
        }
    }

    private func statusText(_ text: String) -> String {
        guard let initialStoryWarningText else {
            return text
        }
        return "\(text) \(initialStoryWarningText)"
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    nonisolated private static func defaultStore() -> JSONFitnessRPGStore {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseURL.appendingPathComponent("FitnessRPG", isDirectory: true)
        return JSONFitnessRPGStore(directoryURL: directory)
    }
}
