# 2026-06-12 Demo History 详情截图设计

## 目标

把最新训练日详情页加入 demo 截图库。History 列表能证明有训练记录，详情页能展示 Watch 回传日志、训练结果和故事推进，是端到端 demo 闭环的重要证据。

## 设计

- 复用现有 DEBUG 启动参数 `--fitnessrpg-open-latest-history-detail`。
- 在 `--screenshots-dir` 模式中新增 `history-detail.png`。
- 截图顺序放在 `history.png` 后面，形成“列表 -> 详情”的自然演示路径。
- 保留同一个 `--screenshot-delay` 等待策略。

## 非目标

- 不新增新的 app launch argument。
- 不改变 History 详情 UI。
- 不做自动 OCR 或像素检查。
