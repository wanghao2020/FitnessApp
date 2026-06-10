# WatchConnectivity 任务同步实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加第一版 iPhone 到 Apple Watch 的任务同步，以及 Watch 到 iPhone 的执行记录回传。

**Architecture:** 先在 `FitnessRPGCore` 建立可测试、版本化、Codable 的同步契约，再让 iOS 和 watchOS 各自实现很薄的 `WCSession` 适配层。顺手把 Core 中与本功能相关的大文件拆成更清楚的模型、引擎和同步契约文件，但不改变现有 readiness、quest、execution 的业务行为。

**Tech Stack:** Swift 6, SwiftUI, XCTest, WatchConnectivity, Xcode project file, Swift Package Manager.

---

## 文件结构

- 修改 `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift`：让需要传输的领域类型支持 `Codable`，保留公开初始化接口。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/SyncPayloads.swift`：同步消息类型、版本化 envelope、payload 和字典编码辅助。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/MockHealthProfiles.swift`：从 `Models.swift` 拆出 mock profile。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/ReadinessEngine.swift`：从 `Engines.swift` 拆出 readiness 评估。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/QuestEngine.swift`：从 `Engines.swift` 拆出 quest 生成。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/ExecutionEngine.swift`：从 `Engines.swift` 拆出执行结果解析。
- 新建 `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelHarnessBuilder.swift`：从 `Engines.swift` 拆出 model harness 预览。
- 修改 `native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift`：拆分后删除该文件内容或留下兼容性注释。
- 修改 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`：增加同步契约 round-trip 和失败路径测试。
- 新建 `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift`：iOS 端发送 quest、接收 logs、解析 `WorkoutResult`。
- 修改 `native/AppSources/iOS/FitnessRPGApp.swift`：持有 iOS 同步 model 并传给 Today UI。
- 修改 `native/AppSources/iOS/TodayCommandCenterView.swift`：展示同步状态，发送当前 quest，显示返回的执行结果。
- 新建 `native/AppSources/watchOS/WatchQuestSyncModel.swift`：watchOS 端接收 quest、记录 logs、回传 logs。
- 修改 `native/AppSources/watchOS/FitnessRPGWatchApp.swift`：持有 watchOS 同步 model。
- 修改 `native/AppSources/watchOS/WatchExecutionView.swift`：按钮产生真实 `ExecutionLog`。
- 修改 `native/FitnessRPG.xcodeproj/project.pbxproj`：把新 iOS/watchOS 源文件加入对应 target，并为两个 app target 链接 `WatchConnectivity.framework`。
- 修改 `README.md` 和 `native/README.md`：记录 WatchConnectivity MVP 和验证命令。

---

### Task 1: 增加 Core 同步契约测试和实现

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/SyncPayloads.swift`

- [ ] **Step 1: 写失败测试**

把下面 4 个测试追加到 `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift` 的 `FitnessRPGCoreTests` class 内部：

```swift
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
```

- [ ] **Step 2: 运行测试确认失败**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：测试失败，编译错误里会出现 `QuestSyncPayload`、`ExecutionLogSyncPayload`、`SyncEnvelope`、`SyncPayloadError` 尚未定义，或 `DailyQuest` / `ExecutionLog` 尚未支持 `Codable`。

- [ ] **Step 3: 给传输相关模型增加 Codable**

修改 `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift` 中这些类型的声明行：

```swift
public enum ReadinessColor: String, Codable, Equatable, Sendable {
```

```swift
public struct HealthSummary: Codable, Equatable, Sendable {
```

```swift
public struct ReadinessResult: Codable, Equatable, Sendable {
```

```swift
public struct WatchStep: Codable, Equatable, Sendable {
```

```swift
public struct DailyQuest: Codable, Equatable, Sendable {
```

```swift
public enum WatchAction: String, Codable, Equatable, Sendable {
```

```swift
public struct ExecutionLog: Codable, Equatable, Sendable {
```

```swift
public enum CompletionState: String, Codable, Equatable, Sendable {
```

```swift
public struct WorkoutResult: Codable, Equatable, Sendable {
```

```swift
public enum ModelMode: String, Codable, Equatable, Sendable {
```

```swift
public struct ModelHarnessSnapshot: Codable, Equatable, Sendable {
```

不要改变任何属性名和 initializer。

- [ ] **Step 4: 创建同步契约实现**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/SyncPayloads.swift`：

```swift
import Foundation

public enum SyncMessageKind: String, Codable, Equatable, Sendable {
    case quest
    case executionLogs
}

public enum SyncPayloadError: Error, Equatable, Sendable {
    case missingEnvelopeData
    case unsupportedSchemaVersion(Int)
    case unexpectedKind(expected: SyncMessageKind, actual: SyncMessageKind)
}

public struct SyncEnvelope: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let dictionaryPayloadKey = "fitnessRPGSyncEnvelope"

    public let schemaVersion: Int
    public let kind: SyncMessageKind
    public let encodedAt: Date
    public let payloadData: Data

    public init(
        schemaVersion: Int = SyncEnvelope.currentSchemaVersion,
        kind: SyncMessageKind,
        encodedAt: Date = Date(),
        payloadData: Data
    ) {
        self.schemaVersion = schemaVersion
        self.kind = kind
        self.encodedAt = encodedAt
        self.payloadData = payloadData
    }

    public init<Payload: Encodable>(
        schemaVersion: Int = SyncEnvelope.currentSchemaVersion,
        kind: SyncMessageKind,
        encodedAt: Date = Date(),
        payload: Payload
    ) throws {
        self.init(
            schemaVersion: schemaVersion,
            kind: kind,
            encodedAt: encodedAt,
            payloadData: try SyncEnvelope.makeEncoder().encode(payload)
        )
    }

    public func decodePayload<Payload: Decodable>(
        _ type: Payload.Type,
        expectedKind: SyncMessageKind
    ) throws -> Payload {
        guard schemaVersion == SyncEnvelope.currentSchemaVersion else {
            throw SyncPayloadError.unsupportedSchemaVersion(schemaVersion)
        }

        guard kind == expectedKind else {
            throw SyncPayloadError.unexpectedKind(expected: expectedKind, actual: kind)
        }

        return try SyncEnvelope.makeDecoder().decode(Payload.self, from: payloadData)
    }

    public func toDictionary() throws -> [String: Any] {
        [
            SyncEnvelope.dictionaryPayloadKey: try SyncEnvelope.makeEncoder().encode(self)
        ]
    }

    public static func fromDictionary(_ dictionary: [String: Any]) throws -> SyncEnvelope {
        guard let data = dictionary[SyncEnvelope.dictionaryPayloadKey] as? Data else {
            throw SyncPayloadError.missingEnvelopeData
        }

        return try SyncEnvelope.makeDecoder().decode(SyncEnvelope.self, from: data)
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public struct QuestSyncPayload: Codable, Equatable, Sendable {
    public let quest: DailyQuest
    public let readinessColor: ReadinessColor
    public let generatedAt: Date

    public init(quest: DailyQuest, readinessColor: ReadinessColor, generatedAt: Date = Date()) {
        self.quest = quest
        self.readinessColor = readinessColor
        self.generatedAt = generatedAt
    }
}

public struct ExecutionLogSyncPayload: Codable, Equatable, Sendable {
    public let questTitle: String
    public let logs: [ExecutionLog]
    public let sentAt: Date

    public init(questTitle: String, logs: [ExecutionLog], sentAt: Date = Date()) {
        self.questTitle = questTitle
        self.logs = logs
        self.sentAt = sentAt
    }
}
```

- [ ] **Step 5: 运行 Core 测试确认通过**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：新增 4 个同步契约测试通过，现有 11 个测试继续通过，总数为 15 个测试、0 failures。

- [ ] **Step 6: 提交 Core 同步契约**

运行：

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift native/FitnessRPGCore/Sources/FitnessRPGCore/SyncPayloads.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "feat: add watch sync payload contracts"
```

---

### Task 2: 拆分 Core 引擎文件

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/MockHealthProfiles.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/ReadinessEngine.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/QuestEngine.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/ExecutionEngine.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelHarnessBuilder.swift`

- [ ] **Step 1: 运行当前 Core 测试作为重构基线**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：15 个测试全部通过。只有在这个基线通过后才开始移动代码。

- [ ] **Step 2: 从 Models.swift 移出 MockHealthProfiles**

从 `native/FitnessRPGCore/Sources/FitnessRPGCore/Models.swift` 删除 `public enum MockHealthProfiles { ... }` 整个 enum，并创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/MockHealthProfiles.swift`：

```swift
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

- [ ] **Step 3: 从 Engines.swift 拆出 ReadinessEngine**

从 `native/FitnessRPGCore/Sources/FitnessRPGCore/Engines.swift` 删除 `public enum ReadinessEngine { ... }`，并创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/ReadinessEngine.swift`，内容使用当前 `ReadinessEngine.evaluate(_:)` 的完整实现，不改变任何字符串、阈值或返回值。

如果需要手动核对，移动后的文件开头应为：

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
```

- [ ] **Step 4: 从 Engines.swift 拆出 QuestEngine**

创建 `native/FitnessRPGCore/Sources/FitnessRPGCore/QuestEngine.swift`，把当前 `QuestEngine.quest(for:storyNode:)` 的完整实现移动进去，不改变任何 quest 标题、目标、奖励、步骤或安全提示。

移动后的文件开头应为：

```swift
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
```

- [ ] **Step 5: 从 Engines.swift 拆出 ExecutionEngine 和 ModelHarnessBuilder**

创建：

- `native/FitnessRPGCore/Sources/FitnessRPGCore/ExecutionEngine.swift`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelHarnessBuilder.swift`

分别把当前 `ExecutionEngine.resolve(quest:logs:)` 和 `ModelHarnessBuilder.snapshot(readiness:quest:mode:logs:)` 的完整实现移动进去。不要改变排序逻辑、overload 判断、中文文案、fallback 文案或 `promptPreview` 模板。

移动完成后，`Engines.swift` 应只保留这个兼容性注释：

```swift
// Engine implementations live in focused files:
// ReadinessEngine.swift, QuestEngine.swift, ExecutionEngine.swift, and ModelHarnessBuilder.swift.
```

- [ ] **Step 6: 运行 Core 测试确认重构无行为变化**

运行：

```bash
cd native/FitnessRPGCore
swift test
```

预期：15 个测试全部通过。

- [ ] **Step 7: 提交 Core 文件拆分**

运行：

```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git commit -m "refactor: split core models and engines"
```

---

### Task 3: 增加 iOS WatchConnectivity 发送和回传处理

**Files:**
- Create: `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift`
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: 创建 iOS 同步 model**

创建目录 `native/AppSources/iOS/WatchConnectivity/`，再创建 `native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift`：

```swift
import Foundation
import WatchConnectivity
import FitnessRPGCore

@MainActor
final class WatchQuestSyncModel: NSObject, ObservableObject {
    @Published private(set) var statusText = "Watch 同步尚未启动。"
    @Published private(set) var latestResult: WorkoutResult?

    private let session: WCSession?
    private var currentQuest: DailyQuest?

    init(session: WCSession? = WCSession.isSupported() ? WCSession.default : nil) {
        self.session = session
        super.init()

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity。"
            return
        }

        session.delegate = self
        session.activate()
        statusText = "正在激活 Watch 同步。"
    }

    func send(quest: DailyQuest, readinessColor: ReadinessColor) {
        currentQuest = quest

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity。"
            return
        }

        do {
            let payload = QuestSyncPayload(
                quest: quest,
                readinessColor: readinessColor,
                generatedAt: Date()
            )
            let message = try SyncEnvelope(kind: .quest, payload: payload).toDictionary()

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { [weak self] error in
                    Task { @MainActor in
                        self?.statusText = "Watch 发送失败：\(error.localizedDescription)"
                    }
                }
                statusText = "已发送今日任务到 Watch。"
            } else {
                session.transferUserInfo(message)
                statusText = "Watch 暂不可达，今日任务已排队。"
            }
        } catch {
            statusText = "任务同步编码失败。"
        }
    }

    private func receive(_ dictionary: [String: Any]) {
        do {
            let envelope = try SyncEnvelope.fromDictionary(dictionary)
            let payload = try envelope.decodePayload(
                ExecutionLogSyncPayload.self,
                expectedKind: .executionLogs
            )

            guard let currentQuest else {
                statusText = "已收到 Watch 记录，但当前 iPhone 没有匹配任务。"
                return
            }

            latestResult = ExecutionEngine.resolve(quest: currentQuest, logs: payload.logs)
            statusText = "已收到 Watch 执行记录：\(payload.logs.count) 条。"
        } catch {
            statusText = "Watch 记录解码失败。"
        }
    }
}

extension WatchQuestSyncModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                statusText = "Watch 同步激活失败：\(error.localizedDescription)"
            } else {
                statusText = activationState == .activated ? "Watch 同步已激活。" : "Watch 同步未激活。"
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            statusText = "Watch 同步暂时 inactive。"
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
        Task { @MainActor in
            statusText = "Watch 同步已重新激活。"
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            receive(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            receive(userInfo)
        }
    }
}
```

- [ ] **Step 2: 修改 iOS app 注入同步 model**

替换 `native/AppSources/iOS/FitnessRPGApp.swift` 内容：

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGApp: App {
    @StateObject private var healthViewModel = TodayHealthViewModel()
    @StateObject private var watchSyncModel = WatchQuestSyncModel()

    var body: some Scene {
        WindowGroup {
            TodayCommandCenterView(
                readiness: healthViewModel.readiness,
                modelMode: .localFirst,
                sourceNote: healthViewModel.sourceNote,
                watchSyncModel: watchSyncModel
            )
            .task {
                await healthViewModel.loadHealthSummary()
            }
        }
    }
}
```

- [ ] **Step 3: 修改 Today UI 发送 quest 并显示同步状态**

替换 `native/AppSources/iOS/TodayCommandCenterView.swift` 内容：

```swift
import SwiftUI
import FitnessRPGCore

struct TodayCommandCenterView: View {
    let readiness: ReadinessResult
    let modelMode: ModelMode
    let sourceNote: String?
    @ObservedObject var watchSyncModel: WatchQuestSyncModel

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
                        if let sourceNote, !sourceNote.isEmpty {
                            Text(sourceNote)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text(watchSyncModel.statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ReadinessPanel(readiness: readiness)
                    QuestPanel(quest: quest)

                    Button("发送到 Watch") {
                        watchSyncModel.send(quest: quest, readinessColor: readiness.color)
                    }
                    .buttonStyle(.borderedProminent)

                    if let result = watchSyncModel.latestResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Watch 回传")
                                .font(.headline)
                            Text(result.safetyFeedback)
                            Text(result.nextRecommendation)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    ModelHarnessPanel(snapshot: harness)
                }
                .padding()
            }
            .navigationTitle("Fitness RPG")
            .onAppear {
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
            .onChange(of: readiness.score) { _, _ in
                watchSyncModel.send(quest: quest, readinessColor: readiness.color)
            }
        }
    }
}

#Preview {
    TodayCommandCenterView(
        readiness: ReadinessEngine.evaluate(MockHealthProfiles.green),
        modelMode: .localFirst,
        sourceNote: "已读取 HealthKit 今日健康摘要。",
        watchSyncModel: WatchQuestSyncModel(session: nil)
    )
}
```

- [ ] **Step 4: 暂不构建，等 Task 5 把文件加入 Xcode project**

不要在这个任务里运行 `xcodebuild`。此时新 iOS 文件还没有加入 `project.pbxproj`，构建预期会失败或不会编译新文件。

---

### Task 4: 增加 watchOS 接收任务和回传记录

**Files:**
- Create: `native/AppSources/watchOS/WatchQuestSyncModel.swift`
- Modify: `native/AppSources/watchOS/FitnessRPGWatchApp.swift`
- Modify: `native/AppSources/watchOS/WatchExecutionView.swift`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: 创建 watchOS 同步 model**

创建 `native/AppSources/watchOS/WatchQuestSyncModel.swift`：

```swift
import Foundation
import WatchConnectivity
import FitnessRPGCore

@MainActor
final class WatchQuestSyncModel: NSObject, ObservableObject {
    @Published private(set) var quest: DailyQuest
    @Published private(set) var logs: [ExecutionLog] = []
    @Published private(set) var statusText = "等待 iPhone 任务。"

    private let session: WCSession?

    init(
        initialQuest: DailyQuest = QuestEngine.quest(
            for: ReadinessEngine.evaluate(MockHealthProfiles.green),
            storyNode: "回声训练厅"
        ),
        session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    ) {
        self.quest = initialQuest
        self.session = session
        super.init()

        guard let session else {
            statusText = "当前设备不支持 WatchConnectivity，使用本地安全任务。"
            return
        }

        session.delegate = self
        session.activate()
        statusText = "正在连接 iPhone。"
    }

    func record(action: WatchAction, step: WatchStep, order: Int) {
        let log = ExecutionLog(
            action: action,
            order: order,
            rpe: rpe(for: action),
            note: note(for: action, step: step)
        )
        logs.append(log)
        sendLogs()
    }

    private func rpe(for action: WatchAction) -> Int {
        switch action {
        case .complete:
            return 6
        case .tooHeavy:
            return 9
        case .skip:
            return 2
        case .rpeWithinTarget:
            return 5
        }
    }

    private func note(for action: WatchAction, step: WatchStep) -> String {
        switch action {
        case .complete:
            return "\(step.instruction) 完成"
        case .tooHeavy:
            return "\(step.instruction) 过重"
        case .skip:
            return "\(step.instruction) 跳过"
        case .rpeWithinTarget:
            return "\(step.instruction) RPE 在目标内"
        }
    }

    private func sendLogs() {
        guard let session else {
            statusText = "本地已记录，无法同步到 iPhone。"
            return
        }

        do {
            let payload = ExecutionLogSyncPayload(
                questTitle: quest.title,
                logs: logs,
                sentAt: Date()
            )
            let message = try SyncEnvelope(kind: .executionLogs, payload: payload).toDictionary()

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { [weak self] error in
                    Task { @MainActor in
                        self?.statusText = "回传失败：\(error.localizedDescription)"
                    }
                }
                statusText = "已回传 \(logs.count) 条记录。"
            } else {
                session.transferUserInfo(message)
                statusText = "iPhone 暂不可达，记录已排队。"
            }
        } catch {
            statusText = "执行记录编码失败。"
        }
    }

    private func receive(_ dictionary: [String: Any]) {
        do {
            let envelope = try SyncEnvelope.fromDictionary(dictionary)
            let payload = try envelope.decodePayload(
                QuestSyncPayload.self,
                expectedKind: .quest
            )
            quest = payload.quest
            logs = []
            statusText = "已收到 iPhone 今日任务。"
        } catch {
            statusText = "iPhone 任务解码失败，继续使用本地安全任务。"
        }
    }
}

extension WatchQuestSyncModel: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                statusText = "iPhone 连接失败：\(error.localizedDescription)"
            } else {
                statusText = activationState == .activated ? "已连接 iPhone。" : "iPhone 连接未激活。"
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            receive(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            receive(userInfo)
        }
    }
}
```

- [ ] **Step 2: 修改 watchOS app 注入同步 model**

替换 `native/AppSources/watchOS/FitnessRPGWatchApp.swift` 内容：

```swift
import SwiftUI
import FitnessRPGCore

@main
struct FitnessRPGWatchApp: App {
    @StateObject private var syncModel = WatchQuestSyncModel()

    var body: some Scene {
        WindowGroup {
            WatchExecutionView(syncModel: syncModel)
        }
    }
}
```

- [ ] **Step 3: 修改 WatchExecutionView 产生真实日志**

替换 `native/AppSources/watchOS/WatchExecutionView.swift` 内容：

```swift
import SwiftUI
import FitnessRPGCore

struct WatchExecutionView: View {
    @ObservedObject var syncModel: WatchQuestSyncModel
    @State private var stepIndex = 0

    private var quest: DailyQuest {
        syncModel.quest
    }

    private var currentStep: WatchStep? {
        guard !quest.watchSteps.isEmpty else {
            return nil
        }

        return quest.watchSteps[min(stepIndex, quest.watchSteps.count - 1)]
    }

    var body: some View {
        Group {
            if let step = currentStep {
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

                    Text(syncModel.statusText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("完成") { record(.complete, step: step) }
                        Button("过重") { record(.tooHeavy, step: step) }
                    }

                    HStack {
                        Button("跳过") { record(.skip, step: step) }
                        Button("RPE内") { record(.rpeWithinTarget, step: step) }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("暂无 Watch 步骤")
                        .font(.headline)
                    Text("请回到 iPhone 重新生成任务。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onChange(of: quest.title) { _, _ in
            stepIndex = 0
        }
    }

    private func record(_ action: WatchAction, step: WatchStep) {
        guard !quest.watchSteps.isEmpty else {
            return
        }

        syncModel.record(action: action, step: step, order: stepIndex + 1)
        advance()
    }

    private func advance() {
        guard !quest.watchSteps.isEmpty else {
            return
        }

        stepIndex = min(stepIndex + 1, quest.watchSteps.count - 1)
    }
}

#Preview {
    WatchExecutionView(
        syncModel: WatchQuestSyncModel(session: nil)
    )
}
```

- [ ] **Step 4: 暂不构建，等 Task 5 把文件和 framework 加入 Xcode project**

不要在这个任务里运行 `xcodebuild`。此时新 watchOS 文件还没有加入 `project.pbxproj`，构建预期会失败或不会编译新文件。

---

### Task 5: 更新 Xcode project 并验证平台构建

**Files:**
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`

- [ ] **Step 1: 修改 PBXBuildFile section**

在 `/* Begin PBXBuildFile section */` 中追加：

```text
		01A00000000000000000000D /* WatchQuestSyncModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 01B00000000000000000000E /* WatchQuestSyncModel.swift */; };
		01A00000000000000000000E /* WatchQuestSyncModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 01B00000000000000000000F /* WatchQuestSyncModel.swift */; };
		01A00000000000000000000F /* WatchConnectivity.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 01B000000000000000000010 /* WatchConnectivity.framework */; };
		01A000000000000000000010 /* WatchConnectivity.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 01B000000000000000000010 /* WatchConnectivity.framework */; };
```

- [ ] **Step 2: 修改 PBXFileReference section**

在 `/* Begin PBXFileReference section */` 中追加：

```text
		01B00000000000000000000E /* WatchQuestSyncModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WatchQuestSyncModel.swift; sourceTree = "<group>"; };
		01B00000000000000000000F /* WatchQuestSyncModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WatchQuestSyncModel.swift; sourceTree = "<group>"; };
		01B000000000000000000010 /* WatchConnectivity.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = WatchConnectivity.framework; path = System/Library/Frameworks/WatchConnectivity.framework; sourceTree = SDKROOT; };
```

- [ ] **Step 3: 修改 Frameworks build phases**

把 iOS framework phase 的 `files` 改成：

```text
			files = (
				01A000000000000000000008 /* FitnessRPGCore in Frameworks */,
				01A00000000000000000000C /* HealthKit.framework in Frameworks */,
				01A00000000000000000000F /* WatchConnectivity.framework in Frameworks */,
			);
```

把 watchOS framework phase 的 `files` 改成：

```text
			files = (
				01A000000000000000000009 /* FitnessRPGCore in Frameworks */,
				01A000000000000000000010 /* WatchConnectivity.framework in Frameworks */,
			);
```

- [ ] **Step 4: 修改 iOS 和 watchOS groups**

在 iOS group 的 children 中加入：

```text
				01E000000000000000000008 /* WatchConnectivity */,
```

在 watchOS group 的 children 中加入：

```text
				01B00000000000000000000F /* WatchQuestSyncModel.swift */,
```

在 `PBXGroup section` 中追加 iOS WatchConnectivity group：

```text
		01E000000000000000000008 /* WatchConnectivity */ = {
			isa = PBXGroup;
			children = (
				01B00000000000000000000E /* WatchQuestSyncModel.swift */,
			);
			path = WatchConnectivity;
			sourceTree = "<group>";
		};
```

在 Frameworks group children 中加入：

```text
				01B000000000000000000010 /* WatchConnectivity.framework */,
```

- [ ] **Step 5: 修改 Sources build phases**

把 iOS sources phase 的 files 中加入：

```text
				01A00000000000000000000D /* WatchQuestSyncModel.swift in Sources */,
```

把 watchOS sources phase 的 files 中加入：

```text
				01A00000000000000000000E /* WatchQuestSyncModel.swift in Sources */,
```

- [ ] **Step 6: 用 rg 确认 project 文件包含新引用**

运行：

```bash
rg -n "WatchQuestSyncModel|WatchConnectivity.framework" native/FitnessRPG.xcodeproj/project.pbxproj
```

预期：能看到 iOS/watchOS 两个 `WatchQuestSyncModel.swift` build file/file reference，以及两个 target 对 `WatchConnectivity.framework` 的 framework build file。

- [ ] **Step 7: 构建 iOS target**

运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

预期：最终输出 `** BUILD SUCCEEDED **`。

- [ ] **Step 8: 构建 watchOS target**

运行：

```bash
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

预期：最终输出 `** BUILD SUCCEEDED **`。

- [ ] **Step 9: 提交平台同步适配器**

运行：

```bash
git add native/AppSources/iOS/WatchConnectivity/WatchQuestSyncModel.swift native/AppSources/iOS/FitnessRPGApp.swift native/AppSources/iOS/TodayCommandCenterView.swift native/AppSources/watchOS/WatchQuestSyncModel.swift native/AppSources/watchOS/FitnessRPGWatchApp.swift native/AppSources/watchOS/WatchExecutionView.swift native/FitnessRPG.xcodeproj/project.pbxproj
git commit -m "feat: sync quests and execution logs with watch"
```

---

### Task 6: 更新文档和完整验证

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [ ] **Step 1: 更新 root README 的 Native Status**

在 `README.md` 的 `Native Status` 段落中追加：

```markdown
The native app now includes a first-pass WatchConnectivity sync layer. The iOS app can package the current `DailyQuest` into a versioned Core payload and send it to the watchOS app; the watchOS app records `ExecutionLog` feedback and returns it to iPhone for deterministic `ExecutionEngine` resolution. When WatchConnectivity is unavailable, both app surfaces keep safe fallback behavior.
```

- [ ] **Step 2: 更新 root README 的 Next Major Work**

把 `README.md` 的 `Next Major Work` 列表改成：

```markdown
1. Add persistence for workout results, memory drafts, and story progression.
2. Improve real-device WatchConnectivity companion configuration and diagnostics after device testing.
3. Integrate local model runtime behind the deterministic harness and validator.
4. Harden HealthKit data coverage, diagnostics, and onboarding copy after device testing.
```

- [ ] **Step 3: 更新 native README 的 Current Pass**

在 `native/README.md` 的 `Current Pass` 段落后追加：

```markdown
The current native pass also includes first-pass WatchConnectivity source adapters. iOS sends versioned quest payloads derived from `ReadinessEngine` and `QuestEngine`; watchOS receives those payloads, records step feedback as `ExecutionLog` values, and sends logs back for `ExecutionEngine` resolution on iPhone.
```

- [ ] **Step 4: 更新 native README 的 Future Integration Points**

把 `native/README.md` 的 `Future Integration Points` 列表改成：

```markdown
- Persistence adapter stores workout results, memory drafts, and story progression.
- LiteRT-LM / Gemma adapter drafts coach text before deterministic safety validation.
- Real-device WatchConnectivity diagnostics and companion target configuration can be hardened after device testing.
```

- [ ] **Step 5: 运行完整验证**

从仓库根目录运行：

```bash
(cd native/FitnessRPGCore && swift test)
node prototype/tests/prototypeContract.test.mjs
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

预期：

- `swift test` 显示 15 个 Core 测试、0 failures。
- `prototype contract ok`。
- iOS build 输出 `** BUILD SUCCEEDED **`。
- watchOS build 输出 `** BUILD SUCCEEDED **`。

- [ ] **Step 6: 检查 git diff**

运行：

```bash
git status --short
git diff --stat
```

预期：只包含本计划列出的 Core、iOS、watchOS、Xcode project 和 README 文件。

- [ ] **Step 7: 提交文档**

运行：

```bash
git add README.md native/README.md
git commit -m "docs: document watch sync mvp"
```

---

## 完成标准

- Core 同步 payload 有测试覆盖，并能拒绝错误 kind 和错误 schema version。
- `FitnessRPGCore` 的模型、mock、engine、health signals、sync payload 文件边界清楚。
- iOS app 能生成当前 quest sync payload，显示 Watch 同步状态，接收 logs 后用 `ExecutionEngine.resolve` 得到结果。
- watchOS app 能保留安全 mock fallback，收到 iPhone quest 后切换任务，按钮能产生 `ExecutionLog` 并回传。
- iOS 和 watchOS targets 都链接 `WatchConnectivity.framework` 并构建通过。
- 完整验证命令全部通过。
