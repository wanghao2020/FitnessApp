# 本地模型 Runtime 诊断面板设计

## 目标

把本地模型 adapter 边界显示到 iOS DEBUG 诊断面板中，让开发时能看到当前 provider 状态、输出来源、安全校验和 fallback 路径。

## 背景

Core 已经有：

- `ModelRuntimeContextBuilder`
- `ModelOutputValidator`
- `ModelRuntimeRunner`
- `ModelDraftProvider`
- `DeterministicModelDraftProvider`
- `UnavailableModelDraftProvider`

但 iOS 诊断面板目前仍只展示旧的 model harness 文案，没有显示真实 adapter 边界状态。后续接 LiteRT-LM / Gemma 时，需要一个稳定 UI 位置确认 provider 是否可用，以及是否走了 fallback。

## 方案

新增 Core 展示摘要：

- `ModelRuntimeDiagnosticsSummary`
- `ModelRuntimeDiagnosticsRow`
- `ModelRuntimeDiagnosticsBuilder.summary(providerDiagnostics:response:)`

SwiftUI 增加 `ModelRuntimeDiagnosticsPanel`，并让 `ModelHarnessPanel` 保留可选 `runtimeSummary` 区块以便后续嵌入式复用。在 `--fitnessrpg-show-diagnostics` 时，Today 第一屏优先显示 Runtime 诊断卡：

- provider 名称
- provider 状态
- provider message
- 输出来源
- validator 结果
- fallback 可用状态

Today 当前先显示 `DeterministicModelDraftProvider` 的 diagnostics，代表 adapter 边界已接通；不在普通用户路径显示，不改变实际 quest 生成。Runtime 卡片放在 WatchConnectivity 诊断前，避免后续继续接 SDK 时第一屏看不到 provider 状态。

## 非目标

- 不接真实 LiteRT-LM / Gemma SDK。
- 不新增模型资源文件。
- 不改变 Today 普通用户界面。
- 不让 SwiftUI 直接处理 SDK 或 provider 错误细节。

## 验证

- Core 测试覆盖 ready provider 摘要和 unavailable fallback 摘要。
- SwiftPM 全量测试通过。
- iOS 和 watchOS build 通过。
- 模拟器诊断模式截图确认本地模型 Runtime 区块显示正常。
