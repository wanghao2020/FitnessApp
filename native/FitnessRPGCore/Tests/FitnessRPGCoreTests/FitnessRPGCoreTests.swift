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
        XCTAssertEqual(pendingDay.executionSummary, "尚未收到 Watch 执行结果。")
        XCTAssertEqual(pendingDay.memoryDraft, "Memory 草稿尚未生成。")
        XCTAssertEqual(pendingDay.storyNodeTitle, StoryNode.calibrationRune.title)
        XCTAssertEqual(inProgressDay.completionLabel, "同步中")
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

    private func makeHistoryRecord(
        date: String,
        readinessColor: ReadinessColor,
        completionState: CompletionState?,
        storyNode: StoryNode,
        updatedAt: Date
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
        let logs = completionState == nil
            ? []
            : [ExecutionLog(action: .complete, order: 1, rpe: 6, note: "完成")]
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
}
