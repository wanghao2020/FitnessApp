# Demo Seed 运行手册

当真实 HealthKit、WatchConnectivity 或 LiteRT-LM 资源还没有接入时，用这份手册打开一个可重复的 native demo。

## Xcode 路径

1. 打开 `native/FitnessRPG.xcodeproj`。
2. 选择共享 scheme：`FitnessRPGDemo`。
3. 在 iPhone 模拟器上运行。
4. 预期首屏：直接进入 History，展示已种子的周回顾和训练记录。
5. 预期 demo banner：
   - 顶部显示 `演示模式`。
   - evidence 区展示 Today、History、Memory、Diagnostics 四个状态。
   - action 区展示 Today、History、Memory、Diagnostics 四个路径按钮。
6. 预期数据：
   - `2026-06-12` 今日训练已完成。
   - 周回顾标题为 `演示周报：保守推进已闭环`。
   - Memory Review 中有 Watch 执行结果生成的记忆草稿。
   - Today 可显示 Diagnostics，因为 scheme 默认启用 `--fitnessrpg-show-diagnostics`。

## CLI Smoke 路径

从仓库根目录运行：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh
```

脚本会查找已启动的 iPhone 模拟器；如果没有，就启动 `iPhone 17`。随后它会构建 `FitnessRPGDemo`、安装 app、用 demo 参数启动，并验证这些 JSON 文件：

- `training-days.json`
- `weekly-summary-polish-entries.json`
- `validation-reports.json`

通过输出：

```text
FitnessRPGDemo smoke passed on simulator <device-id>.
```

## 截图证据

需要同时留存 UI 证据时，传入 `--screenshot`：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh --screenshot /private/tmp/fitnessrpg-demo-smoke.png
```

预期截图应能看到 History 首屏、`演示模式` banner、四个 evidence 状态块，以及四个路径按钮。人工确认重点：

- 中文没有乱码。
- 按钮不重叠，文字没有溢出。
- 顶部 safe area 和返回按钮没有遮挡内容。

需要一次导出完整 demo 截图库时，传入 `--screenshots-dir`：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
```

脚本会输出：

- `/private/tmp/fitnessrpg-demo-gallery/history.png`
- `/private/tmp/fitnessrpg-demo-gallery/history-detail.png`
- `/private/tmp/fitnessrpg-demo-gallery/today.png`
- `/private/tmp/fitnessrpg-demo-gallery/memory.png`
- `/private/tmp/fitnessrpg-demo-gallery/validation-archive.png`
- `/private/tmp/fitnessrpg-demo-gallery/manifest.md`
- `/private/tmp/fitnessrpg-demo-gallery/index.html`

这五张图覆盖 History 首屏、最新训练详情、Today 诊断、Memory Review 和验证报告归档入口。`manifest.md` 会记录生成时间、模拟器、每张截图的文件名和启动参数。`index.html` 可以直接在浏览器中打开，用来扫读整套 demo 截图。

也可以指定设备：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh --device <device-id> --screenshots-dir /private/tmp/fitnessrpg-demo-gallery
```

脚本默认会在截图前等待 2 秒，避免截到 iOS 启动过渡黑屏。较慢的模拟器可以加长等待：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh --screenshot /private/tmp/fitnessrpg-demo-smoke.png --screenshot-delay 4
```

旧的位置参数仍然兼容：

```bash
bash native/scripts/demo-seed-simulator-smoke.sh <device-id>
```

## 手动启动参数

如果使用普通 `FitnessRPG` scheme，手动添加这些 Debug launch arguments：

```text
--fitnessrpg-demo-seed
--fitnessrpg-open-history
--fitnessrpg-show-diagnostics
```
