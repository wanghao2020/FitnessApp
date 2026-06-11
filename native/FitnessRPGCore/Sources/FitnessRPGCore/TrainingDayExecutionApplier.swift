import Foundation

public struct TrainingDayExecutionApplication: Equatable, Sendable {
    public let status: TrainingDayExecutionApplicationStatus
    public let record: TrainingDayRecord
    public let progression: StoryProgression?
    public let memory: MemoryEntry?

    public init(
        status: TrainingDayExecutionApplicationStatus,
        record: TrainingDayRecord,
        progression: StoryProgression? = nil,
        memory: MemoryEntry? = nil
    ) {
        self.status = status
        self.record = record
        self.progression = progression
        self.memory = memory
    }
}

public enum TrainingDayExecutionApplicationStatus: Equatable, Sendable {
    case intermediateSnapshot
    case finalResult
    case questMismatch
    case duplicate
    case stale
    case alreadySettled
    case conflictingSameCount
}

public enum TrainingDayExecutionApplier {
    public static func apply(
        payload: ExecutionLogSyncPayload,
        to record: TrainingDayRecord,
        baselineProgression: StoryProgression,
        receivedAt: Date = Date()
    ) -> TrainingDayExecutionApplication {
        guard payload.questTitle == record.quest.title else {
            return TrainingDayExecutionApplication(status: .questMismatch, record: record)
        }

        guard let ignoredStatus = ignoredStatus(for: payload, record: record) else {
            var updatedRecord = record
            updatedRecord.executionLogs = payload.logs
            updatedRecord.updatedAt = receivedAt

            guard isFinalPayload(payload, for: record) else {
                return TrainingDayExecutionApplication(status: .intermediateSnapshot, record: updatedRecord)
            }

            let progressionBaseline = record.storyProgression ?? baselineProgression
            let result = ExecutionEngine.resolve(quest: record.quest, logs: payload.logs)
            let nextProgression = StoryProgressionEngine.progression(
                after: progressionBaseline,
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

            updatedRecord.workoutResult = result
            updatedRecord.storyProgression = nextProgression

            return TrainingDayExecutionApplication(
                status: .finalResult,
                record: updatedRecord,
                progression: nextProgression,
                memory: memory
            )
        }

        return TrainingDayExecutionApplication(status: ignoredStatus, record: record)
    }

    private static func ignoredStatus(
        for payload: ExecutionLogSyncPayload,
        record: TrainingDayRecord
    ) -> TrainingDayExecutionApplicationStatus? {
        if record.executionLogs == payload.logs {
            return .duplicate
        }

        if payload.logs.count < record.executionLogs.count {
            return .stale
        }

        if record.workoutResult != nil {
            return .alreadySettled
        }

        if payload.logs.count == record.executionLogs.count && !record.executionLogs.isEmpty {
            return .conflictingSameCount
        }

        return nil
    }

    private static func isFinalPayload(_ payload: ExecutionLogSyncPayload, for record: TrainingDayRecord) -> Bool {
        payload.logs.count >= record.quest.watchSteps.count || containsOverloadSignal(payload.logs)
    }

    private static func containsOverloadSignal(_ logs: [ExecutionLog]) -> Bool {
        logs.contains { $0.action == .tooHeavy || $0.rpe >= 9 }
    }
}
