# Memory Review 设计

## 目标

为原生 iOS 应用增加第一版独立 Memory Review 页面，让已经持久化的 `MemoryEntry` 从“隐藏的模型上下文候选”变成用户可回顾的产品能力。

这一轮只做只读回顾，不做编辑、删除、确认状态或存储格式迁移。目标是给后续本地模型 runtime 和 retrieval engine 准备稳定的用户可见入口。

## 范围

- 在 `FitnessRPGCore` 增加 `MemoryReviewEntry` 和 `MemoryReviewBuilder`，把 `MemoryEntry` 派生成 UI 可消费的展示模型。
- 在 iOS `TodayPersistenceModel` 增加 memory review 读取状态。
- 新增 `MemoryReviewView`，展示 memory 列表、空状态、读取失败状态和详情页。
- 从 Today 顶部导航进入 Memory Review。
- 更新 README 路线图，说明 History 已有，下一步聚焦 Memory Review、真机诊断、HealthKit UX 和本地模型 runtime。

## 非目标

- 不修改 `MemoryEntry` schema。
- 不增加编辑、删除、确认或归档状态。
- 不把 memory 直接接入真实 LLM runtime。
- 不做搜索、筛选、周/月统计。
- 不做 SwiftData 或 CloudKit 迁移。

## 数据模型

`MemoryReviewEntry` 是只读展示模型，包含：

- `date`
- `questTitle`
- `completionLabel`
- `completionSymbolName`
- `storyNodeTitle`
- `storyContextLabel`
- `sourceSummary`
- `rewardSummary`
- `draft`
- `createdAt`

`MemoryReviewBuilder.entries(from:records:)` 按 `createdAt` 倒序排列 memory entries，并尽量用同日期、同 quest title 的 `TrainingDayRecord` 补充 Watch 进度、难度和奖励摘要。找不到训练记录时仍展示 memory 本身，不丢弃数据。

## UI

Memory Review 使用 `NavigationStack` 内的列表 + 详情模式：

- 列表标题：`记忆回顾`
- 列表行显示日期、任务标题、故事节点、完成状态和简短草稿。
- 详情页显示任务来源、故事上下文、奖励摘要和完整 memory draft。
- 空状态说明：完成一次 Watch 回传并生成 Memory 草稿后，这里会出现可回顾条目。
- 读取失败状态用 `ContentUnavailableView` 展示，不崩溃。

Today 顶部增加一个轻量 `记忆` 入口，和现有 `历史` 入口并列。底部仍保留 `发送到 Watch` 主 CTA，不引入 Tab。

## 测试

核心测试覆盖：

- Memory entries 按 `createdAt` 倒序。
- 有匹配训练记录时，能派生 Watch 进度、奖励和故事上下文。
- 没有匹配训练记录时，仍展示 memory draft 和 fallback 来源摘要。
- 导航展示常量包含中文 memory 标签。
- debug launch argument 能打开 Memory Review。

平台验证：

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGMemoryReviewIOS CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,id=62F2C4FA-A9CA-432C-AE3B-76177C6C6AC7' -derivedDataPath /private/tmp/FitnessRPGMemoryReviewWatch CODE_SIGNING_ALLOWED=NO build
```

## 后续

完成只读 Memory Review 后，后续可以继续：

1. 增加 memory review 状态，例如确认、隐藏、归档。
2. 增加 memory 搜索和按故事节点筛选。
3. 将已确认 memory 接入本地模型 prompt context。
4. 增加 weekly summary，把最近 memory 和训练记录聚合成周回顾。
