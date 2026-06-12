# Model Artifact Git Guard Design

## Goal

防止本地授权模型包、LiteRT-LM `.litertlm` 文件和其他模型二进制被误提交到仓库，同时保留本地真机验证所需的放置路径与文档模板。

## Chosen Direction

采用仓库级轻量护栏：

1. `.gitignore` 只忽略 `ModelResources` 下的本地模型工件，不影响 README 或 manifest 模板。
2. 新增一个可重复运行的 shell 校验脚本，检查已跟踪和暂存的模型工件。
3. 将校验脚本接入 LiteRT-LM 集成 checklist，让真机验证前置步骤自动覆盖提交安全。

这样可以让开发者继续把授权模型放在 iOS bundle 资源目录进行本机测试，但 Git 默认不会带走模型包。

## Scope

需要保护的路径：

- `native/AppSources/iOS/ModelRuntime/ModelResources/`

需要阻止进入 Git 的文件类型：

- `.litertlm`
- `.task`
- `.tflite`
- `.onnx`
- `.mlmodel`
- `.mlpackage`

允许继续提交：

- `README.md`
- `model-package-manifest.example.json`
- 未来的小型文档或模板文件

## Behavior

`native/scripts/model-artifact-git-guard.sh` 应该：

- 在仓库根目录运行，也可以从任意目录调用。
- 验证 `.gitignore` 包含当前模型工件忽略规则。
- 检查 `git ls-files` 中是否已有被跟踪的模型工件。
- 检查 `git diff --cached --name-only` 中是否有暂存的模型工件。
- 发现问题时输出具体路径和修复提示。
- 没有问题时输出明确通过信息。

## Integration

`native/scripts/litertlm-integration-checklist.sh` 应该把 Git 护栏作为默认检查的一部分。即使还没有真实 LiteRTLM SDK 或模型包，默认 fallback checklist 也应该能够证明：

- 本地模型目录可以保留文档和模板。
- 授权模型文件不会被误提交。
- 后续 `--require-real-runtime` 只负责真实运行时和模型存在性，不负责替代 Git 护栏。

## Testing

验证命令：

```bash
bash -n native/scripts/model-artifact-git-guard.sh
bash native/scripts/model-artifact-git-guard.sh
bash native/scripts/litertlm-integration-checklist.sh
git check-ignore native/AppSources/iOS/ModelRuntime/ModelResources/gemma-4-E2B-it.litertlm
swift test --package-path native/FitnessRPGCore
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
git diff --check
```
