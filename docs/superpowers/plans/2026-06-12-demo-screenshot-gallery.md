# Demo 截图库执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 给 demo smoke 脚本增加 `--screenshots-dir`，一次产出 History、Today、Memory、Validation Archive 四张 demo 截图。

**架构：** 脚本仍负责构建、安装、启动、JSON 验证；新增 gallery 截图函数复用同一个 app 和同一个模拟器，通过 terminate + launch 切换 DEBUG 启动参数。

**技术栈：** Bash、`xcodebuild`、`xcrun simctl`、Markdown。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-screenshot-gallery-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-screenshot-gallery.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "--screenshots-dir" native/scripts/demo-seed-simulator-smoke.sh
rg -q -- "screenshots-dir" docs/validation/demo-seed-runbook.md
```

预期：两条命令都失败，说明脚本和 runbook 还没有多截图目录参数。

- [x] **步骤 2：实现 gallery 参数**

新增 `--screenshots-dir <dir>`，并在同一次 smoke 中输出 `history.png`、`today.png`、`memory.png`、`validation-archive.png`。

- [x] **步骤 3：更新文档**

在 demo runbook 和 README 中记录多截图命令和文件名。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --help
bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
test -s /private/tmp/fitnessrpg-demo-gallery/history.png
test -s /private/tmp/fitnessrpg-demo-gallery/today.png
test -s /private/tmp/fitnessrpg-demo-gallery/memory.png
test -s /private/tmp/fitnessrpg-demo-gallery/validation-archive.png
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): capture demo screenshot gallery`
