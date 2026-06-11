# 实机验证报告复制设计

## 目标

在 DEBUG Today 诊断区域增加一个可复制的“实机验证报告”，把当前 WatchConnectivity、HealthKit、Runtime、History 周回顾缓存状态汇总成一段稳定纯文本。后续真实 iPhone / Apple Watch / LiteRT-LM 验证时，可以直接把报告贴进 issue、测试记录或对话里。

## 背景

当前 DEBUG 页面已经有“实机验证总览”卡片和详细 Runtime / WatchConnectivity 面板。它能告诉测试者当前卡在哪一步，但测试结果仍需要手动抄写。真机验证往往跨设备、权限、资源包和缓存状态，手抄容易漏掉最近发送、最近回传、模型资源缺失或 HealthKit fallback 动作。

## 方案

新增 Core 级 `RealDeviceValidationReportBuilder`，输入现有展示模型：

- `RealDeviceValidationChecklist`
- `WatchConnectivityDiagnosticsSnapshot`
- `HealthDataSourceSnapshot`
- `ModelRuntimeDiagnosticsSummary`
- `historyRecordCount`
- `hasWeeklyPolishCache`
- `generatedAt`

输出稳定的纯文本报告：

- 标题和 ISO 8601 生成时间。
- 总览标题、总览进度和四个 checklist row。
- HealthKit 状态、说明和 action rows。
- Runtime 标题、详情和所有 diagnostics rows。
- WatchConnectivity 标题、详情和所有 diagnostics rows。
- History 记录数和周回顾缓存状态。

iOS Today DEBUG 总览卡增加一个小按钮“复制报告”。点击后把 Core 生成的报告写入 `UIPasteboard.general.string`，按钮短暂显示“已复制”。该按钮只在 `--fitnessrpg-show-diagnostics` 下出现，不进入普通用户路径。

## UI 原则

- 沿用现有 material 卡片、8pt 圆角、SF Symbols 和系统字体。
- 按钮放在总览卡标题区右侧，使用 `doc.on.doc.fill` 图标，保持调试工具属性。
- 不新增解释性大段文案，不让诊断页变成文档页。
- 文本报告用纯文本，不依赖富文本、JSON pretty print 或本地化环境，便于粘贴。

## 非目标

- 不自动上传报告。
- 不读取系统日志。
- 不保存报告文件。
- 不新增 Release 可见入口。
- 不改变 WatchConnectivity、HealthKit、Runtime 或 History 行为。

## 验证

- Core tests 覆盖报告标题、生成时间、总览行、HealthKit action、Runtime rows、WatchConnectivity rows 和 History 缓存状态。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS / watchOS generic build 通过。
- 模拟器用 `--fitnessrpg-show-diagnostics` 截图确认复制按钮可见且没有遮挡。
