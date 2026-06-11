# 本地模型输出解析边界设计

## 目标

为未来 LiteRT-LM / Gemma SDK 接入增加一个 Core 级解析层，把模型原始文本输出转换成 `ModelRuntimeDraft`。真实 SDK 可以先返回 `String`，Core 负责解析、裁剪和交给现有 validator/fallback 链路。

## 当前问题

当前 `ModelDraftProvider` 和 `ResourceBackedModelDraftProvider` 已经能接收 `ModelRuntimeDraft`。但真实本地模型通常先返回自由文本或 JSON 文本，如果每个 SDK adapter 自己解析，后续容易出现：

- JSON key 不一致。
- markdown fenced JSON 解析分散。
- 空输出或缺 body 的错误分类不稳定。
- 输出过长直接进入 UI 和 Watch payload。

## 方案

新增 Core 文件：

- `native/FitnessRPGCore/Sources/FitnessRPGCore/ModelRuntimeDraftParser.swift`

新增类型：

- `ModelRuntimeDraftParsingError`
  - `emptyOutput`
  - `missingBody`
- `ModelRuntimeDraftParser`
  - `draft(from:) throws -> ModelRuntimeDraft`

解析规则：

- 输入为空或只有空白时抛 `emptyOutput`。
- 如果文本中包含 JSON object，则优先解析 JSON。
  - 支持纯 JSON。
  - 支持 markdown fenced JSON 或前后有说明文字的 JSON object。
  - 支持 `nextAction` 和 `next_action`。
  - `body` 为空时抛 `missingBody`。
  - `title` 为空时使用默认 `本地模型建议`。
  - `nextAction` 为空时使用默认 `发送到 Watch`。
- 如果不是 JSON，则作为普通文本解析。
  - 使用默认 title。
  - body 使用去空白后的原文。
  - nextAction 使用默认 `发送到 Watch`。
- 输出裁剪：
  - title 最多 36 个字符。
  - body 最多 240 个字符。
  - nextAction 最多 40 个字符。

扩展 provider：

- 新增 `ModelRuntimeTextGenerator`
  - `@Sendable (ModelRuntimeContext) async throws -> String`
- `ResourceBackedModelDraftProvider` 新增 init：
  - `init(resourceStatus:textGenerator:)`
  - 内部调用 `ModelRuntimeDraftParser.draft(from:)`。

## 测试

- 纯 JSON 输出解析成 `ModelRuntimeDraft`。
- fenced JSON 且使用 `next_action` 能解析。
- 普通中文段落能使用默认 title/nextAction。
- 空输出抛 `emptyOutput`。
- JSON body 为空抛 `missingBody`。
- textGenerator initializer 能让 resource-backed provider 走 local model 路径。

## 非目标

- 不接入或下载 LiteRT-LM / Gemma SDK。
- 不提交真实模型资源。
- 不修改 `ModelOutputValidator` 规则。
- 不改变 SwiftUI Runtime diagnostics 布局。
