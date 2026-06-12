# Demo 路径入口执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 给 demo banner 增加可点击的路径入口，让演示者可以从种子 demo 页面快速切换 Today、History、Memory 和 Diagnostics。

**架构：** Core 定义 demo 目标页面和操作展示模型；Today 持有 `NavigationStack` 路径，并把同一个 action handler 传给 Today 和 History banner。

**技术栈：** Swift Package 领域模型、SwiftUI `NavigationStack`、现有 demo seed presentation。

---

## 文件

- 修改：`native/FitnessRPGCore/Sources/FitnessRPGCore/FitnessRPGDemoSeed.swift`
- 修改：`native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- 修改：`native/AppSources/iOS/History/HistoryView.swift`
- 修改：`native/AppSources/iOS/TodayCommandCenterView.swift`
- 修改：`docs/superpowers/plans/2026-06-12-demo-path-actions.md`

## 任务

- [x] **步骤 1：添加失败的 Core 测试**

断言 `FitnessRPGDemoSeed.showcase.presentation.actions` 暴露 `[.today, .history, .memory, .diagnostics]` 四个目标。

- [x] **步骤 2：确认 RED**

运行：`swift test --package-path native/FitnessRPGCore --filter FitnessRPGCoreTests/testFitnessRPGDemoSeedProvidesPathActions`

预期：编译失败，因为 `actions` 还不存在。

- [x] **步骤 3：实现 Core actions**

添加目标枚举、action 结构体，并在 `presentation()` 中提供 4 个 action。

- [x] **步骤 4：渲染操作按钮**

更新 `DemoSeedPresentationBanner`，接收 action handler，并在 evidence 下方渲染 2x2 按钮。

- [x] **步骤 5：接入导航 handler**

更新 `TodayCommandCenterView`，把 demo 目标映射到 `navigationPath`，并把 handler 传给 Today 和 History。

- [x] **步骤 6：验证**

运行：

```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
bash native/scripts/demo-seed-simulator-smoke.sh
git diff --check
```

- [x] **步骤 7：提交并推送**

提交信息：`feat(native): add demo path actions`
