public struct TodayCommandCenterSummary: Equatable, Sendable {
    public let readinessLabel: String
    public let readinessScoreLabel: String
    public let watchProgressLabel: String
    public let watchStatusLabel: String
    public let questContextLabel: String
    public let rewardSummary: String
    public let primaryActionLabel: String
    public let primaryActionSystemImage: String
    public let nextFocusHeadline: String
    public let nextFocusDetail: String
    public let nextFocusSystemImage: String

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

        if executionLogCount <= 0 {
            self.nextFocusHeadline = "下一步：发送到 Watch"
            self.nextFocusDetail = "把 \(totalSteps) 个步骤同步到手表。"
            self.nextFocusSystemImage = "applewatch"
        } else if executionLogCount < totalSteps {
            self.nextFocusHeadline = "下一步：继续 Watch 执行"
            self.nextFocusDetail = "已回传 \(executionLogCount)/\(totalSteps) 步，完成剩余步骤后回到 iPhone。"
            self.nextFocusSystemImage = "figure.run"
        } else {
            self.nextFocusHeadline = "下一步：查看 History"
            self.nextFocusDetail = "今日 Watch 记录已收齐，查看结果与故事进度。"
            self.nextFocusSystemImage = "clock.arrow.circlepath"
        }
    }
}
