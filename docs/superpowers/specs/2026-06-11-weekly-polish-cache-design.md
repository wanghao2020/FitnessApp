# History 周回顾润色缓存设计

## 背景

History 已经可以在本地模型输出通过校验时展示“本地模型润色”区块。当前结果只存在于页面运行时：重新打开 History 时，如果 provider 不可用或模型资源未就绪，用户会回到纯确定性 summary。

这一步把“已通过校验的本地模型周回顾润色文案”保存为本地草稿缓存。缓存只存被接受的 local model 输出，不存 fallback。

## 目标

- 为周回顾润色结果增加独立 JSON 持久化集合。
- 按确定性 `WeeklyTrainingSummary` 生成稳定 fingerprint。
- History 打开时优先展示匹配 fingerprint 的缓存。
- 没有缓存时才调用本地模型；模型输出通过校验后写回缓存。
- 不修改 `TrainingDayRecord` schema，不影响 Watch 历史和 Memory Review。

## 非目标

- 不新增编辑/删除 UI。
- 不同步到 watchOS。
- 不保存 provider 失败、解析失败或 validator fallback 结果。
- 不做多周周报浏览页。

## 数据模型

新增 `WeeklySummaryPolishEntry`：

- `id`: 与 `summaryFingerprint` 相同，便于 upsert。
- `summaryFingerprint`: 由周范围、完成分布、readiness 分布、安全提示和下周计划组成的稳定字符串。
- `dateRangeLabel`: 用于调试和未来列表展示。
- `draft`: 已通过校验的 `ModelRuntimeDraft`。
- `providerID`: 产生该草稿的 provider ID，若没有 diagnostics 则用 `local-model`。
- `createdAt`: 首次保存时间。
- `updatedAt`: 最近替换时间。

新增 `WeeklySummaryPolishCache`：

- `fingerprint(for:)`
- `entry(for:in:)`
- `upserting(response:summary:in:date:)`

`upserting` 只接受 `.localModel` response。fallback response 返回原 entries，不落盘。

## 持久化

`JSONFitnessRPGStore` 新增：

- `loadWeeklySummaryPolishEntries()`
- `saveWeeklySummaryPolishEntries(_:)`

文件名：`weekly-summary-polish-entries.json`。

## iOS 行为

`TodayPersistenceModel` 发布：

- `weeklySummaryPolishEntry`

History refresh 顺序：

1. `reloadHistory()` 后匹配缓存。
2. 如果缓存存在，直接显示缓存。
3. 如果缓存不存在，调用 `WeeklySummaryPolishRunner`。
4. 如果 response 是 `.localModel`，保存并发布缓存。
5. 如果 response 是 fallback，保持纯确定性周总结。

## 验证

- Core cache upsert 测试。
- JSON store round-trip 测试。
- SwiftPM 全量测试。
- iOS / watchOS Xcode build。
- Simulator 先用 ready fixture 生成并展示缓存，再不带 fixture 重新打开 History，确认缓存仍显示。
- `git diff --check`。
