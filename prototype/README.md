# Fitness RPG 中文交互原型

这是一个无依赖浏览器原型，用来在进入原生 iPhone / watchOS 开发前，对齐 Fitness RPG 的“今日任务中枢”体验。

原型重点：

- iPhone 作为每日健康摘要、任务生成和剧情教练中枢。
- Apple Watch 作为训练中执行动作、记录 RPE 和快速反馈的表面。
- HealthKit 恢复状态映射为 `绿 / 黄 / 红` 三种任务分支。
- 剧情 RPG 作为训练动机层，但安全边界始终优先。
- 顶部使用 `prototype/assets/resonance-hall.svg` 作为低干扰 RPG 氛围资产，并通过状态色 token 区分 `共振稳定 / 共振偏移 / 营火修复`。

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
- 确认顶部氛围图正常显示，且状态切换后视觉边框 token 随 readiness 更新。
- 确认黄色与红色状态会降低强度，并且恢复任务仍被叙事为正向进展。
- 在 `Apple Watch 执行` 中使用 `上一项 / 下一项` 切换动作。
- 对当前动作点击 `完成 / 过重 / 跳过 / RPE≤目标`，确认 `训练日志草稿` 同步更新。
- 切换模型模式：`本地优先`、`本地 + 远程增强`、`禁用远程`。
- 查看 `本地模型 Harness`，确认输入上下文、Skill 规则、生成路径、Fallback 和 Prompt 预览会随模型模式与训练日志变化。
- 点击一次 `过重`，确认 Harness 中出现过重信号与降负规则。
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
node --check prototype/src/modelHarness.js
node prototype/tests/prototypeContract.test.mjs
curl -s http://localhost:5173
test -f prototype/assets/resonance-hall.svg
```
