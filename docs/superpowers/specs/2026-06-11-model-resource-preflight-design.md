# 本地模型资源预检设计

## 目标

在接入真实 LiteRT-LM / Gemma SDK 之前，先为 Core 增加模型资源清单和可用性预检。这样 provider 可以明确区分“SDK/模型文件未安装”“资源文件过小或损坏”和“资源就绪”，诊断 UI 也能显示更具体的 fallback 原因。

## 背景

当前 Core 已有：

- `ModelDraftProvider`
- `ModelRuntimeRunner`
- `ModelRuntimeProviderDiagnostics`
- `ModelRuntimeDiagnosticsBuilder`
- DEBUG Runtime 诊断卡片

但 provider diagnostics 只有单条 message。后续接真实模型时，如果缺 model、tokenizer 或 config 文件，只能写成模糊的“模型不可用”。需要一个不依赖具体 SDK 的资源预检层，让平台 adapter 或真实 provider 把 Bundle / 文件系统扫描结果转换成 Core 可测试的数据。

## 方案

新增 Core 资源预检类型：

- `ModelRuntimeResources.swift`
  - 独立承载资源预检类型，避免 `ModelRuntime.swift` 继续膨胀。
- `ModelRuntimeResourceKind`
  - 区分 model、tokenizer、config、other。
- `ModelRuntimeResourceRequirement`
  - 描述 provider 需要的资源 ID、显示名、文件名和最小字节数。
- `ModelRuntimeResourceObservation`
  - 表示平台层观察到的某个资源是否存在、大小是多少。
- `ModelRuntimeResourceStatus`
  - 将 requirement 和 observation 合并成 ready、missing、invalid 三种状态。
- `ModelRuntimeResourcePreflightResult`
  - 聚合 provider 级状态、message 和资源行。
- `ModelRuntimeResourcePreflight.evaluate(...)`
  - 输入 requirement 列表和 observation 列表，输出稳定、可测试的预检结果。

`ModelRuntimeProviderDiagnostics` 增加可选 `resourceStatus`。当 provider 使用资源预检结果时：

- 资源全部就绪：diagnostics state 为 ready，message 为资源就绪说明。
- 缺资源或资源过小：diagnostics state 为 unavailable，message 说明首个阻塞原因。
- `ModelRuntimeDiagnosticsBuilder` 在有 resourceStatus 时增加“资源”行，继续保留 provider、状态、消息、输出来源、校验、fallback 行。

## 非目标

- 不下载模型。
- 不链接 LiteRT-LM / Gemma SDK。
- 不读取真实 Bundle 或文件系统。
- 不改变 Today 普通用户路径。
- 不让资源预检成为训练安全判断来源。

## 验证

- Core 测试覆盖资源全部就绪。
- Core 测试覆盖缺 tokenizer。
- Core 测试覆盖 model 文件小于最小字节数。
- Core 测试覆盖 diagnostics summary 增加资源行。
- SwiftPM 全量测试通过。
- iOS 和 watchOS build 通过。
