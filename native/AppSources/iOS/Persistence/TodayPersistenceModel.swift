import Combine
import Foundation
import FitnessRPGCore
import FitnessRPGPersistence

@MainActor
final class TodayPersistenceModel: ObservableObject {
    @Published private(set) var todayRecord: TrainingDayRecord?
    @Published private(set) var storyProgression: StoryProgression
    @Published private(set) var storageStatusText = "本地记录尚未加载。"
    @Published private(set) var historyDays: [TrainingHistoryDay] = []
    @Published private(set) var historyLoadErrorText: String?
    @Published private(set) var weeklySummaryPolishEntry: WeeklySummaryPolishEntry?
    @Published private(set) var memoryReviewEntries: [MemoryReviewEntry] = []
    @Published private(set) var memoryReviewLoadErrorText: String?
    @Published private(set) var validationReportEntries: [RealDeviceValidationReportEntry] = []

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
        reloadValidationReports()
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

    var historyEmptyStateText: String {
        "还没有历史记录。完成一次 Today 任务或同步一次 Watch 结果后，这里会显示训练回顾。"
    }

    var weeklyTrainingSummary: WeeklyTrainingSummary {
        WeeklyTrainingSummaryBuilder.summary(from: historyDays.map(\.record))
    }

    var memoryReviewEmptyStateText: String {
        "还没有记忆草稿。完成一次 Watch 回传并生成训练结果后，这里会显示可回顾的故事记忆。"
    }

    func reloadHistory() {
        let loadedRecords = store.loadTrainingDays()
        if let warning = loadedRecords.warning {
            historyLoadErrorText = "本地训练记录读取失败：\(warning)"
            return
        }

        historyLoadErrorText = nil
        publishHistory(from: loadedRecords.value)
    }

    func saveWeeklySummaryPolishResponse(_ response: ModelRuntimeResponse, date: Date = Date()) {
        guard !historyDays.isEmpty else {
            weeklySummaryPolishEntry = nil
            return
        }

        let loadedEntries = store.loadWeeklySummaryPolishEntries()
        if let warning = loadedEntries.warning {
            storageStatusText = "本地周回顾润色缓存读取失败：\(warning)"
            return
        }

        let summary = weeklyTrainingSummary
        let updatedEntries = WeeklySummaryPolishCache.upserting(
            response: response,
            summary: summary,
            in: loadedEntries.value,
            date: date
        )
        guard updatedEntries != loadedEntries.value else {
            return
        }

        do {
            try store.saveWeeklySummaryPolishEntries(updatedEntries)
            weeklySummaryPolishEntry = WeeklySummaryPolishCache.entry(for: summary, in: updatedEntries)
            storageStatusText = statusText("已保存周回顾本地模型润色。")
        } catch {
            storageStatusText = "周回顾本地模型润色保存失败：\(error.localizedDescription)"
        }
    }

    func clearWeeklySummaryPolishEntry() {
        guard !historyDays.isEmpty else {
            weeklySummaryPolishEntry = nil
            return
        }

        let loadedEntries = store.loadWeeklySummaryPolishEntries()
        if let warning = loadedEntries.warning {
            storageStatusText = "本地周回顾润色缓存读取失败：\(warning)"
            return
        }

        let summary = weeklyTrainingSummary
        let updatedEntries = WeeklySummaryPolishCache.removing(
            summary: summary,
            from: loadedEntries.value
        )

        do {
            if updatedEntries != loadedEntries.value {
                try store.saveWeeklySummaryPolishEntries(updatedEntries)
                storageStatusText = statusText("已清除当前周回顾本地模型润色。")
            } else {
                storageStatusText = statusText("当前周回顾没有可清除的本地模型润色。")
            }
            weeklySummaryPolishEntry = WeeklySummaryPolishCache.entry(for: summary, in: updatedEntries)
        } catch {
            storageStatusText = "周回顾本地模型润色清除失败：\(error.localizedDescription)"
        }
    }

    func reloadMemoryReview() {
        let loadedMemoryEntries = store.loadMemoryEntries()
        if let warning = loadedMemoryEntries.warning {
            memoryReviewLoadErrorText = "本地记忆记录读取失败：\(warning)"
            memoryReviewEntries = []
            return
        }

        let loadedRecords = store.loadTrainingDays()
        let records = loadedRecords.warning == nil ? loadedRecords.value : []
        memoryReviewLoadErrorText = nil
        publishMemoryReview(from: loadedMemoryEntries.value, records: records)

        if let warning = loadedRecords.warning {
            storageStatusText = "本地训练记录读取失败，记忆来源信息可能不完整：\(warning)"
        }
    }

    func reloadValidationReports() {
        let loadedEntries = store.loadValidationReportEntries()
        if let warning = loadedEntries.warning {
            validationReportEntries = []
            storageStatusText = "本地实机验证报告读取失败：\(warning)"
            return
        }

        validationReportEntries = loadedEntries.value.sorted { left, right in
            left.createdAt > right.createdAt
        }
    }

    func saveValidationReport(
        _ report: RealDeviceValidationReport,
        headline: String,
        date: Date = Date()
    ) {
        let loadedEntries = store.loadValidationReportEntries()
        if let warning = loadedEntries.warning {
            storageStatusText = "本地实机验证报告读取失败：\(warning)"
            return
        }

        let updatedEntries = RealDeviceValidationReportArchive.upserting(
            report: report,
            headline: headline,
            in: loadedEntries.value,
            createdAt: date
        )

        do {
            try store.saveValidationReportEntries(updatedEntries)
            validationReportEntries = updatedEntries
            storageStatusText = statusText("已保存实机验证报告。")
        } catch {
            storageStatusText = "实机验证报告保存失败：\(error.localizedDescription)"
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

    func applyExecutionPayload(_ payload: ExecutionLogSyncPayload, receivedAt: Date = Date()) {
        let payloadDayKey = Self.dayKey(for: payload.sentAt, calendar: calendar)
        let currentDayKey = Self.dayKey(for: receivedAt, calendar: calendar)
        let isDisplayedRecord = todayRecord?.date == payloadDayKey
        guard let records = loadSafeTrainingDays() else {
            return
        }
        let diskRecord = records.first { $0.date == payloadDayKey }
        let candidate = diskRecord ?? (isDisplayedRecord ? todayRecord : nil)

        guard let record = candidate else {
            storageStatusText = "已收到 Watch 记录，但本地没有今日任务。"
            return
        }

        let shouldPublishIntermediateRecord = payloadDayKey == currentDayKey || isDisplayedRecord
        let shouldPublishFinalRecord = payloadDayKey == currentDayKey
        let shouldUpdateGlobalStory = payloadDayKey == currentDayKey
        let application = TrainingDayExecutionApplier.apply(
            payload: payload,
            to: record,
            baselineProgression: storyProgression,
            receivedAt: receivedAt
        )

        switch application.status {
        case .intermediateSnapshot:
            saveIntermediateSnapshot(
                record: application.record,
                shouldPublishRecord: shouldPublishIntermediateRecord,
                successStatusText: shouldPublishIntermediateRecord
                    ? "已保存 Watch 训练快照。"
                    : "已保存历史 Watch 训练快照，当前任务未切换。"
            )
        case .finalResult:
            guard let progression = application.progression,
                  let memory = application.memory else {
                storageStatusText = "Watch 训练结果生成失败。"
                return
            }

            persist(
                record: application.record,
                progression: progression,
                memory: memory,
                shouldUpdateGlobalStory: shouldUpdateGlobalStory,
                shouldPublishRecord: shouldPublishFinalRecord,
                successStatusText: shouldUpdateGlobalStory
                    ? "已保存 Watch 训练结果和故事进度。"
                    : "已保存历史 Watch 训练结果和记忆，当前故事未回退。"
            )
        case .questMismatch:
            storageStatusText = "已收到 Watch 记录，但与今日任务不匹配。"
        case .duplicate:
            storageStatusText = "已忽略重复的 Watch 训练记录。"
        case .stale:
            storageStatusText = "已忽略过期的 Watch 训练记录。"
        case .alreadySettled:
            storageStatusText = "已忽略已结算后的 Watch 训练记录。"
        case .conflictingSameCount:
            storageStatusText = "已忽略可能覆盖现有结果的 Watch 训练记录。"
        }
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
            publishHistory(from: records)
            publishMemoryReview(from: memoryEntries, records: records)
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
                publishMemoryReview(from: oldMemoryEntries, records: oldRecords)
                storageStatusText = "训练结果保存失败，已尽量恢复本地记录：\(error.localizedDescription)"
            } else {
                storageStatusText = "训练结果保存失败，且回滚未完全成功：\(error.localizedDescription)"
            }
        }
    }

    private func publishHistory(from records: [TrainingDayRecord]) {
        historyLoadErrorText = nil
        historyDays = TrainingHistoryBuilder.days(from: records)
        publishWeeklySummaryPolish()
    }

    private func publishMemoryReview(from memories: [MemoryEntry], records: [TrainingDayRecord]) {
        memoryReviewLoadErrorText = nil
        memoryReviewEntries = MemoryReviewBuilder.entries(from: memories, records: records)
    }

    private func publishWeeklySummaryPolish() {
        guard !historyDays.isEmpty else {
            weeklySummaryPolishEntry = nil
            return
        }

        let loadedEntries = store.loadWeeklySummaryPolishEntries()
        if let warning = loadedEntries.warning {
            weeklySummaryPolishEntry = nil
            storageStatusText = "本地周回顾润色缓存读取失败：\(warning)"
            return
        }

        weeklySummaryPolishEntry = WeeklySummaryPolishCache.entry(
            for: weeklyTrainingSummary,
            in: loadedEntries.value
        )
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
