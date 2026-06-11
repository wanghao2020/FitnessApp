import Foundation

public struct ModelRuntimeMemorySummary: Codable, Equatable, Sendable {
    public let date: String
    public let questTitle: String
    public let completionLabel: String
    public let storyNodeTitle: String
    public let draft: String

    public init(
        date: String,
        questTitle: String,
        completionLabel: String,
        storyNodeTitle: String,
        draft: String
    ) {
        self.date = date
        self.questTitle = questTitle
        self.completionLabel = completionLabel
        self.storyNodeTitle = storyNodeTitle
        self.draft = draft
    }
}

public struct ModelRuntimeContext: Codable, Equatable, Sendable {
    public let readinessTitle: String
    public let readinessScore: Int
    public let readinessColor: ReadinessColor
    public let safetyGuidance: String
    public let questTitle: String
    public let questObjective: String
    public let questDifficulty: String
    public let storyNode: String
    public let watchStepSummaries: [String]
    public let recentMemories: [ModelRuntimeMemorySummary]
    public let safetyRules: [String]
    public let promptPreview: String

    public init(
        readinessTitle: String,
        readinessScore: Int,
        readinessColor: ReadinessColor,
        safetyGuidance: String,
        questTitle: String,
        questObjective: String,
        questDifficulty: String,
        storyNode: String,
        watchStepSummaries: [String],
        recentMemories: [ModelRuntimeMemorySummary],
        safetyRules: [String],
        promptPreview: String
    ) {
        self.readinessTitle = readinessTitle
        self.readinessScore = readinessScore
        self.readinessColor = readinessColor
        self.safetyGuidance = safetyGuidance
        self.questTitle = questTitle
        self.questObjective = questObjective
        self.questDifficulty = questDifficulty
        self.storyNode = storyNode
        self.watchStepSummaries = watchStepSummaries
        self.recentMemories = recentMemories
        self.safetyRules = safetyRules
        self.promptPreview = promptPreview
    }
}

public enum ModelRuntimeContextBuilder {
    public static func context(
        readiness: ReadinessResult,
        quest: DailyQuest,
        memories: [MemoryReviewEntry],
        maxMemoryCount: Int = 3
    ) -> ModelRuntimeContext {
        let safeMemoryCount = max(0, maxMemoryCount)
        let recentMemories = memories
            .sorted { left, right in
                if left.createdAt == right.createdAt {
                    return left.id < right.id
                }

                return left.createdAt > right.createdAt
            }
            .prefix(safeMemoryCount)
            .map { entry in
                ModelRuntimeMemorySummary(
                    date: entry.date,
                    questTitle: entry.questTitle,
                    completionLabel: entry.completionLabel,
                    storyNodeTitle: entry.storyNodeTitle,
                    draft: entry.draft
                )
            }

        var safetyRules = [
            "安全优先：\(readiness.safetyGuidance)",
            "恢复也计入成长，不能被叙事惩罚。",
            "Watch Payload 必须保持短句、目标、时长和安全提示。"
        ]

        if readiness.color != .green {
            safetyRules.append("非绿灯状态必须降低强度或进入恢复任务。")
        }

        if recentMemories.contains(where: \.requiresDowngradeGuidance) {
            safetyRules.append("最近存在过重或降阶记忆，下一轮必须说明降阶或恢复策略。")
        }

        let watchStepSummaries = quest.watchSteps.map { step in
            "\(step.instruction) · \(step.target) · \(step.duration) · \(step.safetyNote)"
        }
        let memoryLines = recentMemories.isEmpty
            ? ["Memory：暂无可用记忆"]
            : recentMemories.map { memory in
                "Memory：\(memory.date) · \(memory.completionLabel) · \(memory.storyNodeTitle) · \(memory.draft)"
            }
        let promptPreview = ([
            "Readiness：\(readiness.title) \(readiness.score) · \(readiness.safetyGuidance)",
            "Quest：\(quest.title) · \(quest.objective)",
            "Story：\(quest.storyNode)",
            "Safety：\(safetyRules.joined(separator: "；"))"
        ] + memoryLines + [
            "Output：给出短中文教练文案、下一步动作，不生成原始 HealthKit 或 WatchConnectivity 数据。"
        ]).joined(separator: "\n")

        return ModelRuntimeContext(
            readinessTitle: readiness.title,
            readinessScore: readiness.score,
            readinessColor: readiness.color,
            safetyGuidance: readiness.safetyGuidance,
            questTitle: quest.title,
            questObjective: quest.objective,
            questDifficulty: quest.difficulty,
            storyNode: quest.storyNode,
            watchStepSummaries: watchStepSummaries,
            recentMemories: Array(recentMemories),
            safetyRules: safetyRules,
            promptPreview: promptPreview
        )
    }
}

public struct ModelRuntimeDraft: Codable, Equatable, Sendable {
    public let title: String
    public let body: String
    public let nextAction: String

    public init(title: String, body: String, nextAction: String) {
        self.title = title
        self.body = body
        self.nextAction = nextAction
    }
}

public enum ModelRuntimeValidationIssue: String, Codable, Equatable, Sendable {
    case unsafeIntensityForReadiness
    case missingDowngradeAfterOverload
    case emptyDraft
    case providerUnavailable
    case providerFailed
}

public struct ModelRuntimeValidationResult: Codable, Equatable, Sendable {
    public let issues: [ModelRuntimeValidationIssue]

    public init(issues: [ModelRuntimeValidationIssue]) {
        self.issues = issues
    }

    public var isValid: Bool {
        issues.isEmpty
    }
}

public enum ModelOutputValidator {
    public static func validate(
        draft: ModelRuntimeDraft,
        context: ModelRuntimeContext
    ) -> ModelRuntimeValidationResult {
        var issues: [ModelRuntimeValidationIssue] = []
        let combinedText = "\(draft.title) \(draft.body) \(draft.nextAction)"

        if combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyDraft)
        }

        if context.readinessColor != .green && containsUnsafeIntensityLanguage(combinedText) {
            issues.append(.unsafeIntensityForReadiness)
        }

        let requiresDowngrade = context.recentMemories.contains(where: \.requiresDowngradeGuidance)
        if requiresDowngrade && !containsDowngradeGuidance(combinedText) {
            issues.append(.missingDowngradeAfterOverload)
        }

        return ModelRuntimeValidationResult(issues: issues)
    }

    private static func containsUnsafeIntensityLanguage(_ text: String) -> Bool {
        ["冲刺", "最大重量", "PR", "破纪录", "HIIT", "力竭", "爆发"].contains { keyword in
            text.localizedCaseInsensitiveContains(keyword)
        }
    }

    private static func containsDowngradeGuidance(_ text: String) -> Bool {
        ["降阶", "降低强度", "恢复", "减量", "保守"].contains { keyword in
            text.localizedCaseInsensitiveContains(keyword)
        }
    }
}

public enum ModelRuntimeDraftSource: String, Codable, Equatable, Sendable {
    case localModel
    case deterministicFallback
}

public struct ModelRuntimeResponse: Codable, Equatable, Sendable {
    public let draft: ModelRuntimeDraft
    public let source: ModelRuntimeDraftSource
    public let validation: ModelRuntimeValidationResult
    public let providerDiagnostics: ModelRuntimeProviderDiagnostics?

    public init(
        draft: ModelRuntimeDraft,
        source: ModelRuntimeDraftSource,
        validation: ModelRuntimeValidationResult,
        providerDiagnostics: ModelRuntimeProviderDiagnostics? = nil
    ) {
        self.draft = draft
        self.source = source
        self.validation = validation
        self.providerDiagnostics = providerDiagnostics
    }

    public var usedFallback: Bool {
        source == .deterministicFallback
    }
}

public enum ModelRuntimeOrchestrator {
    public static func response(
        context: ModelRuntimeContext,
        modelDraft: ModelRuntimeDraft?,
        providerDiagnostics: ModelRuntimeProviderDiagnostics? = nil,
        additionalIssues: [ModelRuntimeValidationIssue] = []
    ) -> ModelRuntimeResponse {
        guard let modelDraft else {
            return fallbackResponse(
                context: context,
                validation: ModelRuntimeValidationResult(issues: additionalIssues),
                providerDiagnostics: providerDiagnostics
            )
        }

        let validation = ModelOutputValidator.validate(draft: modelDraft, context: context)
        let combinedValidation = ModelRuntimeValidationResult(issues: additionalIssues + validation.issues)
        guard combinedValidation.isValid else {
            return fallbackResponse(
                context: context,
                validation: combinedValidation,
                providerDiagnostics: providerDiagnostics
            )
        }

        return ModelRuntimeResponse(
            draft: modelDraft,
            source: .localModel,
            validation: combinedValidation,
            providerDiagnostics: providerDiagnostics
        )
    }

    public static func fallbackDraft(for context: ModelRuntimeContext) -> ModelRuntimeDraft {
        let body: String
        switch context.readinessColor {
        case .green:
            body = "\(context.questTitle) 保持稳定节奏，按 Watch 步骤完成训练，并保留安全反馈。"
        case .yellow:
            body = "\(context.questTitle) 使用降阶策略，降低强度，优先完成动作质量和恢复观察。"
        case .red:
            body = "\(context.questTitle) 转入恢复优先，保留轻量活动，把恢复也计入成长。"
        }

        return ModelRuntimeDraft(
            title: "确定性安全建议",
            body: body,
            nextAction: "发送到 Watch 前保留当前安全提示。"
        )
    }

    private static func fallbackResponse(
        context: ModelRuntimeContext,
        validation: ModelRuntimeValidationResult,
        providerDiagnostics: ModelRuntimeProviderDiagnostics?
    ) -> ModelRuntimeResponse {
        return ModelRuntimeResponse(
            draft: fallbackDraft(for: context),
            source: .deterministicFallback,
            validation: validation,
            providerDiagnostics: providerDiagnostics
        )
    }
}

public enum ModelRuntimeProviderState: String, Codable, Equatable, Sendable {
    case ready
    case unavailable
    case failed
}

public struct ModelRuntimeProviderDiagnostics: Codable, Equatable, Sendable {
    public let providerID: String
    public let displayName: String
    public let state: ModelRuntimeProviderState
    public let message: String

    public init(
        providerID: String,
        displayName: String,
        state: ModelRuntimeProviderState,
        message: String
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.state = state
        self.message = message
    }
}

public protocol ModelDraftProvider: Sendable {
    var diagnostics: ModelRuntimeProviderDiagnostics { get }

    func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft
}

public enum ModelRuntimeRunner {
    public static func response(
        context: ModelRuntimeContext,
        provider: any ModelDraftProvider
    ) async -> ModelRuntimeResponse {
        let diagnostics = provider.diagnostics

        guard diagnostics.state == .ready else {
            return ModelRuntimeOrchestrator.response(
                context: context,
                modelDraft: nil,
                providerDiagnostics: diagnostics,
                additionalIssues: [.providerUnavailable]
            )
        }

        do {
            let draft = try await provider.draft(for: context)
            return ModelRuntimeOrchestrator.response(
                context: context,
                modelDraft: draft,
                providerDiagnostics: diagnostics
            )
        } catch {
            let failedDiagnostics = ModelRuntimeProviderDiagnostics(
                providerID: diagnostics.providerID,
                displayName: diagnostics.displayName,
                state: .failed,
                message: error.localizedDescription
            )
            return ModelRuntimeOrchestrator.response(
                context: context,
                modelDraft: nil,
                providerDiagnostics: failedDiagnostics,
                additionalIssues: [.providerFailed]
            )
        }
    }
}

public struct DeterministicModelDraftProvider: ModelDraftProvider {
    public let diagnostics: ModelRuntimeProviderDiagnostics

    public init(
        diagnostics: ModelRuntimeProviderDiagnostics = ModelRuntimeProviderDiagnostics(
            providerID: "deterministic-local-stub",
            displayName: "Deterministic Local Stub",
            state: .ready,
            message: "占位 provider 已就绪"
        )
    ) {
        self.diagnostics = diagnostics
    }

    public func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft {
        let title: String
        let body: String

        switch context.readinessColor {
        case .green:
            title = "本地草稿：稳定推进"
            body = "\(context.questTitle) 可以保持稳定节奏，按 Watch 步骤执行，并记录 RPE。"
        case .yellow:
            title = "本地草稿：降阶校准"
            body = "\(context.questTitle) 采用降阶策略，降低强度，优先动作质量和恢复观察。"
        case .red:
            title = "本地草稿：恢复优先"
            body = "\(context.questTitle) 以恢复为主，保留轻量活动，把恢复也计入成长。"
        }

        return ModelRuntimeDraft(
            title: title,
            body: body,
            nextAction: "发送到 Watch"
        )
    }
}

public struct UnavailableModelDraftProvider: ModelDraftProvider {
    public let diagnostics: ModelRuntimeProviderDiagnostics

    public init(
        providerID: String = "local-model-unavailable",
        displayName: String = "Local Model Unavailable",
        message: String
    ) {
        diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: providerID,
            displayName: displayName,
            state: .unavailable,
            message: message
        )
    }

    public func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft {
        throw UnavailableProviderError(message: diagnostics.message)
    }

    private struct UnavailableProviderError: Error, LocalizedError {
        let message: String

        var errorDescription: String? {
            message
        }
    }
}

private extension ModelRuntimeMemorySummary {
    var requiresDowngradeGuidance: Bool {
        completionLabel.contains("降阶")
            || draft.contains("过重")
            || draft.contains("降阶")
            || draft.localizedCaseInsensitiveContains("RPE 9")
    }
}
