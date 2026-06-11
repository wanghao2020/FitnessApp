# HealthKit 来源状态 UX 执行计划

**目标：** 让 Today 能明确显示 HealthKit 来源状态，并在 fallback 时给出用户可读原因。

**架构：** Core 提供纯展示 snapshot；iOS HealthKit Provider 返回 summary + snapshot；Today 根据 snapshot 决定是否展示提示卡。

---

## Task 1: Core 红测

- [x] 新增 HealthKit 来源状态展示测试。
- [x] 运行过滤测试确认失败。

## Task 2: Core 展示模型

- [x] 新增 `HealthDataSourceStatus` 和 `HealthDataSourceSnapshot`。
- [x] 实现成功、不可用、授权失败、数据不足、loading 的文案和图标。
- [x] 运行 Core 过滤测试。

## Task 3: iOS Provider 和 ViewModel 接入

- [x] Provider 返回 `HealthKitHealthSummaryLoadResult`。
- [x] ViewModel 发布 `healthDataSourceSnapshot` 并继续发布兼容的 `sourceNote`。
- [x] 保持保守黄灯 fallback 不变。

## Task 4: Today UI 提示卡

- [x] Today 接收 `healthDataSourceSnapshot`。
- [x] fallback 状态在 Hero 下方显示 HealthKit 来源提示卡。
- [x] 成功读取和 loading 状态不增加普通路径噪音。

## Task 5: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 模拟器截图检查 fallback 提示卡。
