# iOS Gemma Adapter 占位层设计

## 目标

在不链接 LiteRT/Gemma SDK、不引入真实模型文件的前提下，为 iOS target 建立一个清晰的本地模型 adapter 接入点。资源预检、raw text 解析、validator 和 fallback 仍由 `FitnessRPGCore` 统一处理。

## 背景

Core 已经具备模型资源目录、Bundle 资源预检、resource-backed provider、raw text parser 和诊断摘要。iOS 当前只能把 Bundle 资源状态传给 Core provider；下一步需要一个真实 SDK 可以替换的边界，否则后续接 SDK 时容易把平台执行细节塞进 observer 或 UI。

## 方案

- 新增 `GemmaLocalModelAdapting` 协议。
  - 暴露 `isAvailable`，让平台层决定 SDK adapter 是否可用。
  - 暴露 `generateText(for:)`，只返回模型 raw text，不直接返回 UI 文案状态。
- 新增默认 `GemmaLocalModelAdapter`。
  - 默认 `isAvailable == false`。
  - 如果被直接调用，抛出 “LiteRT/Gemma SDK 尚未接入”。
  - 不导入、链接或模拟真实 SDK。
- 扩展 `LocalModelResourceBundleObserver`。
  - 继续扫描 `Bundle.main/ModelResources`。
  - adapter 可用时把 raw text generator 传给 Core provider。
  - adapter 不可用时传 `nil`，Core 显示 “模型执行 adapter 未接入” 并走确定性 fallback。
- 扩展 Core provider facade。
  - 增加 optional text-generator 初始化入口，避免 iOS 层重复 adapter 缺席逻辑。

## 非目标

- 不下载模型。
- 不链接 LiteRT/Gemma SDK。
- 不改变 Today 默认用户路径。
- 不调整诊断 UI 版式，只保持现有系统图标、中文文案和小半径面板风格。

## 验证

- Core 红绿测试覆盖 optional text generator 的 nil/可用两种路径。
- SwiftPM 全量测试通过。
- iOS 和 watchOS Xcode build 通过。
- DEBUG 诊断启动可继续展示本地模型 Runtime 面板。
