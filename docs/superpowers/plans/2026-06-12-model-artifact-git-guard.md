# Model Artifact Git Guard 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LiteRT-LM / Gemma 本地模型资源增加 Git 护栏，避免授权模型包被误提交，同时继续支持真机本地验证。

**Architecture:** 使用 `.gitignore` 做默认保护，用 `native/scripts/model-artifact-git-guard.sh` 做可验证保护，再把脚本接入 `litertlm-integration-checklist.sh` 和相关文档。

**Tech Stack:** Bash, Git, Xcode project docs, Swift Package verification.

---

## 文件结构

- 修改 `.gitignore`：忽略 `ModelResources` 下的本地模型工件。
- 新建 `native/scripts/model-artifact-git-guard.sh`：检查被跟踪或暂存的模型工件。
- 修改 `native/scripts/litertlm-integration-checklist.sh`：默认运行 Git 护栏。
- 修改 `native/AppSources/iOS/ModelRuntime/ModelResources/README.md`：说明本地模型放置和提交护栏。
- 修改 `docs/validation/litertlm-real-device-runbook.md`：把护栏加入 LiteRT-LM 集成流程。
- 修改 `native/README.md`：在未来集成点中提到提交护栏。

---

### Task 1: 添加 Git 忽略规则和校验脚本

- [x] 更新 `.gitignore`，只忽略 `ModelResources` 目录下的模型二进制。
- [x] 新增 `native/scripts/model-artifact-git-guard.sh`。
- [x] 脚本检查 `.gitignore` 必要规则、已跟踪模型工件和暂存模型工件。
- [x] 脚本在失败时输出可执行的修复提示。

### Task 2: 接入 LiteRT-LM 集成检查

- [x] 在 `litertlm-integration-checklist.sh` 的 help 文本中列出 Git 护栏。
- [x] 在集成文件检查中要求护栏脚本存在。
- [x] 在默认 checklist 中运行护栏脚本。
- [x] 在 checklist 的 next steps 中提醒提交前运行护栏。

### Task 3: 更新文档

- [x] 更新 `ModelResources/README.md`，说明本地模型被 Git 忽略。
- [x] 更新 LiteRT-LM 真机 runbook，把 Git 护栏放到模型放置和提交流程中。
- [x] 更新 `native/README.md` 的 LiteRT-LM 后续集成说明。

### Task 4: 验证

- [x] `bash -n native/scripts/model-artifact-git-guard.sh`
- [x] `bash native/scripts/model-artifact-git-guard.sh`
- [x] `bash native/scripts/litertlm-integration-checklist.sh`
- [x] `git check-ignore native/AppSources/iOS/ModelRuntime/ModelResources/gemma-4-E2B-it.litertlm`
- [x] `swift test --package-path native/FitnessRPGCore`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `git diff --check`
