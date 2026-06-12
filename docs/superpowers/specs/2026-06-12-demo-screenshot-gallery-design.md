# 2026-06-12 Demo 截图库设计

## 目标

让 `demo-seed-simulator-smoke.sh` 一次运行即可产出完整 demo 截图库，覆盖 History、Today、Memory Review 和 Validation Archive。这样 demo 不只证明 JSON 数据存在，还能证明主要展示面都能启动、中文正常、布局可见。

## 设计

- 新增 `--screenshots-dir <dir>` 参数。
- 脚本继续只构建和安装 `FitnessRPGDemo` 一次。
- JSON 验证仍在默认 History demo 启动后执行。
- 如果提供 `--screenshots-dir`，脚本依次 terminate 并重新 launch app：
  - `history.png`：`--fitnessrpg-demo-seed --fitnessrpg-open-history --fitnessrpg-show-diagnostics`
  - `today.png`：`--fitnessrpg-demo-seed --fitnessrpg-show-diagnostics`
  - `memory.png`：`--fitnessrpg-demo-seed --fitnessrpg-open-memory-review --fitnessrpg-show-diagnostics`
  - `validation-archive.png`：`--fitnessrpg-demo-seed --fitnessrpg-open-validation-report-archive`
- 每张截图复用 `--screenshot-delay` 等待，避免启动过渡黑屏。
- 原有 `--screenshot <path>` 单图能力保留，继续捕获默认 History 首屏。

## 非目标

- 不新增 UI test target。
- 不做 OCR、像素比对或自动判断中文内容。
- 不把截图文件提交到仓库。

## 验证

- `bash -n` 验证脚本语法。
- `--help` 输出包含 `--screenshots-dir`。
- 实际运行后检查四张截图文件均非空，并人工查看至少一张确认不是黑屏。
