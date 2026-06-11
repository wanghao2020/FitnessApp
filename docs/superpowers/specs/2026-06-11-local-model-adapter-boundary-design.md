# 本地模型 Adapter 边界设计

## 目标

在不接入真实 LiteRT-LM / Gemma SDK 的前提下，为 Core 增加本地模型 adapter 边界：未来真实模型只需要实现 provider 协议，所有输出仍必须经过确定性 validator 和 fallback。

## 背景

上一轮已经完成 `ModelRuntimeContextBuilder`、`ModelOutputValidator` 和 `ModelRuntimeOrchestrator`。现在缺少一个可替换的异步 provider 接口。没有这个边界，后续接真实模型时容易把 SDK 细节、模型文件状态和安全校验混在一起。

## 方案

新增 Core 类型：

- `ModelDraftProvider`
  - 异步产生 `ModelRuntimeDraft`。
  - 暴露 `ModelRuntimeProviderDiagnostics`。
- `ModelRuntimeRunner`
  - 检查 provider 是否 ready。
  - 调用 provider。
  - 将草稿交给 `ModelRuntimeOrchestrator`。
  - provider 不可用或抛错时返回确定性 fallback。
- `DeterministicModelDraftProvider`
  - 可测试的占位 provider。
  - 不代表真实模型，只用于连接 UI/诊断和 adapter 边界。
- `UnavailableModelDraftProvider`
  - 表示 SDK 或模型文件尚未安装。

## 非目标

- 不下载或链接 LiteRT-LM / Gemma。
- 不新增模型资源文件。
- 不改变 Today 用户路径。
- 不绕过 `ModelOutputValidator`。

## 验证

- Core 测试覆盖 ready provider、unavailable provider、deterministic stub provider。
- 全量 SwiftPM 测试通过。
- iOS 和 watchOS build 通过。
