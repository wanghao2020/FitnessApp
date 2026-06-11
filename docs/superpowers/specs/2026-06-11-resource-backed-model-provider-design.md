# Resource-backed 本地模型 Provider Facade 设计

## 目标

在不链接 LiteRT-LM / Gemma SDK、不提交真实模型文件的前提下，增加一个更接近真实接入形态的本地模型 provider facade。它把资源预检结果、执行 adapter 是否接入、runner fallback 行为串起来，为后续真实 SDK adapter 留出稳定入口。

## 当前问题

当前 Core 已有：

- `ModelDraftProvider`
- `ModelRuntimeRunner`
- `ModelRuntimeResourcePreflight`
- `ModelRuntimeResourceCatalog.gemmaE2B`

iOS 已能扫描 `Bundle.main/ModelResources` 并生成 `ModelRuntimeProviderDiagnostics`。但资源预检和 provider 执行仍是分离的：诊断面板知道资源是否存在，runner 还没有一个“资源驱动的真实 provider 壳”来表达下一阶段 SDK 接入状态。

## 方案

新增 Core facade：

- `ModelRuntimeDraftGenerator`
  - `@Sendable (ModelRuntimeContext) async throws -> ModelRuntimeDraft`
  - 未来真实 LiteRT/Gemma adapter 把 SDK 输出转换成 `ModelRuntimeDraft`。
- `ResourceBackedModelDraftProvider`
  - 持有 `ModelRuntimeResourcePreflightResult`。
  - 可选持有 `ModelRuntimeDraftGenerator`。
  - 继续实现 `ModelDraftProvider`。

diagnostics 规则：

- 资源未就绪：`state = .unavailable`，message 使用资源预检的首个阻塞原因，并保留 `resourceStatus`。
- 资源就绪但没有 generator：`state = .unavailable`，message 为 `模型执行 adapter 未接入`，并保留 ready 的资源明细。
- 资源就绪且有 generator：`state = .ready`，message 为 `模型资源与执行 adapter 已就绪`。

`draft(for:)` 只在 diagnostics ready 且 generator 存在时调用 generator。其他状态抛出本地 provider unavailable 错误；正常路径仍由 `ModelRuntimeRunner` 把草稿交给 `ModelOutputValidator` 和 deterministic fallback 链路。

iOS `LocalModelResourceBundleObserver` 改为：

- 私有生成 `resourceStatus`。
- 新增 `provider`，返回 `ResourceBackedModelDraftProvider(resourceStatus:)`。
- `diagnostics` 读取 `provider.diagnostics`，让 UI 路径也经过同一个 facade。

## 测试

- Core 测试资源缺失时 facade 进入 unavailable 并让 runner fallback。
- Core 测试资源就绪但 generator 缺失时仍进入 unavailable，message 明确 adapter 未接入。
- Core 测试资源就绪且 generator 存在时 runner 接受本地模型草稿。
- iOS/watchOS 构建继续通过。
- DEBUG 诊断启动截图确认 Runtime 卡仍能显示资源预检信息。

## 非目标

- 不下载、链接或调用 LiteRT-LM / Gemma SDK。
- 不提交 `.task`、`.model` 或其他真实模型资源。
- 不改变模型输出 schema。
- 不改变 Today 普通用户路径。
