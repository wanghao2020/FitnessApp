# History Watch 结果展示优化设计

## 目标

让 iOS `History` 页面更清楚地展示 Watch 回传后的完成结果。用户进入历史详情时，应能快速确认最终状态、完成进度、每个 Watch 步骤的动作、RPE 和备注。

本轮只做展示派生和 UI polish，不改变 WatchConnectivity 协议、训练结算逻辑、持久化格式或 HealthKit 行为。

## 选定方案

采用方案 A：在 `FitnessRPGCore` 增加可测试的历史展示字段，然后让 SwiftUI 只负责布局。

这样可以把“3/3 步骤”“已完成 · 3/3 步骤”“步骤 action / RPE / note”等展示逻辑固定在 core 层，避免 `HistoryView` 里堆字符串拼接。SwiftUI 页面只消费已经整理好的 `TrainingHistoryDay` 和 Watch log row。

## 范围

允许内容：

- 为 `TrainingHistoryDay` 增加完成进度和结果摘要字段。
- 为每条 `ExecutionLog` 派生可展示的 Watch 步骤行。
- History 列表行显示更明确的状态和进度。
- History 详情页结构化展示 Watch 回传日志。
- 增加 core 单元测试覆盖完成进度、action 文案、RPE 和步骤名映射。

暂缓内容：

- 搜索、筛选、统计图。
- 可编辑或删除历史记录。
- 修改 Watch 同步协议。
- 修改 JSON 持久化结构。
- 重新设计全局导航。

## 数据流

```text
TrainingDayRecord.executionLogs
    -> TrainingHistoryDay.watchProgressLabel
    -> TrainingHistoryDay.resultSummary
    -> TrainingHistoryDay.watchLogRows
    -> HistoryView 列表和详情展示
```

`watchLogRows` 按 `ExecutionLog.order` 升序排列。每条 row 尝试用 1-based `order` 匹配 `DailyQuest.watchSteps`，若匹配失败则显示 `步骤 N`，避免异常数据导致 UI 空白。

## UI 行为

视觉方向采用 `Native Pro + RPG Chronicle` 的组合：

- 以 iOS 原生系统风格为主，使用 SF Symbols、清晰字体层级、稳定留白和 8pt 圆角卡片。
- 轻量保留 RPG 叙事感，把故事节点、奖励摘要和任务结果放在详情 hero 区域。
- 不把 History 做成重装饰故事页，也不提前转向高密度统计工具。

History 列表行：

- 主标题保持日期。
- 副标题保持任务标题。
- 状态行改为 `结果摘要 · readiness 摘要`，例如 `已完成 · 3/3 步骤 · 共振稳定 · 82`。
- 使用系统图标和 readiness tint 传达状态，不使用自绘图标。

History 详情页的 `Watch 回传` 区块：

- 顶部显示结果摘要。
- 显示安全反馈和下一次建议。
- 有回传日志时显示步骤列表，每行包含步骤名、action 文案、RPE 和 note。
- 没有回传日志时显示等待 Watch 回传的空状态文案。

History 详情页增加轻量 hero：

- 显示结果摘要、故事节点和任务标题。
- 显示三个紧凑指标：Watch 步骤进度、readiness 分数、奖励摘要。
- 保持系统字体，标题使用 `.rounded` 字体设计，正文使用默认 San Francisco。

## DEBUG 验证入口

为避免依赖 macOS 辅助访问权限点击 Simulator UI，iOS DEBUG 构建支持启动参数 `--fitnessrpg-open-history`。当该参数存在时，App 初始导航直接进入 History 页面；Release 构建忽略该参数。

同时支持 `--fitnessrpg-open-latest-history-detail`，用于直接打开最新一条 History 详情并截图验证 Watch 步骤日志。两个入口只用于模拟器截图和回归验证，不改变用户生产路径。正常启动仍进入 Today 中枢。

## 错误和边界

- 没有 logs：进度显示 `0/N 步骤`。
- logs 数量超过 quest 步骤数量：分母使用较大值，避免 `4/3` 这类不稳定展示。
- log order 找不到对应步骤：步骤名显示 `步骤 N`。
- 未结算但有 logs：结果摘要显示 `同步中 · X/N 步骤`。

## 测试

Core 测试覆盖：

- 完成记录能生成 `已完成 · 3/3 步骤`。
- Watch log rows 能映射步骤名、action 文案、RPE 和 note。
- 未开始记录显示 `待执行 · 0/3 步骤`。

平台验证：

```bash
cd native/FitnessRPGCore
swift test
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGHistoryPolishIOS CODE_SIGNING_ALLOWED=NO build
xcrun simctl launch 9B424038-58BD-41D9-A446-399BCC2265C2 com.hao.fitnessrpg --fitnessrpg-open-history
```
