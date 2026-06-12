# LiteRT-LM Integration Kit 设计

## 目标

为未来真实 LiteRT-LM / Gemma SDK 接入补一套本地工程工具包：示例 `.xcconfig`、模型包 manifest 模板、接入 checklist 脚本和文档入口。目标是让开发者拿到 SDK URL、授权模型包和签名设备后，知道应该改哪几个位置，并能在默认 fallback 和真实 runtime 两种模式下快速验证。

## 背景

当前仓库已经具备：

- iOS `GemmaLocalModelAdapter` 的 conditional bridge：`canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM`。
- `ModelResources/gemma-4-E2B-it.litertlm` 的 Core catalog 和 Bundle diagnostics。
- `litertlm-real-device-preflight.sh --require-real-runtime`，可检查模型包、`LiteRTLM` 项目引用和编译 flag。
- LiteRT-LM 单点 runbook 和端到端 runbook。

缺口是：接入前没有一套可复制的 Xcode flag 模板和模型包记录模板。真实 SDK 接入通常要经过 Xcode 手工添加 package、target link、build flag、模型文件放置、runbook 复测；如果这些步骤散落在 runbook 段落里，容易漏掉或留下无法复现的模型包来源。

## 方案

新增 `native/Config/LiteRTLMRealRuntime.example.xcconfig`：

- 只作为示例，不自动接入 project。
- 包含 `SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) FITNESSRPG_ENABLE_LITERTLM`。
- 注释说明启用前必须先把 LiteRTLM package product link 到 iOS target。

新增 `native/AppSources/iOS/ModelRuntime/ModelResources/model-package-manifest.example.json`：

- 记录 expected file name、bundle relative path、minimum byte size、license/source notes、checksum 占位字段。
- 明确不要提交真实模型文件。

新增 `native/scripts/litertlm-integration-checklist.sh`：

- 默认检查当前桥接代码、示例 xcconfig、manifest 模板、ModelResources README、runbook 和真实 runtime preflight 是否存在。
- 默认调用 `litertlm-real-device-preflight.sh --skip-build --skip-tests` 验证现有 fallback wiring。
- `--require-real-runtime` 透传给 `litertlm-real-device-preflight.sh --require-real-runtime`，供真实 SDK/模型接入后使用。

更新文档入口：

- `native/AppSources/iOS/ModelRuntime/ModelResources/README.md` 增加 manifest 示例和 checklist 脚本说明。
- `docs/validation/litertlm-real-device-runbook.md` 增加“Integration Kit”小节。
- `native/README.md` 的 LiteRT-LM bullet 指向 checklist。
- Root `README.md` 的 LiteRT-LM 下一步指向 checklist。

## 非目标

- 不添加 LiteRTLM Swift package URL。
- 不修改 `project.pbxproj` 的 packageReferences 或 target link 阶段。
- 不开启 `FITNESSRPG_ENABLE_LITERTLM`。
- 不提交 `.litertlm` 模型文件。
- 不改变 Runtime adapter、parser、validator 或 fallback 行为。

## 验证

- RED：`bash native/scripts/litertlm-integration-checklist.sh --help` 在脚本不存在时失败。
- GREEN：脚本 `--help` 输出 usage。
- 语法检查：`bash -n native/scripts/litertlm-integration-checklist.sh`。
- 轻量路径：`bash native/scripts/litertlm-integration-checklist.sh`。
- 现有 LiteRT-LM 轻量 preflight：`bash native/scripts/litertlm-real-device-preflight.sh --skip-build --skip-tests`。
- `swift test --package-path native/FitnessRPGCore`。
- iOS/watchOS generic build。
- `git diff --check`。
