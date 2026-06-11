# iOS Launch Screen 缩放修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 iOS app 添加现代 Launch Screen 配置，修复默认启动截图里的上下黑边和兼容缩放。

**Architecture:** 使用 `LaunchScreen.storyboard` 作为最小启动资源，并通过 generated Info.plist build setting 指向该 storyboard。验证以构建产物 `Info.plist` 和模拟器截图为准。

**Tech Stack:** Xcode project、Storyboard XML、generated Info.plist、iOS Simulator。

---

## 文件结构

- Create: `native/AppSources/iOS/LaunchScreen.storyboard`
  - 最小 iOS launch storyboard，提供系统全屏尺寸兼容声明。
- Modify: `native/FitnessRPG.xcodeproj/project.pbxproj`
  - 增加 storyboard file reference、resource build file、Resources phase 引用，以及 `INFOPLIST_KEY_UILaunchStoryboardName`。

## Task 1: 红测确认缺少 Launch Screen

- [x] **Step 1: 运行 Info.plist 检查**

```bash
plutil -extract UILaunchStoryboardName raw /private/tmp/FitnessRPGTodayPolishIOS/Build/Products/Debug-iphonesimulator/FitnessRPG.app/Info.plist
```

Expected: FAIL，提示 `UILaunchStoryboardName` 不存在。

## Task 2: 增加 Launch Screen 资源和配置

- [x] **Step 1: 创建 `LaunchScreen.storyboard`**

创建一个空白安全的 launch screen，背景使用 system grouped background，避免启动和 Today 页面之间出现强烈闪烁。

- [x] **Step 2: 更新 Xcode project**

把 storyboard 加入 iOS group 和 iOS Resources phase，并在 Debug/Release build settings 中加入：

```text
INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
```

## Task 3: 验证

- [x] **Step 1: iOS build**

```bash
xcodebuild -quiet -project native/FitnessRPG.xcodeproj -scheme FitnessRPG -destination 'platform=iOS Simulator,id=9B424038-58BD-41D9-A446-399BCC2265C2' -derivedDataPath /private/tmp/FitnessRPGLaunchFixIOS CODE_SIGNING_ALLOWED=NO build
```

- [x] **Step 2: Info.plist 绿测**

```bash
plutil -extract UILaunchStoryboardName raw /private/tmp/FitnessRPGLaunchFixIOS/Build/Products/Debug-iphonesimulator/FitnessRPG.app/Info.plist
```

Expected: PASS，输出 `LaunchScreen`。

- [x] **Step 3: 模拟器截图**

安装并启动 `/private/tmp/FitnessRPGLaunchFixIOS/Build/Products/Debug-iphonesimulator/FitnessRPG.app`，截图到 `/private/tmp/fitnessrpg-launch-fix.png`，确认 app 全屏显示。

- [x] **Step 4: 回归检查**

```bash
cd native/FitnessRPGCore
swift test
git diff --check
```
