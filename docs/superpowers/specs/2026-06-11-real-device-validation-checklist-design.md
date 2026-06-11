# 实机验证总览清单设计

## 目标

在 DEBUG Today 页面增加一张“实机验证总览”卡片，把 WatchConnectivity、HealthKit、Runtime 和 History 周回顾缓存操作串成一组可扫读检查项。这样后续拿真实 iPhone / Apple Watch / LiteRT-LM 资源测试时，不需要在多个面板之间来回推断下一步。

## 背景

当前项目已经有多个独立诊断能力：

- WatchConnectivity 面板显示配对、安装、发送和回传。
- HealthKit fallback notice 显示权限、设备和数据覆盖下一步。
- Runtime 面板显示 LiteRT-LM 资源、adapter、parser、validator 和 fallback。
- History 周回顾润色区块可以清除或重新生成缓存。

这些能力各自可用，但端到端验证时缺少一张总览，说明“现在卡在哪一段，下一步该验证哪一段”。

## 设计

新增 Core 级 `RealDeviceValidationChecklistBuilder`。它只消费现有展示模型和少量状态：

- `WatchConnectivityDiagnosticsSnapshot`
- `HealthDataSourceSnapshot`
- `ModelRuntimeDiagnosticsSummary`
- `historyRecordCount`
- `hasWeeklyPolishCache`

输出：

- `RealDeviceValidationChecklist`
- `RealDeviceValidationRow`
- `RealDeviceValidationState`

四个 rows：

1. `Watch 同步`：安装、发送、回传是否推进。
2. `HealthKit`：是否成功读取，或显示当前 fallback 下一步。
3. `Runtime`：LiteRT-LM provider 是否就绪，或显示当前资源/adapter/fallback 状态。
4. `History 周回顾`：是否已有 History 记录，以及当前周 polish cache 是否已生成。

Today 只在 `--fitnessrpg-show-diagnostics` 下显示这张卡片，并放在 Runtime / WatchConnectivity 详细面板上方。它不替代详细面板，只做入口级总览。

## 状态规则

- 全部通过：绿色，标题为“实机验证清单已通过”。
- 有阻塞项：橙色，标题为“实机验证还有阻塞项”。
- 没有阻塞但仍待推进：蓝色，标题为“实机验证正在推进”。

## 非目标

- 不自动执行真机测试。
- 不改变 WatchConnectivity、HealthKit、Runtime 或 History 的业务行为。
- 不把 DEBUG 面板暴露到 Release。
- 不存储验证结果。
- 不新增新的启动参数。

## 验证

- Core tests 覆盖阻塞状态、推进状态和全通过状态。
- `swift test --package-path native/FitnessRPGCore` 通过。
- iOS / watchOS generic build 通过。
- 模拟器用 `--fitnessrpg-show-diagnostics` 截图检查总览卡片无乱码、无遮挡。
