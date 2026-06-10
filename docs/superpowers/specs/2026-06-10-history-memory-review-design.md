# 历史 / 记忆回顾 UI 设计

## 目标

为 Fitness RPG 原生 iOS 应用增加第一版独立 `History` 页面，让刚完成的持久化 MVP 变成用户可见能力。

这一轮的目标不是做完整统计中心，而是让用户能从 Today 中枢进入历史回顾，查看最近训练日，并打开某一天的详情，确认当天的任务、执行结果、记忆草稿和故事节点。

## 选定方向

采用方案 B：独立 History 屏，首版范围为“列表 + 详情”。

`TodayCommandCenterView` 继续作为当天行动中心，只增加一个清晰入口。`HistoryView` 负责历史列表和训练日详情。这样 Today 不会继续变长，History 也能自然承载后续的搜索、筛选、故事回顾和模型上下文能力。

首版不引入 TabView。当前还没有稳定并列的角色页、设置页或统计页，过早加入全局 Tab 壳会扩大导航重构范围。

## 范围

允许内容：

- 在 Today 顶部工具栏增加 History 入口。
- 新建独立的 History SwiftUI 页面。
- 展示最近训练日列表。
- 展示选中训练日详情。
- 显示空状态、加载状态和基础错误状态。
- 为 `TodayPersistenceModel` 增加只读历史数据访问能力。
- 为历史排序和空状态补充单元测试。

暂缓内容：

- 搜索、筛选和统计图。
- 完整训练时间线。
- 角色成长页。
- 跨设备冲突历史。
- 云同步。
- SwiftData 迁移。
- 本地模型运行时。

## 架构

本轮保持现有边界：

1. `FitnessRPGCore`
   - 继续定义 `TrainingDayRecord`、`MemoryEntry`、`StoryProgression` 等持久化模型。
   - 不加入 SwiftUI 或平台导航概念。

2. `JSONFitnessRPGStore`
   - 继续负责 JSON 文件读写。
   - History 不直接调用 store。

3. `TodayPersistenceModel`
   - 作为 iOS UI 的持久化门面。
   - 新增只读历史列表、选中记录和详情展示需要的派生属性。
   - 继续隐藏底层文件路径、编码细节和 store 错误。

4. SwiftUI 视图
   - `TodayCommandCenterView` 只负责入口。
   - 新建 `HistoryView` 负责列表和详情。
   - 可拆出小型子视图，例如 `HistoryDayRow`、`HistoryDetailView`、`HistoryEmptyStateView`。

## 数据流

```text
JSONFitnessRPGStore
    -> TodayPersistenceModel.load()
    -> historyRecords 派生列表
    -> HistoryView 列表
    -> selectedTrainingDay
    -> HistoryDetailView
```

Today 页面继续通过现有流程生成当天记录、执行结果、记忆草稿和故事进度。History 页面只读取这些已持久化的数据，不负责生成任务或改写训练记录。

## iOS UI 行为

Today 顶部导航栏增加 History 入口。入口可以先使用文字按钮 `History` 或系统图标加文字，保持和现有 SwiftUI 风格一致。

History 页面首屏包含：

- 标题：`History`
- 最近训练日列表。
- 每条记录展示日期、任务标题、完成状态、readiness 颜色或摘要。
- 没有记录时显示空状态，引导用户回到 Today 完成一次任务或同步一次 Watch 结果。

详情页包含：

- 日期和 readiness 摘要。
- 当天 `DailyQuest` 标题和训练步骤摘要。
- 执行结果状态，例如完成、跳过、过重或待同步。
- `Memory 草稿` 内容或“尚未生成”的状态。
- 当前故事节点标题或章节摘要。

首版详情可以使用 navigation push，也可以在宽屏时自然扩展为列表 + 详情布局。实现时优先选择最贴近当前 iOS scaffold 的简单导航方式。

## 状态与错误处理

预期状态：

- 没有历史记录。
- 记录存在，但尚未有 Watch 执行结果。
- 记录存在，但尚未有 memory draft。
- 故事进度为空或节点缺失。
- JSON 读取失败。

这些状态都应变成用户可理解的 UI 文案，不应导致崩溃。读取失败时显示简短错误，并保留返回 Today 的能力。

## 测试

Core / persistence 测试应覆盖：

- 多个 `TrainingDayRecord` 能按日期倒序展示。
- 空历史记录返回空列表，而不是抛出 UI 层异常。
- 选中记录后能派生任务标题、状态、memory draft 和故事节点摘要。
- 读取失败时 model 暴露错误状态。

平台验证应包含：

```bash
cd native/FitnessRPGCore && swift test
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
node prototype/tests/prototypeContract.test.mjs
```

浏览器 prototype 不在本轮修改范围内，但 contract test 继续作为回归保护。

## 安全边界

History 页面不得：

- 生成新的训练任务。
- 修改 readiness 评分。
- 写入 HealthKit。
- 开始真实 workout session。
- 让 Watch 成为安全判断来源。
- 展示原始 HealthKit samples。
- 在没有执行结果时伪造完成状态。

iPhone 仍然是规划和安全判断界面。History 只展示已经落盘的训练和叙事结果。

## 非目标

本轮不包含：

- 可编辑历史记录。
- 删除历史记录。
- 手动合并 Watch 结果。
- 趋势图和周/月统计。
- 多设备同步冲突解决。
- SwiftData 或数据库迁移。
- AI 自动总结历史。
- 生产级视觉润色。

## 后续迭代

完成这一轮后，可以继续：

1. 增加 History 搜索和按 readiness / 完成状态筛选。
2. 增加训练时间线和周/月趋势。
3. 把 memory draft 扩展成可复盘的故事日志。
4. 将 History 的选中记录作为本地模型上下文输入。
5. 在真实设备上验证 Watch 返回结果到 History 的完整链路。
