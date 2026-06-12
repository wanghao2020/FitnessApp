# Demo 截图库 Manifest 执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 为 `--screenshots-dir` 生成 `manifest.md`，记录 demo 截图库的生成环境、文件清单和启动参数。

**架构：** Bash 脚本在 gallery 模式初始化 Markdown manifest；每次截图成功后追加一行表格。单图 `--screenshot` 不生成 manifest，避免改变原有轻量路径。

**技术栈：** Bash、Markdown、`xcrun simctl`、现有 demo smoke 脚本。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-gallery-manifest-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-gallery-manifest.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "manifest.md" native/scripts/demo-seed-simulator-smoke.sh docs/validation/demo-seed-runbook.md
```

预期：失败，说明 gallery 还不会生成 manifest。

- [x] **步骤 2：实现 manifest 写入**

新增 `write_gallery_manifest_header`、`append_gallery_manifest_row` 和 `capture_gallery_screen`，让 gallery 模式输出 `manifest.md`。

- [x] **步骤 3：更新文档**

在 runbook 和 README 中说明 `manifest.md` 会随 gallery 生成。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --help
bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
test -s /private/tmp/fitnessrpg-demo-gallery/manifest.md
rg -q -- "history-detail.png" /private/tmp/fitnessrpg-demo-gallery/manifest.md
rg -q -- "--fitnessrpg-open-validation-report-archive" /private/tmp/fitnessrpg-demo-gallery/manifest.md
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): write demo gallery manifest`
