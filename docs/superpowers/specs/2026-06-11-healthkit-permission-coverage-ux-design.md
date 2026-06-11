# HealthKit 权限与数据覆盖 UX 设计

## 目标

让 Today 页面在 HealthKit 不可用、授权未完成或数据不足时，不只说明系统已切到保守黄灯，还明确告诉用户下一步该做什么。

## 背景

当前 `HealthDataSourceSnapshot` 已能区分 HealthKit 成功读取、不可用、授权未完成和数据不足。Today 也会在 fallback 状态显示来源提示卡，但卡片主要是一段说明文字，缺少可扫读的行动项。真机调试时，用户仍需要自己判断是设备问题、权限问题还是 Apple Health 数据覆盖不足。

## 设计

本轮在 `FitnessRPGCore` 中为 `HealthDataSourceSnapshot` 增加结构化 action rows。Core 继续只输出可展示文案和 SF Symbols 名称，不依赖 SwiftUI 或 HealthKit framework。

每个 fallback 状态提供 2-3 行：

- `unavailable`: 真机/设备检查、当前保守策略。
- `authorizationDenied`: iOS 健康权限路径、当前保守策略。
- `insufficientData`: 缺少的信号、补齐数据方式、当前保守策略。

Today 的 `TodayHealthSourceNoticeCard` 在现有标题和说明下方渲染这些行。视觉上保持紧凑、可扫读、支持多行中文，并复用系统图标、系统字体和现有 8pt 圆角卡片风格。

## UX 原则

- 先解释状态，再给下一步。
- 不把 fallback 写成错误；这是安全策略。
- 文案面向普通用户，同时保留真机验证需要的诊断线索。
- UI 不新增入口、不引入大面积视觉重构。

## 非目标

- 不改变 HealthKit 授权请求、读取类型或采样逻辑。
- 不写入 HealthKit。
- 不加入独立 onboarding 流程。
- 不在 watchOS target 引入 HealthKit。
- 不把原始 HealthKit samples 暴露给模型 prompt 或历史记录。

## 验证

- Core tests 覆盖各 fallback 状态的 action rows。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS 和 watchOS generic build 通过。
- 在模拟器或截图中检查提示卡没有乱码、遮挡或明显溢出。
