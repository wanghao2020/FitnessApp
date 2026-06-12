# HealthKit 真机权限与数据覆盖验证 Runbook 设计

## 目标

为 iPhone 真机上的 HealthKit 权限、数据覆盖和 Today fallback notice 增加一份可重复执行的验证 runbook，并增加一个本机预检脚本确认工程配置没有明显遗漏。

## 背景

当前 iOS HealthKit MVP 已经具备：

- read-only HealthKit provider。
- sleep、resting heart rate、HRV、heart rate、active energy、exercise time、steps、workouts 读取。
- `HealthDataSourceSnapshot` 区分 loading、HealthKit 成功、不可用、授权未完成、数据不足。
- Today fallback notice 会展示下一步操作行。
- 实机验证总览和验证报告会汇总 HealthKit 状态。

下一步需要把这些状态变成真机验证流程，确认用户看到的 action rows 足够清楚，再决定是否需要更深 onboarding。

## 方案

新增 `native/scripts/healthkit-real-device-preflight.sh`：

- `--help` 输出说明。
- 检查命令：`xcodebuild`、`swift`、`plutil`。
- 检查 `native/AppSources/iOS/FitnessRPG.entitlements` 存在，并包含 `com.apple.developer.healthkit`。
- 检查 `native/FitnessRPG.xcodeproj/project.pbxproj` 包含：
  - `CODE_SIGN_ENTITLEMENTS = AppSources/iOS/FitnessRPG.entitlements`
  - `INFOPLIST_KEY_NSHealthShareUsageDescription`
  - `HealthKit.framework`
  - `HealthKitHealthSummaryProvider.swift`
- 可选运行 Core tests 和 iOS generic build。
- 输出 runbook 路径和推荐 DEBUG 启动参数。

新增 `docs/validation/healthkit-real-device-runbook.md`：

- 前置条件：真实 iPhone、Apple Watch 健康数据、DEBUG build。
- 验证状态：
  1. Simulator / 不支持环境：应显示 `HealthKit 不可用`。
  2. 初次/未授权：应触发授权流程；拒绝或未完成后显示 `HealthKit 权限未完成`。
  3. 数据不足：缺少睡眠、恢复或活动信号时显示 `HealthKit 数据不足` 和缺少信号。
  4. 成功读取：显示 `Apple Health 已接入`，Today readiness 使用 HealthKit 摘要。
- 每个状态都保存验证报告，确认报告正文包含 HealthKit 标题和 action rows。
- 失败分流：entitlement 缺失、usage description 缺失、授权弹窗不出现、数据不足、Simulator 误判、HealthKit 成功但仍保守黄灯。

更新 README：

- Root README 的 Next Major Work 第二项指向脚本和 runbook。
- Native README 的 HealthKit MVP / Future Integration Points 指向脚本和 runbook。

## 非目标

- 不新增 HealthKit UI。
- 不自动读写用户真实健康数据到仓库。
- 不改变 HealthKit provider 的读取范围。
- 不新增 onboarding。
- 不自动操作 iOS 设置或 Health App。

## 验证

- 先运行不存在脚本的 `--help` 作为 RED。
- 实现脚本后运行 `bash native/scripts/healthkit-real-device-preflight.sh --help`。
- 运行 `bash -n native/scripts/healthkit-real-device-preflight.sh`。
- 运行 `bash native/scripts/healthkit-real-device-preflight.sh --skip-build --skip-tests`。
- 运行 `swift test --package-path native/FitnessRPGCore`。
- 运行 iOS/watchOS generic build。
- 运行 `git diff --check`。
