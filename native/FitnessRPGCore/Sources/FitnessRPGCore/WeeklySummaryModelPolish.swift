import Foundation

public enum WeeklySummaryModelContextBuilder {
    public static func context(summary: WeeklyTrainingSummary) -> ModelRuntimeContext {
        let conservative = requiresConservativeCopy(summary)
        let safetyRules = [
            "不得改写周训练统计数字。",
            "必须保留确定性安全提示：\(summary.safetyLabel)",
            "不得建议冲刺、PR、最大重量或力竭。",
            "模型只能润色标题、正文和下一步提示。"
        ]
        let questObjective = [
            summary.headline,
            summary.detail,
            summary.completionLabel,
            summary.readinessLabel,
            summary.safetyLabel,
            summary.nextWeekPlanTitle,
            summary.nextWeekActions.joined(separator: " / ")
        ].joined(separator: "\n")
        let promptPreview = [
            "Weekly：\(summary.dateRangeLabel)",
            "Summary：\(summary.headline)",
            "Stats：\(summary.completionLabel) · \(summary.readinessLabel)",
            "Safety：\(summary.safetyLabel)",
            "Next：\(summary.nextWeekPlanTitle) · \(summary.nextWeekActions.joined(separator: " / "))",
            "Rules：\(safetyRules.joined(separator: "；"))",
            "Output：返回短中文周回顾标题、正文和下一步提示。"
        ].joined(separator: "\n")

        return ModelRuntimeContext(
            readinessTitle: conservative ? "周回顾保守推进" : "周回顾稳定推进",
            readinessScore: conservative ? 65 : 85,
            readinessColor: conservative ? .yellow : .green,
            safetyGuidance: summary.safetyLabel,
            questTitle: "周训练总结",
            questObjective: questObjective,
            questDifficulty: conservative ? "保守" : "标准",
            storyNode: "History 周回顾",
            watchStepSummaries: summary.nextWeekActions,
            recentMemories: [],
            safetyRules: safetyRules,
            promptPreview: promptPreview
        )
    }

    private static func requiresConservativeCopy(_ summary: WeeklyTrainingSummary) -> Bool {
        let markerText = [
            summary.headline,
            summary.safetyLabel,
            summary.nextWeekPlanTitle
        ].joined(separator: " ")

        return markerText.contains("安全降阶")
            || markerText.contains("记录到降阶")
            || markerText.contains("包含恢复")
            || markerText.contains("保守")
            || markerText.contains("降阶巩固")
    }
}

public enum WeeklySummaryPolishRunner {
    public static func response(
        summary: WeeklyTrainingSummary,
        provider: any ModelDraftProvider
    ) async -> ModelRuntimeResponse {
        let context = WeeklySummaryModelContextBuilder.context(summary: summary)
        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        guard response.source == .localModel else {
            return ModelRuntimeResponse(
                draft: fallbackDraft(for: summary),
                source: .deterministicFallback,
                validation: response.validation,
                providerDiagnostics: response.providerDiagnostics
            )
        }

        return response
    }

    public static func fallbackDraft(for summary: WeeklyTrainingSummary) -> ModelRuntimeDraft {
        ModelRuntimeDraft(
            title: summary.headline,
            body: "\(summary.detail) \(summary.safetyLabel)",
            nextAction: summary.nextWeekPlanTitle
        )
    }
}

public struct WeeklySummaryPolishEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let summaryFingerprint: String
    public let dateRangeLabel: String
    public let draft: ModelRuntimeDraft
    public let providerID: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        summary: WeeklyTrainingSummary,
        draft: ModelRuntimeDraft,
        providerID: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let fingerprint = WeeklySummaryPolishCache.fingerprint(for: summary)
        self.id = fingerprint
        self.summaryFingerprint = fingerprint
        self.dateRangeLabel = summary.dateRangeLabel
        self.draft = draft
        self.providerID = providerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private init(
        id: String,
        summaryFingerprint: String,
        dateRangeLabel: String,
        draft: ModelRuntimeDraft,
        providerID: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.summaryFingerprint = summaryFingerprint
        self.dateRangeLabel = dateRangeLabel
        self.draft = draft
        self.providerID = providerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func replacing(
        draft: ModelRuntimeDraft,
        providerID: String,
        updatedAt: Date
    ) -> WeeklySummaryPolishEntry {
        WeeklySummaryPolishEntry(
            id: id,
            summaryFingerprint: summaryFingerprint,
            dateRangeLabel: dateRangeLabel,
            draft: draft,
            providerID: providerID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public var modelRuntimeResponse: ModelRuntimeResponse {
        ModelRuntimeResponse(
            draft: draft,
            source: .localModel,
            validation: ModelRuntimeValidationResult(issues: [])
        )
    }
}

public enum WeeklySummaryPolishCache {
    public static func fingerprint(for summary: WeeklyTrainingSummary) -> String {
        [
            summary.dateRangeLabel,
            summary.headline,
            summary.detail,
            summary.completionLabel,
            summary.readinessLabel,
            summary.safetyLabel,
            summary.nextWeekPlanTitle,
            summary.nextWeekActions.joined(separator: " / ")
        ].joined(separator: " | ")
    }

    public static func entry(
        for summary: WeeklyTrainingSummary,
        in entries: [WeeklySummaryPolishEntry]
    ) -> WeeklySummaryPolishEntry? {
        let fingerprint = fingerprint(for: summary)
        return entries.first { entry in
            entry.summaryFingerprint == fingerprint
        }
    }

    public static func upserting(
        response: ModelRuntimeResponse,
        summary: WeeklyTrainingSummary,
        in entries: [WeeklySummaryPolishEntry],
        date: Date = Date()
    ) -> [WeeklySummaryPolishEntry] {
        guard response.source == .localModel, response.validation.isValid else {
            return entries
        }

        let fingerprint = fingerprint(for: summary)
        let providerID = response.providerDiagnostics?.providerID ?? "local-model"
        let newEntry = WeeklySummaryPolishEntry(
            summary: summary,
            draft: response.draft,
            providerID: providerID,
            createdAt: date,
            updatedAt: date
        )
        var updatedEntries = entries
        guard let index = entries.firstIndex(where: { $0.summaryFingerprint == fingerprint }) else {
            updatedEntries.append(newEntry)
            return updatedEntries
        }

        updatedEntries[index] = entries[index].replacing(
            draft: response.draft,
            providerID: providerID,
            updatedAt: date
        )
        return updatedEntries
    }

    public static func removing(
        summary: WeeklyTrainingSummary,
        from entries: [WeeklySummaryPolishEntry]
    ) -> [WeeklySummaryPolishEntry] {
        let fingerprint = fingerprint(for: summary)
        return entries.filter { entry in
            entry.summaryFingerprint != fingerprint
        }
    }
}
