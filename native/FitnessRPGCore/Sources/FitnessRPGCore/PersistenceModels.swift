import Foundation

public struct TrainingDayRecord: Codable, Equatable, Sendable {
    public let id: String
    public let date: String
    public var readiness: ReadinessResult
    public var quest: DailyQuest
    public var executionLogs: [ExecutionLog]
    public var workoutResult: WorkoutResult?
    public var storyProgression: StoryProgression?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String? = nil,
        date: String,
        readiness: ReadinessResult,
        quest: DailyQuest,
        executionLogs: [ExecutionLog] = [],
        workoutResult: WorkoutResult? = nil,
        storyProgression: StoryProgression? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id ?? date
        self.date = date
        self.readiness = readiness
        self.quest = quest
        self.executionLogs = executionLogs
        self.workoutResult = workoutResult
        self.storyProgression = storyProgression
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct StoryChapter: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let kind: Kind

    public enum Kind: String, Codable, Equatable, Sendable {
        case main
        case calibration
        case recovery
    }

    public init(id: String, title: String, kind: Kind) {
        self.id = id
        self.title = title
        self.kind = kind
    }

    public static let mainLine = StoryChapter(
        id: "chapter-1-echo-gate",
        title: "第一章 · 回声城门",
        kind: .main
    )

    public static let calibration = StoryChapter(
        id: "chapter-1-deep-hall",
        title: "第一章 · 深厅回廊",
        kind: .calibration
    )

    public static let recovery = StoryChapter(
        id: "chapter-1-north-camp",
        title: "第一章 · 北境营地",
        kind: .recovery
    )
}

public struct StoryNode: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let chapterID: String
    public let title: String
    public let summary: String

    public init(id: String, chapterID: String, title: String, summary: String) {
        self.id = id
        self.chapterID = chapterID
        self.title = title
        self.summary = summary
    }

    public static let mainTrial = StoryNode(
        id: "node-breakthrough-trial",
        chapterID: StoryChapter.mainLine.id,
        title: "破障试炼",
        summary: "共振稳定时推进主线。"
    )

    public static let calibrationRune = StoryNode(
        id: "node-calibration-rune",
        chapterID: StoryChapter.calibration.id,
        title: "校准符文",
        summary: "共振偏移时用技术质量推进。"
    )

    public static let recoveryCharm = StoryNode(
        id: "node-recovery-charm",
        chapterID: StoryChapter.recovery.id,
        title: "修复护符",
        summary: "恢复任务保护下一章训练。"
    )

    public static let safetyDowngrade = StoryNode(
        id: "node-safety-downgrade",
        chapterID: StoryChapter.recovery.id,
        title: "安全降阶",
        summary: "过重或高 RPE 反馈触发保护性进度。"
    )
}

public enum StoryProgressionOutcome: String, Codable, Equatable, Sendable {
    case advanced
    case calibrated
    case recovered
    case downgraded
}

public struct StoryProgression: Codable, Equatable, Sendable {
    public var currentChapterID: String
    public var currentNodeID: String
    public var completedNodeIDs: [String]
    public var lastOutcome: StoryProgressionOutcome
    public var lastReason: String
    public var updatedAt: Date

    public init(
        currentChapterID: String,
        currentNodeID: String,
        completedNodeIDs: [String] = [],
        lastOutcome: StoryProgressionOutcome,
        lastReason: String,
        updatedAt: Date = Date()
    ) {
        self.currentChapterID = currentChapterID
        self.currentNodeID = currentNodeID
        self.completedNodeIDs = completedNodeIDs
        self.lastOutcome = lastOutcome
        self.lastReason = lastReason
        self.updatedAt = updatedAt
    }

    public static func initial(updatedAt: Date = Date()) -> StoryProgression {
        StoryProgression(
            currentChapterID: StoryChapter.mainLine.id,
            currentNodeID: StoryNode.mainTrial.id,
            completedNodeIDs: [],
            lastOutcome: .advanced,
            lastReason: "故事从回声城门开启。",
            updatedAt: updatedAt
        )
    }
}

public struct MemoryEntry: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let date: String
    public let questTitle: String
    public let completionState: CompletionState
    public let storyNodeID: String
    public let draft: String
    public let createdAt: Date

    public init(
        id: String? = nil,
        date: String,
        questTitle: String,
        completionState: CompletionState,
        storyNodeID: String,
        draft: String,
        createdAt: Date = Date()
    ) {
        self.id = id ?? "\(date)-\(questTitle)-\(createdAt.timeIntervalSince1970)"
        self.date = date
        self.questTitle = questTitle
        self.completionState = completionState
        self.storyNodeID = storyNodeID
        self.draft = draft
        self.createdAt = createdAt
    }
}
