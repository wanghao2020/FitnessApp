import XCTest
@testable import FitnessRPGCore

final class FitnessRPGCoreTests: XCTestCase {
    func testGreenReadinessProducesActiveTrainingQuest() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        XCTAssertEqual(readiness.color, .green)
        XCTAssertEqual(readiness.title, "共振稳定")

        let quest = QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
        XCTAssertEqual(quest.difficulty, "标准")
        XCTAssertTrue(quest.attributeRewards.contains("END +12"))
        XCTAssertEqual(quest.watchSteps.count, 3)
        XCTAssertTrue(quest.watchSteps[0].safetyNote.contains("热身"))
    }

    func testYellowReadinessProducesReducedIntensityQuest() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertEqual(readiness.title, "共振偏移")

        let quest = QuestEngine.quest(for: readiness, storyNode: "灰烬坡道")
        XCTAssertEqual(quest.difficulty, "降阶")
        XCTAssertTrue(quest.objective.contains("降低强度"))
        XCTAssertTrue(quest.attributeRewards.contains("CON +8"))
    }

    func testRedReadinessProducesRecoveryGuidance() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        XCTAssertEqual(readiness.color, .red)
        XCTAssertEqual(readiness.title, "营火修复")

        let quest = QuestEngine.quest(for: readiness, storyNode: "营火边缘")
        XCTAssertEqual(quest.difficulty, "恢复")
        XCTAssertTrue(quest.objective.contains("恢复"))
        XCTAssertFalse(quest.objective.contains("冲刺"))
    }

    func testMissingHealthKitDataUsesConservativeYellowReadiness() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.missing)

        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertEqual(readiness.title, "共振偏移")
        XCTAssertTrue(readiness.explanation.contains("HealthKit 数据缺失"))
        XCTAssertTrue(readiness.safetyGuidance.contains("降低强度"))
    }

    func testTooHeavyLogDowngradesResultAndHarness() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
        let logs = [
            ExecutionLog(action: .complete, order: 1, rpe: 6, note: "热身完成"),
            ExecutionLog(action: .tooHeavy, order: 2, rpe: 9, note: "深蹲过重")
        ]

        let result = ExecutionEngine.resolve(quest: quest, logs: logs)
        XCTAssertEqual(result.completionState, .downgraded)
        XCTAssertTrue(result.safetyFeedback.contains("过重"))
        XCTAssertTrue(result.nextRecommendation.contains("降阶"))
        XCTAssertTrue(result.memoryDraft.contains("深蹲过重"))

        let harness = ModelHarnessBuilder.snapshot(
            readiness: readiness,
            quest: quest,
            mode: .localFirst,
            logs: logs
        )
        XCTAssertTrue(harness.skillRules.joined(separator: " / ").contains("降阶"))
        XCTAssertTrue(harness.promptPreview.contains("过重"))
    }

    func testRemoteDisabledHarnessUsesDeterministicFallback() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: "灰烬坡道")
        let harness = ModelHarnessBuilder.snapshot(
            readiness: readiness,
            quest: quest,
            mode: .remoteDisabled,
            logs: []
        )

        XCTAssertTrue(harness.fallbackPolicy.contains("确定性模板"))
        XCTAssertFalse(harness.generationPath.joined(separator: " ").contains("远程"))
        XCTAssertTrue(harness.promptPreview.contains("禁用远程"))
    }

    func testModelRuntimeContextUsesNewestBoundedMemoryReviewEntries() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let entries = [
            makeMemoryReviewEntry(id: "oldest", date: "2026-06-07", createdAt: Date(timeIntervalSince1970: 1)),
            makeMemoryReviewEntry(id: "newest", date: "2026-06-10", createdAt: Date(timeIntervalSince1970: 4)),
            makeMemoryReviewEntry(id: "middle", date: "2026-06-09", createdAt: Date(timeIntervalSince1970: 3)),
            makeMemoryReviewEntry(id: "older", date: "2026-06-08", createdAt: Date(timeIntervalSince1970: 2))
        ]

        let context = ModelRuntimeContextBuilder.context(
            readiness: readiness,
            quest: quest,
            memories: entries,
            maxMemoryCount: 3
        )

        XCTAssertEqual(context.recentMemories.map(\.date), ["2026-06-10", "2026-06-09", "2026-06-08"])
        XCTAssertEqual(context.questTitle, quest.title)
        XCTAssertTrue(context.safetyRules.contains("Watch Payload 必须保持短句、目标、时长和安全提示。"))
        XCTAssertTrue(context.promptPreview.contains("Memory：2026-06-10"))
        XCTAssertFalse(context.promptPreview.contains("2026-06-07"))
    }

    func testModelRuntimeRejectsUnsafeHighIntensityDraftForRedReadiness() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let unsafeDraft = ModelRuntimeDraft(
            title: "冲刺 PR 挑战",
            body: "今天直接冲刺最大重量，突破 PR。",
            nextAction: "发送到 Watch"
        )

        let response = ModelRuntimeOrchestrator.response(context: context, modelDraft: unsafeDraft)

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.source, .deterministicFallback)
        XCTAssertTrue(response.validation.issues.contains(.unsafeIntensityForReadiness))
        XCTAssertTrue(response.draft.body.contains("恢复"))
        XCTAssertTrue(response.draft.nextAction.contains("发送到 Watch"))
    }

    func testModelRuntimeRequiresDowngradeGuidanceAfterOverloadMemory() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let context = ModelRuntimeContextBuilder.context(
            readiness: readiness,
            quest: quest,
            memories: [
                makeMemoryReviewEntry(
                    id: "downgrade",
                    date: "2026-06-10",
                    completionLabel: "已降阶",
                    draft: "过重信号触发安全降阶。",
                    createdAt: Date(timeIntervalSince1970: 10)
                )
            ]
        )
        let unsafeDraft = ModelRuntimeDraft(
            title: "继续标准训练",
            body: "今天保持标准训练节奏，完成全部力量循环。",
            nextAction: "发送到 Watch"
        )

        let validation = ModelOutputValidator.validate(draft: unsafeDraft, context: context)

        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.issues.contains(.missingDowngradeAfterOverload))
    }

    func testModelRuntimeRunnerAcceptsValidProviderDraft() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = FixedModelDraftProvider(draft: ModelRuntimeDraft(
            title: "本地模型建议",
            body: "保持稳定节奏，按 Watch 步骤完成今日训练。",
            nextAction: "发送到 Watch"
        ))

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertFalse(response.usedFallback)
        XCTAssertEqual(response.source, .localModel)
        XCTAssertEqual(response.providerDiagnostics?.state, .ready)
        XCTAssertEqual(response.draft.title, "本地模型建议")
        XCTAssertTrue(response.validation.isValid)
    }

    func testModelRuntimeRunnerFallsBackWhenProviderUnavailable() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = UnavailableModelDraftProvider(message: "模型文件未安装")

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.source, .deterministicFallback)
        XCTAssertEqual(response.providerDiagnostics?.state, .unavailable)
        XCTAssertEqual(response.providerDiagnostics?.message, "模型文件未安装")
        XCTAssertTrue(response.validation.issues.contains(.providerUnavailable))
        XCTAssertTrue(response.draft.body.contains("降阶"))
    }

    func testResourceBackedModelDraftProviderFallsBackWhenResourcesMissing() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 64_000_000
                )
            ]
        )
        let provider = ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.state, .unavailable)
        XCTAssertEqual(response.providerDiagnostics?.message, "缺少 Tokenizer：tokenizer.model")
        XCTAssertEqual(response.providerDiagnostics?.resourceStatus, resourceStatus)
        XCTAssertTrue(response.validation.issues.contains(.providerUnavailable))
    }

    func testResourceBackedModelDraftProviderFallsBackWhenAdapterMissingAfterResourcesReady() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let resourceStatus = readyGemmaResourceStatus
        let provider = ResourceBackedModelDraftProvider(resourceStatus: resourceStatus)

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.state, .unavailable)
        XCTAssertEqual(response.providerDiagnostics?.message, "模型执行 adapter 未接入")
        XCTAssertEqual(response.providerDiagnostics?.resourceStatus?.state, .ready)
        XCTAssertTrue(response.validation.issues.contains(.providerUnavailable))
    }

    func testResourceBackedModelDraftProviderUsesAdapterDraftWhenResourcesReady() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            draftGenerator: { _ in
                ModelRuntimeDraft(
                    title: "Gemma 草稿",
                    body: "保持稳定节奏，按 Watch 步骤完成今日训练。",
                    nextAction: "发送到 Watch"
                )
            }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertFalse(response.usedFallback)
        XCTAssertEqual(response.source, .localModel)
        XCTAssertEqual(response.providerDiagnostics?.state, .ready)
        XCTAssertEqual(response.providerDiagnostics?.message, "模型资源与执行 adapter 已就绪")
        XCTAssertEqual(response.draft.title, "Gemma 草稿")
    }

    func testModelRuntimeDraftParserParsesJSONObject() throws {
        let draft = try ModelRuntimeDraftParser.draft(from: """
        {
          "title": "本地模型建议",
          "body": "保持稳定节奏，按 Watch 步骤完成今日训练。",
          "nextAction": "发送到 Watch"
        }
        """)

        XCTAssertEqual(draft, ModelRuntimeDraft(
            title: "本地模型建议",
            body: "保持稳定节奏，按 Watch 步骤完成今日训练。",
            nextAction: "发送到 Watch"
        ))
    }

    func testModelRuntimeDraftParserParsesFencedJSONWithSnakeCaseNextAction() throws {
        let draft = try ModelRuntimeDraftParser.draft(from: """
        下面是今日建议：
        ```json
        {
          "title": "降阶校准",
          "body": "降低强度，优先动作质量和恢复观察。",
          "next_action": "发送到 Watch"
        }
        ```
        """)

        XCTAssertEqual(draft.nextAction, "发送到 Watch")
        XCTAssertEqual(draft.title, "降阶校准")
        XCTAssertEqual(draft.body, "降低强度，优先动作质量和恢复观察。")
    }

    func testModelRuntimeDraftParserUsesPlainTextFallback() throws {
        let draft = try ModelRuntimeDraftParser.draft(from: "今天保持稳定节奏，按 Watch 步骤完成训练。")

        XCTAssertEqual(draft.title, "本地模型建议")
        XCTAssertEqual(draft.body, "今天保持稳定节奏，按 Watch 步骤完成训练。")
        XCTAssertEqual(draft.nextAction, "发送到 Watch")
    }

    func testModelRuntimeDraftParserRejectsEmptyOutput() {
        XCTAssertThrowsError(try ModelRuntimeDraftParser.draft(from: "  \n\t ")) { error in
            XCTAssertEqual(error as? ModelRuntimeDraftParsingError, .emptyOutput)
        }
    }

    func testModelRuntimeDraftParserRejectsMissingBody() {
        XCTAssertThrowsError(
            try ModelRuntimeDraftParser.draft(from: #"{"title":"空输出","body":" ","nextAction":"发送到 Watch"}"#)
        ) { error in
            XCTAssertEqual(error as? ModelRuntimeDraftParsingError, .missingBody)
        }
    }

    func testResourceBackedModelDraftProviderParsesTextGeneratorOutput() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            textGenerator: { _ in
                """
                {
                  "title": "Gemma JSON 草稿",
                  "body": "保持稳定节奏，按 Watch 步骤完成今日训练。",
                  "nextAction": "发送到 Watch"
                }
                """
            }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertFalse(response.usedFallback)
        XCTAssertEqual(response.source, .localModel)
        XCTAssertEqual(response.draft.title, "Gemma JSON 草稿")
        XCTAssertEqual(response.providerDiagnostics?.state, .ready)
    }

    func testResourceBackedModelDraftProviderAcceptsOptionalTextGeneratorAdapter() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let unavailableProvider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            optionalTextGenerator: nil
        )
        let availableProvider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            optionalTextGenerator: { _ in "保持稳定节奏，按 Watch 步骤完成今日训练。" }
        )

        let unavailableResponse = await ModelRuntimeRunner.response(context: context, provider: unavailableProvider)
        let availableResponse = await ModelRuntimeRunner.response(context: context, provider: availableProvider)

        XCTAssertTrue(unavailableResponse.usedFallback)
        XCTAssertEqual(unavailableResponse.providerDiagnostics?.state, .unavailable)
        XCTAssertEqual(unavailableResponse.providerDiagnostics?.message, "模型执行 adapter 未接入")
        XCTAssertFalse(availableResponse.usedFallback)
        XCTAssertEqual(availableResponse.source, .localModel)
        XCTAssertEqual(availableResponse.providerDiagnostics?.state, .ready)
        XCTAssertEqual(availableResponse.draft.title, "本地模型建议")
    }

    func testResourceBackedModelDraftProviderClassifiesTextGeneratorFailuresAsAdapterFailures() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            textGenerator: { _ in
                throw TestModelRuntimeError(message: "LiteRT/Gemma SDK 尚未接入")
            }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.state, .failed)
        XCTAssertEqual(response.providerDiagnostics?.message, "LiteRT/Gemma SDK 尚未接入")
        XCTAssertEqual(response.providerDiagnostics?.failureStage, .adapter)
        XCTAssertTrue(response.validation.issues.contains(.providerFailed))
    }

    func testDeterministicModelDraftProviderProducesValidBoundedDraft() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = DeterministicModelDraftProvider()

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)

        XCTAssertFalse(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.providerID, "deterministic-local-stub")
        XCTAssertEqual(response.source, .localModel)
        XCTAssertTrue(response.draft.body.contains("恢复"))
        XCTAssertTrue(response.validation.isValid)
    }

    func testModelRuntimeDiagnosticsSummarizesReadyProviderWithoutRun() {
        let diagnostics = DeterministicModelDraftProvider().diagnostics

        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: diagnostics,
            response: nil
        )

        XCTAssertEqual(summary.headline, "本地模型 Provider 就绪")
        XCTAssertEqual(summary.tintName, "green")
        XCTAssertEqual(summary.systemImageName, "cpu.fill")
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "Provider",
            value: "Deterministic Local Stub",
            systemImageName: "shippingbox.fill"
        )))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "Fallback",
            value: "确定性安全文案可用",
            systemImageName: "arrow.uturn.backward.circle.fill"
        )))
    }

    func testModelRuntimeDiagnosticsSummarizesUnavailableFallbackResponse() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let diagnostics = UnavailableModelDraftProvider(message: "模型文件未安装").diagnostics
        let response = ModelRuntimeOrchestrator.response(
            context: context,
            modelDraft: nil,
            providerDiagnostics: diagnostics,
            additionalIssues: [.providerUnavailable]
        )

        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: diagnostics,
            response: response
        )

        XCTAssertEqual(summary.headline, "本地模型不可用，使用确定性 fallback")
        XCTAssertEqual(summary.tintName, "orange")
        XCTAssertEqual(summary.systemImageName, "exclamationmark.triangle.fill")
        XCTAssertTrue(summary.detail.contains("模型文件未安装"))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "输出来源",
            value: "确定性 fallback",
            systemImageName: "doc.text.fill"
        )))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "校验",
            value: "providerUnavailable",
            systemImageName: "checkmark.shield.fill"
        )))
    }

    func testModelRuntimeDiagnosticsIncludesRunDraftSummaryRows() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            draftGenerator: { _ in
                ModelRuntimeDraft(
                    title: "Gemma 草稿",
                    body: "保持稳定节奏，按 Watch 步骤完成今日训练。",
                    nextAction: "发送到 Watch"
                )
            }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)
        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: response.providerDiagnostics!,
            response: response
        )

        XCTAssertFalse(response.usedFallback)
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "草稿",
            value: "Gemma 草稿",
            systemImageName: "sparkles"
        )))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "下一步",
            value: "发送到 Watch",
            systemImageName: "arrow.right.circle.fill"
        )))
    }

    func testModelRuntimeDiagnosticsShowsParsingFailureReason() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            textGenerator: { _ in #"{"title":"空输出","body":" ","nextAction":"发送到 Watch"}"# }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)
        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: response.providerDiagnostics!,
            response: response
        )

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.failureStage, .parsing)
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "解析",
            value: "模型输出缺少正文",
            systemImageName: "curlybraces.square.fill"
        )))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "校验",
            value: "providerFailed",
            systemImageName: "checkmark.shield.fill"
        )))
    }

    func testModelRuntimeDiagnosticsShowsAdapterFailureReason() async {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let provider = ResourceBackedModelDraftProvider(
            resourceStatus: readyGemmaResourceStatus,
            draftGenerator: { _ in throw TestModelRuntimeError(message: "SDK 执行失败") }
        )

        let response = await ModelRuntimeRunner.response(context: context, provider: provider)
        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: response.providerDiagnostics!,
            response: response
        )

        XCTAssertTrue(response.usedFallback)
        XCTAssertEqual(response.providerDiagnostics?.failureStage, .adapter)
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "Adapter",
            value: "SDK 执行失败",
            systemImageName: "wrench.and.screwdriver.fill"
        )))
    }

    func testModelRuntimeDiagnosticsShowsValidatorFallbackReason() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
        let context = ModelRuntimeContextBuilder.context(readiness: readiness, quest: quest, memories: [])
        let diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            state: .ready,
            message: "模型资源与执行 adapter 已就绪"
        )
        let response = ModelRuntimeOrchestrator.response(
            context: context,
            modelDraft: ModelRuntimeDraft(
                title: "冲刺 PR",
                body: "今天直接冲刺最大重量，突破 PR。",
                nextAction: "发送到 Watch"
            ),
            providerDiagnostics: diagnostics
        )

        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: diagnostics,
            response: response
        )

        XCTAssertTrue(response.usedFallback)
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "校验",
            value: "unsafeIntensityForReadiness",
            systemImageName: "checkmark.shield.fill"
        )))
    }

    func testModelRuntimeResourcePreflightReportsReadyResources() {
        let result = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 64_000_000
                ),
                ModelRuntimeResourceObservation(
                    requirementID: "tokenizer",
                    fileName: "tokenizer.model",
                    byteSize: 16_384
                )
            ]
        )

        XCTAssertEqual(result.state, .ready)
        XCTAssertEqual(result.message, "2 个模型资源就绪")
        XCTAssertEqual(result.statuses.map(\.state), [.ready, .ready])

        let diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            resourceStatus: result
        )
        XCTAssertEqual(diagnostics.state, .ready)
        XCTAssertEqual(diagnostics.message, "2 个模型资源就绪")
    }

    func testModelRuntimeResourcePreflightReportsMissingTokenizer() {
        let result = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 64_000_000
                )
            ]
        )

        XCTAssertEqual(result.state, .unavailable)
        XCTAssertEqual(result.message, "缺少 Tokenizer：tokenizer.model")
        XCTAssertEqual(result.statuses.first { $0.requirementID == "tokenizer" }?.state, .missing)
    }

    func testModelRuntimeResourcePreflightReportsUndersizedModelFile() {
        let result = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 512
                ),
                ModelRuntimeResourceObservation(
                    requirementID: "tokenizer",
                    fileName: "tokenizer.model",
                    byteSize: 16_384
                )
            ]
        )

        XCTAssertEqual(result.state, .unavailable)
        XCTAssertEqual(result.message, "Model 文件过小：512 / 1024 bytes")
        XCTAssertEqual(result.statuses.first { $0.requirementID == "model" }?.state, .invalid)
    }

    func testModelRuntimeDiagnosticsIncludesResourcePreflightRow() {
        let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 64_000_000
                )
            ]
        )
        let diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            resourceStatus: resourceStatus
        )

        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: diagnostics,
            response: nil
        )

        XCTAssertEqual(summary.headline, "本地模型 Provider 不可用")
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "资源",
            value: "缺少 Tokenizer：tokenizer.model",
            systemImageName: "externaldrive.fill"
        )))
    }

    func testModelRuntimeDiagnosticsIncludesEachResourceStatusRow() {
        let resourceStatus = ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: ModelRuntimeResourceCatalog.gemmaE2B.requirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "ModelResources/gemma-e2b.task",
                    byteSize: 512
                )
            ]
        )
        let diagnostics = ModelRuntimeProviderDiagnostics(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            resourceStatus: resourceStatus
        )

        let summary = ModelRuntimeDiagnosticsBuilder.summary(
            providerDiagnostics: diagnostics,
            response: nil
        )

        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "资源 · Model 文件",
            value: "Model 文件过小：512 / 1024 bytes",
            systemImageName: "exclamationmark.triangle.fill"
        )))
        XCTAssertTrue(summary.rows.contains(ModelRuntimeDiagnosticsRow(
            title: "资源 · Tokenizer 文件",
            value: "缺少 Tokenizer 文件：ModelResources/tokenizer.model",
            systemImageName: "xmark.circle.fill"
        )))
    }

    func testModelRuntimeResourceObservationBuilderMatchesRequirementFileNames() {
        let observations = ModelRuntimeResourceObservationBuilder.observations(
            requirements: gemmaResourceRequirements,
            files: [
                ModelRuntimeResourceFileSnapshot(fileName: "gemma-e2b.task", byteSize: 64_000_000),
                ModelRuntimeResourceFileSnapshot(fileName: "tokenizer.model", byteSize: 16_384)
            ]
        )

        XCTAssertEqual(observations, [
            ModelRuntimeResourceObservation(
                requirementID: "model",
                fileName: "gemma-e2b.task",
                byteSize: 64_000_000
            ),
            ModelRuntimeResourceObservation(
                requirementID: "tokenizer",
                fileName: "tokenizer.model",
                byteSize: 16_384
            )
        ])
    }

    func testModelRuntimeResourceObservationBuilderIgnoresUnmatchedFiles() {
        let observations = ModelRuntimeResourceObservationBuilder.observations(
            requirements: gemmaResourceRequirements,
            files: [
                ModelRuntimeResourceFileSnapshot(fileName: "unused.bin", byteSize: 4_096),
                ModelRuntimeResourceFileSnapshot(fileName: "gemma-e2b.task", byteSize: 64_000_000)
            ]
        )

        XCTAssertEqual(observations, [
            ModelRuntimeResourceObservation(
                requirementID: "model",
                fileName: "gemma-e2b.task",
                byteSize: 64_000_000
            )
        ])
    }

    func testModelRuntimeResourceCatalogDefinesGemmaE2BBundleRequirements() {
        let profile = ModelRuntimeResourceCatalog.gemmaE2B

        XCTAssertEqual(profile.providerID, "gemma-e2b")
        XCTAssertEqual(profile.displayName, "Gemma E2B Local")
        XCTAssertEqual(profile.requirements, [
            ModelRuntimeResourceRequirement(
                id: "model",
                displayName: "Model 文件",
                kind: .model,
                fileName: "ModelResources/gemma-e2b.task",
                minimumByteSize: 1_024
            ),
            ModelRuntimeResourceRequirement(
                id: "tokenizer",
                displayName: "Tokenizer 文件",
                kind: .tokenizer,
                fileName: "ModelResources/tokenizer.model",
                minimumByteSize: 1
            )
        ])
    }

    func testAppLaunchOptionsOpenHistoryFromArguments() {
        XCTAssertEqual(
            AppLaunchOptions.initialDestination(arguments: ["FitnessRPG"]),
            .today
        )
        XCTAssertEqual(
            AppLaunchOptions.initialDestination(arguments: ["FitnessRPG", "--fitnessrpg-open-history"]),
            .history
        )
        XCTAssertEqual(
            AppLaunchOptions.initialDestination(arguments: ["FitnessRPG", "--fitnessrpg-open-latest-history-detail"]),
            .latestHistoryDetail
        )
        XCTAssertEqual(
            AppLaunchOptions.initialDestination(arguments: ["FitnessRPG", "--fitnessrpg-open-memory-review"]),
            .memoryReview
        )
    }

    func testAppLaunchOptionsShowDiagnosticsFromArguments() {
        XCTAssertFalse(
            AppLaunchOptions.showsDiagnostics(arguments: ["FitnessRPG"])
        )
        XCTAssertTrue(
            AppLaunchOptions.showsDiagnostics(arguments: ["FitnessRPG", "--fitnessrpg-show-diagnostics"])
        )
    }

    func testAppLaunchOptionsParseModelRuntimeDebugFixtureModes() {
        XCTAssertNil(
            AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ["FitnessRPG"])
        )
        XCTAssertEqual(
            AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ["FitnessRPG", "--fitnessrpg-model-fixture-ready"]),
            .ready
        )
        XCTAssertEqual(
            AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ["FitnessRPG", "--fitnessrpg-model-fixture-parsing-failure"]),
            .parsingFailure
        )
        XCTAssertEqual(
            AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ["FitnessRPG", "--fitnessrpg-model-fixture-adapter-failure"]),
            .adapterFailure
        )
        XCTAssertEqual(
            AppLaunchOptions.modelRuntimeDebugFixtureMode(arguments: ["FitnessRPG", "--fitnessrpg-model-fixture-validator-failure"]),
            .validatorFailure
        )
    }

    func testAppNavigationDisplayUsesLocalizedHistoryLabels() {
        XCTAssertEqual(AppNavigationDisplay.todayTitle, "Fitness RPG")
        XCTAssertEqual(AppNavigationDisplay.historyTitle, "训练历史")
        XCTAssertEqual(AppNavigationDisplay.historyEntryLabel, "历史")
        XCTAssertEqual(AppNavigationDisplay.historyEntrySystemImage, "clock.arrow.circlepath")
        XCTAssertEqual(AppNavigationDisplay.memoryReviewTitle, "记忆回顾")
        XCTAssertEqual(AppNavigationDisplay.memoryReviewEntryLabel, "记忆")
        XCTAssertEqual(AppNavigationDisplay.memoryReviewEntrySystemImage, "book.closed")
    }

    func testTodayCommandCenterSummaryBuildsHeroAndQuestLabels() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)

        let summary = TodayCommandCenterSummary(
            readiness: readiness,
            quest: quest,
            executionLogCount: 2
        )

        XCTAssertEqual(summary.readinessLabel, "\(readiness.title) · \(readiness.score)")
        XCTAssertEqual(summary.readinessScoreLabel, "\(readiness.score)")
        XCTAssertEqual(summary.watchProgressLabel, "2/3")
        XCTAssertEqual(summary.watchStatusLabel, "已收到 2 条 Watch 记录")
        XCTAssertEqual(summary.questContextLabel, "\(StoryNode.calibrationRune.title) · 降阶")
        XCTAssertEqual(summary.rewardSummary, "CON +8 / AGI +5 / INT +4")
        XCTAssertEqual(summary.primaryActionLabel, "发送到 Watch")
        XCTAssertEqual(summary.primaryActionSystemImage, "applewatch")
    }

    func testHealthySignalsMapToGreenLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 8.1,
                hrvSDNN: 68,
                restingHeartRate: 56,
                restingHeartRateBaseline: 58,
                activeEnergyKcal: 420,
                exerciseMinutes: 38,
                stepCount: 9200,
                workoutCount: 1
            )
        )

        XCTAssertGreaterThanOrEqual(summary.energy, 75)
        XCTAssertGreaterThanOrEqual(summary.recovery, 75)
        XCTAssertLessThan(summary.strain, 70)
        XCTAssertGreaterThanOrEqual(summary.sleep, 80)
        XCTAssertEqual(summary.heartRateTrend, 0)
        XCTAssertTrue(summary.drivers.contains("睡眠稳定"))
        XCTAssertTrue(summary.drivers.contains("恢复良好"))
    }

    func testHighStrainSignalsMapToYellowLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 6.6,
                hrvSDNN: 45,
                restingHeartRate: 64,
                restingHeartRateBaseline: 58,
                activeEnergyKcal: 960,
                exerciseMinutes: 96,
                stepCount: 16800,
                workoutCount: 2
            )
        )

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertGreaterThan(summary.strain, 72)
        XCTAssertTrue(summary.drivers.contains("昨日负荷偏高"))
    }

    func testPoorSleepAndElevatedHeartRateMapToRedLeaningSummary() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 4.2,
                hrvSDNN: 24,
                restingHeartRate: 76,
                restingHeartRateBaseline: 60,
                activeEnergyKcal: 280,
                exerciseMinutes: 18,
                stepCount: 4200,
                workoutCount: 0
            )
        )

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .red)
        XCTAssertLessThan(summary.sleep, 50)
        XCTAssertGreaterThanOrEqual(summary.heartRateTrend, 12)
        XCTAssertTrue(summary.drivers.contains("睡眠不足"))
        XCTAssertTrue(summary.drivers.contains("心率趋势偏高"))
    }

    func testMissingSignalsUseConservativeHealthKitFallback() {
        let summary = HealthSummaryMapper.summary(from: .missing)

        XCTAssertEqual(summary, MockHealthProfiles.missing)

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertTrue(readiness.explanation.contains("HealthKit 数据缺失"))
    }

    func testHealthDataSourceSnapshotDisplaysSuccessfulHealthKitLoad() {
        let snapshot = HealthDataSourceSnapshot(status: .healthKit)

        XCTAssertEqual(snapshot.sourceNote, "已读取 HealthKit 今日健康摘要。")
        XCTAssertEqual(snapshot.headline, "Apple Health 已接入")
        XCTAssertEqual(snapshot.detail, "今日 Readiness 已根据 HealthKit 睡眠、恢复和活动信号生成。")
        XCTAssertEqual(snapshot.systemImageName, "heart.text.square.fill")
        XCTAssertEqual(snapshot.tintName, "green")
        XCTAssertFalse(snapshot.shouldShowNotice)
    }

    func testHealthDataSourceSnapshotExplainsAuthorizationFallback() {
        let snapshot = HealthDataSourceSnapshot(status: .authorizationDenied)

        XCTAssertEqual(snapshot.sourceNote, "未完成 HealthKit 读取授权，已使用保守黄灯策略。")
        XCTAssertEqual(snapshot.headline, "HealthKit 权限未完成")
        XCTAssertTrue(snapshot.detail.contains("iOS 设置"))
        XCTAssertEqual(snapshot.systemImageName, "lock.shield.fill")
        XCTAssertEqual(snapshot.tintName, "orange")
        XCTAssertTrue(snapshot.shouldShowNotice)
    }

    func testHealthDataSourceSnapshotExplainsInsufficientDataFallback() {
        let snapshot = HealthDataSourceSnapshot(
            status: .insufficientData,
            missingSignalLabels: ["睡眠", "恢复"]
        )

        XCTAssertEqual(snapshot.sourceNote, "HealthKit 睡眠、恢复数据不足，已使用保守黄灯策略。")
        XCTAssertEqual(snapshot.headline, "HealthKit 数据不足")
        XCTAssertTrue(snapshot.detail.contains("睡眠、恢复"))
        XCTAssertEqual(snapshot.systemImageName, "waveform.path.ecg.rectangle")
        XCTAssertEqual(snapshot.tintName, "orange")
        XCTAssertTrue(snapshot.shouldShowNotice)
    }

    func testIncompleteSignalsUseConservativeHealthKitFallback() {
        let summary = HealthSummaryMapper.summary(
            from: HealthSignals(
                sleepHours: 8.0,
                hrvSDNN: nil,
                restingHeartRate: nil,
                restingHeartRateBaseline: nil,
                activeEnergyKcal: nil,
                exerciseMinutes: nil,
                stepCount: nil,
                workoutCount: nil
            )
        )

        XCTAssertEqual(summary, MockHealthProfiles.missing)

        let readiness = ReadinessEngine.evaluate(summary)
        XCTAssertEqual(readiness.color, .yellow)
        XCTAssertTrue(readiness.explanation.contains("HealthKit 数据缺失"))
    }

    func testQuestSyncPayloadRoundTripsThroughEnvelope() throws {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
        let generatedAt = Date(timeIntervalSince1970: 1_717_171_200)
        let encodedAt = Date(timeIntervalSince1970: 1_717_171_260)
        let payload = QuestSyncPayload(
            quest: quest,
            readinessColor: readiness.color,
            generatedAt: generatedAt
        )

        let envelope = try SyncEnvelope(
            kind: .quest,
            payload: payload,
            encodedAt: encodedAt
        )
        let dictionary = try envelope.toDictionary()
        let decodedEnvelope = try SyncEnvelope.fromDictionary(dictionary)
        let decodedPayload = try decodedEnvelope.decodePayload(
            QuestSyncPayload.self,
            expectedKind: .quest
        )

        XCTAssertEqual(decodedEnvelope.schemaVersion, SyncEnvelope.currentSchemaVersion)
        XCTAssertEqual(decodedEnvelope.kind, .quest)
        XCTAssertEqual(decodedEnvelope.encodedAt, encodedAt)
        XCTAssertEqual(decodedPayload, payload)
    }

    func testSyncEnvelopePreservesFractionalSecondDates() throws {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
        let generatedAt = Date(timeIntervalSince1970: 1_717_171_260.123456)
        let encodedAt = Date(timeIntervalSince1970: 1_717_171_260.654321)
        let payload = QuestSyncPayload(
            quest: quest,
            readinessColor: readiness.color,
            generatedAt: generatedAt
        )

        let envelope = try SyncEnvelope(
            kind: .quest,
            payload: payload,
            encodedAt: encodedAt
        )
        let decodedEnvelope = try SyncEnvelope.fromDictionary(try envelope.toDictionary())
        let decodedPayload = try decodedEnvelope.decodePayload(
            QuestSyncPayload.self,
            expectedKind: .quest
        )

        XCTAssertEqual(decodedEnvelope.encodedAt, encodedAt)
        XCTAssertEqual(decodedPayload.generatedAt, generatedAt)
    }

    func testExecutionLogSyncPayloadRoundTripsThroughEnvelope() throws {
        let logs = [
            ExecutionLog(action: .complete, order: 1, rpe: 5, note: "动态热身完成"),
            ExecutionLog(action: .tooHeavy, order: 2, rpe: 9, note: "力量循环过重")
        ]
        let payload = ExecutionLogSyncPayload(
            questTitle: "回声训练厅：力量共振",
            logs: logs,
            sentAt: Date(timeIntervalSince1970: 1_717_171_300)
        )

        let envelope = try SyncEnvelope(
            kind: .executionLogs,
            payload: payload,
            encodedAt: Date(timeIntervalSince1970: 1_717_171_360)
        )
        let decodedPayload = try SyncEnvelope
            .fromDictionary(try envelope.toDictionary())
            .decodePayload(ExecutionLogSyncPayload.self, expectedKind: .executionLogs)

        XCTAssertEqual(decodedPayload.questTitle, "回声训练厅：力量共振")
        XCTAssertEqual(decodedPayload.logs, logs)
        XCTAssertEqual(decodedPayload.sentAt, payload.sentAt)
    }

    func testWatchExecutionLogFactoryBuildsManualAndDebugCompletionLogs() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let firstStep = quest.watchSteps[0]

        let manualLog = WatchExecutionLogFactory.log(action: .tooHeavy, step: firstStep, order: 1)
        let debugLogs = WatchExecutionLogFactory.completedLogs(for: quest)

        XCTAssertEqual(manualLog, ExecutionLog(action: .tooHeavy, order: 1, rpe: 9, note: "\(firstStep.instruction) 过重"))
        XCTAssertEqual(debugLogs.count, quest.watchSteps.count)
        XCTAssertEqual(debugLogs.map(\.order), [1, 2, 3])
        XCTAssertTrue(debugLogs.allSatisfy { $0.action == .complete && $0.rpe == 6 })
        XCTAssertEqual(debugLogs[0].note, "\(quest.watchSteps[0].instruction) 完成")
    }

    func testSyncEnvelopeRejectsUnexpectedMessageKind() throws {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let payload = QuestSyncPayload(
            quest: QuestEngine.quest(for: readiness, storyNode: "回声训练厅"),
            readinessColor: readiness.color,
            generatedAt: Date(timeIntervalSince1970: 1_717_171_200)
        )
        let envelope = try SyncEnvelope(kind: .quest, payload: payload)

        XCTAssertThrowsError(
            try envelope.decodePayload(
                ExecutionLogSyncPayload.self,
                expectedKind: .executionLogs
            )
        ) { error in
            XCTAssertEqual(
                error as? SyncPayloadError,
                .unexpectedKind(expected: .executionLogs, actual: .quest)
            )
        }
    }

    func testSyncEnvelopeRejectsUnsupportedSchemaVersion() throws {
        let payload = ExecutionLogSyncPayload(
            questTitle: "灰烬坡道：降阶巡航",
            logs: [ExecutionLog(action: .skip, order: 1, rpe: 2, note: "今日恢复优先")],
            sentAt: Date(timeIntervalSince1970: 1_717_171_400)
        )
        let envelope = try SyncEnvelope(
            schemaVersion: 999,
            kind: .executionLogs,
            encodedAt: Date(timeIntervalSince1970: 1_717_171_460),
            payload: payload
        )

        XCTAssertThrowsError(
            try envelope.decodePayload(
                ExecutionLogSyncPayload.self,
                expectedKind: .executionLogs
            )
        ) { error in
            XCTAssertEqual(
                error as? SyncPayloadError,
                .unsupportedSchemaVersion(999)
            )
        }
    }

    func testTrainingDayRecordRoundTripsThroughJSON() throws {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: "破障试炼")
        let result = ExecutionEngine.resolve(
            quest: quest,
            logs: [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "热身完成")]
        )
        let progression = StoryProgression(
            currentChapterID: StoryChapter.mainLine.id,
            currentNodeID: StoryNode.mainTrial.id,
            completedNodeIDs: [StoryNode.mainTrial.id],
            lastOutcome: .advanced,
            lastReason: "绿色任务完成，主线推进。",
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        let record = TrainingDayRecord(
            date: "2026-06-10",
            readiness: readiness,
            quest: quest,
            executionLogs: [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "热身完成")],
            workoutResult: result,
            storyProgression: progression,
            createdAt: Date(timeIntervalSince1970: 1_717_171_900),
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let data = try SyncEnvelope.makeEncoder().encode(record)
        let decoded = try SyncEnvelope.makeDecoder().decode(TrainingDayRecord.self, from: data)

        XCTAssertEqual(decoded, record)
        XCTAssertEqual(decoded.id, "2026-06-10")
    }

    func testTrainingDayExecutionApplierCreatesIntermediateSnapshotBeforeFinalStep() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let record = TrainingDayRecord(
            date: "2026-06-11",
            readiness: readiness,
            quest: quest,
            storyProgression: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            createdAt: Date(timeIntervalSince1970: 2),
            updatedAt: Date(timeIntervalSince1970: 2)
        )
        let payload = ExecutionLogSyncPayload(
            questTitle: quest.title,
            logs: [ExecutionLog(action: .complete, order: 1, rpe: 5, note: "低强度热身完成")],
            sentAt: Date(timeIntervalSince1970: 3)
        )

        let application = TrainingDayExecutionApplier.apply(
            payload: payload,
            to: record,
            baselineProgression: .initial(updatedAt: Date(timeIntervalSince1970: 0)),
            receivedAt: Date(timeIntervalSince1970: 4)
        )

        XCTAssertEqual(application.status, .intermediateSnapshot)
        XCTAssertEqual(application.record.executionLogs, payload.logs)
        XCTAssertNil(application.record.workoutResult)
        XCTAssertNil(application.progression)
        XCTAssertNil(application.memory)
    }

    func testTrainingDayExecutionApplierFinalizesRecordAndMemoryWhenAllWatchStepsReturn() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let record = TrainingDayRecord(
            date: "2026-06-11",
            readiness: readiness,
            quest: quest,
            storyProgression: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            createdAt: Date(timeIntervalSince1970: 2),
            updatedAt: Date(timeIntervalSince1970: 2)
        )
        let logs = quest.watchSteps.enumerated().map { index, step in
            ExecutionLog(
                action: .complete,
                order: index + 1,
                rpe: 5,
                note: "\(step.instruction) 完成"
            )
        }
        let receivedAt = Date(timeIntervalSince1970: 4)
        let payload = ExecutionLogSyncPayload(
            questTitle: quest.title,
            logs: logs,
            sentAt: Date(timeIntervalSince1970: 3)
        )

        let application = TrainingDayExecutionApplier.apply(
            payload: payload,
            to: record,
            baselineProgression: .initial(updatedAt: Date(timeIntervalSince1970: 0)),
            receivedAt: receivedAt
        )

        XCTAssertEqual(application.status, .finalResult)
        XCTAssertEqual(application.record.executionLogs, logs)
        XCTAssertEqual(application.record.workoutResult?.completionState, .completed)
        XCTAssertEqual(application.record.updatedAt, receivedAt)
        XCTAssertEqual(application.progression?.currentNodeID, StoryNode.calibrationRune.id)
        XCTAssertEqual(application.progression?.updatedAt, receivedAt)
        XCTAssertEqual(application.memory?.date, record.date)
        XCTAssertEqual(application.memory?.questTitle, quest.title)
        XCTAssertEqual(application.memory?.draft, application.record.workoutResult?.memoryDraft)
    }

    func testStoryModelsAndMemoryEntryRoundTripThroughJSON() throws {
        let memory = MemoryEntry(
            date: "2026-06-10",
            questTitle: "回声训练厅：力量共振",
            completionState: .completed,
            storyNodeID: StoryNode.mainTrial.id,
            draft: "任务完成，力量属性成长。",
            createdAt: Date(timeIntervalSince1970: 1_717_172_100)
        )
        let progression = StoryProgression.initial(
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let chapterData = try SyncEnvelope.makeEncoder().encode(StoryChapter.mainLine)
        let nodeData = try SyncEnvelope.makeEncoder().encode(StoryNode.mainTrial)
        let progressionData = try SyncEnvelope.makeEncoder().encode(progression)
        let memoryData = try SyncEnvelope.makeEncoder().encode(memory)

        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryChapter.self, from: chapterData), .mainLine)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryNode.self, from: nodeData), .mainTrial)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(StoryProgression.self, from: progressionData), progression)
        XCTAssertEqual(try SyncEnvelope.makeDecoder().decode(MemoryEntry.self, from: memoryData), memory)
    }

    func testMemoryReviewEntriesSortNewestFirstAndUseTrainingRecordContext() {
        let olderMemory = MemoryEntry(
            id: "memory-older",
            date: "2026-06-09",
            questTitle: "灰烬坡道：降阶巡航",
            completionState: .downgraded,
            storyNodeID: StoryNode.safetyDowngrade.id,
            draft: "过重信号触发安全降阶。",
            createdAt: Date(timeIntervalSince1970: 1_717_171_000)
        )
        let newerMemory = MemoryEntry(
            id: "memory-newer",
            date: "2026-06-10",
            questTitle: "回声训练厅：力量共振",
            completionState: .completed,
            storyNodeID: StoryNode.mainTrial.id,
            draft: "主线训练完成，力量共振稳定。",
            createdAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        let fullLogs = [
            ExecutionLog(action: .complete, order: 1, rpe: 6, note: "动态热身 完成"),
            ExecutionLog(action: .complete, order: 2, rpe: 6, note: "力量循环 完成"),
            ExecutionLog(action: .complete, order: 3, rpe: 6, note: "冷却记录 完成")
        ]
        let matchingRecord = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: .completed,
            storyNode: .mainTrial,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_100),
            logs: fullLogs
        )

        let entries = MemoryReviewBuilder.entries(
            from: [olderMemory, newerMemory],
            records: [matchingRecord]
        )

        XCTAssertEqual(entries.map(\.id), ["memory-newer", "memory-older"])
        XCTAssertEqual(entries[0].date, "2026-06-10")
        XCTAssertEqual(entries[0].questTitle, "回声训练厅：力量共振")
        XCTAssertEqual(entries[0].completionLabel, "已完成")
        XCTAssertEqual(entries[0].completionSymbolName, "checkmark.circle.fill")
        XCTAssertEqual(entries[0].storyContextLabel, "\(StoryNode.mainTrial.title) · 标准")
        XCTAssertEqual(entries[0].sourceSummary, "已完成 · 3/3 步骤")
        XCTAssertEqual(entries[0].rewardSummary, "STR +10 / END +12 / CON +6")
        XCTAssertEqual(entries[0].draft, "主线训练完成，力量共振稳定。")
    }

    func testMemoryReviewEntriesKeepFallbackContextWithoutTrainingRecord() {
        let memory = MemoryEntry(
            id: "memory-unmatched",
            date: "2026-06-08",
            questTitle: "北境营地：恢复护符",
            completionState: .skipped,
            storyNodeID: StoryNode.recoveryCharm.id,
            draft: "恢复日保留体力，完成营地叙事。",
            createdAt: Date(timeIntervalSince1970: 1_717_170_000)
        )

        let entries = MemoryReviewBuilder.entries(from: [memory], records: [])

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].id, "memory-unmatched")
        XCTAssertEqual(entries[0].completionLabel, "已跳过")
        XCTAssertEqual(entries[0].completionSymbolName, "minus.circle.fill")
        XCTAssertEqual(entries[0].storyNodeTitle, StoryNode.recoveryCharm.title)
        XCTAssertEqual(entries[0].storyContextLabel, StoryNode.recoveryCharm.title)
        XCTAssertEqual(entries[0].sourceSummary, "已跳过 · 2026-06-08")
        XCTAssertEqual(entries[0].rewardSummary, "暂无训练奖励")
        XCTAssertEqual(entries[0].draft, "恢复日保留体力，完成营地叙事。")
    }

    func testStoryProgressionAdvancesMainLineForGreenCompletion() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let result = WorkoutResult(
            completionState: .completed,
            safetyFeedback: "训练完成且未记录过重信号。",
            nextRecommendation: "保持当前节奏。",
            memoryDraft: "主线推进。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.mainLine.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.mainTrial.id)
        XCTAssertEqual(progression.lastOutcome, .advanced)
        XCTAssertTrue(progression.completedNodeIDs.contains(StoryNode.mainTrial.id))
        XCTAssertTrue(progression.lastReason.contains("主线"))
    }

    func testStoryProgressionRecordsCalibrationForYellowCompletion() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let result = WorkoutResult(
            completionState: .completed,
            safetyFeedback: "技术训练完成。",
            nextRecommendation: "继续观察恢复。",
            memoryDraft: "校准推进。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.calibration.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.calibrationRune.id)
        XCTAssertEqual(progression.lastOutcome, .calibrated)
        XCTAssertTrue(progression.lastReason.contains("校准"))
    }

    func testStoryProgressionRecordsSafetyDowngrade() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.mainTrial.title)
        let result = WorkoutResult(
            completionState: .downgraded,
            safetyFeedback: "检测到过重信号。",
            nextRecommendation: "下一次降阶。",
            memoryDraft: "安全降阶。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.recovery.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.safetyDowngrade.id)
        XCTAssertEqual(progression.lastOutcome, .downgraded)
        XCTAssertFalse(progression.completedNodeIDs.contains(StoryNode.mainTrial.id))
    }

    func testStoryProgressionRecordsRecoveryForRedOrSkippedResult() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.recoveryCharm.title)
        let result = WorkoutResult(
            completionState: .skipped,
            safetyFeedback: "恢复优先。",
            nextRecommendation: "下一次重新评估。",
            memoryDraft: "恢复进度。"
        )

        let progression = StoryProgressionEngine.progression(
            after: .initial(updatedAt: Date(timeIntervalSince1970: 1)),
            readinessColor: readiness.color,
            quest: quest,
            result: result,
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(progression.currentChapterID, StoryChapter.recovery.id)
        XCTAssertEqual(progression.currentNodeID, StoryNode.recoveryCharm.id)
        XCTAssertEqual(progression.lastOutcome, .recovered)
        XCTAssertTrue(progression.lastReason.contains("恢复"))
    }

    func testTrainingHistoryDaysSortNewestFirstAndExposeCompletedDetail() {
        let older = makeHistoryRecord(
            date: "2026-06-09",
            readinessColor: .yellow,
            completionState: .downgraded,
            storyNode: .safetyDowngrade,
            updatedAt: Date(timeIntervalSince1970: 1_717_170_000)
        )
        let newer = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: .completed,
            storyNode: .mainTrial,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let history = TrainingHistoryBuilder.days(from: [older, newer])

        XCTAssertEqual(history.map(\.date), ["2026-06-10", "2026-06-09"])
        XCTAssertEqual(history[0].questTitle, "回声训练厅：力量共振")
        XCTAssertEqual(history[0].readinessTitle, "共振稳定")
        XCTAssertEqual(history[0].completionLabel, "已完成")
        XCTAssertEqual(history[0].memoryDraft, "2026-06-10 的 Memory 草稿")
        XCTAssertEqual(history[0].storyNodeTitle, StoryNode.mainTrial.title)
        XCTAssertTrue(history[0].stepSummary.contains("动态热身"))
    }

    func testTrainingHistoryDaySummarizesWatchProgressAndRows() {
        let logs = [
            ExecutionLog(action: .complete, order: 1, rpe: 6, note: "动态热身 完成"),
            ExecutionLog(action: .rpeWithinTarget, order: 2, rpe: 5, note: "力量循环 RPE 在目标内"),
            ExecutionLog(action: .skip, order: 3, rpe: 2, note: "冷却记录 跳过")
        ]
        let record = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: .completed,
            storyNode: .mainTrial,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000),
            logs: logs
        )

        let day = TrainingHistoryDay(record: record)

        XCTAssertEqual(day.watchProgressLabel, "3/3 步骤")
        XCTAssertEqual(day.resultSummary, "已完成 · 3/3 步骤")
        XCTAssertEqual(day.rewardSummary, "STR +10 / END +12 / CON +6")
        XCTAssertEqual(day.storyContextLabel, "\(StoryNode.mainTrial.title) · 标准")
        XCTAssertEqual(day.completionSymbolName, "checkmark.circle.fill")
        XCTAssertEqual(day.watchLogRows.map(\.stepTitle), ["动态热身", "力量循环", "冷却记录"])
        XCTAssertEqual(day.watchLogRows.map(\.actionLabel), ["完成", "RPE 达标", "跳过"])
        XCTAssertEqual(day.watchLogRows.map(\.actionSymbolName), ["checkmark.circle.fill", "scope", "minus.circle.fill"])
        XCTAssertEqual(day.watchLogRows.map(\.rpeLabel), ["RPE 6", "RPE 5", "RPE 2"])
        XCTAssertEqual(day.watchLogRows[1].note, "力量循环 RPE 在目标内")
    }

    func testTrainingHistoryDaysUseUpdatedAtTieBreakerForSameDate() {
        let earlierUpdate = Date(timeIntervalSince1970: 1_717_172_000)
        let laterUpdate = Date(timeIntervalSince1970: 1_717_172_600)
        let earlier = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .yellow,
            completionState: .downgraded,
            storyNode: .safetyDowngrade,
            updatedAt: earlierUpdate
        )
        let later = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: .completed,
            storyNode: .mainTrial,
            updatedAt: laterUpdate
        )

        let history = TrainingHistoryBuilder.days(from: [earlier, later])

        XCTAssertEqual(history.map(\.record.updatedAt), [laterUpdate, earlierUpdate])
        XCTAssertNotEqual(history[0].id, history[1].id)
    }

    func testTrainingHistoryDayIDDoesNotChangeWhenRecordIsUpdated() {
        var record = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .green,
            completionState: nil,
            storyNode: .mainTrial,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        let originalID = TrainingHistoryDay(record: record).id

        record.updatedAt = Date(timeIntervalSince1970: 1_717_172_600)

        XCTAssertEqual(TrainingHistoryDay(record: record).id, originalID)
    }

    func testTrainingHistoryDayShowsPendingAndIntermediateStates() {
        let pending = makeHistoryRecord(
            date: "2026-06-10",
            readinessColor: .yellow,
            completionState: nil,
            storyNode: .calibrationRune,
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        var inProgress = pending
        inProgress.executionLogs = [
            ExecutionLog(action: .complete, order: 1, rpe: 5, note: "热身完成")
        ]

        let pendingDay = TrainingHistoryDay(record: pending)
        let inProgressDay = TrainingHistoryDay(record: inProgress)

        XCTAssertEqual(pendingDay.completionLabel, "待执行")
        XCTAssertEqual(pendingDay.watchProgressLabel, "0/3 步骤")
        XCTAssertEqual(pendingDay.resultSummary, "待执行 · 0/3 步骤")
        XCTAssertEqual(pendingDay.executionSummary, "尚未收到 Watch 执行结果。")
        XCTAssertEqual(pendingDay.memoryDraft, "Memory 草稿尚未生成。")
        XCTAssertEqual(pendingDay.storyNodeTitle, StoryNode.calibrationRune.title)
        XCTAssertEqual(inProgressDay.completionLabel, "同步中")
        XCTAssertEqual(inProgressDay.watchProgressLabel, "1/3 步骤")
        XCTAssertEqual(inProgressDay.resultSummary, "同步中 · 1/3 步骤")
        XCTAssertEqual(inProgressDay.executionSummary, "已同步 1 / 3 个 Watch 步骤。")
    }

    func testTrainingHistoryDayUsesQuestStoryNodeForPendingProgressionMismatch() {
        let readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        let quest = QuestEngine.quest(for: readiness, storyNode: StoryNode.calibrationRune.title)
        let progression = StoryProgression.initial(
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )
        let record = TrainingDayRecord(
            date: "2026-06-10",
            readiness: readiness,
            quest: quest,
            workoutResult: nil,
            storyProgression: progression,
            createdAt: Date(timeIntervalSince1970: 1_717_171_900),
            updatedAt: Date(timeIntervalSince1970: 1_717_172_000)
        )

        let historyDay = TrainingHistoryDay(record: record)
        XCTAssertEqual(historyDay.storyNodeTitle, StoryNode.calibrationRune.title)
        XCTAssertEqual(historyDay.storyReason, "故事节点尚未更新。")
    }

    func testTrainingHistoryBuilderReturnsEmptyListForEmptyRecords() {
        XCTAssertEqual(TrainingHistoryBuilder.days(from: []), [])
    }

    func testWatchConnectivityDiagnosticsSummarizesUnsupportedState() {
        let snapshot = WatchConnectivityDiagnosticsSnapshot(
            isSupported: false,
            activationState: .notActivated,
            isPaired: false,
            isWatchAppInstalled: false,
            isReachable: false
        )

        let summary = snapshot.summary

        XCTAssertEqual(summary.headline, "WatchConnectivity 不可用")
        XCTAssertEqual(summary.detail, "当前设备无法建立 iPhone 与 Apple Watch 的同步会话。")
        XCTAssertEqual(summary.systemImageName, "exclamationmark.triangle.fill")
        XCTAssertEqual(summary.tintName, "orange")
        XCTAssertTrue(summary.rows.contains(WatchConnectivityDiagnosticsRow(
            title: "支持状态",
            value: "不可用",
            systemImageName: "iphone.slash"
        )))
    }

    func testWatchConnectivityDiagnosticsSummarizesReachableReadyState() {
        let sentAt = Date(timeIntervalSince1970: 1_717_172_000)
        let snapshot = WatchConnectivityDiagnosticsSnapshot(
            isSupported: true,
            activationState: .activated,
            isPaired: true,
            isWatchAppInstalled: true,
            isReachable: true,
            lastOutbound: WatchConnectivityTransferRecord(
                date: sentAt,
                transport: .message,
                detail: "回声训练厅：力量共振"
            )
        )

        let summary = snapshot.summary

        XCTAssertEqual(summary.headline, "Watch 可实时发送")
        XCTAssertEqual(summary.systemImageName, "applewatch.radiowaves.left.and.right")
        XCTAssertEqual(summary.tintName, "green")
        XCTAssertTrue(summary.detail.contains("sendMessage"))
        XCTAssertTrue(summary.rows.contains(WatchConnectivityDiagnosticsRow(
            title: "可达性",
            value: "实时可达",
            systemImageName: "dot.radiowaves.left.and.right"
        )))
        XCTAssertTrue(summary.rows.contains(WatchConnectivityDiagnosticsRow(
            title: "最近发送",
            value: "sendMessage · 回声训练厅：力量共振",
            systemImageName: "arrow.up.circle.fill"
        )))
    }

    func testWatchConnectivityDiagnosticsSummarizesQueuedReadyState() {
        let snapshot = WatchConnectivityDiagnosticsSnapshot(
            isSupported: true,
            activationState: .activated,
            isPaired: true,
            isWatchAppInstalled: true,
            isReachable: false,
            lastErrorText: "Watch 暂不可达"
        )

        let summary = snapshot.summary

        XCTAssertEqual(summary.headline, "Watch 已就绪，等待实时可达")
        XCTAssertEqual(summary.systemImageName, "tray.and.arrow.down.fill")
        XCTAssertEqual(summary.tintName, "blue")
        XCTAssertTrue(summary.detail.contains("transferUserInfo"))
        XCTAssertTrue(summary.rows.contains(WatchConnectivityDiagnosticsRow(
            title: "最近错误",
            value: "Watch 暂不可达",
            systemImageName: "exclamationmark.circle"
        )))
    }

    private func makeHistoryRecord(
        date: String,
        readinessColor: ReadinessColor,
        completionState: CompletionState?,
        storyNode: StoryNode,
        updatedAt: Date,
        logs customLogs: [ExecutionLog]? = nil
    ) -> TrainingDayRecord {
        let readiness: ReadinessResult
        switch readinessColor {
        case .green:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.green)
        case .yellow:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.yellow)
        case .red:
            readiness = ReadinessEngine.evaluate(MockHealthProfiles.red)
        }

        let quest = QuestEngine.quest(for: readiness, storyNode: storyNode.title)
        let logs = customLogs ?? (completionState == nil
            ? []
            : [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "完成")])
        let result = completionState.map { state in
            WorkoutResult(
                completionState: state,
                safetyFeedback: "\(date) safety",
                nextRecommendation: "\(date) recommendation",
                memoryDraft: "\(date) 的 Memory 草稿"
            )
        }
        let progression = StoryProgression(
            currentChapterID: storyNode.chapterID,
            currentNodeID: storyNode.id,
            completedNodeIDs: result == nil ? [] : [storyNode.id],
            lastOutcome: completionState == .downgraded ? .downgraded : .advanced,
            lastReason: "\(date) story reason",
            updatedAt: updatedAt
        )

        return TrainingDayRecord(
            date: date,
            readiness: readiness,
            quest: quest,
            executionLogs: logs,
            workoutResult: result,
            storyProgression: progression,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    private func makeMemoryReviewEntry(
        id: String,
        date: String,
        completionLabel: String = "已完成",
        draft: String = "训练完成，状态稳定。",
        createdAt: Date
    ) -> MemoryReviewEntry {
        MemoryReviewEntry(
            id: id,
            date: date,
            questTitle: "回声训练厅：力量共振",
            completionLabel: completionLabel,
            completionSymbolName: "checkmark.circle.fill",
            storyNodeTitle: StoryNode.mainTrial.title,
            storyContextLabel: "\(StoryNode.mainTrial.title) · 标准",
            sourceSummary: "\(completionLabel) · 3/3 步骤",
            rewardSummary: "STR +10 / END +12 / CON +6",
            draft: draft,
            createdAt: createdAt
        )
    }

    private var gemmaResourceRequirements: [ModelRuntimeResourceRequirement] {
        [
            ModelRuntimeResourceRequirement(
                id: "model",
                displayName: "Model",
                kind: .model,
                fileName: "gemma-e2b.task",
                minimumByteSize: 1_024
            ),
            ModelRuntimeResourceRequirement(
                id: "tokenizer",
                displayName: "Tokenizer",
                kind: .tokenizer,
                fileName: "tokenizer.model",
                minimumByteSize: 1
            )
        ]
    }

    private var readyGemmaResourceStatus: ModelRuntimeResourcePreflightResult {
        ModelRuntimeResourcePreflight.evaluate(
            providerID: "gemma-e2b",
            displayName: "Gemma E2B Local",
            requirements: gemmaResourceRequirements,
            observations: [
                ModelRuntimeResourceObservation(
                    requirementID: "model",
                    fileName: "gemma-e2b.task",
                    byteSize: 64_000_000
                ),
                ModelRuntimeResourceObservation(
                    requirementID: "tokenizer",
                    fileName: "tokenizer.model",
                    byteSize: 16_384
                )
            ]
        )
    }
}

private struct FixedModelDraftProvider: ModelDraftProvider {
    let draft: ModelRuntimeDraft

    var diagnostics: ModelRuntimeProviderDiagnostics {
        ModelRuntimeProviderDiagnostics(
            providerID: "fixed-test-provider",
            displayName: "Fixed Test Provider",
            state: .ready,
            message: "测试 provider 已就绪"
        )
    }

    func draft(for context: ModelRuntimeContext) async throws -> ModelRuntimeDraft {
        draft
    }
}

private struct TestModelRuntimeError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
