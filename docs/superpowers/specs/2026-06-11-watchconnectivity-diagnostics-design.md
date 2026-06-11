# WatchConnectivity 诊断面板设计

## 目标

在 DEBUG 诊断模式下，为 Today 页面增加一块 WatchConnectivity 状态面板，帮助真机和模拟器调试时快速判断 iPhone 与 Apple Watch 的同步链路是否可用。

## 背景

当前 iOS 端只有 `statusText`，它适合给用户展示一句同步反馈，但不适合排查以下问题：

- 当前设备是否支持 WatchConnectivity。
- WCSession 是否已激活。
- 是否已配对 Apple Watch。
- Watch App 是否安装。
- 当前是否可实时发送 `sendMessage`。
- 最近一次发送或回传走的是实时消息还是 `transferUserInfo` 队列。
- 最近错误是否来自激活、编码、发送失败或解码失败。

这些信息应保留在 DEBUG 入口内，不进入普通用户路径。

## 方案

新增 Core 层纯展示模型：

- `WatchConnectivityDiagnosticsSnapshot`
- `WatchConnectivityDiagnosticsSummary`
- `WatchConnectivityDiagnosticsRow`
- `WatchConnectivityTransferRecord`

iOS `WatchQuestSyncModel` 将 `WCSession` 状态映射到 Snapshot，SwiftUI 面板只读取摘要展示。

展示策略：

- 不可用：橙色警示，说明当前设备不支持同步会话。
- 会话未激活：橙色警示，提示等待激活或检查错误。
- 未配对或未安装 Watch App：橙色警示，给出明确阻断原因。
- 已激活且实时可达：绿色状态，说明可走 `sendMessage`。
- 已激活但暂不可达：蓝色状态，说明可走 `transferUserInfo` 队列。

## UI 约束

- 沿用 Today 既有工具型信息面板风格，不新增 Hero、Tab 或设置页。
- 使用 SF Symbols 图标辅助扫描。
- 圆角保持 8pt。
- 正文使用系统字体和 Dynamic Type，关键状态不低于 footnote。
- 行内容纵向排列，避免大字号或长中文在小屏重叠。
- 面板只在 `--fitnessrpg-show-diagnostics` 开启时出现。

## 非目标

- 不修改 WatchConnectivity payload schema。
- 不改变 Watch App 执行记录逻辑。
- 不新增用户可见设置。
- 不依赖真机才能通过基础构建和单元测试。

## 验证

- Core 单元测试覆盖不可用、实时可达、排队可达三类摘要。
- iOS build 通过。
- watchOS build 通过。
- 用 `--fitnessrpg-show-diagnostics` 启动模拟器，截图确认诊断面板显示且无乱码、无文字重叠。
