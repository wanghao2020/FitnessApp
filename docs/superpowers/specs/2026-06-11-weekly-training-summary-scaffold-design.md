# 周训练总结脚手架设计

## 目标

为 Fitness RPG 增加确定性的周训练总结 Core 脚手架。它先从本地训练记录生成可展示的周回顾和下周计划，后续本地模型只负责润色，不成为安全或计划决策的唯一来源。

## 背景

当前 app 已经有 Today、History、Memory Review 和本地模型 Runtime。README 的下一阶段目标是“先增加确定性 weekly summaries 和 next-week plan scaffolding，再做模型生成周文案”。这一步需要先在 Core 中建立稳定的数据结构和聚合规则。

## 方案

- 新增 `WeeklyTrainingSummary`。
  - 输出周范围、标题、详情、完成标签、readiness 标签、安全标签、下周计划标题和动作列表。
- 新增 `WeeklyTrainingSummaryBuilder.summary(from:)`。
  - 输入 `[TrainingDayRecord]`。
  - 按日期升序计算范围。
  - 统计完成、降阶、跳过、待执行数量。
  - 统计绿/黄/红 readiness 分布。
  - 根据安全信号生成确定性下周计划。
- 空状态也返回完整 summary。
  - UI 后续不需要自行拼接空状态。

## 决策规则

- 有跳过、红灯或降阶信号时，优先给出保守重启或降阶巩固。
- 完成且没有安全信号时，给出稳定推进。
- 无记录时，给出建立基线的低风险动作。

## 非目标

- 不新增 iOS UI。
- 不写入持久化。
- 不生成模型周报正文。
- 不改变 Today / Watch 执行流程。

## 验证

- Core 测试覆盖混合训练周的安全计划。
- Core 测试覆盖空状态计划。
- SwiftPM 全量测试通过。
- iOS / watchOS build 通过。
