# 本地模型资源打包入口设计

## 目标

为真实本地模型文件预留稳定的 iOS 打包路径，让后续把 `gemma-e2b.task` 和 `tokenizer.model` 放入仓库时，Bundle 扫描、Core catalog 和 Xcode 资源阶段都指向同一个位置。

## 背景

当前 Core catalog 已集中定义 Gemma E2B 的 provider ID、显示名和资源要求，iOS `LocalModelResourceBundleObserver` 会按 catalog 扫描 `Bundle.main`。但 catalog 仍指向 bundle 根目录文件名。后续如果真实模型资源直接散在 app bundle 根目录，项目会难以管理，也不利于扩展多个模型 profile。

## 方案

新增 iOS 资源目录：

- `native/AppSources/iOS/ModelRuntime/ModelResources/`

该目录作为 Xcode folder reference 加入 iOS target 的 Resources build phase。Core catalog 的文件路径改为：

- `ModelResources/gemma-e2b.task`
- `ModelResources/tokenizer.model`

目录内只提交 `README.md`，说明真实模型文件如何放置；不提交 `.task` 或 tokenizer 模型文件。`LocalModelResourceBundleObserver` 已经通过 `bundle.resourceURL?.appendingPathComponent(fileName)` 读取 catalog 路径，不需要额外改扫描逻辑。

## 非目标

- 不提交真实模型文件。
- 不下载或链接 LiteRT-LM / Gemma SDK。
- 不改变 Runtime 诊断卡布局。
- 不改变普通用户路径。

## 验证

- Core 测试覆盖 catalog 中的资源路径带 `ModelResources/` 前缀。
- iOS build 通过。
- 构建产物包含 `FitnessRPG.app/ModelResources/README.md`。
- watchOS build 通过。
- `git diff --check` 通过。
