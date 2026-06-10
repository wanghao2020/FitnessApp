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
