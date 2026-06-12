# 验证报告归档浏览设计

## 目标

在 DEBUG Today 诊断区域为已保存的实机验证报告增加本地浏览入口。测试者可以查看历史报告列表、打开单条报告详情、再次复制报告正文，用于多轮真机验证对比。

## 背景

当前诊断总览可以复制并保存验证报告，保存结果会写入 `validation-reports.json`，但 UI 只显示数量。下一步需要一个轻量浏览入口，否则保存能力仍然需要开发者去文件系统里查 JSON。

## 方案

扩展 Core `RealDeviceValidationReportEntry` 的展示属性：

- `createdAtLabel`：ISO 8601 时间，适合测试记录。
- `bodyPreview`：报告正文第一行，供列表扫读。

扩展 Today DEBUG 总览卡：

- 当 `savedReportCount > 0` 时显示“查看归档”小按钮。
- 点击后打开 `.sheet`，展示 `ValidationReportArchiveSheet`。
- DEBUG 启动参数 `--fitnessrpg-open-validation-report-archive` 会同时启用诊断区并自动打开归档 sheet，便于模拟器和真机 smoke test 截图复现。
- Sheet 使用 `NavigationStack` + `List`：
  - 无保存报告时显示系统图标、标题和短说明，避免空白页面被误判为加载失败。
  - 列表行显示 headline、createdAtLabel、bodyPreview。
  - 点击进入详情页。
  - 详情页显示完整报告正文，并提供“复制” toolbar 按钮。

## UI 原则

- 仅在 `--fitnessrpg-show-diagnostics` 下可见。
- 入口放在保存数量旁边，不挤占顶部复制/保存按钮。
- 触控按钮保持至少 44pt 高度，按钮间距不小于 8pt。
- 继续使用 SF Symbols、系统字体、inset grouped list 和小半径卡片。

## 非目标

- 不新增删除报告功能。
- 不新增导出文件或分享 sheet。
- 不做搜索、筛选、比较 diff。
- 不在 Release 暴露入口。

## 验证

- Core tests 覆盖 `createdAtLabel`、`bodyPreview` 和空状态文案。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS / watchOS generic build 通过。
- 模拟器用 `--fitnessrpg-open-validation-report-archive` 启动，截图确认归档 sheet 可见，不与复制/保存按钮重叠。
