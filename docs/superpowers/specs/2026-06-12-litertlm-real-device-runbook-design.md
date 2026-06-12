# LiteRT-LM / Gemma 真机执行验证 Runbook 设计

## 目标

为真实 LiteRT-LM / Gemma 模型执行增加一份可重复的验证 runbook 和本机预检脚本。默认路径确认当前 fallback 诊断链路仍健康；当授权模型包和 Swift SDK 准备好后，可用强制参数检查真实 runtime 所需资源、SDK 标记和编译 flag。

## 背景

当前本地模型链路已经具备：

- Core prompt formatter、raw text parser、validator 和 deterministic fallback。
- `ModelRuntimeResourceCatalog.gemmaE2B` 指向 `ModelResources/gemma-4-E2B-it.litertlm`。
- iOS `GemmaLocalModelAdapter` 通过 `#if canImport(LiteRTLM) && FITNESSRPG_ENABLE_LITERTLM` 包裹真实执行入口。
- `ModelResources/README.md` 说明不提交大型或受限模型文件。
- DEBUG Runtime diagnostics 和验证报告可以展示资源、adapter、parser、validator 和 fallback 状态。

缺口是：真实 SDK / 模型文件接入前后没有固定验证流程。开发者容易只看到 fallback 文案，却不清楚是模型资源缺失、SDK 未链接、编译 flag 没开，还是输出被 parser/validator 拦截。

## 方案

新增 `native/scripts/litertlm-real-device-preflight.sh`：

- `--help` 输出说明。
- 默认检查：
  - `xcodebuild`、`swift`。
  - `GemmaLocalModelAdapter.swift` 存在并包含 `canImport(LiteRTLM)` 和 `FITNESSRPG_ENABLE_LITERTLM`。
  - `ModelResources/README.md` 存在并提到 `gemma-4-E2B-it.litertlm`。
  - `project.pbxproj` 包含 `ModelResources` folder reference 和 resources build phase。
  - Core catalog / tests 已引用 `ModelResources/gemma-4-E2B-it.litertlm`。
- 默认可运行 Core tests、iOS generic build、watchOS generic build。
- `--require-real-runtime` 强制额外检查：
  - `native/AppSources/iOS/ModelRuntime/ModelResources/gemma-4-E2B-it.litertlm` 存在且大于 1024 bytes。
  - `project.pbxproj` 包含 `LiteRTLM` 字样。
  - `project.pbxproj` 包含 `FITNESSRPG_ENABLE_LITERTLM` 字样。

新增 `docs/validation/litertlm-real-device-runbook.md`：

- 默认 fallback pass：无 SDK/模型时，验证 Runtime diagnostics 清楚显示资源或 adapter blocker，并保存报告。
- Fixture pass：用现有 DEBUG fixture 启动参数验证 ready、parsing failure、adapter failure、validator failure。
- Real runtime pass：添加 SDK、放入授权 `.litertlm`、打开 flag 后，在真实 iPhone 上验证 diagnostics 变为 ready，并确认模型输出经过 parser/validator 后进入 Today/History weekly polish。
- 失败分流：模型包缺失、模型包过小、SDK 未链接、flag 未打开、parser 失败、validator 拒绝、设备性能或内存问题。

更新 README：

- Root README 的 Next Major Work 第三项指向脚本和 runbook。
- Native README 的 Future Integration Points 指向脚本和 runbook。
- `ModelResources/README.md` 增加脚本/runbook 入口。

## 非目标

- 不下载或提交真实模型文件。
- 不添加未经确认的 Swift package URL。
- 不默认打开 `FITNESSRPG_ENABLE_LITERTLM`。
- 不改变 fallback、parser 或 validator 行为。
- 不改变用户可见 UI。

## 验证

- 先运行不存在脚本的 `--help` 作为 RED。
- 实现脚本后运行 `bash native/scripts/litertlm-real-device-preflight.sh --help`。
- 运行 `bash -n native/scripts/litertlm-real-device-preflight.sh`。
- 运行 `bash native/scripts/litertlm-real-device-preflight.sh --skip-build --skip-tests`。
- 运行 `swift test --package-path native/FitnessRPGCore`。
- 运行 iOS/watchOS generic build。
- 运行 `git diff --check`。
