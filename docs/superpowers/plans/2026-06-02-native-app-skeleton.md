# Native App Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first native iPhone / watchOS skeleton for Fitness RPG with a testable shared Swift core and SwiftUI source scaffolds.

**Architecture:** Put all compiled product logic in `native/FitnessRPGCore`, a Swift Package with deterministic models, mock health profiles, and engines. Keep iPhone and watchOS app files under `native/AppSources/` as source scaffolds for future Xcode targets, importing the shared core but not compiled by this package yet.

**Tech Stack:** Swift 6, Swift Package Manager, XCTest, SwiftUI source scaffolds, existing browser prototype contract tests for regression checks.

---

## File Structure

- Create `native/FitnessRPGCore/Package.swift`: Swift Package manifest for the compiled core and tests.
- Create `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift`: shared enums, structs, and mock health profiles.
- Create `native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift`: readiness, quest, execution, and model harness engines.
- Create `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`: deterministic tests for native product logic.
- Create `native/AppSources/iOS/FitnessRPGApp.swift`: iPhone app entry placeholder for a future Xcode target.
- Create `native/AppSources/iOS/TodayCommandCenterView.swift`: iPhone command center SwiftUI scaffold.
- Create `native/AppSources/iOS/ReadinessPanel.swift`: iPhone readiness and safety panel.
- Create `native/AppSources/iOS/QuestPanel.swift`: iPhone daily quest panel.
- Create `native/AppSources/iOS/ModelHarnessPanel.swift`: iPhone local model harness panel.
- Create `native/AppSources/watchOS/FitnessRPGWatchApp.swift`: watchOS app entry placeholder for a future Xcode target.
- Create `native/AppSources/watchOS/WatchExecutionView.swift`: Watch execution SwiftUI scaffold.
- Create `native/README.md`: native architecture and future target setup notes.

---

### Task 1: Add Shared Core Package and Failing Tests

**Files:**
- Create: `native/FitnessRPGCore/Package.swift`
- Create: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: Create the Swift Package manifest**

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FitnessRPGCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FitnessRPGCore",
            targets: ["FitnessRPGCore"]
        )
    ],
    targets: [
        .target(
            name: "FitnessRPGCore"
        ),
        .testTarget(
            name: "FitnessRPGCoreTests",
            dependencies: ["FitnessRPGCore"]
        )
    ]
)
```

- [ ] **Step 2: Write failing core behavior tests**

```swift
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
}
```

- [ ] **Step 3: Run tests and verify they fail before implementation**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: FAIL with compile errors for missing symbols such as `ReadinessEngine`, `MockHealthProfiles`, `QuestEngine`, `ExecutionLog`, and `ModelHarnessBuilder`.

- [ ] **Step 4: Commit the failing test package scaffold**

```bash
git add native/FitnessRPGCore/Package.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "test: add native core behavior tests"
```

---

### Task 2: Implement Shared Core Models and Engines

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift`

- [ ] **Step 1: Add shared domain models**

```swift
public enum ReadinessColor: String, Equatable {
    case green
    case yellow
    case red
}

public struct HealthSummary: Equatable {
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

public struct ReadinessResult: Equatable {
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

public struct WatchStep: Equatable {
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

public struct DailyQuest: Equatable {
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

public enum WatchAction: String, Equatable {
    case complete
    case tooHeavy
    case skip
    case rpeWithinTarget
}

public struct ExecutionLog: Equatable {
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

public enum CompletionState: String, Equatable {
    case completed
    case downgraded
    case skipped
}

public struct WorkoutResult: Equatable {
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

public enum ModelMode: String, Equatable {
    case localFirst
    case hybrid
    case remoteDisabled
}

public struct ModelHarnessSnapshot: Equatable {
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
```

- [ ] **Step 2: Add deterministic engines**

```swift
public enum ReadinessEngine {
    public static func evaluate(_ health: HealthSummary) -> ReadinessResult {
        if health.drivers.contains("HealthKit 数据缺失") {
            return ReadinessResult(
                score: 55,
                color: .yellow,
                title: "共振偏移",
                explanation: "HealthKit 数据缺失，使用保守黄灯策略。",
                safetyGuidance: "降低强度，优先确认身体状态。"
            )
        }

        let score = max(
            0,
            min(
                100,
                (health.energy + health.recovery + health.sleep + (100 - health.strain) + (100 - health.heartRateTrend * 4)) / 5
            )
        )

        if health.recovery < 45 || health.sleep < 50 || health.heartRateTrend >= 12 {
            return ReadinessResult(
                score: score,
                color: .red,
                title: "营火修复",
                explanation: "恢复或睡眠信号不足，今日训练应转为修复。",
                safetyGuidance: "避免高强度训练，恢复也计入成长。"
            )
        }

        if health.energy < 68 || health.recovery < 66 || health.strain > 72 {
            return ReadinessResult(
                score: score,
                color: .yellow,
                title: "共振偏移",
                explanation: "身体可训练但负荷需要下调。",
                safetyGuidance: "降低强度，保持动作质量和可持续完成。"
            )
        }

        return ReadinessResult(
            score: score,
            color: .green,
            title: "共振稳定",
            explanation: "恢复、能量与负荷处在可推进区间。",
            safetyGuidance: "可以执行标准训练，但保留热身和RPE监控。"
        )
    }
}

public enum QuestEngine {
    public static func quest(for readiness: ReadinessResult, storyNode: String) -> DailyQuest {
        switch readiness.color {
        case .green:
            return DailyQuest(
                title: "回声训练厅：力量共振",
                objective: "完成标准力量循环，维持RPE 6-7。",
                difficulty: "标准",
                attributeRewards: ["STR +10", "END +12", "CON +6"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "动态热身", target: "关节活动 + 轻负荷", duration: "8分钟", safetyNote: "热身完成后再进入主训练。"),
                    WatchStep(instruction: "力量循环", target: "3组，RPE 6-7", duration: "24分钟", safetyNote: "任何过重信号都立即降阶。"),
                    WatchStep(instruction: "冷却记录", target: "呼吸 + 拉伸", duration: "6分钟", safetyNote: "记录RPE和异常感觉。")
                ]
            )
        case .yellow:
            return DailyQuest(
                title: "灰烬坡道：降阶巡航",
                objective: "降低强度，完成动作质量优先的轻量训练。",
                difficulty: "降阶",
                attributeRewards: ["CON +8", "AGI +5", "INT +4"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "低强度热身", target: "RPE 3-4", duration: "8分钟", safetyNote: "用热身确认状态，不追求速度。"),
                    WatchStep(instruction: "轻量循环", target: "2组，RPE 5以内", duration: "18分钟", safetyNote: "疲劳上升时直接跳过剩余组。"),
                    WatchStep(instruction: "恢复收尾", target: "拉伸 + 呼吸", duration: "8分钟", safetyNote: "恢复完成同样计入成长。")
                ]
            )
        case .red:
            return DailyQuest(
                title: "营火边缘：恢复仪式",
                objective: "恢复优先，完成轻活动、补水和睡眠准备。",
                difficulty: "恢复",
                attributeRewards: ["CON +10", "INT +6"],
                storyNode: storyNode,
                watchSteps: [
                    WatchStep(instruction: "轻步行", target: "舒适配速", duration: "12分钟", safetyNote: "不进入冲刺或力量训练。"),
                    WatchStep(instruction: "呼吸恢复", target: "鼻吸口呼", duration: "5分钟", safetyNote: "若不适则停止。"),
                    WatchStep(instruction: "睡眠准备", target: "放松流程", duration: "10分钟", safetyNote: "今晚目标是恢复资源。")
                ]
            )
        }
    }
}

public enum ExecutionEngine {
    public static func resolve(quest: DailyQuest, logs: [ExecutionLog]) -> WorkoutResult {
        let sortedLogs = logs.sorted { $0.order < $1.order }
        let heavyLog = sortedLogs.first { $0.action == .tooHeavy || $0.rpe >= 9 }
        let skippedEverything = !sortedLogs.isEmpty && sortedLogs.allSatisfy { $0.action == .skip }

        if let heavyLog {
            return WorkoutResult(
                completionState: .downgraded,
                safetyFeedback: "检测到过重信号：\(heavyLog.note)。本次结果记录为安全降阶。",
                nextRecommendation: "下一次同类任务降阶一档，并优先检查动作质量。",
                memoryDraft: "任务「\(quest.title)」中出现过重反馈：\(heavyLog.note)。后续推荐降低负荷。"
            )
        }

        if skippedEverything {
            return WorkoutResult(
                completionState: .skipped,
                safetyFeedback: "本次 Watch 步骤均跳过，保持恢复优先。",
                nextRecommendation: "下一次从恢复或轻量任务重新进入。",
                memoryDraft: "任务「\(quest.title)」被跳过，可能需要重新评估当天可训练性。"
            )
        }

        return WorkoutResult(
            completionState: .completed,
            safetyFeedback: "训练完成且未记录过重信号。",
            nextRecommendation: "保持当前节奏，下一次根据 readiness 决定是否推进。",
            memoryDraft: "任务「\(quest.title)」完成，奖励 \(quest.attributeRewards.joined(separator: " / "))。"
        )
    }
}

public enum ModelHarnessBuilder {
    public static func snapshot(
        readiness: ReadinessResult,
        quest: DailyQuest,
        mode: ModelMode,
        logs: [ExecutionLog]
    ) -> ModelHarnessSnapshot {
        let overload = logs.contains { $0.action == .tooHeavy || $0.rpe >= 9 }
        var rules = [
            "安全优先：\(readiness.safetyGuidance)",
            "恢复也计入成长，不能被叙事惩罚。",
            "Watch Payload 必须保持短句、目标、时长和安全提示。"
        ]

        if readiness.color != .green {
            rules.append("非绿灯状态必须降低强度或进入恢复任务。")
        }

        if overload {
            rules.append("Watch 已记录过重，下一轮推荐必须降阶。")
        }

        let generationPath: [String]
        let fallbackPolicy: String
        let modeLabel: String

        switch mode {
        case .localFirst:
            modeLabel = "本地优先"
            generationPath = ["规则过滤", "本地 Gemma / LiteRT-LM 草稿", "安全校验", "Watch Payload"]
            fallbackPolicy = "本地生成失败时使用确定性模板，并保留全部安全规则。"
        case .hybrid:
            modeLabel = "本地 + 远程增强"
            generationPath = ["规则过滤", "本地安全草稿", "安全校验", "远程仅润色周总结", "Watch Payload"]
            fallbackPolicy = "远程不可用时退回本地草稿；远程不参与安全决策。"
        case .remoteDisabled:
            modeLabel = "禁用远程"
            generationPath = ["规则过滤", "确定性模板", "安全校验", "Watch Payload"]
            fallbackPolicy = "禁用远程时使用确定性模板，不请求远程增强。"
        }

        let inputContext = [
            "状态：\(readiness.title) \(readiness.score)",
            "剧情节点：\(quest.storyNode)",
            "任务：\(quest.title)",
            "Watch 记录：\(logs.count) 条"
        ]

        let overloadLine = overload ? "已出现过重反馈，必须降阶。" : "未出现过重反馈。"
        let promptPreview = """
        模式：\(modeLabel)
        Readiness：\(readiness.title)，\(readiness.explanation)
        Quest：\(quest.title)，\(quest.objective)
        Safety：\(rules.joined(separator: "；"))
        Watch：输出短步骤、目标、时长、安全提示。\(overloadLine)
        """

        return ModelHarnessSnapshot(
            inputContext: inputContext,
            skillRules: rules,
            generationPath: generationPath,
            fallbackPolicy: fallbackPolicy,
            promptPreview: promptPreview
        )
    }
}
```

- [ ] **Step 3: Run Swift tests and verify they pass**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with all five `FitnessRPGCoreTests` tests succeeding.

- [ ] **Step 4: Commit shared core implementation**

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift
git commit -m "feat: add native fitness rpg core"
```

---

### Task 3: Add iPhone and watchOS SwiftUI Source Scaffolds

**Files:**
- Create: `native/AppSources/iOS/FitnessRPGApp.swift`
- Create: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Create: `native/AppSources/iOS/ReadinessPanel.swift`
- Create: `native/AppSources/iOS/QuestPanel.swift`
- Create: `native/AppSources/iOS/ModelHarnessPanel.swift`
- Create: `native/AppSources/watchOS/FitnessRPGWatchApp.swift`
- Create: `native/AppSources/watchOS/WatchExecutionView.swift`

- [ ] **Step 1: Add the iPhone app entry scaffold**

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
                modelMode: .localFirst
            )
        }
    }
}
```

- [ ] **Step 2: Add the iPhone command center view**

```swift
import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode

    private var quest: DailyQuest {
        QuestEngine.quest(for: readiness, storyNode: "回声训练厅")
    }

    private var harness: ModelHarnessSnapshot {
        ModelHarnessBuilder.snapshot(
            readiness: readiness,
            quest: quest,
            mode: modelMode,
            logs: []
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日任务中枢")
                            .font(.largeTitle.bold())
                        Text("iPhone 是大脑，Apple Watch 是执行面。")
                            .foregroundStyle(.secondary)
                    }

                    ReadinessPanel(readiness: readiness)
                    QuestPanel(quest: quest)
                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst
    )
}
```

- [ ] **Step 3: Add the iPhone readiness panel**

```swift
import SwiftUI
import FitnessRPGCore

struct ReadinessPanel: View {
    let readiness: ReadinessResult

    private var accent: Color {
        switch readiness.color {
        case .green:
            return .green
        case .yellow:
            return .orange
        case .red:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(readiness.title)
                    .font(.headline)
                Spacer()
                Text("\(readiness.score)")
                    .font(.title2.bold())
                    .foregroundStyle(accent)
            }

            Text(readiness.explanation)
                .font(.subheadline)

            Text(readiness.safetyGuidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 4: Add the iPhone quest panel**

```swift
import SwiftUI
import FitnessRPGCore

struct QuestPanel: View {
    let quest: DailyQuest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(quest.title)
                    .font(.headline)
                Spacer()
                Text(quest.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }

            Text(quest.objective)
                .font(.subheadline)

            Text(quest.attributeRewards.joined(separator: " / "))
                .font(.footnote.weight(.semibold))

            ForEach(Array(quest.watchSteps.enumerated()), id: \.offset) { index, step in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watch \(index + 1)：\(step.instruction)")
                        .font(.subheadline.weight(.semibold))
                    Text("\(step.target) · \(step.duration)")
                        .font(.footnote)
                    Text(step.safetyNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 5: Add the iPhone model harness panel**

```swift
import SwiftUI
import FitnessRPGCore

struct ModelHarnessPanel: View {
    let snapshot: ModelHarnessSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本地模型 Harness")
                .font(.headline)

            Group {
                section("输入上下文", snapshot.inputContext)
                section("Skill 规则", snapshot.skillRules)
                section("生成路径", snapshot.generationPath)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Fallback")
                    .font(.subheadline.weight(.semibold))
                Text(snapshot.fallbackPolicy)
                    .font(.footnote)
            }

            Text(snapshot.promptPreview)
                .font(.caption.monospaced())
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func section(_ title: String, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ForEach(lines, id: \.self) { line in
                Text("· \(line)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 6: Add the watchOS app entry scaffold**

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchExecutionView(
                quest: QuestEngine.quest(
                    for: ReadinessEngine.evaluate(MockHealthProfiles.green),
                    storyNode: "回声训练厅"
                )
            )
        }
    }
}
```

- [ ] **Step 7: Add the Watch execution view**

```swift
import SwiftUI
import FitnessRPGCore

struct WatchExecutionView: View {
    let quest: DailyQuest
    @State private var stepIndex = 0

    private var step: WatchStep {
        quest.watchSteps[min(stepIndex, quest.watchSteps.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quest.difficulty)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(step.instruction)
                .font(.headline)

            Text(step.target)
                .font(.subheadline)

            Text(step.duration)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(step.safetyNote)
                .font(.caption2)
                .foregroundStyle(.orange)

            HStack {
                Button("完成") { advance() }
                Button("过重") { advance() }
            }

            HStack {
                Button("跳过") { advance() }
                Button("RPE内") { advance() }
            }
        }
        .padding()
    }

    private func advance() {
        stepIndex = min(stepIndex + 1, quest.watchSteps.count - 1)
    }
}

#Preview {
    WatchExecutionView(
        quest: QuestEngine.quest(
            for: ReadinessEngine.evaluate(MockHealthProfiles.green),
            storyNode: "回声训练厅"
        )
    )
}
```

- [ ] **Step 8: Verify shared package still passes**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS. The `native/AppSources/` files are not part of the Swift Package in this pass, so this command verifies the compiled shared core has not regressed.

- [ ] **Step 9: Commit app source scaffolds**

```bash
git add native/AppSources
git commit -m "feat: add native app source scaffolds"
```

---

### Task 4: Add Native README and Final Verification

**Files:**
- Create: `native/README.md`

- [ ] **Step 1: Add native architecture README**

````markdown
# Fitness RPG Native Scaffold

This folder contains the first native iPhone / watchOS scaffold for Fitness RPG.

## Structure

- `FitnessRPGCore/`: compiled Swift Package for shared product logic.
- `AppSources/iOS/`: SwiftUI source files for a future iPhone app target.
- `AppSources/watchOS/`: SwiftUI source files for a future watchOS app target.

## Current Pass

The shared core is the only compiled native target in this repository pass. It includes deterministic mock health profiles, readiness evaluation, quest selection, Watch execution result handling, and local model harness explanation.

The app source folders are intentionally not wired into an Xcode project yet. They are source scaffolds that should be copied or referenced by future Xcode app targets after the project file is created.

## Future Xcode Target Setup

1. Create an iOS app target named `FitnessRPG`.
2. Add `FitnessRPGCore` as a local Swift Package dependency from `native/FitnessRPGCore`.
3. Add `AppSources/iOS/*.swift` to the iOS target.
4. Create a watchOS app target named `FitnessRPGWatch`.
5. Add the same `FitnessRPGCore` package dependency to the watchOS target.
6. Add `AppSources/watchOS/*.swift` to the watchOS target.

## Future Integration Points

- HealthKit adapter feeds `HealthSummary`.
- WatchConnectivity adapter syncs `DailyQuest` and `ExecutionLog`.
- LiteRT-LM / Gemma adapter drafts coach text before deterministic safety validation.
- Persistence adapter stores memory drafts and completed workouts.

## Verification

Run the shared core tests:

```bash
cd native/FitnessRPGCore
swift test
```

Run the existing browser prototype contract test from the repository root:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
```
````

- [ ] **Step 2: Run native tests**

Run:

```bash
cd native/FitnessRPGCore
swift test
```

Expected: PASS with all five core tests succeeding.

- [ ] **Step 3: Run existing prototype regression checks**

Run from the repository root:

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
```

Expected: PASS with `prototype contract ok`.

- [ ] **Step 4: Confirm migration files remain untouched**

Run:

```bash
git status --short
```

Expected: only the known untracked migration-context files remain outside the native/doc changes:

```text
?? README.md
?? docs/project-brief.md
?? records/
?? work/
```

- [ ] **Step 5: Commit native README**

```bash
git add native/README.md
git commit -m "docs: add native scaffold guide"
```

---

## Final Verification Checklist

- `cd native/FitnessRPGCore && swift test` passes.
- Existing prototype syntax checks pass.
- `node prototype/tests/prototypeContract.test.mjs` prints `prototype contract ok`.
- `native/README.md` documents how the scaffold connects to future Xcode targets.
- `git status --short` shows no tracked-file changes left uncommitted.
