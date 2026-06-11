import Foundation

public struct MemoryReviewEntry: Equatable, Identifiable, Sendable {
    public let id: String
    public let date: String
    public let questTitle: String
    public let completionLabel: String
    public let completionSymbolName: String
    public let storyNodeTitle: String
    public let storyContextLabel: String
    public let sourceSummary: String
    public let rewardSummary: String
    public let draft: String
    public let createdAt: Date

    public init(
        id: String,
        date: String,
        questTitle: String,
        completionLabel: String,
        completionSymbolName: String,
        storyNodeTitle: String,
        storyContextLabel: String,
        sourceSummary: String,
        rewardSummary: String,
        draft: String,
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.questTitle = questTitle
        self.completionLabel = completionLabel
        self.completionSymbolName = completionSymbolName
        self.storyNodeTitle = storyNodeTitle
        self.storyContextLabel = storyContextLabel
        self.sourceSummary = sourceSummary
        self.rewardSummary = rewardSummary
        self.draft = draft
        self.createdAt = createdAt
    }
}

public enum MemoryReviewBuilder {
    public static func entries(
        from memories: [MemoryEntry],
        records: [TrainingDayRecord]
    ) -> [MemoryReviewEntry] {
        memories
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id < rhs.id
                }

                return lhs.createdAt > rhs.createdAt
            }
            .map { memory in
                let record = records.first { record in
                    record.date == memory.date && record.quest.title == memory.questTitle
                }
                let historyDay = record.map(TrainingHistoryDay.init(record:))
                let storyNodeTitle = TrainingHistoryBuilder.storyNodeTitle(for: memory.storyNodeID)
                let completionLabel = label(for: memory.completionState)

                return MemoryReviewEntry(
                    id: memory.id,
                    date: memory.date,
                    questTitle: memory.questTitle,
                    completionLabel: completionLabel,
                    completionSymbolName: symbolName(for: memory.completionState),
                    storyNodeTitle: storyNodeTitle,
                    storyContextLabel: historyDay?.storyContextLabel ?? storyNodeTitle,
                    sourceSummary: historyDay.map { "\(completionLabel) · \($0.watchProgressLabel)" }
                        ?? "\(completionLabel) · \(memory.date)",
                    rewardSummary: historyDay?.rewardSummary ?? "暂无训练奖励",
                    draft: memory.draft,
                    createdAt: memory.createdAt
                )
            }
    }

    private static func label(for state: CompletionState) -> String {
        switch state {
        case .completed:
            return "已完成"
        case .downgraded:
            return "已降阶"
        case .skipped:
            return "已跳过"
        }
    }

    private static func symbolName(for state: CompletionState) -> String {
        switch state {
        case .completed:
            return "checkmark.circle.fill"
        case .downgraded:
            return "arrow.down.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }
}
