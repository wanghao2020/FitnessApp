# 2026-06-12 Demo Smoke 截图设计

## 目标

让 `native/scripts/demo-seed-simulator-smoke.sh` 除了验证 demo JSON 数据外，还可以在同一次模拟器启动后输出截图。这样 demo banner、路径入口按钮、History 首屏和中文字体显示都能留下可复现证据。

## 设计

- 保留现有无参数用法，继续自动查找或启动 iPhone 模拟器。
- 新增 `--screenshot <path>` 参数，在 app 启动并完成 JSON 验证后调用 `xcrun simctl io <device> screenshot <path>`。
- 截图前默认等待 2 秒，避开 iOS 启动过渡黑屏；必要时可用 `--screenshot-delay <seconds>` 调整。
- 新增 `--device <id>` 参数，同时兼容旧的第一个位置参数作为 device id。
- 新增 `--help`，说明参数和输出。
- runbook 改为中文，并记录截图命令、预期首屏和 demo banner 四个路径按钮。

## 非目标

- 不新增 UI test target。
- 不做 OCR 或像素级自动判定。
- 不改变 `FitnessRPGDemo` scheme 的启动参数。

## UI/UX 依据

- demo 截图要覆盖真实首屏，而不是只验证文件落盘。
- banner 按钮继续保持 44pt 以上触控高度和 8pt 间距。
- 截图用于人工确认中文不乱码、按钮不重叠、safe area 没有遮挡。
