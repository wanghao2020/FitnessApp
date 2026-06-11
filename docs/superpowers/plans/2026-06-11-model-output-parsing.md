# 本地模型输出解析 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增加 Core 级模型原始文本解析层，把 LiteRT-LM / Gemma 风格的文本输出转换为 `ModelRuntimeDraft`，并接入 resource-backed provider facade。

**Architecture:** 新增 `ModelRuntimeDraftParser.swift` 承担解析、默认值和长度裁剪；`ModelRuntime.swift` 只新增 `ModelRuntimeTextGenerator` 和 `ResourceBackedModelDraftProvider(resourceStatus:textGenerator:)` 便捷入口。现有 runner、validator、fallback 不变。

**Tech Stack:** Swift 6、Foundation JSONDecoder、Swift Package、XCTest async tests、Xcode iOS/watchOS schemes.

---

### Task 1: Parser 和 text generator 红测

**Files:**
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [x] **Step 1: Add parser tests**

Add these tests near the existing model runtime provider/parser-related tests:

```swift
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
```

```swift
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
```

```swift
func testModelRuntimeDraftParserUsesPlainTextFallback() throws {
    let draft = try ModelRuntimeDraftParser.draft(from: "今天保持稳定节奏，按 Watch 步骤完成训练。")

    XCTAssertEqual(draft.title, "本地模型建议")
    XCTAssertEqual(draft.body, "今天保持稳定节奏，按 Watch 步骤完成训练。")
    XCTAssertEqual(draft.nextAction, "发送到 Watch")
}
```

```swift
func testModelRuntimeDraftParserRejectsEmptyOutput() {
    XCTAssertThrowsError(try ModelRuntimeDraftParser.draft(from: "  \n\t ")) { error in
        XCTAssertEqual(error as? ModelRuntimeDraftParsingError, .emptyOutput)
    }
}
```

```swift
func testModelRuntimeDraftParserRejectsMissingBody() {
    XCTAssertThrowsError(try ModelRuntimeDraftParser.draft(from: #"{"title":"空输出","body":" ","nextAction":"发送到 Watch"}"#)) { error in
        XCTAssertEqual(error as? ModelRuntimeDraftParsingError, .missingBody)
    }
}
```

- [x] **Step 2: Add provider text generator test**

Add:

```swift
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
```

- [x] **Step 3: Verify RED**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testModelRuntimeDraftParser
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testResourceBackedModelDraftProviderParsesTextGeneratorOutput
```

Expected: build fails because `ModelRuntimeDraftParser`, `ModelRuntimeDraftParsingError`, and the text-generator initializer do not exist yet.

### Task 2: Core parser implementation

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeDraftParser.swift`

- [x] **Step 1: Add parser file**

Create the file with:

```swift
import Foundation

public enum ModelRuntimeDraftParsingError: Error, Equatable, LocalizedError, Sendable {
    case emptyOutput
    case missingBody

    public var errorDescription: String? {
        switch self {
        case .emptyOutput:
            return "模型输出为空"
        case .missingBody:
            return "模型输出缺少正文"
        }
    }
}

public enum ModelRuntimeDraftParser {
    public static let defaultTitle = "本地模型建议"
    public static let defaultNextAction = "发送到 Watch"

    public static func draft(from rawOutput: String) throws -> ModelRuntimeDraft {
        let trimmedOutput = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutput.isEmpty else {
            throw ModelRuntimeDraftParsingError.emptyOutput
        }

        if let jsonData = jsonObjectData(in: trimmedOutput),
           let payload = try? JSONDecoder().decode(Payload.self, from: jsonData) {
            return try draft(from: payload)
        }

        return try draftFromPlainText(trimmedOutput)
    }

    private static func draft(from payload: Payload) throws -> ModelRuntimeDraft {
        let body = trimmed(payload.body)
        guard !body.isEmpty else {
            throw ModelRuntimeDraftParsingError.missingBody
        }

        let title = trimmed(payload.title).isEmpty ? defaultTitle : trimmed(payload.title)
        let nextAction = trimmed(payload.nextAction).isEmpty ? defaultNextAction : trimmed(payload.nextAction)

        return ModelRuntimeDraft(
            title: bounded(title, maxLength: 36),
            body: bounded(body, maxLength: 240),
            nextAction: bounded(nextAction, maxLength: 40)
        )
    }

    private static func draftFromPlainText(_ text: String) throws -> ModelRuntimeDraft {
        let body = trimmed(text)
        guard !body.isEmpty else {
            throw ModelRuntimeDraftParsingError.emptyOutput
        }

        return ModelRuntimeDraft(
            title: defaultTitle,
            body: bounded(body, maxLength: 240),
            nextAction: defaultNextAction
        )
    }

    private static func jsonObjectData(in text: String) -> Data? {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}"),
            start <= end
        else {
            return nil
        }

        return String(text[start...end]).data(using: .utf8)
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func bounded(_ value: String, maxLength: Int) -> String {
        guard value.count > maxLength else {
            return value
        }

        return String(value.prefix(maxLength))
    }

    private struct Payload: Decodable {
        let title: String?
        let body: String?
        let nextAction: String?

        enum CodingKeys: String, CodingKey {
            case title
            case body
            case nextAction
            case nextActionSnakeCase = "next_action"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            body = try container.decodeIfPresent(String.self, forKey: .body)
            nextAction = try container.decodeIfPresent(String.self, forKey: .nextAction)
                ?? container.decodeIfPresent(String.self, forKey: .nextActionSnakeCase)
        }
    }
}
```

- [x] **Step 2: Run parser tests**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testModelRuntimeDraftParser
```

Expected: parser tests pass, provider text-generator test still fails until Task 3.

### Task 3: Provider text-generator bridge

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift`

- [x] **Step 1: Add text generator alias**

Add near `ModelRuntimeDraftGenerator`:

```swift
public typealias ModelRuntimeTextGenerator = @Sendable (ModelRuntimeContext) async throws -> String
```

- [x] **Step 2: Add convenience init**

Inside `ResourceBackedModelDraftProvider`, add:

```swift
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
```

- [x] **Step 3: Run provider text-generator test**

Run:

```bash
swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testResourceBackedModelDraftProviderParsesTextGeneratorOutput
```

Expected: test passes.

### Task 4: Docs and verification

**Files:**
- Modify: `README.md`
- Modify: `native/README.md`

- [x] **Step 1: Update docs**

Mention the Core model output parser and that SDK adapters can return raw text before validation.

- [x] **Step 2: Full Core test**

Run:

```bash
swift test --package-path native/FitnessRPGCore
```

- [x] **Step 3: Build iOS/watchOS**

Run:

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGModelOutputParsingIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGModelOutputParsingWatch CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 4: Commit**

Run:

```bash
git add README.md native/README.md native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntime.swift native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeDraftParser.swift native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift docs/superpowers/specs/2026-06-11-model-output-parsing-design.md docs/superpowers/plans/2026-06-11-model-output-parsing.md
git commit -m "feat(core): parse local model text output"
git push origin main
```
