# 2026-06-12 Demo 截图库 Index 设计

## 目标

让 `--screenshots-dir` 输出目录自带 `index.html`，可以直接在浏览器里查看 5 张 demo 截图、对应启动参数和 manifest 链接。这样 demo 产物从“几张散图”变成一个可浏览、可交付的小包。

## 设计

- 仅在 `--screenshots-dir` 模式下生成 `index.html`。
- `index.html` 与截图同目录，使用相对路径引用 PNG 和 `manifest.md`。
- 页面结构：
  - 顶部：标题、生成时间、设备、Bundle ID、manifest 链接。
  - 截图网格：History、History detail、Today、Memory Review、Validation archive。
  - 每张卡片显示文件名、启动参数和图片。
- UI 原则：
  - 走 “operations gallery” 风格，内容优先、可扫读。
  - 不依赖外部字体、图片、CDN 或 JavaScript。
  - 响应式网格，窄屏单列，宽屏多列。
  - 图片保持固定最大宽度，避免大图撑破页面。

## 非目标

- 不提交生成的 `index.html`。
- 不做交互筛选或缩放控件。
- 不引入 npm、Playwright 或额外静态站点工具。

## 验证

- RED：脚本和 runbook 中缺少 `index.html`。
- GREEN：gallery smoke 后检查 `index.html` 非空，并包含 5 张 PNG、`manifest.md` 和关键启动参数。
