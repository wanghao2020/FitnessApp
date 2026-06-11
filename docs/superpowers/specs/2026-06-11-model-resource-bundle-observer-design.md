# 本地模型 Bundle 资源观察器设计

## 目标

把上一轮 Core 模型资源预检接到 iOS 的 Bundle/文件扫描，让 DEBUG Runtime 诊断卡可以显示真实 app bundle 中模型资源是否存在，而不是只显示 deterministic stub provider 状态。

## 背景

Core 已经有 SDK 无关的资源预检：

- `ModelRuntimeResourceRequirement`
- `ModelRuntimeResourceObservation`
- `ModelRuntimeResourcePreflight`
- `ModelRuntimeProviderDiagnostics.resourceStatus`

缺口是 iOS 侧还没有把 `Bundle.main` 里的模型文件转换成 observations。后续接 LiteRT-LM / Gemma SDK 前，需要先能稳定看到“缺少 model/tokenizer”这类状态。

## 方案

采用推荐方案：Core 可测试转换 + iOS 薄扫描器。

1. Core 新增 `ModelRuntimeResourceFileSnapshot`
   - 表示平台层看到的文件名和字节数。
   - 不包含 URL、Bundle 或 FileManager。

2. Core 新增 `ModelRuntimeResourceObservationBuilder`
   - 输入 resource requirements 和 file snapshots。
   - 只为匹配 `fileName` 的 requirement 生成 observation。
   - 预检仍由 `ModelRuntimeResourcePreflight.evaluate(...)` 负责判断 missing/invalid/ready。

3. iOS 新增 `LocalModelResourceBundleObserver`
   - 默认扫描 `Bundle.main`。
   - 使用一组本地模型 requirements：`gemma-e2b.task` 和 `tokenizer.model`。
   - 从 Bundle resourceURL/FileManager 读取文件大小。
   - 输出 `ModelRuntimeProviderDiagnostics(providerID:displayName:resourceStatus:)`。

4. Today DEBUG diagnostics 改为使用 `LocalModelResourceBundleObserver().diagnostics`
   - 当前没有真实模型资源时会显示不可用和缺失原因。
   - 普通用户路径不显示该诊断卡，也不改变任务生成。

## 非目标

- 不加入真实模型文件。
- 不下载或链接 LiteRT-LM / Gemma SDK。
- 不执行模型推理。
- 不改变 Watch payload 或训练安全规则。

## 验证

- Core 测试覆盖 file snapshot 生成 observation。
- Core 测试覆盖未匹配文件不会生成 observation。
- SwiftPM 全量测试通过。
- iOS build 通过，确认 Xcode project 已包含新 iOS 文件。
- watchOS build 通过，确认 Core 变更不破坏 Watch target。
- iOS 模拟器诊断模式截图确认 Runtime 卡显示资源缺失原因。
