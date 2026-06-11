# 本地模型 Runtime Scaffold 设计

## 目标

为原生 Core 增加第一版本地模型 runtime scaffold：把 Memory Review、今日 quest 和 readiness 汇总成有界上下文，并在任何模型草稿进入产品文案前运行确定性安全校验。

## 背景

项目已经具备：

- `ModelHarnessBuilder`：说明本地模型会如何参与。
- `MemoryEntry` / `MemoryReviewEntry`：持久化训练记忆和可读回顾。
- `ReadinessResult` / `DailyQuest`：当前安全边界和 Watch payload 目标。

但目前还没有真实 runtime 接入前的上下文边界和输出校验器。如果直接接 LiteRT-LM / Gemma，模型输出会缺少可测试的安全闸门。

## 方案

新增 Core-only scaffold：

- `ModelRuntimeContextBuilder`
  - 输入 `ReadinessResult`、`DailyQuest`、`MemoryReviewEntry`。
  - 只保留最多 3 条最新 memory。
  - 输出 bounded `ModelRuntimeContext` 和 prompt preview。
- `ModelOutputValidator`
  - 拦截红灯/黄灯场景中的冲刺、最大重量、PR、HIIT 等高强度文案。
  - 如果最近 memory 出现过重或已降阶，要求输出包含降阶、降低强度或恢复建议。
- `ModelRuntimeOrchestrator`
  - 接受可选模型草稿。
  - 模型草稿缺失或校验失败时返回确定性 fallback。
  - 本轮不调用真实模型 SDK。

## 非目标

- 不接 LiteRT-LM / Gemma 二进制或模型文件。
- 不新增远程 API。
- 不改变 QuestEngine、ExecutionEngine、WatchConnectivity 或持久化 schema。
- 不把原始 HealthKit samples 放入 prompt。

## 验证

- Core 测试覆盖 memory 上下文裁剪、红灯高强度拒绝、过重记忆后的降阶要求。
- iOS build 通过。
- watchOS build 通过。
- README 更新后路线图进入真实 runtime adapter。
