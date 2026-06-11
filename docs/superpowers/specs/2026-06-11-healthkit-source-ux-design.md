# HealthKit 来源状态 UX 设计

## 目标

把 iOS Today 中的 HealthKit 读取状态从一句自由文案升级为可测试、可展示的来源状态，让用户和调试者能区分“设备不支持、授权未完成、数据不足、成功读取”。

## 背景

当前 `TodayHealthViewModel` 只发布 `sourceNote`。当 HealthKit 不可用、授权失败或样本不足时，界面都显示“HealthKit 数据缺失，已使用保守黄灯策略”。这个行为安全，但不利于用户理解下一步该做什么，也不利于后续真机调试。

## 方案

新增 Core 层展示模型：

- `HealthDataSourceStatus`
- `HealthDataSourceSnapshot`

Core 负责稳定派生：

- `sourceNote`
- `headline`
- `detail`
- `systemImageName`
- `tintName`
- `shouldShowNotice`

iOS `HealthKitHealthSummaryProvider` 返回 `HealthKitHealthSummaryLoadResult`，包含 `HealthSummary` 和 `HealthDataSourceSnapshot`。`TodayHealthViewModel` 持有 snapshot，成功读取时不额外打扰；fallback 时 Today 在 Hero 下方显示一张小型 HealthKit 来源提示卡。

## 状态

- `loading`: 正在读取 HealthKit，暂不显示提示卡。
- `healthKit`: 成功读取 HealthKit，普通路径只显示 Hero 内的来源文案。
- `unavailable`: 当前设备不支持 HealthKit。
- `authorizationDenied`: HealthKit 授权流程未完成或失败。
- `insufficientData`: 已完成读取流程，但缺少睡眠、恢复或活动中的必要信号。

## 非目标

- 不改变 Readiness 评分和保守黄灯 fallback。
- 不写入 HealthKit。
- 不打开系统设置或新增权限引导流程。
- 不在 watchOS target 引入 HealthKit。

## 验证

- Core 测试覆盖成功读取、授权 fallback、数据不足 fallback。
- iOS build 通过。
- watchOS build 通过。
- 模拟器截图确认 fallback 提示卡中文正常、无重叠。
