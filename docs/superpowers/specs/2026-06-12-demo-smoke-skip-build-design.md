# 2026-06-12 Demo Smoke Skip Build 设计

## 目标

给 `demo-seed-simulator-smoke.sh` 增加 `--skip-build`，让已经有本地构建产物时可以快速重新安装、启动和采集 demo 截图。这个模式主要服务 UI 截图复查、gallery/index 重采集和文档验证，不改变默认完整 smoke。

## 设计

- 新增 `--skip-build` 参数。
- 默认行为不变：仍然执行 `xcodebuild`。
- 使用 `--skip-build` 时：
  - 不执行 `xcodebuild`。
  - 仍然要求 `$APP_PATH` 存在。
  - 仍然执行 `xcrun simctl install "$device_id" "$APP_PATH"`，避免依赖模拟器里未知旧安装。
  - 如果 `$APP_PATH` 不存在，输出明确错误，提示先运行不带 `--skip-build` 的 smoke。
- `--screenshots-dir`、`--screenshot`、`--device` 与 `--skip-build` 可组合使用。

## 非目标

- 不新增 `--skip-install`。
- 不改变 DerivedData 默认路径。
- 不自动查找多个历史构建产物。

## 验证

- RED：脚本和 runbook 中缺少 `--skip-build`。
- GREEN：脚本语法通过，help 显示 `--skip-build`，已有构建产物时 `--skip-build --screenshots-dir ...` 能完成 gallery/index/manifest 生成。
