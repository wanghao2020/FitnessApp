# 2026-06-12 Demo Scheme Runbook Design

## 目标

在 demo seed 已经可用的基础上，增加一个一键演示入口：共享 Xcode scheme `FitnessRPGDemo` 和命令行 smoke 脚本。后续演示不需要手动记启动参数，就能构建、安装、启动并验证 demo 数据落盘。

## 范围

- 新增 `native/FitnessRPG.xcodeproj/xcshareddata/xcschemes/FitnessRPGDemo.xcscheme`。
- `FitnessRPGDemo` 复用 iOS app target，LaunchAction 默认启用：
  - `--fitnessrpg-demo-seed`
  - `--fitnessrpg-open-history`
  - `--fitnessrpg-show-diagnostics`
- 新增 `native/scripts/demo-seed-simulator-smoke.sh`，用于构建 simulator app、安装到 booted iPhone 模拟器、用 demo 参数启动、检查 JSON seed 文件。
- 新增 `docs/validation/demo-seed-runbook.md`，记录 Xcode 和 CLI 两条演示路径。
- 更新 README / native README，把 demo 入口放到当前验证说明中。

## 成功标准

- `xcodebuild -project native/FitnessRPG.xcodeproj -list` 能列出 `FitnessRPGDemo`。
- `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGDemo -destination 'platform=iOS Simulator,id=<booted iPhone>' CODE_SIGNING_ALLOWED=NO build` 通过。
- `bash native/scripts/demo-seed-simulator-smoke.sh` 能构建、安装、启动 app，并确认 `training-days.json`、`weekly-summary-polish-entries.json`、`validation-reports.json` 包含 demo 关键字段。

## 非目标

- 不改 release 行为。
- 不新增真实 HealthKit、WatchConnectivity 或 LiteRT-LM 依赖。
- 不替换已有 `FitnessRPG` 和 `FitnessRPGWatch` schemes。
