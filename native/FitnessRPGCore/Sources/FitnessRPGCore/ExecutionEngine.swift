public enum ExecutionEngine {
    public static func resolve(quest: DailyQuest, logs: [ExecutionLog]) -> WorkoutResult {
        let sortedLogs = logs.sorted { $0.order < $1.order }
        let heavyLog = sortedLogs.first { $0.action == .tooHeavy || $0.rpe >= 9 }
        let skippedEverything = !sortedLogs.isEmpty && sortedLogs.allSatisfy { $0.action == .skip }

        if let heavyLog {
            return WorkoutResult(
                completionState: .downgraded,
                safetyFeedback: "检测到过重信号：\(heavyLog.note)。本次结果记录为安全降阶。",
                nextRecommendation: "下一次同类任务降阶一档，并优先检查动作质量。",
                memoryDraft: "任务「\(quest.title)」中出现过重反馈：\(heavyLog.note)。后续推荐降低负荷。"
            )
        }

        if skippedEverything {
            return WorkoutResult(
                completionState: .skipped,
                safetyFeedback: "本次 Watch 步骤均跳过，保持恢复优先。",
                nextRecommendation: "下一次从恢复或轻量任务重新进入。",
                memoryDraft: "任务「\(quest.title)」被跳过，可能需要重新评估当天可训练性。"
            )
        }

        return WorkoutResult(
            completionState: .completed,
            safetyFeedback: "训练完成且未记录过重信号。",
            nextRecommendation: "保持当前节奏，下一次根据 readiness 决定是否推进。",
            memoryDraft: "任务「\(quest.title)」完成，奖励 \(quest.attributeRewards.joined(separator: " / "))。"
        )
    }
}
