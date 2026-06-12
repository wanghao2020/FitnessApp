# End-to-end Real-device Validation 设计

## 目标

把 WatchConnectivity、HealthKit、LiteRT-LM / Gemma 和 History weekly polish cache 的真机验证串成一个总入口。开发者先跑一个聚合 preflight，再按一个总 runbook 执行真实设备流程，最终用 validation report archive 留下 baseline、状态中间值和 final 证据。

## 背景

当前已经有三条单点验证路径：

- `native/scripts/watchconnectivity-real-device-preflight.sh` 和 `docs/validation/watchconnectivity-real-device-runbook.md`。
- `native/scripts/healthkit-real-device-preflight.sh` 和 `docs/validation/healthkit-real-device-runbook.md`。
- `native/scripts/litertlm-real-device-preflight.sh` 和 `docs/validation/litertlm-real-device-runbook.md`。

这些入口各自可用，但 README 的下一步已经指向“端到端 real-device pass”。如果继续只让验证者手动拼三份文档，容易重复构建、遗漏 launch arguments、没有统一的 evidence 命名，也无法清楚说明 Runtime fallback 是否阻塞 Watch/HealthKit 验证。

## 方案

新增 `native/scripts/end-to-end-real-device-preflight.sh`：

- 默认调用三条单点 preflight 的轻量 wiring 检查：
  - WatchConnectivity：`--skip-build --skip-tests --skip-devices`。
  - HealthKit：`--skip-build --skip-tests`。
  - LiteRT-LM：`--skip-build --skip-tests`，可透传 `--require-real-runtime`。
- 总脚本只跑一次 `swift test`。
- 总脚本只跑一次 iOS generic build 和一次 watchOS generic build。
- 默认尝试 `xcrun devicectl list devices`，失败时只提示继续在 Xcode 里确认设备。
- 支持 `--skip-tests`、`--skip-build`、`--skip-devices`、`--require-real-runtime`、`--derived-data DIR`。
- SwiftPM / Xcode package cache 使用 DerivedData 下的可写目录，减少受用户 Home cache 权限影响。

新增 `docs/validation/end-to-end-real-device-runbook.md`：

- 本地预检：先跑总脚本，真实 Runtime 场景可加 `--require-real-runtime`。
- 真机 launch arguments：`--fitnessrpg-show-diagnostics`，截图/归档时使用 `--fitnessrpg-open-validation-report-archive`。
- 验证顺序：
  1. Baseline report。
  2. HealthKit 状态和 action rows。
  3. Watch send / Watch complete / iPhone inbound return。
  4. History latest day detail。
  5. Runtime fallback、fixture 或 real runtime。
  6. History weekly polish regenerate / clear / accepted cache。
  7. Final report 和 archive 确认。
- 失败分流：明确 Runtime fallback 不阻塞 Watch/HealthKit 验证；HealthKit 数据不足不阻塞 Watch sync；Watch inbound 不回来时先保存 report，再转单点 runbook。

更新 README：

- Root README 的 Next Major Work 第 4 项指向总 preflight 和总 runbook。
- Native README 的 Future Integration Points 增加端到端验证入口。

## 非目标

- 不新增真实设备自动化。
- 不更改 iOS / watchOS app 行为。
- 不下载或提交模型文件。
- 不默认要求 LiteRT-LM real runtime；默认仍允许 fallback 验证。

## 验证

- RED：`bash native/scripts/end-to-end-real-device-preflight.sh --help` 在脚本不存在时失败。
- GREEN：`bash native/scripts/end-to-end-real-device-preflight.sh --help` 输出 usage。
- 语法检查：`bash -n native/scripts/end-to-end-real-device-preflight.sh`。
- 轻量路径：`bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices`。
- 完整命令：`bash native/scripts/end-to-end-real-device-preflight.sh --skip-devices --derived-data /private/tmp/FitnessRPGEndToEndRealDevicePreflight`。
- `git diff --check`。
