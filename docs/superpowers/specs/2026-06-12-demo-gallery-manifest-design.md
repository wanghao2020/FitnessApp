# 2026-06-12 Demo 截图库 Manifest 设计

## 目标

让 `--screenshots-dir` 产出的 demo 截图库自带一份 `manifest.md`，记录生成时间、模拟器设备、Bundle ID、截图文件、启动参数和验证结果。这样截图目录可以直接发给别人或附到 issue，不需要额外解释每张图来自哪个 demo 表面。

## 设计

- 仅在 `--screenshots-dir` 模式下生成 `manifest.md`。
- 使用 Markdown 而不是 JSON，避免在 Bash 中引入额外 JSON 转义依赖。
- manifest 头部记录：
  - UTC 生成时间。
  - Simulator device id。
  - Bundle id。
  - 截图等待秒数。
- manifest 表格记录每张图：
  - Screen 名称。
  - 文件名。
  - Launch arguments。
  - 验证结果：文件存在且非空。
- 脚本每完成一张截图就追加一行，确保中途失败时 manifest 也能提示已完成到哪里。

## 非目标

- 不提交截图文件。
- 不生成 JSON manifest。
- 不做 OCR 或像素级验证。

## 验证

- RED：脚本和 runbook 中缺少 `manifest.md`。
- GREEN：gallery smoke 后检查 `manifest.md` 非空，且包含 5 张截图文件名和关键启动参数。
