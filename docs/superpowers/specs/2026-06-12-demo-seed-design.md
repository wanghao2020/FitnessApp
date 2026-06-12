# 2026-06-12 Demo Seed Design

## 目标

在完成真机 HealthKit、WatchConnectivity、LiteRT-LM 模型文件接入前，提供一个可重复打开的 DEBUG 演示入口。启动参数 `--fitnessrpg-demo-seed` 会写入一组确定性的 Today、History、Memory、周回顾润色和实机验证报告数据，让 iOS app 可以展示端到端体验。

## 范围

- Core 增加 `FitnessRPGDemoSeed.showcase`，集中生成演示数据。
- Persistence 增加一次性写入 API，确保所有演示集合保持一致。
- iOS app 在 DEBUG 下识别 `--fitnessrpg-demo-seed`，启动后写入并发布演示数据。
- README 记录启动参数，方便后续 demo 与截图。

## 数据要求

- 至少 4 天训练记录，覆盖绿灯完成、黄灯降阶、红灯恢复/跳过和今日完成。
- 今日记录必须有 quest、execution logs、workout result、story progression。
- Memory Review 至少有 3 条草稿。
- Weekly Summary 必须命中一条本地模型润色缓存。
- Validation Archive 至少有 2 条报告，能直接打开诊断归档页演示。

## 非目标

- 不替换正式 HealthKit、WatchConnectivity 或模型运行路径。
- 不把 demo seed 暴露到 release 自动入口。
- 不修改 Xcode 工程结构；优先复用 Swift Package 自动包含的 Core 文件和现有 iOS 源文件。
