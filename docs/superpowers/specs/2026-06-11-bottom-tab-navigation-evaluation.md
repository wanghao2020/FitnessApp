# 底部 Tab 导航评估

## 结论

当前不引入底部 Tab。Fitness RPG 目前只有两个稳定顶层目的：

- Today：今日行动中心，核心动作是发送任务到 Watch。
- History：训练回顾中心，主要是查看历史记录和详情。

Today 底部已经有固定主 CTA `发送到 Watch`。此时再加入底部 Tab，会让底部安全区同时承载导航和主动作，增加遮挡、误触和视觉噪音。现阶段继续使用右上角“历史”入口更轻、更符合当前产品结构。

## 评估依据

### 当前信息架构

Today 是用户每天最常进入的页面，Watch 同步是最重要的行动。History 是次级回顾路径，访问频率低于 Today，不需要和主 CTA 抢底部空间。

### UI/UX Pro Max 约束

- Bottom tab 通常适合 3 到 5 个稳定顶层目的。
- 移动端固定底部区域必须处理 safe area，不应让固定导航遮挡内容。
- 主触控目标需要 44pt 以上，底部同时放 Tab 和 CTA 会显著增加垂直占用。
- 返回行为应可预测；当前 `NavigationStack` 从 Today 进入 History，系统 back 行为清晰。

### 当前实现状态

- Today 右上角已有中文“历史”胶囊入口。
- History deep link `--fitnessrpg-open-history` 可用。
- Today 底部固定 CTA 已验证在模拟器上可见且不遮挡 home indicator。

## 什么时候再引入 Tab

满足以下任意两项时，再做底部 Tab：

- 新增第三个稳定顶层页面，例如“角色 / 成长”、“设置”、“计划”。
- History 访问频率接近 Today，需要一级导航常驻。
- Watch CTA 改为页面内容内操作，底部安全区不再长期被主按钮占用。
- 需要长期保留多个顶层页面的独立滚动状态。

## 未来 Tab 方案

如果后续引入 Tab，建议使用 3 个 tab：

- 今日：`figure.run.circle`
- 历史：`clock.arrow.circlepath`
- 角色：`person.crop.circle`

Watch 主 CTA 不应和 Tab 同时长期固定在底部。可选方案：

- Today 页内使用任务卡内 CTA，Tab 占底部。
- Today 保留底部 CTA，Tab 改为顶部 segmented control。
- Watch CTA 仅在 Today 滚动到底部或任务卡区域时出现。

## 当前推荐

保留当前结构：

- 顶部：inline app title + 右上角“历史”入口。
- 中部：Today 状态、任务和步骤。
- 底部：固定 `发送到 Watch` 主 CTA。

这让 Today 的核心动作保持最高优先级，同时让 History 仍然容易发现。
