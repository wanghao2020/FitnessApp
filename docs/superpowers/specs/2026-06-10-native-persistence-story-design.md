# Native 持久化与故事进度设计

## 概览

增加第一版 native 持久化能力。iPhone app 是唯一持久化权威，负责保存当日任务、Apple Watch 回传的执行记录、解析后的训练结果、memory 草稿和 RPG 故事进度。Apple Watch 在这一轮仍然只是执行与快速反馈界面，不写入持久化历史。

本轮使用基于 `FileManager` 和 `Codable` 的 JSON 文件仓库。当前 Core 模型已经支持 `Codable`，所以 JSON 存储最适合这个 MVP：透明、可测试、容易调试，也方便以后替换成 SwiftData 或其他持久化后端。

## 目标

- iOS 重启后恢复当天任务，不在同一天生成另一个不同任务。
- 持久化 Watch 回传的 `ExecutionLog` 和确定性解析得到的 `WorkoutResult`。
- 把 `WorkoutResult.memoryDraft` 固化成可供未来本地模型使用的记忆条目。
- 增加真正的 RPG 章节/节点进度模型，而不是只保存一个展示字符串。
- 当内存里的当前任务为空时，允许 Watch logs 优先匹配本地持久化的当日任务，减少回传记录丢失。
- 本轮所有持久化都只发生在 iPhone 端。

## 非目标

- 不做云同步、账号系统或远端备份。
- 不做 watchOS 端持久化。
- 不引入 SwiftData schema 或迁移系统。
- 不接入真实本地模型运行时。
- 不做完整故事编辑 UI 或训练历史浏览页。
- 不把 Quest 生成器扩展成复杂分支系统；故事推进先保持确定性规则。

## Core 领域模型新增

### TrainingDayRecord

`TrainingDayRecord` 表示一个本地自然日的持久化训练记录。

字段：

- `id`：由本地日期生成的稳定 key，例如 `2026-06-10`。
- `date`：用于查询和展示的本地日期字符串。
- `readiness`：用于生成任务的 `ReadinessResult`。
- `quest`：当天选定的 `DailyQuest`。
- `executionLogs`：`[ExecutionLog]`，初始为空，由 Watch 回传更新。
- `workoutResult`：可选 `WorkoutResult`，logs 被解析后写入。
- `storyProgression`：可选 `StoryProgression`，训练结果结算后写入。
- `createdAt`：`Date`。
- `updatedAt`：`Date`。

该模型需要支持 `Codable`、`Equatable` 和 `Sendable`。

### StoryChapter 和 StoryNode

`StoryChapter` 定义可持久化的 RPG 章节。`StoryNode` 定义章节内的节点。

初始章节沿用 prototype 里的中文语义：

- 主线：`第一章 · 回声城门`
- 校准分支：`第一章 · 深厅回廊`
- 恢复分支：`第一章 · 北境营地`

初始节点名称沿用当前任务语言：

- `破障试炼`：绿色 readiness / 主线推进。
- `校准符文`：黄色 readiness / 技术校准。
- `修复护符`：红色 readiness / 恢复进度。
- `安全降阶`：过重反馈或高 RPE 结果。

这些模型保持小而明确，但它们应该是真实持久化数据，不只是 UI 文案。

### StoryProgression

`StoryProgression` 表示一次训练结算后的当前 RPG 状态。

字段：

- `currentChapterID`
- `currentNodeID`
- `completedNodeIDs`
- `lastOutcome`：枚举，例如 `advanced`、`calibrated`、`recovered`、`downgraded`。
- `lastReason`：简短的人类可读说明。
- `updatedAt`

该模型需要支持 `Codable`、`Equatable` 和 `Sendable`。

### MemoryEntry

`MemoryEntry` 保存从训练结果中生成的 durable memory draft。

字段：

- `id`
- `date`
- `questTitle`
- `completionState`
- `storyNodeID`
- `draft`
- `createdAt`

第一版不做 memory 编辑或确认流程，只保存确定性草稿，为后续本地模型上下文打基础。

## 故事推进规则

新增确定性的 `StoryProgressionEngine`。它接收上一次故事进度、当天任务和解析后的 `WorkoutResult`，返回下一版故事进度。

规则：

- 绿色任务 + `.completed`：推进主线节点。
- 黄色任务 + `.completed`：记录校准节点，并标记为技术进度。
- 红色任务 + `.completed` 或 `.skipped`：进入或保留恢复节点。恢复是进度，不是失败。
- `.downgraded`：进入安全降阶节点，不推进主线。
- 非红色任务的 `.skipped`：记录恢复/保护性进度，不推进主线。

故事推进不能惩罚安全选择。跳过、降阶、恢复都应该被记录为保护身体的有效进展。

## 持久化架构

采用 repository protocol + JSON 文件实现。

建议的 repository 职责：

- 读取所有训练日记录。
- 读取或创建当天记录。
- 保存或更新训练日记录。
- 读取和保存故事进度。
- 追加 memory entry。
- 读取最近 memory entries。

建议的 JSON 文件：

- `training-days.json`
- `story-progress.json`
- `memory-entries.json`

每个文件都用带 schema version 的小 wrapper 包裹，为后续迁移留位置。

JSON 实现应放在 iOS app source 层，或一个只链接到 iOS target 的 native shared source 层。Core 负责纯模型和确定性 engine，文件系统细节不要放进纯领域逻辑。

## iOS 数据流

### 启动

1. `FitnessRPGApp` 创建 iOS 持久化 store。
2. Today 状态模型读取当天 durable record。
3. 如果当前本地日期已有 record，UI 复用其中的 `DailyQuest`。
4. 如果没有 record，则读取 HealthKit readiness，通过 `QuestEngine` 生成 quest，并保存新 record。
5. 如果 record 已有 `WorkoutResult`，Today UI 展示最近训练结果和 memory draft。
6. 如果已有故事进度，Today UI 可以用一个紧凑面板或状态行展示当前章节/节点。

### 发送到 Watch

Today UI 发送到 Watch 的 quest 必须来自当天持久化 record。这样可以避免 iPhone durable state 和 Watch payload 不一致。

### 接收 Watch Logs

iPhone 收到 `ExecutionLogSyncPayload` 后：

1. 找到当天持久化 record。
2. 用持久化 quest title 匹配 logs。
3. 将 incoming logs 保存到 record。
4. 使用 `ExecutionEngine.resolve` 解析 `WorkoutResult`。
5. 将 result 保存到 record。
6. 基于 `WorkoutResult.memoryDraft` 创建并追加 `MemoryEntry`。
7. 通过 `StoryProgressionEngine` 推进故事进度。
8. 发布新的 Today UI 状态。

如果内存里的 `currentQuest` 为空，应先使用持久化的当日 quest 作为匹配目标，再报告“没有匹配任务”。

## 错误处理

- JSON 文件不存在：视为空 store。
- JSON 内容损坏：app 保持可用，使用保守 fallback 状态，并展示本地记录不可用的状态文案。
- JSON 写入失败：不阻塞当前训练流程，展示保存失败状态，并保留内存状态。
- logs 属于未知 quest：不写入当天 record。
- 故事推进失败：仍然保存 workout result 和 memory entry。

## UI 范围

本轮 UI 保持克制：

- Today screen 展示恢复出来的最近训练结果。
- Today screen 可以展示当前章节/节点的紧凑状态行或小面板。
- 不做完整历史列表。
- 不做 memory 编辑器。

本轮主要价值是 durable state 和重启恢复，不是新增大型 UI。

## 测试策略

Core 测试：

- `TrainingDayRecord` 可以 JSON round-trip。
- `StoryChapter`、`StoryNode`、`StoryProgression` 和 `MemoryEntry` 可以 JSON round-trip。
- `StoryProgressionEngine` 在绿色 completed result 时推进主线。
- `StoryProgressionEngine` 在黄色 completed result 时记录校准进度。
- `StoryProgressionEngine` 在 `.downgraded` 时记录安全降阶。
- `StoryProgressionEngine` 在红色或 skipped result 时记录恢复进度。

Repository 测试：

- 空 JSON store 返回空记录和默认故事进度。
- 保存新 day record 后可以再次读取。
- 更新某一天的 logs/result 时保留同一个 quest。
- 追加 memory entries 后保持顺序。
- 损坏 JSON 不崩溃，并返回可恢复错误。

构建验证：

- `native/FitnessRPGCore` 下运行 `swift test`。
- browser prototype contract test 保持通过。
- iOS Xcode build 通过。
- watchOS Xcode build 通过。

## 完成标准

- iOS 在同一个本地日期重启后恢复同一个 quest，而不是生成新 quest。
- Watch 回传 logs 被 iPhone 持久化，并解析成保存的 `WorkoutResult`。
- 最近一次保存的训练结果和 memory draft 在重启后仍然可见。
- 故事进度通过章节/节点模型按确定性规则推进。
- 安全保护型结果会被记录为有效进度。
- Watch 仍然是非持久化的执行界面。
- 实现后完整验证全部通过。
