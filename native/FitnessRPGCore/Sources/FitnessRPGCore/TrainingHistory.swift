import Foundation

public struct TrainingHistoryWatchLogRow: Equatable, Identifiable, Sendable {
    public let id: String
    public let stepTitle: String
    public let actionLabel: String
    public let actionSymbolName: String
    public let rpeLabel: String
    public let note: String

    public init(
        id: String,
        stepTitle: String,
        actionLabel: String,
        actionSymbolName: String,
        rpeLabel: String,
        note: String
    ) {
        self.id = id
        self.stepTitle = stepTitle
        self.actionLabel = actionLabel
        self.actionSymbolName = actionSymbolName
        self.rpeLabel = rpeLabel
        self.note = note
    }
}

public struct TrainingHistoryDay: Equatable, Identifiable, Sendable {
    public let record: TrainingDayRecord

    public init(record: TrainingDayRecord) {
        self.record = record
    }

    public var id: String { "\(record.id)-\(record.createdAt.timeIntervalSince1970)" }
    public var date: String { record.date }
    public var questTitle: String { record.quest.title }
    public var readinessTitle: String { record.readiness.title }
    public var readinessColor: ReadinessColor { record.readiness.color }

    public var readinessSummary: String {
        "\(record.readiness.title) · \(record.readiness.score)"
    }

    public var rewardSummary: String {
        guard !record.quest.attributeRewards.isEmpty else {
            return "暂无奖励"
        }

        return record.quest.attributeRewards.joined(separator: " / ")
    }

    public var storyContextLabel: String {
        "\(storyNodeTitle) · \(record.quest.difficulty)"
    }

    public var watchProgressLabel: String {
        let totalSteps = max(record.quest.watchSteps.count, record.executionLogs.count)
        return "\(record.executionLogs.count)/\(totalSteps) 步骤"
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

    public var completionSymbolName: String {
        guard let result = record.workoutResult else {
            return record.executionLogs.isEmpty ? "clock.circle.fill" : "arrow.triangle.2.circlepath.circle.fill"
        }

        switch result.completionState {
        case .completed:
            return "checkmark.circle.fill"
        case .downgraded:
            return "arrow.down.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }

    public var resultSummary: String {
        "\(completionLabel) · \(watchProgressLabel)"
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
        guard record.workoutResult != nil else {
            return record.quest.storyNode
        }

        guard let progression = record.storyProgression else {
            return record.quest.storyNode
        }

        return TrainingHistoryBuilder.storyNodeTitle(for: progression.currentNodeID)
    }

    public var storyReason: String {
        guard record.workoutResult != nil else {
            return "故事节点尚未更新。"
        }

        return record.storyProgression?.lastReason ?? "故事节点尚未更新。"
    }

    public var stepSummary: String {
        record.quest.watchSteps.map(\.instruction).joined(separator: " / ")
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
                    actionSymbolName: TrainingHistoryBuilder.actionSymbolName(for: log.action),
                    rpeLabel: "RPE \(log.rpe)",
                    note: log.note
                )
            }
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

    public static func actionSymbolName(for action: WatchAction) -> String {
        switch action {
        case .complete:
            return "checkmark.circle.fill"
        case .tooHeavy:
            return "exclamationmark.triangle.fill"
        case .skip:
            return "minus.circle.fill"
        case .rpeWithinTarget:
            return "scope"
        }
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
