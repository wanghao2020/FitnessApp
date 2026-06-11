# History 周回顾本地模型润色设计

## 背景

History 已经展示确定性的 `WeeklyTrainingSummary`。下一步需要给本地模型一个受控入口，让它只润色周回顾文案，而不是改写训练统计、安全规则或持久化记录。

## 目标

- 复用现有 `ModelRuntimeRunner`、provider diagnostics、parser 和 validator。
- 为周回顾构造专用 `ModelRuntimeContext`，把确定性 summary 转成模型可读的 prompt。
- Provider 不可用、解析失败或校验失败时，继续使用确定性周总结作为 fallback。
- iOS History 仅在本地模型输出通过校验时展示“本地模型润色”区块。
- DEBUG fixture 可以在 Simulator 中验证成功、解析失败、adapter 失败和 validator fallback 路径。

## 非目标

- 不接入真实 LiteRT-LM / Gemma SDK。
- 不让模型修改完成天数、降阶天数、跳过天数、readiness 分布或安全提示。
- 不新增持久化字段；模型润色结果本轮只作为页面内运行时展示。
- 不把 History 改成完整统计仪表盘。

## 方案

采用 Core 小边界：

- 新增 `WeeklySummaryModelContextBuilder`。
- 新增 `WeeklySummaryPolishRunner`。
- 继续使用 `ModelRuntimeDraft` 作为模型输出结构：
  - `title`：润色后的周回顾短标题。
  - `body`：润色后的周回顾正文。
  - `nextAction`：下周行动提示。

`WeeklySummaryModelContextBuilder` 会把 `WeeklyTrainingSummary` 映射成 `ModelRuntimeContext`：

- `questTitle` 固定为 `周训练总结`。
- `questObjective` 包含 `headline`、`detail`、`completionLabel`、`readinessLabel`、`safetyLabel` 和下周动作。
- `safetyRules` 明确要求不得改写统计数字，必须保留确定性安全边界。
- 如果 summary 包含降阶、跳过、红灯或恢复提示，则用非绿灯 readiness 让现有 validator 拦截激进文案。

`WeeklySummaryPolishRunner` 负责调用 provider：

- Provider ready 且输出通过校验：返回 local model draft。
- Provider 不可用、解析失败、adapter 失败或 validator 失败：返回 deterministic fallback draft，内容来自 `WeeklyTrainingSummary`。

## iOS 展示

`HistoryView` 保持现有列表结构。`WeeklyTrainingSummaryCard` 新增可选 `polishResponse`：

- `source == .localModel` 时显示“本地模型润色”区块。
- fallback、nil 或 provider 不可用时不显示额外区块，页面继续显示确定性 summary。

`TodayCommandCenterView` 将 DEBUG fixture mode 传给 `HistoryView`。History 使用与 Today 相同的 `LocalModelResourceBundleObserver`，因此 `--fitnessrpg-model-fixture-ready` 可以在 History 验证成功润色显示。

## 验证

- 先写 Core 红测：
  - 周回顾 context 必须包含不可改写统计和 safety rules。
  - 周回顾 polish runner 接受安全 provider 输出。
  - provider 不可用时 fallback 到确定性 summary 文案。
- 运行 `swift test --package-path native/FitnessRPGCore`。
- 运行 iOS / watchOS generic Xcode build。
- 使用 Simulator 启动 `--fitnessrpg-open-history --fitnessrpg-model-fixture-ready` 截图验证润色区块。
- 运行 `git diff --check`。
