import Foundation

public struct TrainingHistoryDay: Equatable, Identifiable, Sendable {
    public let record: TrainingDayRecord

    public init(record: TrainingDayRecord) {
        self.record = record
    }

    public var id: String { "\(record.id)-\(record.updatedAt.timeIntervalSince1970)" }
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
