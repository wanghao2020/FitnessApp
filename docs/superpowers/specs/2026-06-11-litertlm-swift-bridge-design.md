# LiteRT-LM Swift 接入桥设计

## 目标

把 iOS 本地模型占位层推进到可接 LiteRT-LM Swift SDK 的形态，同时保持默认仓库在没有 SDK、没有模型资源时仍能编译、运行并走确定性 fallback。

## 背景

当前本地模型链路已经具备：

- `ModelRuntimeContext`：只包含 bounded app context，不暴露原始 HealthKit 或 WatchConnectivity 数据。
- `ModelRuntimeDraftParser`：把模型原始文本解析成 `ModelRuntimeDraft`。
- `ModelOutputValidator`：校验安全文案，必要时 fallback。
- `ResourceBackedModelDraftProvider`：把资源预检、adapter 执行和 fallback 统一起来。
- iOS `GemmaLocalModelAdapter`：目前只报告 “LiteRT/Gemma SDK 尚未接入”。

后续真实 SDK 接入需要两个更稳定的接口：

1. 资源目录要贴近 LiteRT-LM 的 `.litertlm` 模型包，而不是旧的 `.task + tokenizer.model` 散文件。
2. Adapter 需要把 `ModelRuntimeContext` 格式化为模型可读 prompt，并在 SDK 缺失时继续保持明确 fallback。

## 设计

### Core Prompt 格式

新增 Core 级 `ModelRuntimePrompt` 和 `ModelRuntimePromptFormatter`。

`ModelRuntimePrompt` 包含：

- `systemInstruction`：固定安全规则、输出语言和 JSON contract。
- `userMessage`：由 `ModelRuntimeContext` 派生，包含 readiness、quest、story、watch steps、memory 和 safety rules。
- `rawText`：把 system 与 user 合并，给只接受单字符串 prompt 的 adapter 使用。

输出 contract 要求模型优先返回 JSON：

```json
{"title":"...","body":"...","nextAction":"..."}
```

解析和安全校验仍然由 Core 现有链路负责，adapter 不直接信任模型输出。

### LiteRT-LM 资源 Profile

把 `ModelRuntimeResourceCatalog.gemmaE2B` 改为面向 LiteRT-LM Swift 的单文件容器：

- provider ID：`gemma-4-e2b-litertlm`
- display name：`Gemma 4 E2B LiteRT-LM`
- required file：`ModelResources/gemma-4-E2B-it.litertlm`

现有资源预检仍然检查 bundle 内文件是否存在、大小是否满足最小值，并把状态展示到 DEBUG diagnostics。

### iOS Adapter

`GemmaLocalModelAdapter` 增加 bundle/profile/fileManager 配置，用 catalog 中的 `.litertlm` 文件定位模型包。

默认构建不链接外部 SDK：

- `isAvailable == false`
- provider 显示 adapter 未接入或资源缺失
- app 继续使用 deterministic fallback

当未来工程加入 `LiteRTLM` Swift package，并显式开启 `FITNESSRPG_ENABLE_LITERTLM` 编译标记时，adapter 的 conditional code 会：

1. 使用 `.litertlm` 模型包路径创建 LiteRT-LM engine。
2. 用 `ModelRuntimePromptFormatter` 生成 prompt。
3. 返回原始文本交给 Core parser/validator。

## 非目标

- 不下载或提交真实模型文件。
- 不默认打开 `FITNESSRPG_ENABLE_LITERTLM`。
- 不绕过现有 parser、validator 或 deterministic fallback。
- 不把 SDK 类型暴露到 `FitnessRPGCore`。
- 不改变 Today、History 或 Watch 的业务逻辑。

## 验证

- Core tests 覆盖 prompt formatter、`.litertlm` catalog 和资源预检文案。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS/watchOS generic build 通过。
- DEBUG diagnostics 在无模型包时仍显示清晰 missing resource/fallback。
