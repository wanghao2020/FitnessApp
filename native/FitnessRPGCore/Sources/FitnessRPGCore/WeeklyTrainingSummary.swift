public struct WeeklyTrainingSummary: Equatable, Sendable {
    public let dateRangeLabel: String
    public let headline: String
    public let detail: String
    public let completionLabel: String
    public let readinessLabel: String
    public let safetyLabel: String
    public let nextWeekPlanTitle: String
    public let nextWeekActions: [String]

    public init(
        dateRangeLabel: String,
        headline: String,
        detail: String,
        completionLabel: String,
        readinessLabel: String,
        safetyLabel: String,
        nextWeekPlanTitle: String,
        nextWeekActions: [String]
    ) {
        self.dateRangeLabel = dateRangeLabel
        self.headline = headline
        self.detail = detail
        self.completionLabel = completionLabel
        self.readinessLabel = readinessLabel
        self.safetyLabel = safetyLabel
        self.nextWeekPlanTitle = nextWeekPlanTitle
        self.nextWeekActions = nextWeekActions
    }
}

public enum WeeklyTrainingSummaryBuilder {
    public static func summary(from records: [TrainingDayRecord]) -> WeeklyTrainingSummary {
        let sortedRecords = records.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }

            return lhs.updatedAt < rhs.updatedAt
        }
        let counts = Counts(records: sortedRecords)

        guard !sortedRecords.isEmpty else {
            return WeeklyTrainingSummary(
                dateRangeLabel: "暂无训练周",
                headline: "本周还没有训练记录",
                detail: "完成 Watch 任务后会生成周回顾和下周计划。",
                completionLabel: completionLabel(for: counts),
                readinessLabel: readinessLabel(for: counts),
                safetyLabel: "先完成 Watch 任务，再生成周回顾。",
                nextWeekPlanTitle: "下周计划：建立基线",
                nextWeekActions: [
                    "完成 2 次低风险 Watch 任务",
                    "记录 RPE 和过重信号",
                    "周末回顾 Memory 草稿"
                ]
            )
        }

        return WeeklyTrainingSummary(
            dateRangeLabel: dateRangeLabel(for: sortedRecords),
            headline: headline(for: counts),
            detail: detail(for: counts),
            completionLabel: completionLabel(for: counts),
            readinessLabel: readinessLabel(for: counts),
            safetyLabel: safetyLabel(for: counts),
            nextWeekPlanTitle: nextWeekPlanTitle(for: counts),
            nextWeekActions: nextWeekActions(for: counts)
        )
    }

    private static func dateRangeLabel(for records: [TrainingDayRecord]) -> String {
        guard let firstDate = records.first?.date,
              let lastDate = records.last?.date else {
            return "暂无训练周"
        }

        return firstDate == lastDate ? firstDate : "\(firstDate) - \(lastDate)"
    }

    private static func headline(for counts: Counts) -> String {
        if counts.downgraded > 0 || counts.skipped > 0 || counts.red > 0 {
            return "本周以安全降阶为主"
        }

        if counts.completed > 0 && counts.pending == 0 {
            return "本周训练稳定完成"
        }

        return "本周训练仍在进行"
    }

    private static func detail(for counts: Counts) -> String {
        "已完成 \(counts.completed) 天，降阶 \(counts.downgraded) 天，跳过 \(counts.skipped) 天，待执行 \(counts.pending) 天。"
    }

    private static func completionLabel(for counts: Counts) -> String {
        "完成 \(counts.completed) · 降阶 \(counts.downgraded) · 跳过 \(counts.skipped) · 待执行 \(counts.pending)"
    }

    private static func readinessLabel(for counts: Counts) -> String {
        "绿 \(counts.green) · 黄 \(counts.yellow) · 红 \(counts.red)"
    }

    private static func safetyLabel(for counts: Counts) -> String {
        if counts.downgraded > 0 {
            return "记录到降阶信号，下周优先保守推进。"
        }

        if counts.skipped > 0 || counts.red > 0 {
            return "包含恢复或跳过日，下周保留恢复窗口。"
        }

        return "未记录过重或跳过信号。"
    }

    private static func nextWeekPlanTitle(for counts: Counts) -> String {
        if counts.skipped > 0 || counts.red > 0 {
            return "下周计划：保守重启"
        }

        if counts.downgraded > 0 || counts.yellow > counts.green {
            return "下周计划：降阶巩固"
        }

        return "下周计划：稳定推进"
    }

    private static func nextWeekActions(for counts: Counts) -> [String] {
        if counts.skipped > 0 || counts.red > 0 || counts.downgraded > 0 {
            return [
                "前 2 次训练降低一档强度",
                "任一动作 RPE >= 9 时立即降阶",
                "保留 1 天恢复或散步任务"
            ]
        }

        return [
            "保持 3 次标准 Watch 任务",
            "保留 1 次技术质量日",
            "周末生成 Memory 回顾"
        ]
    }

    private struct Counts {
        let completed: Int
        let downgraded: Int
        let skipped: Int
        let pending: Int
        let green: Int
        let yellow: Int
        let red: Int

        init(records: [TrainingDayRecord]) {
            completed = records.count { $0.workoutResult?.completionState == .completed }
            downgraded = records.count { $0.workoutResult?.completionState == .downgraded }
            skipped = records.count { $0.workoutResult?.completionState == .skipped }
            pending = records.count { $0.workoutResult == nil }
            green = records.count { $0.readiness.color == .green }
            yellow = records.count { $0.readiness.color == .yellow }
            red = records.count { $0.readiness.color == .red }
        }
    }
}
