public struct TodayCommandCenterSummary: Equatable, Sendable {
    public let readinessLabel: String
    public let readinessScoreLabel: String
    public let watchProgressLabel: String
    public let watchStatusLabel: String
    public let questContextLabel: String
    public let rewardSummary: String
    public let primaryActionLabel: String
    public let primaryActionSystemImage: String

    public init(
        readiness: ReadinessResult,
        quest: DailyQuest,
        executionLogCount: Int
    ) {
        let totalSteps = max(quest.watchSteps.count, executionLogCount)

        self.readinessLabel = "\(readiness.title) · \(readiness.score)"
        self.readinessScoreLabel = "\(readiness.score)"
        self.watchProgressLabel = "\(executionLogCount)/\(totalSteps)"
        self.watchStatusLabel = executionLogCount == 0
            ? "等待 Watch 回传"
            : "已收到 \(executionLogCount) 条 Watch 记录"
        self.questContextLabel = "\(quest.storyNode) · \(quest.difficulty)"
        self.rewardSummary = quest.attributeRewards.isEmpty
            ? "暂无奖励"
            : quest.attributeRewards.joined(separator: " / ")
        self.primaryActionLabel = "发送到 Watch"
        self.primaryActionSystemImage = "applewatch"
    }
}
