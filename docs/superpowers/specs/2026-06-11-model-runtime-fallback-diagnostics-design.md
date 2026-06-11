# 模型 Runtime Fallback 诊断扩展设计

## 目标

让 DEBUG Runtime 诊断面板在本地模型 fallback 时更清楚地说明原因：区分模型资源问题、模型输出解析问题、provider/adapter 执行问题和安全校验问题。这样接入真实 LiteRT-LM / Gemma SDK 时，能快速判断 fallback 是因为 SDK 没跑起来、输出格式不对，还是输出被安全规则拦截。

## 当前问题

现有 Runtime diagnostics 已显示 provider 状态、消息、资源明细、输出来源、校验和 fallback。但当 `ResourceBackedModelDraftProvider(textGenerator:)` 解析失败时，runner 只把错误转换成 `providerFailed`，诊断面板只能看到泛化的 provider failed，不知道这是解析失败。安全校验失败虽然会显示校验 issue，但没有测试保证 fallback 面板保留该行。

## 方案

新增 Core 类型：

- `ModelRuntimeProviderFailureStage`
  - `adapter`
  - `parsing`

扩展 `ModelRuntimeProviderDiagnostics`：

- 新增可选字段 `failureStage`。
- 现有 ready/unavailable/resource diagnostics 默认 `nil`。
- runner catch provider 错误时：
  - 如果 error 是 `ModelRuntimeDraftParsingError`，设置 `.parsing`。
  - 其他错误设置 `.adapter`。

扩展 `ModelRuntimeDiagnosticsBuilder`：

- 当 `providerDiagnostics.failureStage == .parsing` 时，追加诊断行：
  - title: `解析`
  - value: `providerDiagnostics.message`
  - icon: `curlybraces.square.fill`
- 当 `providerDiagnostics.failureStage == .adapter` 时，追加诊断行：
  - title: `Adapter`
  - value: `providerDiagnostics.message`
  - icon: `wrench.and.screwdriver.fill`
- 现有 `校验` 行继续显示 validation issues，例如 `unsafeIntensityForReadiness`。

## 测试

- 新增 async Core 测试：text generator 返回缺 body 的 JSON，runner fallback 后 diagnostics summary 包含 `解析` 行。
- 新增 async Core 测试：adapter/generator 抛错时，runner fallback 后 diagnostics summary 包含 `Adapter` 行。
- 新增 Core 测试：validator 拦截红灯高强度输出，diagnostics summary 保留 `校验` 行并显示 `unsafeIntensityForReadiness`。
- 保留现有 provider/resource diagnostics 测试。

## 非目标

- 不修改 SwiftUI diagnostics UI 组件。
- 不改变 parser 规则。
- 不接入真实 LiteRT-LM / Gemma SDK。
- 不新增真实模型资源。
