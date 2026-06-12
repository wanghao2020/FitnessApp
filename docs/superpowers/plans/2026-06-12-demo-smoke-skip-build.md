# Demo Smoke Skip Build 执行计划

> **给执行代理：** 按步骤执行本计划，并用复选框状态跟踪进度。

**目标：** 给 demo smoke 脚本增加 `--skip-build`，让已构建过的 app 可以快速重新安装并采集 demo 截图产物。

**架构：** Bash 脚本新增 `run_build` 开关；默认执行原有 `xcodebuild`，`--skip-build` 时检查现有 `$APP_PATH` 并继续安装、启动、验证和截图。

**技术栈：** Bash、`xcodebuild`、`xcrun simctl`、Markdown。

---

## 文件

- 修改：`native/scripts/demo-seed-simulator-smoke.sh`
- 修改：`docs/validation/demo-seed-runbook.md`
- 修改：`README.md`
- 修改：`native/README.md`
- 新增：`docs/superpowers/specs/2026-06-12-demo-smoke-skip-build-design.md`
- 新增：`docs/superpowers/plans/2026-06-12-demo-smoke-skip-build.md`

## 任务

- [x] **步骤 1：确认 RED**

运行：

```bash
rg -q -- "--skip-build" native/scripts/demo-seed-simulator-smoke.sh docs/validation/demo-seed-runbook.md
```

预期：失败，说明脚本和 runbook 还没有 skip build 入口。

- [x] **步骤 2：实现 `--skip-build`**

新增 `run_build=1`，解析 `--skip-build` 后设置为 `0`，并在 build 阶段：

```bash
if [[ "$run_build" -eq 1 ]]; then
  xcodebuild ...
elif [[ ! -d "$APP_PATH" ]]; then
  echo "Missing existing app build at $APP_PATH. Run without --skip-build first." >&2
  exit 1
fi
```

- [x] **步骤 3：更新文档**

在 runbook 和 README 中说明 `--skip-build` 用于已构建后的快速截图重采集。

- [x] **步骤 4：验证**

运行：

```bash
bash -n native/scripts/demo-seed-simulator-smoke.sh
bash native/scripts/demo-seed-simulator-smoke.sh --help
bash native/scripts/demo-seed-simulator-smoke.sh --skip-build --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
test -s /private/tmp/fitnessrpg-demo-gallery/index.html
test -s /private/tmp/fitnessrpg-demo-gallery/manifest.md
git diff --check
```

- [x] **步骤 5：提交并推送**

提交信息：`chore(native): speed up demo smoke recapture`
