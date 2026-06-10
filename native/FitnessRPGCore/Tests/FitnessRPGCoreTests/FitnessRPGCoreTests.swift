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
}
