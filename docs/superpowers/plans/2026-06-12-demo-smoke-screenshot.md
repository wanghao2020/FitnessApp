# Demo Smoke 截图执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 给 demo seed smoke 脚本增加可选截图输出，让本地 demo 每次运行都能同时验证数据和留存 UI 证据。

**架构：** smoke 脚本继续负责构建、安装、启动和 JSON 检查；截图作为启动后的可选步骤；runbook 记录 Xcode 和 CLI 两条路径。

**技术栈：** Bash、`xcodebuild`、`xcrun simctl`、Markdown。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-smoke-screenshot-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-smoke-screenshot.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "--screenshot" native/scripts/demo-seed-simulator-smoke.sh
rg -q -- "--screenshot" docs/validation/demo-seed-runbook.md
```

预期：两条命令都失败，说明脚本和 runbook 还没有截图参数。

- [x] **步骤 2：实现脚本参数**

新增 `--help`、`--device <id>`、`--screenshot <path>`、`--screenshot-delay <seconds>`，并保留旧的位置参数 device id。

- [x] **步骤 3：更新 runbook 和 README**

用中文记录截图命令、预期 UI 证据，以及 demo banner 四个路径入口。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --help
bash native/scripts/demo-seed-simulator-smoke.sh --screenshot /private/tmp/fitnessrpg-demo-smoke.png
test -s /private/tmp/fitnessrpg-demo-smoke.png
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): capture demo smoke screenshot`
