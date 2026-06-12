# Demo History 详情截图执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 在 demo 截图库中新增 `history-detail.png`，覆盖最新训练日详情页。

**架构：** 复用 `demo-seed-simulator-smoke.sh` 的 gallery 截图流程，通过 `--fitnessrpg-open-latest-history-detail` 启动最新详情页并截图。

**技术栈：** Bash、`xcrun simctl`、现有 DEBUG launch arguments、Markdown。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-history-detail-screenshot-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-history-detail-screenshot.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "history-detail.png" native/scripts/demo-seed-simulator-smoke.sh docs/validation/demo-seed-runbook.md
```

预期：失败，说明 gallery 还没有 History 详情截图。

- [x] **步骤 2：实现截图**

在 `--screenshots-dir` 模式中新增：

```bash
launch_demo \
  --fitnessrpg-demo-seed \
  --fitnessrpg-open-latest-history-detail \
  --fitnessrpg-show-diagnostics
capture_screenshot "$screenshots_dir/history-detail.png"
```

- [x] **步骤 3：更新文档**

在 runbook 和 README 中把 gallery 从四张更新为五张，并列出 `history-detail.png`。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --help
bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
test -s /private/tmp/fitnessrpg-demo-gallery/history-detail.png
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): capture demo history detail`
