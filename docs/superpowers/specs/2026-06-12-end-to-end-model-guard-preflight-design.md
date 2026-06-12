# End-to-end Model Guard Preflight Design

## Goal

让端到端真机预检链覆盖本地模型工件 Git 护栏，避免验证者在准备 LiteRT-LM / Gemma 本地模型时，把授权模型包误暂存或误提交。

## Chosen Direction

在 `native/scripts/end-to-end-real-device-preflight.sh` 中增加一个独立步骤：

```bash
bash native/scripts/model-artifact-git-guard.sh
```

这个步骤应在 WatchConnectivity、HealthKit 和 LiteRT-LM wiring 检查之前运行。原因是提交安全是验证前置条件，不依赖真实设备、SDK 或模型是否存在。

## Scope

修改范围保持很小：

- 聚合 preflight help 文本列出模型工件 Git 护栏。
- 聚合 preflight 默认运行 `model-artifact-git-guard.sh`。
- 端到端 runbook 说明聚合 preflight 会检查本地模型文件是否保持 ignored/untracked。
- README 的端到端说明不需要扩展，因为入口命令不变。

## Non-goals

- 不改变 LiteRT-LM real runtime 的要求。
- 不下载、生成或提交任何模型文件。
- 不增加新的真机自动化。
- 不改变 iOS/watchOS app 行为。

## Test Strategy

先用命令证明当前轻量路径没有输出模型 Git 护栏步骤：

```bash
bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices | rg "Checking local model artifact git guard"
```

预期：失败，因为当前聚合 preflight 没有调用护栏。

实现后运行：

```bash
bash -n native/scripts/end-to-end-real-device-preflight.sh
bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices
bash native/scripts/model-artifact-git-guard.sh
swift test --package-path native/FitnessRPGCore
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
git diff --check
```
