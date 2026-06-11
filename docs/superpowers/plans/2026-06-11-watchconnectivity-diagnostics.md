# WatchConnectivity 诊断面板执行计划

**目标：** 在 DEBUG 诊断模式下显示 WatchConnectivity 会话状态、最近传输记录和错误原因，支撑后续真机配对调试。

**架构：** Core 提供可测试的诊断摘要；iOS `WatchQuestSyncModel` 负责把 `WCSession` 映射为 Snapshot；SwiftUI 只负责紧凑展示。

---

## Task 1: Core 红测

- [x] 新增 `WatchConnectivityDiagnosticsSnapshot` 相关测试。
- [x] 运行过滤测试确认当前失败。

## Task 2: Core 诊断摘要模型

- [x] 新增 Snapshot、Summary、Row、TransferRecord 类型。
- [x] 实现不可用、未激活、未配对、未安装、实时可达、队列可达的摘要文案和图标。
- [x] 运行 Core 过滤测试。

## Task 3: iOS 同步模型接入

- [x] `WatchQuestSyncModel` 增加 `diagnosticsSnapshot`。
- [x] 初始化、激活回调、Watch 状态变化、可达性变化、发送、回传、错误路径都刷新 Snapshot。
- [x] 保持现有 `statusText` 行为和 payload schema 不变。

## Task 4: SwiftUI 诊断面板

- [x] 新增 `WatchConnectivityDiagnosticsPanel`。
- [x] Today 在 `showsDiagnostics` 为 true 时显示该面板。
- [x] 面板使用紧凑行、SF Symbols、8pt 圆角和 Dynamic Type 友好的纵向布局。

## Task 5: 文档与验证

- [x] 更新 README 和 native README。
- [x] 运行 `swift test`。
- [x] 运行 iOS build。
- [x] 运行 watchOS build。
- [x] 运行 `git diff --check`。
- [x] 在模拟器用 `--fitnessrpg-show-diagnostics` 截图检查显示。
