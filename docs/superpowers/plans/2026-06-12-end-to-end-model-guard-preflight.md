# End-to-end Model Guard Preflight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把模型工件 Git 护栏接入端到端真机预检链，确保聚合 preflight 覆盖授权模型文件的提交安全。

**Architecture:** 保持聚合脚本作为总入口，新增一个前置 Git 护栏步骤；文档只更新端到端 runbook 的本地预检说明。单点 LiteRT-LM 脚本和 app 行为不变。

**Tech Stack:** Bash, Git, Swift Package verification, xcodebuild generic builds, Markdown.

---

## 文件结构

- 修改 `native/scripts/end-to-end-real-device-preflight.sh`：help 文本列出 Git 护栏，并默认调用 `model-artifact-git-guard.sh`。
- 修改 `docs/validation/end-to-end-real-device-runbook.md`：说明聚合 preflight 覆盖本地模型工件提交安全。

---

### Task 1: 接入模型工件 Git 护栏

**Files:**
- Modify: `native/scripts/end-to-end-real-device-preflight.sh`

- [x] **Step 1: RED 验证当前聚合脚本缺少 Git 护栏**

Run:

```bash
bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices | rg "Checking local model artifact git guard"
```

Expected: exits non-zero because the aggregate script does not print that guard step yet.

- [x] **Step 2: 更新脚本 help 文本**

在 usage 的 `Runbook:` 之前加入：

```text
Model Artifact Guard:
  native/scripts/model-artifact-git-guard.sh
```

- [x] **Step 3: 默认调用 Git 护栏**

在 `log "Checking local toolchain"` 之后、WatchConnectivity 检查之前加入：

```bash
log "Checking local model artifact git guard"
bash native/scripts/model-artifact-git-guard.sh
```

- [x] **Step 4: GREEN 验证轻量路径**

Run:

```bash
bash -n native/scripts/end-to-end-real-device-preflight.sh
bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices
```

Expected: both exit 0, and the light path prints “Checking local model artifact git guard”.

### Task 2: 更新端到端 runbook

**Files:**
- Modify: `docs/validation/end-to-end-real-device-runbook.md`

- [x] **Step 1: 更新 Local Preflight 说明**

在 aggregate preflight 命令后说明：

```markdown
The aggregate preflight also runs `native/scripts/model-artifact-git-guard.sh` so local licensed model files can stay in `ModelResources` without being tracked or staged.
```

- [x] **Step 2: 验证文档引用**

Run:

```bash
rg -n "model-artifact-git-guard|local licensed model files" docs/validation/end-to-end-real-device-runbook.md native/scripts/end-to-end-real-device-preflight.sh
```

Expected: output includes the script help text, the script call, and the runbook note.

### Task 3: 完整验证和提交

- [x] `bash native/scripts/model-artifact-git-guard.sh`
- [x] `bash native/scripts/end-to-end-real-device-preflight.sh --skip-build --skip-tests --skip-devices`
- [x] `swift test --package-path native/FitnessRPGCore`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `xcodebuild -project native/FitnessRPG.xcodeproj -scheme FitnessRPGWatch -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build`
- [x] `git diff --check`
- [x] Commit with `chore(native): include model guard in end-to-end preflight`
