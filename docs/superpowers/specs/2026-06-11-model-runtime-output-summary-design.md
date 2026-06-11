# 模型 Runtime 输出摘要设计

## 目标

让 Runtime 诊断面板在本地模型实际运行后，直接显示本次输出的草稿标题和下一步动作。这样 DEBUG fixture、fallback 和未来真实模型接入都能在首屏排障时看到“到底产出了什么”。

## 背景

当前诊断面板已经显示 provider、资源、adapter、parser、validator 和 fallback 状态。但 ready fixture 成功时只能看到 provider 就绪和校验通过，不能快速确认输出摘要；失败 fallback 时也不清楚最终展示的确定性草稿是什么。

## 方案

- 扩展 `ModelRuntimeDiagnosticsBuilder.summary`。
  - 当 `response == nil` 时保持现状，只展示静态 provider/resource 状态。
  - 当 `response != nil` 时追加两行：
    - `草稿`：`response.draft.title`
    - `下一步`：`response.draft.nextAction`
- 不展示正文 body。
  - 正文可能较长，放进紧凑诊断卡会降低可扫读性。
  - 标题和下一步足够确认模型路径或 fallback 路径是否产出正确类型。

## UI/UX 原则

- 保持现有系统图标、小半径卡片和紧凑行布局。
- 只增加运行后信息，不让未运行的资源预检面板变得更长。
- 行标题使用短中文，避免按钮底部 CTA 被挤出太远。

## 非目标

- 不改变模型运行逻辑。
- 不改变 validator 或 fallback。
- 不新增生产开关。
- 不展示完整模型正文。

## 验证

- Core 测试覆盖运行后 summary 包含 `草稿` 和 `下一步` 行。
- SwiftPM 全量测试通过。
- iOS / watchOS build 通过。
- iOS Simulator ready fixture 截图检查 Runtime 面板正常渲染；新增行由 Core 测试直接验证。
