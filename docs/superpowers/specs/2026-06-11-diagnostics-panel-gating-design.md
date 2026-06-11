# Today 开发诊断面板开关设计

## 目标

让 Today 默认首屏更像正式用户界面，不再在普通启动路径展示 `ModelHarnessPanel`。开发验证能力保留，但必须通过 DEBUG launch argument 显式打开。

## 背景

当前 Today 页面底部直接渲染 `ModelHarnessPanel`。它对开发验证很有价值，但普通用户路径中会显得像调试面板，削弱 Fitness RPG 的正式产品感。

项目已有 DEBUG launch argument 模式：

- `--fitnessrpg-open-history`
- `--fitnessrpg-open-latest-history-detail`

因此诊断面板也沿用这个入口，而不是新增设置页、隐藏手势或额外导航。

## 方案

新增 launch argument：

```text
--fitnessrpg-show-diagnostics
```

行为：

- Debug build 中，只有传入该参数时 Today 才展示 `ModelHarnessPanel`。
- Debug build 默认启动不展示诊断面板。
- Release build 永远不展示诊断面板。
- `ModelHarnessBuilder` 和 `ModelHarnessPanel` 保留，不删除现有开发工具。

## 非目标

- 不修改模型 harness 的内容和生成逻辑。
- 不新增设置页。
- 不新增 Tab 或开发者菜单。
- 不改变 Today 的 Watch、HealthKit、故事推进和持久化行为。

## 验证

- Core 测试覆盖 `AppLaunchOptions.showsDiagnostics(arguments:)`。
- iOS build 通过。
- 默认启动截图确认首屏保持正式 Today 体验。
- 用 `--fitnessrpg-show-diagnostics` 启动时仍可打开诊断面板。
