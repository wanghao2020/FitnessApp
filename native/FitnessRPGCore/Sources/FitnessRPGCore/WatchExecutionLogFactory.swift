public enum WatchExecutionLogFactory {
    public static func log(action: WatchAction, step: WatchStep, order: Int) -> ExecutionLog {
        ExecutionLog(
            action: action,
            order: order,
            rpe: rpe(for: action),
            note: note(for: action, step: step)
        )
    }

    public static func completedLogs(for quest: DailyQuest) -> [ExecutionLog] {
        quest.watchSteps.enumerated().map { index, step in
            log(action: .complete, step: step, order: index + 1)
        }
    }

    private static func rpe(for action: WatchAction) -> Int {
        switch action {
        case .complete:
            return 6
        case .tooHeavy:
            return 9
        case .skip:
            return 2
        case .rpeWithinTarget:
            return 5
        }
    }

    private static func note(for action: WatchAction, step: WatchStep) -> String {
        switch action {
        case .complete:
            return "\(step.instruction) 完成"
        case .tooHeavy:
            return "\(step.instruction) 过重"
        case .skip:
            return "\(step.instruction) 跳过"
        case .rpeWithinTarget:
            return "\(step.instruction) RPE 在目标内"
        }
    }
}
