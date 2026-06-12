# Demo 截图库 Index 执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 为 `--screenshots-dir` 生成 `index.html`，让 demo 截图库可以直接在浏览器中浏览。

**架构：** Bash 脚本在 gallery 模式完成截图和 manifest 后写入一个无依赖静态 HTML。HTML 使用同目录相对路径引用截图和 `manifest.md`。

**技术栈：** Bash、静态 HTML/CSS、Markdown、现有 demo smoke 脚本。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-gallery-index-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-gallery-index.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "index.html" native/scripts/demo-seed-simulator-smoke.sh docs/validation/demo-seed-runbook.md
```

预期：失败，说明 gallery 还不会生成浏览页。

- [x] **步骤 2：实现 index 写入**

新增 `write_gallery_index`，在 gallery 模式截图和 manifest 完成后生成 `index.html`。

- [x] **步骤 3：更新文档**

在 runbook 和 README 中说明 `index.html` 会随 gallery 生成，可直接打开浏览。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
test -s /private/tmp/fitnessrpg-demo-gallery/index.html
rg -q -- "history-detail.png" /private/tmp/fitnessrpg-demo-gallery/index.html
rg -q -- "manifest.md" /private/tmp/fitnessrpg-demo-gallery/index.html
rg -q -- "--fitnessrpg-open-validation-report-archive" /private/tmp/fitnessrpg-demo-gallery/index.html
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): write demo gallery index`
