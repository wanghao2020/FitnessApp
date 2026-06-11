# History 周回顾润色缓存操作设计

## 目标

给 History 的“本地模型润色”区块增加轻量操作，让用户可以清除当前周回顾缓存，或丢弃缓存后重新运行现有本地模型 polish pipeline。

## 背景

当前 History 已经会：

1. 从训练记录生成确定性 `WeeklyTrainingSummary`。
2. 先匹配 `WeeklySummaryPolishCache`。
3. 没有缓存时调用 `WeeklySummaryPolishRunner`。
4. 只缓存通过 validator 的 `.localModel` 输出。

这保证了安全和稳定，但真机或 DEBUG fixture 测试时，如果模型输出已经缓存，用户无法从 UI 触发重新生成，也无法清除旧缓存。

## 设计

### Core

在 `WeeklySummaryPolishCache` 增加 `removing(summary:in:)`。

它使用现有 fingerprint，只移除当前 summary 对应的 entry，不影响其他周回顾缓存。

### Persistence

`TodayPersistenceModel` 增加 `clearWeeklySummaryPolishEntry()`：

- 加载 `weekly-summary-polish-entries.json`。
- 移除当前 `weeklyTrainingSummary` 对应 entry。
- 保存更新后的数组。
- 清空已发布的 `weeklySummaryPolishEntry`。
- 更新 `storageStatusText`，便于调试。

读取或保存失败时，不删除内存中的训练记录，只显示状态文本。

### History UI

`WeeklyTrainingSummaryCard` 在“本地模型润色”区块内显示两个紧凑按钮：

- `重新生成`：先清除当前缓存，再忽略缓存运行一次现有 polish pipeline。
- `清除缓存`：只清除当前缓存，并隐藏本地模型润色区块。

按钮只在当前有 `.localModel` polish response 时出现。确定性 summary 和 next-week plan 始终保留。

## 非目标

- 不删除训练历史、Memory entries 或 Watch execution logs。
- 不缓存 deterministic fallback。
- 不新增独立周报页面。
- 不改变模型 validator、安全规则或 provider 选择。
- 不绕过现有 `WeeklySummaryPolishRunner`。

## 验证

- Core tests 覆盖 cache remove helper。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS/watchOS generic build 通过。
- 模拟器用 `--fitnessrpg-open-history --fitnessrpg-model-fixture-ready` 截图检查按钮显示和布局。
