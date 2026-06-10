public enum ReadinessColor: String, Codable, Equatable, Sendable {
    case green
    case yellow
    case red
}

public struct HealthSummary: Codable, Equatable, Sendable {
    public let energy: Int
    public let recovery: Int
    public let strain: Int
    public let sleep: Int
    public let heartRateTrend: Int
    public let drivers: [String]

    public init(
        energy: Int,
        recovery: Int,
        strain: Int,
        sleep: Int,
        heartRateTrend: Int,
        drivers: [String]
    ) {
        self.energy = energy
        self.recovery = recovery
        self.strain = strain
        self.sleep = sleep
        self.heartRateTrend = heartRateTrend
        self.drivers = drivers
    }
}

public struct ReadinessResult: Codable, Equatable, Sendable {
    public let score: Int
    public let color: ReadinessColor
    public let title: String
    public let explanation: String
    public let safetyGuidance: String

    public init(
        score: Int,
        color: ReadinessColor,
        title: String,
        explanation: String,
        safetyGuidance: String
    ) {
        self.score = score
        self.color = color
        self.title = title
        self.explanation = explanation
        self.safetyGuidance = safetyGuidance
    }
}

public struct WatchStep: Codable, Equatable, Sendable {
    public let instruction: String
    public let target: String
    public let duration: String
    public let safetyNote: String

    public init(instruction: String, target: String, duration: String, safetyNote: String) {
        self.instruction = instruction
        self.target = target
        self.duration = duration
        self.safetyNote = safetyNote
    }
}

public struct DailyQuest: Codable, Equatable, Sendable {
    public let title: String
    public let objective: String
    public let difficulty: String
    public let attributeRewards: [String]
    public let storyNode: String
    public let watchSteps: [WatchStep]

    public init(
        title: String,
        objective: String,
        difficulty: String,
        attributeRewards: [String],
        storyNode: String,
        watchSteps: [WatchStep]
    ) {
        self.title = title
        self.objective = objective
        self.difficulty = difficulty
        self.attributeRewards = attributeRewards
        self.storyNode = storyNode
        self.watchSteps = watchSteps
    }
}

public enum WatchAction: String, Codable, Equatable, Sendable {
    case complete
    case tooHeavy
    case skip
    case rpeWithinTarget
}

public struct ExecutionLog: Codable, Equatable, Sendable {
    public let action: WatchAction
    public let order: Int
    public let rpe: Int
    public let note: String

    public init(action: WatchAction, order: Int, rpe: Int, note: String) {
        self.action = action
        self.order = order
        self.rpe = rpe
        self.note = note
    }
}

public enum CompletionState: String, Codable, Equatable, Sendable {
    case completed
    case downgraded
    case skipped
}

public struct WorkoutResult: Codable, Equatable, Sendable {
    public let completionState: CompletionState
    public let safetyFeedback: String
    public let nextRecommendation: String
    public let memoryDraft: String

    public init(
        completionState: CompletionState,
        safetyFeedback: String,
        nextRecommendation: String,
        memoryDraft: String
    ) {
        self.completionState = completionState
        self.safetyFeedback = safetyFeedback
        self.nextRecommendation = nextRecommendation
        self.memoryDraft = memoryDraft
    }
}

public enum ModelMode: String, Codable, Equatable, Sendable {
    case localFirst
    case hybrid
    case remoteDisabled
}

public struct ModelHarnessSnapshot: Codable, Equatable, Sendable {
    public let inputContext: [String]
    public let skillRules: [String]
    public let generationPath: [String]
    public let fallbackPolicy: String
    public let promptPreview: String

    public init(
        inputContext: [String],
        skillRules: [String],
        generationPath: [String],
        fallbackPolicy: String,
        promptPreview: String
    ) {
        self.inputContext = inputContext
        self.skillRules = skillRules
        self.generationPath = generationPath
        self.fallbackPolicy = fallbackPolicy
        self.promptPreview = promptPreview
    }
}

public enum MockHealthProfiles {
    public static let green = HealthSummary(
        energy: 82,
        recovery: 78,
        strain: 52,
        sleep: 84,
        heartRateTrend: 2,
        drivers: ["睡眠稳定", "恢复良好", "昨日负荷可控"]
    )

    public static let yellow = HealthSummary(
        energy: 61,
        recovery: 58,
        strain: 76,
        sleep: 66,
        heartRateTrend: 6,
        drivers: ["恢复偏低", "昨日负荷偏高", "建议降低强度"]
    )

    public static let red = HealthSummary(
        energy: 38,
        recovery: 34,
        strain: 82,
        sleep: 42,
        heartRateTrend: 14,
        drivers: ["睡眠不足", "心率趋势偏高", "恢复优先"]
    )

    public static let missing = HealthSummary(
        energy: 55,
        recovery: 55,
        strain: 55,
        sleep: 55,
        heartRateTrend: 0,
        drivers: ["HealthKit 数据缺失", "使用保守黄灯"]
    )
}
