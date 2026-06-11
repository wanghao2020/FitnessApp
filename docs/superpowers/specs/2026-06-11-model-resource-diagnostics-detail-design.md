# 模型资源诊断明细设计

## 目标

让 DEBUG Runtime 诊断面板在显示 Bundle 模型资源预检结果时，不只显示首个阻塞原因，还能逐项展示 Gemma E2B 所需资源的状态。这样设备调试时可以同时看到 model 文件过小、tokenizer 缺失或资源就绪等细节。

## 当前问题

Core 已经通过 `ModelRuntimeResourcePreflightResult.statuses` 保存每个资源的状态，但 `ModelRuntimeDiagnosticsBuilder` 只把 `resourceStatus.message` 转成一条“资源”汇总行。UI 面板因此只能看到首个失败原因，无法一次性判断还缺哪些文件。

## 方案

采用小范围 Core 改动：

- 保留现有“资源”汇总行，继续显示 provider 级 message。
- 在汇总行后追加每个 `ModelRuntimeResourceStatus` 的明细行。
- 明细行标题使用 `资源 · <displayName>`，避免与汇总行 ID 冲突。
- 明细行 value 使用现有 `status.detail`，不在 UI 层重新解释资源状态。
- 资源过小文案在 Core 预检层归一化，避免 `Model 文件 文件过小` 这类重复词出现在诊断面板。
- 明细行图标按状态映射：
  - `ready`: `checkmark.circle.fill`
  - `missing`: `xmark.circle.fill`
  - `invalid`: `exclamationmark.triangle.fill`

SwiftUI 面板已有通用 row renderer，本次不新增视图结构，也不改变生产构建开关。

## 测试

- 新增 Core 测试覆盖同时存在 invalid model 和 missing tokenizer 时，summary 包含两条资源明细行。
- 保留现有资源汇总行测试，防止诊断卡丢失 provider 级原因。
- 运行 Core 全量测试、iOS 构建、watchOS 构建，并用诊断启动参数截图确认面板仍能渲染。

## 非目标

- 不引入 LiteRT-LM / Gemma SDK。
- 不提交真实模型文件。
- 不重做 Runtime diagnostics UI 布局。
