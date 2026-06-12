# WatchConnectivity 真机闭环验证 Runbook 设计

## 目标

为 iPhone + Apple Watch 真机验证提供一份可重复执行的 runbook 和一个本机预检脚本。验证者可以先确认本地工程、Core 测试和通用 build 状态，再在真实设备上按固定顺序检查 Watch 安装、Today 发送、Watch 执行、iPhone 回传、History 写入和验证报告归档。

## 背景

当前 DEBUG Today 已经具备：

- WatchConnectivity 诊断面板。
- 实机验证总览。
- 纯文本验证报告复制、保存和归档浏览。
- `--fitnessrpg-show-diagnostics` 和 `--fitnessrpg-open-validation-report-archive` 启动参数。

下一步需要把这些能力组织成一条真机验证流程。真实设备安装和签名仍依赖 Xcode/Apple Developer 配置，因此脚本不负责伪造设备状态或自动完成签名安装，而是做本机可自动化的预检，并输出下一步人工检查点。

## 方案

新增 `native/scripts/watchconnectivity-real-device-preflight.sh`：

- `--help` 输出使用说明。
- 检查命令：`xcodebuild`、`xcrun`、`swift`。
- 运行 `swift test --package-path native/FitnessRPGCore`。
- 构建 iOS generic target。
- 构建 watchOS generic target。
- 尝试运行 `xcrun devicectl list devices`，如果当前环境无法列出设备，只给出提示，不让脚本误判 app 功能失败。
- 输出真机 runbook 路径和推荐 DEBUG 启动参数。

新增 `docs/validation/watchconnectivity-real-device-runbook.md`：

- 前置条件：iPhone/Apple Watch 配对、Xcode 签名、DEBUG scheme、Watch App 安装。
- 启动参数：`--fitnessrpg-show-diagnostics`，需要截图归档时用 `--fitnessrpg-open-validation-report-archive`。
- 验证顺序：
  1. 本机预检。
  2. iPhone 启动 Today 诊断。
  3. 保存 baseline 验证报告。
  4. 检查 Watch 安装/配对/可达。
  5. 点击 Today 底部发送到 Watch。
  6. 在 Watch 上依次完成步骤。
  7. 回 iPhone 检查 inbound、History 和 Memory。
  8. 生成/清除 History weekly polish cache。
  9. 保存 final 验证报告。
- 失败分流：未安装、不可达、只排队不实时、回传不匹配、History 未写入、HealthKit 权限未完成、Runtime 资源缺失。

更新 README：

- Root README 的 Next Major Work 指向 runbook 和脚本。
- Native README 的 DEBUG Launch Arguments 增加 `--fitnessrpg-open-validation-report-archive`。
- Native README 的 Future Integration Points 指向 runbook。

## 非目标

- 不自动签名或安装真机 app。
- 不要求提交 Apple Developer Team ID。
- 不把真机结果写入仓库。
- 不新增 UI 或 WatchConnectivity 行为。
- 不替代真实 iPhone/Apple Watch 手动验证。

## 验证

- 先运行脚本不存在的 `--help` 命令作为 RED。
- 实现脚本后运行 `bash native/scripts/watchconnectivity-real-device-preflight.sh --help`。
- 运行 `bash -n native/scripts/watchconnectivity-real-device-preflight.sh`。
- 运行 `bash native/scripts/watchconnectivity-real-device-preflight.sh --skip-build --skip-tests` 验证轻量路径。
- 运行 `swift test --package-path native/FitnessRPGCore`。
- 运行 iOS / watchOS generic build。
- 运行 `git diff --check`。
