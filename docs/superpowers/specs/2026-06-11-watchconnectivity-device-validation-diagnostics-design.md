# WatchConnectivity 真机验证诊断打磨设计

## 背景

iOS / watchOS 已经有 WatchConnectivity MVP：iPhone 发送今日任务，Watch 记录执行日志并回传，iPhone 再落到 History。DEBUG Today 页面也有 WatchConnectivity 诊断面板，显示支持状态、激活、配对、Watch App、可达性、最近发送、最近回传和最近错误。

下一步是真机验证。当前诊断面板能显示底层状态，但还缺一组“真机检查下一步”提示，让测试者知道应该先确认安装、再确认发送、最后确认回传。

## 目标

- 在 Core 诊断 summary 中增加真机验证清单行。
- 保持 SwiftUI 面板只展示 `summary.rows`，不在 UI 层写判断逻辑。
- 不改变 WatchConnectivity payload、传输策略或持久化格式。
- README / native README 增加可执行的真机验证步骤。

## 非目标

- 不解决真实设备上可能出现的系统级配对或签名问题。
- 不接入自动 UI 测试，因为 WatchConnectivity 真机链路无法由当前模拟器完整证明。
- 不新增日志导出文件或远程上报。

## 诊断清单

在现有诊断行后追加三行：

- `真机检查 · 安装`
  - 已支持、已配对、Watch App 已安装：`iPhone 与 Watch App 已准备好。`
  - 否则提示先检查配对、安装和 companion bundle。
- `真机检查 · 发送`
  - 有最近发送：显示最近发送通道。
  - 无发送但可实时达：提示点击 Today 底部发送按钮。
  - 无发送且不可实时达：提示仍可用 `transferUserInfo` 排队验证。
- `真机检查 · 回传`
  - 有最近回传：显示最近回传通道。
  - 无最近回传：提示在 Watch 完成步骤后回到 iPhone 查看 History。

这些行属于验证辅助，不影响 headline / tint / 原有状态。

## 验证

- Core 单元测试覆盖：
  - ready/reachable 状态下清单提示实时发送。
  - queued 状态下清单提示 transferUserInfo。
  - 有 inbound 时清单显示最近回传。
- SwiftPM 全量测试。
- iOS / watchOS Xcode build。
- README 中记录真机检查顺序。
