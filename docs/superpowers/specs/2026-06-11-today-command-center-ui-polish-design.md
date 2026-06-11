# Today 中枢 UI 优化设计

## 目标

把 Today 中枢对齐 History 的 `Native Pro + 轻 RPG Chronicle` 视觉语言，让用户进入 App 后能更快理解今日状态、任务、Watch 执行进度和故事进度。

本轮只做 UI/UX polish 和展示派生，不改变 HealthKit 读取、WatchConnectivity 协议、训练结算、持久化格式或本地模型 harness 数据。

## 视觉方向

- 使用 iOS 原生系统风格：SF Symbols、系统字体、清晰留白、8pt 圆角卡片。
- 保留轻量 RPG 感：任务节点、奖励、故事进度以标签和图标表达，不使用重装饰背景。
- 首屏优先展示行动信息：readiness、Watch 回传进度、任务步骤和发送到 Watch。
- 保持 Today 是行动中心，History 是回顾中心。

## UI/UX Pro Max 取舍

- 采用移动端检查项：安全区不遮挡、主按钮保持大触控区域、中文正文支持系统 Dynamic Type、避免空白 loading。
- 使用 SF Symbols 作为按钮和状态图标，不使用 emoji 或纯文字伪图标。
- 保留 SwiftUI 系统 rounded 字体；`ui-ux-pro-max` 推荐的 Barlow/Barlow Condensed 更适合 Web 或 React Native，不在本次原生 iOS 版本中引入字体资源。
- 色彩沿用 readiness 语义色作为状态强调，主操作使用系统 prominent button，避免把页面做成单一色块。

## 展示结构

Today 页面从上到下：

1. Hero 摘要
   - `今日任务中枢`
   - readiness 状态和分数
   - Watch 进度
   - 当前 Watch 同步状态

2. 今日任务卡
   - 任务标题、故事节点、难度和奖励
   - Watch 步骤列表
   - 主操作按钮：`发送到 Watch`

3. Watch 回传结果
   - 已有结果时显示安全反馈、下一次建议和 memory 草稿

4. Readiness 指导
   - HealthKit/保守策略解释和安全建议

5. 故事进度
   - 当前节点、推进原因和本地保存状态

6. 本地模型 Harness
   - 保留在下方，作为开发/验证面板。

## Core 展示派生

新增 `TodayCommandCenterSummary`，集中生成 Today UI 需要的稳定文案：

- `readinessLabel`
- `readinessScoreLabel`
- `watchProgressLabel`
- `watchStatusLabel`
- `questContextLabel`
- `rewardSummary`

SwiftUI 不直接拼这些业务文案，避免页面变成字符串逻辑堆叠。

## DEBUG 验证

继续使用现有默认启动路径截图 Today。History 的 DEBUG 参数不变。

## 非目标

- 不重做全局 Tab 导航。
- 不新增角色页。
- 不修改 Watch app UI。
- 不引入新设计系统文件。
- 不改变本地 JSON 数据。
