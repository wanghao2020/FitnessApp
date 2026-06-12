# 实机验证报告归档设计

## 目标

在 DEBUG Today 诊断区域增加“保存报告”能力，把当前实机验证纯文本报告存入本地 JSON。这样真实设备验证时，每次复制前后都能留下本机快照，便于对比 Watch 回传、HealthKit 权限、Runtime 资源和 History 缓存状态的变化。

## 背景

当前总览卡已经可以生成并复制纯文本报告，但报告只存在于剪贴板。如果实机验证要跑多轮，测试者需要手动保存每一次结果。项目已有 JSON persistence 层，适合增加一个轻量 DEBUG 报告集合，不混入训练记录或记忆数据。

## 方案

新增 Core 模型：

- `RealDeviceValidationReportEntry`
  - `id`
  - `headline`
  - `body`
  - `createdAt`

新增 Core helper：

- `RealDeviceValidationReportArchive.upserting(report:headline:in:createdAt:maxCount:)`
  - 使用 `createdAt.timeIntervalSince1970` 生成稳定 id。
  - 新报告排在最前。
  - 默认最多保留 20 条，避免 DEBUG 文件无界增长。

扩展 `JSONFitnessRPGStore`：

- `loadValidationReportEntries()`
- `saveValidationReportEntries(_:)`

扩展 `TodayPersistenceModel`：

- 发布 `validationReportEntries`。
- 启动/刷新时读取已有报告。
- `saveValidationReport(_:)` 将当前报告写入 store，并更新 `storageStatusText`。

扩展 Today DEBUG 总览卡：

- 保留“复制报告”按钮。
- 增加“保存报告”按钮。
- 在卡片详情下方显示已保存数量，例如“已保存 3 份验证报告。”。

## UI 原则

- 仍只在 `--fitnessrpg-show-diagnostics` 下显示。
- 按钮使用 SF Symbols：`doc.on.doc.fill` 复制，`tray.and.arrow.down.fill` 保存。
- 使用 `.bordered` small button，和现有调试卡片风格一致。
- 不新增独立列表页；本轮只做归档能力和数量反馈，避免扩大导航复杂度。

## 非目标

- 不做报告详情浏览页。
- 不导出文件或上传远端。
- 不自动保存每次状态变化。
- 不写入训练 History 或 Memory Review。
- 不改变 Release 行为。

## 验证

- Core tests 覆盖 archive 新增、排序、上限裁剪。
- Persistence tests 覆盖 validation reports JSON round trip。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS / watchOS generic build 通过。
- 模拟器诊断截图确认“复制报告”“保存报告”和已保存数量不重叠。
