# Fitness RPG 中文交互原型

这是一个无依赖浏览器原型，用来在进入原生 iPhone / watchOS 开发前，对齐 Fitness RPG 的“今日任务中枢”体验。

原型重点：

- iPhone 作为每日健康摘要、任务生成和剧情教练中枢。
- Apple Watch 作为训练中执行动作、记录 RPE 和快速反馈的表面。
- HealthKit 恢复状态映射为 `绿 / 黄 / 红` 三种任务分支。
- 剧情 RPG 作为训练动机层，但安全边界始终优先。

## Open

直接打开：

```text
prototype/index.html
```

或启动本地服务：

```bash
cd prototype
python3 -m http.server 5173
```

然后打开 `http://localhost:5173`。

## 交互检查

- 切换 `绿 / 黄 / 红` 状态场景。
- 确认今日状态、世界状态、今日任务、安全边界和 Apple Watch 执行内容同步变化。
- 确认黄色与红色状态会降低强度，并且恢复任务仍被叙事为正向进展。
- 在 `Apple Watch 执行` 中使用 `上一项 / 下一项` 切换动作。
- 对当前动作点击 `完成 / 过重 / 跳过 / RPE≤目标`，确认 `训练日志草稿` 同步更新。
- 切换模型模式：`本地优先`、`本地 + 远程增强`、`禁用远程`。
- 点击 `完成模拟训练`，查看中文训练结果、下一次建议与 `Memory 草稿`。

## 验证命令

```bash
node --check prototype/src/main.js
node --check prototype/src/mockData.js
node --check prototype/src/questEngine.js
node --check prototype/src/readiness.js
node --check prototype/src/render.js
node --check prototype/src/state.js
node --check prototype/src/execution.js
node prototype/tests/prototypeContract.test.mjs
curl -s http://localhost:5173
```
