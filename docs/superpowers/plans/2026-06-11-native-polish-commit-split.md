# Native Polish Commit Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to apply this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将当前未提交的 Watch 同步、执行结算、历史记录、Today UI、诊断面板、启动屏和文档变更拆成可审阅、可回滚的提交序列。

**Architecture:** 按行为边界拆分提交，优先把项目配置修复、核心逻辑重构、UI 打磨和文档决策分开。混合文件使用 `git add -p` 分块暂存，避免把 LaunchScreen、诊断开关和 Today UI 细节误并到同一个提交。

**Tech Stack:** Swift Package tests, SwiftUI iOS app, watchOS app, Xcode project configuration, Markdown specs/plans.

---

## 执行备注

执行时已按可构建边界做了一次保守合并：原计划中的历史导航、Today Command Center UI、首屏密度、粘性 Watch CTA、诊断面板 gating 合并为一个提交 `feat(native): polish today and history flows`。原因是 `TodayCommandCenterView.swift`、`FitnessRPGApp.swift`、`AppLaunchOptions.swift` 和测试文件存在交叉依赖，强行拆成更细提交会让中间提交难以独立构建和审阅。

## 当前变更地图

**已修改文件：**
- `native/FitnessRPG.xcodeproj/project.pbxproj`：Watch app embedding、Watch companion plist、iOS LaunchScreen 配置混在同一文件。
- `native/AppSources/iOS/FitnessRPGApp.swift`：初始导航目的地、诊断面板 debug 参数注入。
- `native/AppSources/iOS/TodayCommandCenterView.swift`：Today 首屏结构、历史入口、粘性 Watch CTA、诊断面板展示条件。
- `native/AppSources/iOS/History/HistoryView.swift`：历史列表/详情视觉层次和启动目的地。
- `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`：训练执行结算改走核心层 applier。
- `native/AppSources/watchOS/WatchQuestSyncModel.swift`：Watch 执行日志创建改走核心层 factory。
- `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`：历史摘要、Watch 结果摘要和展示模型。
- `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`：多个功能的核心测试集中在一个测试文件。
- `native/README.md`：Watch embedding、debug launch arguments 说明。

**新增文件：**
- `native/AppSources/iOS/LaunchScreen.storyboard`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/AppNavigationDisplay.swift`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingDayExecutionApplier.swift`
- `native/FitnessRPGCore/Sources/FitnessRPGCore/WatchExecutionLogFactory.swift`
- `docs/superpowers/specs/2026-06-11-*.md`
- `docs/superpowers/plans/2026-06-11-*.md`

## 暂存原则

- 对 `project.pbxproj`、`FitnessRPGApp.swift`、`TodayCommandCenterView.swift`、`FitnessRPGCoreTests.swift`、`README.md` 使用 `git add -p`。
- 新增 Swift 文件可以整文件暂存，但要跟调用方放进同一个提交。
- Today UI 相关变更可以合并成一个提交；如果需要更细，可以拆成视觉结构、粘性 CTA、历史入口三个提交。
- 每个提交前运行 `git diff --cached --stat` 和 `git diff --cached --check`。
- 整个提交序列完成前，至少跑一次完整 Swift Package test、iOS build、Watch build。

---

### Task 1: 固化当前工作区快照

**Files:**
- Read: 当前工作区所有已修改和新增文件

- [ ] **Step 1: 记录文件清单**

Run:
```bash
git status --short --branch
git diff --stat
git ls-files --others --exclude-standard
```

Expected: 输出包含 iOS、watchOS、FitnessRPGCore、README 和 `docs/superpowers` 下的未提交变更。

- [ ] **Step 2: 检查空白和补丁格式**

Run:
```bash
git diff --check
```

Expected: 没有 trailing whitespace 或 conflict marker 报错。

---

### Task 2: 提交 Watch App 嵌入修复

**Files:**
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`
- Modify: `native/README.md`

- [ ] **Step 1: 仅暂存 Watch embedding 相关 hunk**

Run:
```bash
git add -p native/FitnessRPG.xcodeproj/project.pbxproj
git add -p native/README.md
```

Stage only:
- Watch app dependency
- Embed Watch Content copy phase
- Watch companion bundle id / plist 相关配置
- README 中 Watch app embedding 说明

- [ ] **Step 2: 审核暂存内容**

Run:
```bash
git diff --cached --stat
git diff --cached -- native/FitnessRPG.xcodeproj/project.pbxproj native/README.md
git diff --cached --check
```

Expected: 暂存内容不包含 `LaunchScreen.storyboard` 或诊断参数说明。

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "fix(native): embed companion watch app"
```

---

### Task 3: 提交训练执行结算核心重构

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingDayExecutionApplier.swift`
- Modify: `native/AppSources/iOS/Persistence/TodayPersistenceModel.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: 暂存 applier 和 iOS 调用方**

Run:
```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingDayExecutionApplier.swift
git add native/AppSources/iOS/Persistence/TodayPersistenceModel.swift
git add -p native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
```

Stage only tests that mention `TrainingDayExecutionApplier`, skipped execution, applied execution, reward, story, or history update behavior.

- [ ] **Step 2: 运行核心测试**

Run from repo root:
```bash
swift test --package-path native/FitnessRPGCore
```

Expected: FitnessRPGCore test suite exits with code 0.

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "refactor(core): centralize training execution application"
```

---

### Task 4: 提交 Watch 执行日志 factory 重构

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/WatchExecutionLogFactory.swift`
- Modify: `native/AppSources/watchOS/WatchQuestSyncModel.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`

- [ ] **Step 1: 暂存 factory、watchOS 调用方和对应测试**

Run:
```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/WatchExecutionLogFactory.swift
git add native/AppSources/watchOS/WatchQuestSyncModel.swift
git add -p native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
```

Stage only tests that mention `WatchExecutionLogFactory`, Watch result log payload, completion rate, duration, or skipped status.

- [ ] **Step 2: 运行核心测试**

Run:
```bash
swift test --package-path native/FitnessRPGCore
```

Expected: FitnessRPGCore test suite exits with code 0.

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "refactor(watch): centralize execution log creation"
```

---

### Task 5: 提交历史记录和导航入口打磨

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppNavigationDisplay.swift`
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
- Modify: `native/AppSources/iOS/History/HistoryView.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Add docs: `docs/superpowers/specs/2026-06-11-history-watch-result-polish-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-history-watch-result-polish.md`
- Add docs: `docs/superpowers/specs/2026-06-11-today-history-navigation-entry-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-today-history-navigation-entry.md`

- [ ] **Step 1: 暂存核心展示模型和历史 UI**

Run:
```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift
git add native/FitnessRPGCore/Sources/FitnessRPGCore/AppNavigationDisplay.swift
git add native/AppSources/iOS/History/HistoryView.swift
git add native/FitnessRPGCore/Sources/FitnessRPGCore/TrainingHistory.swift
git add -p native/AppSources/iOS/FitnessRPGApp.swift
git add -p native/AppSources/iOS/TodayCommandCenterView.swift
git add -p native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git add docs/superpowers/specs/2026-06-11-history-watch-result-polish-design.md
git add docs/superpowers/plans/2026-06-11-history-watch-result-polish.md
git add docs/superpowers/specs/2026-06-11-today-history-navigation-entry-design.md
git add docs/superpowers/plans/2026-06-11-today-history-navigation-entry.md
```

Stage only:
- `AppLaunchDestination` 中 history/latestHistoryDetail 相关内容
- Today 顶部历史入口相关内容
- History list/detail 视觉和 Watch 结果摘要
- `TrainingHistory` 中 reward/story/watch summary 相关内容

- [ ] **Step 2: 运行核心测试并构建 iOS**

Run:
```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /private/tmp/FitnessRPGCommitSplitIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: 两个命令都 exits with code 0。

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "feat(native): polish training history navigation"
```

---

### Task 6: 提交 Today Command Center UI 打磨

**Files:**
- Create: `native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Add docs: `docs/superpowers/specs/2026-06-11-today-command-center-ui-polish-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-today-command-center-ui-polish.md`
- Add docs: `docs/superpowers/specs/2026-06-11-today-sticky-watch-cta-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-today-sticky-watch-cta.md`
- Add docs: `docs/superpowers/specs/2026-06-11-today-first-screen-density-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-today-first-screen-density.md`

- [ ] **Step 1: 暂存 Today summary、UI 和对应测试**

Run:
```bash
git add native/FitnessRPGCore/Sources/FitnessRPGCore/TodayCommandCenterSummary.swift
git add -p native/AppSources/iOS/TodayCommandCenterView.swift
git add -p native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git add docs/superpowers/specs/2026-06-11-today-command-center-ui-polish-design.md
git add docs/superpowers/plans/2026-06-11-today-command-center-ui-polish.md
git add docs/superpowers/specs/2026-06-11-today-sticky-watch-cta-design.md
git add docs/superpowers/plans/2026-06-11-today-sticky-watch-cta.md
git add docs/superpowers/specs/2026-06-11-today-first-screen-density-design.md
git add docs/superpowers/plans/2026-06-11-today-first-screen-density.md
```

Stage only:
- Today hero/task/readiness/story/watch result visual hierarchy
- Sticky bottom Watch CTA
- First-screen density changes
- `TodayCommandCenterSummary` labels and CTA copy tests

- [ ] **Step 2: 运行核心测试并构建 iOS**

Run:
```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /private/tmp/FitnessRPGCommitSplitTodayIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: 两个命令都 exits with code 0。

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "feat(native): polish today command center"
```

---

### Task 7: 提交诊断面板 debug gating

**Files:**
- Modify: `native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift`
- Modify: `native/AppSources/iOS/FitnessRPGApp.swift`
- Modify: `native/AppSources/iOS/TodayCommandCenterView.swift`
- Modify: `native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift`
- Modify: `native/README.md`
- Add docs: `docs/superpowers/specs/2026-06-11-diagnostics-panel-gating-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-diagnostics-panel-gating.md`

- [ ] **Step 1: 暂存诊断开关相关 hunk**

Run:
```bash
git add -p native/FitnessRPGCore/Sources/FitnessRPGCore/AppLaunchOptions.swift
git add -p native/AppSources/iOS/FitnessRPGApp.swift
git add -p native/AppSources/iOS/TodayCommandCenterView.swift
git add -p native/FitnessRPGCore/Tests/FitnessRPGCoreTests/FitnessRPGCoreTests.swift
git add -p native/README.md
git add docs/superpowers/specs/2026-06-11-diagnostics-panel-gating-design.md
git add docs/superpowers/plans/2026-06-11-diagnostics-panel-gating.md
```

Stage only:
- `--fitnessrpg-show-diagnostics`
- `showsDiagnostics`
- `ModelHarnessPanel` 条件展示
- README debug launch argument 说明

- [ ] **Step 2: 运行核心测试并构建 iOS**

Run:
```bash
swift test --package-path native/FitnessRPGCore
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /private/tmp/FitnessRPGCommitSplitDiagnosticsIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: 两个命令都 exits with code 0。

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "chore(native): gate diagnostics panel behind debug argument"
```

---

### Task 8: 提交 iOS LaunchScreen 修复

**Files:**
- Create: `native/AppSources/iOS/LaunchScreen.storyboard`
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`
- Add docs: `docs/superpowers/specs/2026-06-11-ios-launch-screen-scale-fix-design.md`
- Add docs: `docs/superpowers/plans/2026-06-11-ios-launch-screen-scale-fix.md`

- [ ] **Step 1: 暂存 LaunchScreen 文件和项目配置 hunk**

Run:
```bash
git add native/AppSources/iOS/LaunchScreen.storyboard
git add -p native/FitnessRPG.xcodeproj/project.pbxproj
git add docs/superpowers/specs/2026-06-11-ios-launch-screen-scale-fix-design.md
git add docs/superpowers/plans/2026-06-11-ios-launch-screen-scale-fix.md
```

Stage only:
- `LaunchScreen.storyboard` resource registration
- `INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen`

- [ ] **Step 2: 构建 iOS**

Run:
```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /private/tmp/FitnessRPGCommitSplitLaunchIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: iOS build exits with code 0。

- [ ] **Step 3: 提交**

Run:
```bash
git commit -m "fix(native): add launch screen for full-screen rendering"
```

---

### Task 9: 提交底部 Tab 评估文档

**Files:**
- Add docs: `docs/superpowers/specs/2026-06-11-bottom-tab-navigation-evaluation.md`

- [ ] **Step 1: 暂存评估文档**

Run:
```bash
git add docs/superpowers/specs/2026-06-11-bottom-tab-navigation-evaluation.md
git diff --cached -- docs/superpowers/specs/2026-06-11-bottom-tab-navigation-evaluation.md
```

Expected: 文档说明当前不新增底部 Tab，并记录原因和后续触发条件。

- [ ] **Step 2: 提交**

Run:
```bash
git commit -m "docs(native): record bottom tab navigation decision"
```

---

### Task 10: 提交后总验证

**Files:**
- Verify: 全仓库当前分支

- [ ] **Step 1: 确认工作区干净**

Run:
```bash
git status --short --branch
```

Expected: 没有未提交变更。

- [ ] **Step 2: 运行核心测试**

Run:
```bash
swift test --package-path native/FitnessRPGCore
```

Expected: FitnessRPGCore test suite exits with code 0。

- [ ] **Step 3: 构建 iOS app**

Run:
```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /private/tmp/FitnessRPGCommitSplitFinalIOS CODE_SIGNING_ALLOWED=NO build
```

Expected: iOS build exits with code 0。

- [ ] **Step 4: 构建 Watch app**

Run:
```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' -derivedDataPath /private/tmp/FitnessRPGCommitSplitFinalWatch CODE_SIGNING_ALLOWED=NO build
```

Expected: Watch build exits with code 0。

- [ ] **Step 5: 检查补丁格式**

Run:
```bash
git diff --check
```

Expected: 没有 trailing whitespace 或 conflict marker 报错。
