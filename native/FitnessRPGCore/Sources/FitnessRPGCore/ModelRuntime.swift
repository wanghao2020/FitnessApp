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

public struct ModelRuntimePrompt: Codable, Equatable, Sendable {
    public let systemInstruction: String
    public let userMessage: String

    public init(systemInstruction: String, userMessage: String) {
        self.systemInstruction = systemInstruction
        self.userMessage = userMessage
    }

    public var rawText: String {
        """
        \(systemInstruction)

        \(userMessage)
        """
    }
}

public enum ModelRuntimePromptFormatter {
    public static func prompt(for context: ModelRuntimeContext) -> ModelRuntimePrompt {
        let systemInstruction = """
        你是 Fitness RPG 的本地教练模型。只返回 JSON，不要输出 Markdown 或额外解释。
        JSON schema: {"title":"短中文标题","body":"短中文教练文案","nextAction":"下一步动作"}
        必须遵守安全规则，不生成原始 HealthKit、WatchConnectivity 或个人敏感数据。
        如果 readiness 不是绿灯，必须降低强度、强调恢复或保守执行。
        """

        let watchStepLines = context.watchStepSummaries.isEmpty
            ? ["- 暂无 Watch steps"]
            : context.watchStepSummaries.map { "- \($0)" }
        let memoryLines = context.recentMemories.isEmpty
            ? ["Memory：暂无可用记忆"]
            : context.recentMemories.map { memory in
                "Memory：\(memory.date) · \(memory.completionLabel) · \(memory.storyNodeTitle) · \(memory.draft)"
            }
        let safetyLines = context.safetyRules.map { "- \($0)" }

        let userMessage = ([
            "Readiness：\(context.readinessTitle) \(context.readinessScore) · \(context.safetyGuidance)",
            "Quest：\(context.questTitle) · \(context.questDifficulty) · \(context.questObjective)",
            "Story：\(context.storyNode)",
            "Watch Steps："
        ] + watchStepLines + [
            "Memory："
        ] + memoryLines + [
            "Safety Rules："
        ] + safetyLines + [
            "Output：返回一个 JSON object，字段只能包含 title、body、nextAction。"
        ]).joined(separator: "\n")

        return ModelRuntimePrompt(systemInstruction: systemInstruction, userMessage: userMessage)
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

public enum ModelRuntimeProviderFailureStage: String, Codable, Equatable, Sendable {
    case adapter
    case parsing
}

public struct ModelRuntimeProviderDiagnostics: Codable, Equatable, Sendable {
    public let providerID: String
    public let displayName: String
    public let state: ModelRuntimeProviderState
    public let message: String
    public let resourceStatus: ModelRuntimeResourcePreflightResult?
    public let failureStage: ModelRuntimeProviderFailureStage?

    public init(
        providerID: String,
        displayName: String,
        state: ModelRuntimeProviderState,
        message: String,
        resourceStatus: ModelRuntimeResourcePreflightResult? = nil,
        failureStage: ModelRuntimeProviderFailureStage? = nil
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.state = state
        self.message = message
        self.resourceStatus = resourceStatus
        self.failureStage = failureStage
    }

    public init(
        providerID: String,
        displayName: String,
        resourceStatus: ModelRuntimeResourcePreflightResult
    ) {
        self.init(
            providerID: providerID,
            displayName: displayName,
            state: resourceStatus.state,
            message: resourceStatus.message,
            resourceStatus: resourceStatus
        )
    }
}

public struct ModelRuntimeDiagnosticsRow: Equatable, Identifiable, Sendable {
    public let title: String
    public let value: String
    public let systemImageName: String

    public var id: String {
        title
    }

    public init(title: String, value: String, systemImageName: String) {
        self.title = title
        self.value = value
        self.systemImageName = systemImageName
    }
}

public struct ModelRuntimeDiagnosticsSummary: Equatable, Sendable {
    public let headline: String
    public let detail: String
    public let systemImageName: String
    public let tintName: String
    public let rows: [ModelRuntimeDiagnosticsRow]

    public init(
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String,
        rows: [ModelRuntimeDiagnosticsRow]
    ) {
        self.headline = headline
        self.detail = detail
        self.systemImageName = systemImageName
        self.tintName = tintName
        self.rows = rows
    }
}

public enum ModelRuntimeDiagnosticsBuilder {
    public static func summary(
        providerDiagnostics: ModelRuntimeProviderDiagnostics,
        response: ModelRuntimeResponse?
    ) -> ModelRuntimeDiagnosticsSummary {
        let presentation = presentation(for: providerDiagnostics, response: response)
        let outputSource = response.map { sourceLabel(for: $0.source) } ?? "尚未运行"
        let validationIssues = response?.validation.issues.map(\.rawValue).joined(separator: " / ") ?? "尚未运行"
        var rows = [
            ModelRuntimeDiagnosticsRow(
                title: "Provider",
                value: providerDiagnostics.displayName,
                systemImageName: "shippingbox.fill"
            ),
            ModelRuntimeDiagnosticsRow(
                title: "状态",
                value: stateLabel(for: providerDiagnostics.state),
                systemImageName: "cpu.fill"
            ),
            ModelRuntimeDiagnosticsRow(
                title: "消息",
                value: providerDiagnostics.message,
                systemImageName: "text.bubble.fill"
            )
        ]

        if let resourceStatus = providerDiagnostics.resourceStatus {
            rows.append(ModelRuntimeDiagnosticsRow(
                title: "资源",
                value: resourceStatus.message,
                systemImageName: "externaldrive.fill"
            ))
            rows.append(contentsOf: resourceStatus.statuses.map { status in
                ModelRuntimeDiagnosticsRow(
                    title: "资源 · \(status.displayName)",
                    value: status.detail,
                    systemImageName: resourceSystemImageName(for: status.state)
                )
            })
        }

        if providerDiagnostics.failureStage == .parsing {
            rows.append(ModelRuntimeDiagnosticsRow(
                title: "解析",
                value: providerDiagnostics.message,
                systemImageName: "curlybraces.square.fill"
            ))
        }
        if providerDiagnostics.failureStage == .adapter {
            rows.append(ModelRuntimeDiagnosticsRow(
                title: "Adapter",
                value: providerDiagnostics.message,
                systemImageName: "wrench.and.screwdriver.fill"
            ))
        }

        rows.append(contentsOf: [
            ModelRuntimeDiagnosticsRow(
                title: "输出来源",
                value: outputSource,
                systemImageName: "doc.text.fill"
            ),
            ModelRuntimeDiagnosticsRow(
                title: "校验",
                value: validationIssues.isEmpty ? "通过" : validationIssues,
                systemImageName: "checkmark.shield.fill"
            ),
            ModelRuntimeDiagnosticsRow(
                title: "Fallback",
                value: "确定性安全文案可用",
                systemImageName: "arrow.uturn.backward.circle.fill"
            )
        ])

        if let response {
            rows.append(contentsOf: [
                ModelRuntimeDiagnosticsRow(
                    title: "草稿",
                    value: response.draft.title,
                    systemImageName: "sparkles"
                ),
                ModelRuntimeDiagnosticsRow(
                    title: "下一步",
                    value: response.draft.nextAction,
                    systemImageName: "arrow.right.circle.fill"
                )
            ])
        }

        return ModelRuntimeDiagnosticsSummary(
            headline: presentation.headline,
            detail: presentation.detail,
            systemImageName: presentation.systemImageName,
            tintName: presentation.tintName,
            rows: rows
        )
    }

    private static func presentation(
        for providerDiagnostics: ModelRuntimeProviderDiagnostics,
        response: ModelRuntimeResponse?
    ) -> (
        headline: String,
        detail: String,
        systemImageName: String,
        tintName: String
    ) {
        if response?.source == .deterministicFallback {
            return (
                "本地模型不可用，使用确定性 fallback",
                "\(providerDiagnostics.displayName)：\(providerDiagnostics.message)。安全校验仍然生效。",
                "exclamationmark.triangle.fill",
                "orange"
            )
        }

        switch providerDiagnostics.state {
        case .ready:
            return (
                "本地模型 Provider 就绪",
                "\(providerDiagnostics.displayName) 已接入 adapter 边界；输出会先经过安全校验。",
                "cpu.fill",
                "green"
            )
        case .unavailable:
            return (
                "本地模型 Provider 不可用",
                "\(providerDiagnostics.displayName)：\(providerDiagnostics.message)。将使用确定性 fallback。",
                "exclamationmark.triangle.fill",
                "orange"
            )
        case .failed:
            return (
                "本地模型 Provider 失败",
                "\(providerDiagnostics.displayName)：\(providerDiagnostics.message)。将使用确定性 fallback。",
                "xmark.octagon.fill",
                "red"
            )
        }
    }

    private static func stateLabel(for state: ModelRuntimeProviderState) -> String {
        switch state {
        case .ready:
            return "就绪"
        case .unavailable:
            return "不可用"
        case .failed:
            return "失败"
        }
    }

    private static func resourceSystemImageName(for state: ModelRuntimeResourceState) -> String {
        switch state {
        case .ready:
            return "checkmark.circle.fill"
        case .missing:
            return "xmark.circle.fill"
        case .invalid:
            return "exclamationmark.triangle.fill"
        }
    }

    private static func sourceLabel(for source: ModelRuntimeDraftSource) -> String {
        switch source {
        case .localModel:
            return "本地模型 provider"
        case .deterministicFallback:
            return "确定性 fallback"
        }
    }
}

public protocol ModelDraftProvider: Sendable {
    var diagnostics: ModelRuntimeProviderDiagnostics { get }

    func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft
}

public typealias ModelRuntimeDraftGenerator = @Sendable (ModelRuntimeContext) async throws -> ModelRuntimeDraft
public typealias ModelRuntimeTextGenerator = @Sendable (ModelRuntimeContext) async throws -> String

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
                message: error.localizedDescription,
                resourceStatus: diagnostics.resourceStatus,
                failureStage: failureStage(for: error)
            )
            return ModelRuntimeOrchestrator.response(
                context: context,
                modelDraft: nil,
                providerDiagnostics: failedDiagnostics,
                additionalIssues: [.providerFailed]
            )
        }
    }

    private static func failureStage(for error: Error) -> ModelRuntimeProviderFailureStage {
        if error is ModelRuntimeDraftParsingError {
            return .parsing
        }

        return .adapter
    }
}

public struct ResourceBackedModelDraftProvider: ModelDraftProvider {
    public let diagnostics: ModelRuntimeProviderDiagnostics
    private let draftGenerator: ModelRuntimeDraftGenerator?

    public init(
        resourceStatus: ModelRuntimeResourcePreflightResult,
        draftGenerator: ModelRuntimeDraftGenerator? = nil
    ) {
        self.draftGenerator = draftGenerator

        guard resourceStatus.state == .ready else {
            diagnostics = ModelRuntimeProviderDiagnostics(
                providerID: resourceStatus.providerID,
                displayName: resourceStatus.displayName,
                resourceStatus: resourceStatus
            )
            return
        }

        guard draftGenerator != nil else {
            diagnostics = ModelRuntimeProviderDiagnostics(
                providerID: resourceStatus.providerID,
                displayName: resourceStatus.displayName,
                state: .unavailable,
                message: "模型执行 adapter 未接入",
                resourceStatus: resourceStatus
            )
            return
        }

        diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: resourceStatus.providerID,
            displayName: resourceStatus.displayName,
            state: .ready,
            message: "模型资源与执行 adapter 已就绪",
            resourceStatus: resourceStatus
        )
    }

    public init(
        resourceStatus: ModelRuntimeResourcePreflightResult,
        textGenerator: @escaping ModelRuntimeTextGenerator
    ) {
        self.init(
            resourceStatus: resourceStatus,
            draftGenerator: { context in
                try ModelRuntimeDraftParser.draft(from: try await textGenerator(context))
            }
        )
    }

    public init(
        resourceStatus: ModelRuntimeResourcePreflightResult,
        optionalTextGenerator: ModelRuntimeTextGenerator?
    ) {
        guard let optionalTextGenerator else {
            self.init(resourceStatus: resourceStatus)
            return
        }

        self.init(resourceStatus: resourceStatus, textGenerator: optionalTextGenerator)
    }

    public func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft {
        guard diagnostics.state == .ready, let draftGenerator else {
            throw ResourceBackedModelProviderError(message: diagnostics.message)
        }

        return try await draftGenerator(context)
    }

    private struct ResourceBackedModelProviderError: Error, LocalizedError, Sendable {
        let message: String

        var errorDescription: String? {
            message
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
