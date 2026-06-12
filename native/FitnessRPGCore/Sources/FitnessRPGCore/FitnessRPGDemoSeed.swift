import Foundation

public struct FitnessRPGDemoSeedPresentationEvidence: Equatable, Sendable {
    public let title: String
    public let value: String
    public let systemImageName: String

    public init(title: String, value: String, systemImageName: String) {
        self.title = title
        self.value = value
        self.systemImageName = systemImageName
    }
}

public enum FitnessRPGDemoSeedPresentationDestination: String, Equatable, Sendable {
    case today
    case history
    case memory
    case diagnostics
}

public struct FitnessRPGDemoSeedPresentationAction: Equatable, Sendable {
    public let title: String
    public let detail: String
    public let systemImageName: String
    public let destination: FitnessRPGDemoSeedPresentationDestination

    public init(
        title: String,
        detail: String,
        systemImageName: String,
        destination: FitnessRPGDemoSeedPresentationDestination
    ) {
        self.title = title
        self.detail = detail
        self.systemImageName = systemImageName
        self.destination = destination
    }
}

public struct FitnessRPGDemoSeedPresentation: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let systemImageName: String
    public let evidence: [FitnessRPGDemoSeedPresentationEvidence]
    public let actions: [FitnessRPGDemoSeedPresentationAction]

    public init(
        title: String,
        subtitle: String,
        systemImageName: String,
        evidence: [FitnessRPGDemoSeedPresentationEvidence],
        actions: [FitnessRPGDemoSeedPresentationAction]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImageName = systemImageName
        self.evidence = evidence
        self.actions = actions
    }
}

public struct FitnessRPGDemoSeed: Equatable, Sendable {
    public let todayRecordID: String
    public let trainingDays: [TrainingDayRecord]
    public let storyProgression: StoryProgression
    public let memoryEntries: [MemoryEntry]
    public let weeklySummaryPolishEntries: [WeeklySummaryPolishEntry]
    public let validationReportEntries: [RealDeviceValidationReportEntry]
    public let presentation: FitnessRPGDemoSeedPresentation

    public init(
        todayRecordID: String,
        trainingDays: [TrainingDayRecord],
        storyProgression: StoryProgression,
        memoryEntries: [MemoryEntry],
        weeklySummaryPolishEntries: [WeeklySummaryPolishEntry],
        validationReportEntries: [RealDeviceValidationReportEntry],
        presentation: FitnessRPGDemoSeedPresentation
    ) {
        self.todayRecordID = todayRecordID
        self.trainingDays = trainingDays
        self.storyProgression = storyProgression
        self.memoryEntries = memoryEntries
        self.weeklySummaryPolishEntries = weeklySummaryPolishEntries
        self.validationReportEntries = validationReportEntries
        self.presentation = presentation
    }

    public var todayRecord: TrainingDayRecord? {
        trainingDays.first { record in
            record.id == todayRecordID
        }
    }

    public static let showcase: FitnessRPGDemoSeed = {
        var progression = StoryProgression.initial(updatedAt: demoDate(day: 0, hour: 8))
        var records: [TrainingDayRecord] = []
        var memories: [MemoryEntry] = []

        let redReadiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let redQuest = QuestEngine.quest(
            for: redReadiness,
            storyNode: StoryProgressionEngine.displayNode(for: redReadiness.color).title
        )
        appendDemoDay(
            date: "2026-06-09",
            readiness: redReadiness,
            quest: redQuest,
            logs: skippedLogs(for: redQuest),
            previousProgression: &progression,
            records: &records,
            memories: &memories,
            dayOffset: 1
        )

        let yellowReadiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let yellowQuest = QuestEngine.quest(
            for: yellowReadiness,
            storyNode: StoryProgressionEngine.displayNode(for: yellowReadiness.color).title
        )
        appendDemoDay(
            date: "2026-06-10",
            readiness: yellowReadiness,
            quest: yellowQuest,
            logs: downgradedLogs(for: yellowQuest),
            previousProgression: &progression,
            records: &records,
            memories: &memories,
            dayOffset: 2
        )

        let greenReadiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let firstGreenQuest = QuestEngine.quest(
            for: greenReadiness,
            storyNode: StoryProgressionEngine.displayNode(for: greenReadiness.color).title
        )
        appendDemoDay(
            date: "2026-06-11",
            readiness: greenReadiness,
            quest: firstGreenQuest,
            logs: completedLogs(for: firstGreenQuest, rpe: 6),
            previousProgression: &progression,
            records: &records,
            memories: &memories,
            dayOffset: 3
        )

        let todayQuest = QuestEngine.quest(
            for: greenReadiness,
            storyNode: StoryProgressionEngine.displayNode(for: greenReadiness.color).title
        )
        appendDemoDay(
            date: "2026-06-12",
            readiness: greenReadiness,
            quest: todayQuest,
            logs: completedLogs(for: todayQuest, rpe: 7),
            previousProgression: &progression,
            records: &records,
            memories: &memories,
            dayOffset: 4
        )

        let summary = WeeklyTrainingSummaryBuilder.summary(from: records)
        let polishEntry = WeeklySummaryPolishEntry(
            summary: summary,
            draft: ModelRuntimeDraft(
                title: "演示周报：保守推进已闭环",
                body: "\(summary.detail) \(summary.safetyLabel) Demo Seed 已预置周回顾润色缓存，可直接验证 History 卡片。",
                nextAction: summary.nextWeekPlanTitle
            ),
            providerID: "demo-seed-local-model",
            createdAt: demoDate(day: 4, hour: 18),
            updatedAt: demoDate(day: 4, hour: 18)
        )

        return FitnessRPGDemoSeed(
            todayRecordID: "2026-06-12",
            trainingDays: records,
            storyProgression: progression,
            memoryEntries: memories,
            weeklySummaryPolishEntries: [polishEntry],
            validationReportEntries: validationReportEntries(),
            presentation: presentation()
        )
    }()

    private static func appendDemoDay(
        date: String,
        readiness: ReadinessResult,
        quest: DailyQuest,
        logs: [ExecutionLog],
        previousProgression: inout StoryProgression,
        records: inout [TrainingDayRecord],
        memories: inout [MemoryEntry],
        dayOffset: Int
    ) {
        let updatedAt = demoDate(day: dayOffset, hour: 17)
        let result = ExecutionEngine.resolve(quest: quest, logs: logs)
        let progression = StoryProgressionEngine.progression(
            after: previousProgression,
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: updatedAt
        )
        let record = TrainingDayRecord(
            date: date,
            readiness: readiness,
            quest: quest,
            executionLogs: logs,
            workoutResult: result,
            storyProgression: progression,
            createdAt: demoDate(day: dayOffset, hour: 8),
            updatedAt: updatedAt
        )
        let memory = MemoryEntry(
            id: "demo-memory-\(date)",
            date: date,
            questTitle: quest.title,
            completionState: result.completionState,
            storyNodeID: progression.currentNodeID,
            draft: result.memoryDraft,
            createdAt: updatedAt
        )

        records.append(record)
        memories.append(memory)
        previousProgression = progression
    }

    private static func completedLogs(for quest: DailyQuest, rpe: Int) -> [ExecutionLog] {
        quest.watchSteps.enumerated().map { index, step in
            ExecutionLog(
                action: .complete,
                order: index + 1,
                rpe: rpe,
                note: "\(step.instruction)完成，RPE \(rpe)。"
            )
        }
    }

    private static func downgradedLogs(for quest: DailyQuest) -> [ExecutionLog] {
        quest.watchSteps.enumerated().map { index, step in
            if index == 1 {
                return ExecutionLog(
                    action: .tooHeavy,
                    order: index + 1,
                    rpe: 9,
                    note: "\(step.instruction)出现过重信号。"
                )
            }

            return ExecutionLog(
                action: .complete,
                order: index + 1,
                rpe: 6,
                note: "\(step.instruction)按降阶节奏完成。"
            )
        }
    }

    private static func skippedLogs(for quest: DailyQuest) -> [ExecutionLog] {
        quest.watchSteps.enumerated().map { index, step in
            ExecutionLog(
                action: .skip,
                order: index + 1,
                rpe: 2,
                note: "\(step.instruction)跳过，保留恢复资源。"
            )
        }
    }

    private static func validationReportEntries() -> [RealDeviceValidationReportEntry] {
        [
            RealDeviceValidationReportEntry(
                headline: "Demo Seed 验证：端到端闭环可演示",
                body: [
                    "Fitness RPG Demo Seed 验证报告",
                    "总览：Today、History、Memory、周回顾润色和诊断归档已预置。",
                    "- [通过] Today：2026-06-12 今日任务含 Watch 执行结果。",
                    "- [通过] History：4 天记录覆盖完成、降阶、跳过。",
                    "- [通过] Memory：训练记忆草稿可回顾。"
                ].joined(separator: "\n"),
                createdAt: demoDate(day: 4, hour: 19)
            ),
            RealDeviceValidationReportEntry(
                headline: "Demo Seed 验证：模型缺失时仍可展示",
                body: [
                    "Fitness RPG Demo Seed 模型回退报告",
                    "总览：无需 LiteRT-LM 文件即可展示缓存周回顾。",
                    "- [通过] Weekly：本地模型润色缓存已命中。",
                    "- [通过] Runtime：demo provider 标记为 demo-seed-local-model。",
                    "- [待办] 真机：后续接入 HealthKit 与 WatchConnectivity 实测。"
                ].joined(separator: "\n"),
                createdAt: demoDate(day: 4, hour: 18)
            )
        ]
    }

    private static func presentation() -> FitnessRPGDemoSeedPresentation {
        FitnessRPGDemoSeedPresentation(
            title: "演示模式",
            subtitle: "已加载可重复的确定性数据，可直接展示 Today、History、Memory 与 Diagnostics 闭环。",
            systemImageName: "sparkles.rectangle.stack",
            evidence: [
                FitnessRPGDemoSeedPresentationEvidence(
                    title: "Today",
                    value: "2026-06-12 完成",
                    systemImageName: "checkmark.circle.fill"
                ),
                FitnessRPGDemoSeedPresentationEvidence(
                    title: "History",
                    value: "4 天训练记录",
                    systemImageName: "clock.arrow.circlepath"
                ),
                FitnessRPGDemoSeedPresentationEvidence(
                    title: "Memory",
                    value: "4 条记忆草稿",
                    systemImageName: "book.closed.fill"
                ),
                FitnessRPGDemoSeedPresentationEvidence(
                    title: "Diagnostics",
                    value: "2 条验证报告",
                    systemImageName: "waveform.path.ecg.rectangle"
                )
            ],
            actions: [
                FitnessRPGDemoSeedPresentationAction(
                    title: "Today",
                    detail: "查看今日任务",
                    systemImageName: "target",
                    destination: .today
                ),
                FitnessRPGDemoSeedPresentationAction(
                    title: "History",
                    detail: "查看周回顾",
                    systemImageName: "clock.arrow.circlepath",
                    destination: .history
                ),
                FitnessRPGDemoSeedPresentationAction(
                    title: "Memory",
                    detail: "查看记忆草稿",
                    systemImageName: "book.closed",
                    destination: .memory
                ),
                FitnessRPGDemoSeedPresentationAction(
                    title: "Diagnostics",
                    detail: "回到 Today 查看诊断",
                    systemImageName: "stethoscope",
                    destination: .diagnostics
                )
            ]
        )
    }

    private static func demoDate(day: Int, hour: Int) -> Date {
        let base = Date(timeIntervalSince1970: 1_780_000_000)
        return base
            .addingTimeInterval(TimeInterval(day) * 86_400)
            .addingTimeInterval(TimeInterval(hour) * 3_600)
    }
}
