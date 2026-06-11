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
