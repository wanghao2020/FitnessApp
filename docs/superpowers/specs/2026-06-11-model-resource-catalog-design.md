# 本地模型资源 Catalog 设计

## 目标

把 Gemma E2B 本地模型的 provider ID、显示名和资源要求集中到 Core，作为后续模型资源打包、Bundle 扫描和真实 provider 接入的单一权威入口。

## 背景

当前 iOS `LocalModelResourceBundleObserver` 已经扫描 `Bundle.main`，但它内部直接写死：

- `gemma-e2b`
- `Gemma E2B Local`
- `gemma-e2b.task`
- `tokenizer.model`

这些值后续还会被真实 LiteRT-LM / Gemma provider、资源打包脚本和诊断测试使用。如果继续散落在 iOS 层，容易出现文件名或 provider ID 漂移。

## 方案

新增 Core 资源 catalog：

- `ModelRuntimeResourceProfile`
  - 包含 providerID、displayName、requirements。
- `ModelRuntimeResourceCatalog.gemmaE2B`
  - 返回 Gemma E2B 的默认资源 profile。
  - requirements 包含：
    - `model`：`gemma-e2b.task`，最小 1024 bytes，显示名 `Model 文件`。
    - `tokenizer`：`tokenizer.model`，最小 1 byte，显示名 `Tokenizer 文件`。

iOS `LocalModelResourceBundleObserver` 改为接受 `profile`，默认使用 `ModelRuntimeResourceCatalog.gemmaE2B`。observer 仍只负责 Bundle/FileManager 扫描，不拥有资源命名规则。

## 非目标

- 不加入模型文件。
- 不链接或调用 LiteRT-LM / Gemma SDK。
- 不改变 Runtime 诊断卡 UI。
- 不改变普通用户路径。

## 验证

- Core 测试覆盖 `ModelRuntimeResourceCatalog.gemmaE2B` 的 providerID、displayName 和资源清单。
- Core 全量测试通过。
- iOS build 通过，确认 observer 使用 Core catalog 后仍可编译。
- watchOS build 通过，确认 Core catalog 不破坏 Watch target。
