# 模型 Runtime DEBUG Fixture 设计

## 目标

为 iOS DEBUG 诊断模式增加可重复的本地模型 fixture 路径。开发时不需要真实 LiteRT/Gemma SDK 或模型文件，也能验证 adapter、raw text 解析、validator 和 fallback 诊断展示。

## 背景

当前 Runtime 面板已经能显示 Bundle 模型资源预检和 adapter 缺席状态。问题是：在没有真实模型资源时，诊断路径总是停在资源缺失，无法快速验证 ready provider、解析失败、adapter 抛错和 validator fallback 的 UI 表达。

## 方案

- 在 Core 增加 `ModelRuntimeDebugFixtureMode` 和 launch arg 解析。
  - `--fitnessrpg-model-fixture-ready`
  - `--fitnessrpg-model-fixture-parsing-failure`
  - `--fitnessrpg-model-fixture-adapter-failure`
  - `--fitnessrpg-model-fixture-validator-failure`
- 在 iOS DEBUG 编译下新增 `DebugGemmaLocalModelAdapter`。
  - ready 返回安全 JSON。
  - parsing failure 返回空白 raw text。
  - adapter failure 抛出 SDK 未接入错误。
  - validator failure 返回不适合非绿灯 readiness 的高强度建议。
- `LocalModelResourceBundleObserver` 支持 resource status override。
  - 普通路径继续扫描 Bundle。
  - fixture 路径注入模拟 ready 资源状态，避免被模型文件缺失挡住。
- Today 诊断面板在 fixture mode 下执行一次 `ModelRuntimeRunner.response`。
  - 非 fixture 模式只展示 provider/resource 状态，不主动执行本地模型。
  - response 的 failed diagnostics 优先展示，保证 adapter/parser 失败行可见。

## UI/UX 原则

- 保持现有小半径诊断卡片、SF Symbols 图标和中文状态文案。
- 不增加用户可见入口；fixture 只通过 DEBUG launch args 使用。
- 诊断信息按开发者排障顺序展示：Provider、状态、消息、资源、输出来源、校验、fallback。

## 非目标

- 不接入真实 SDK。
- 不下载或打包模型文件。
- 不新增生产开关。
- 不改变 Today 普通用户路径。

## 验证

- Core 测试覆盖 launch arg 解析。
- SwiftPM 全量测试通过。
- iOS / watchOS target 构建通过。
- iOS Simulator 使用 fixture 启动后截图检查 Runtime 面板不空白、不乱码。
